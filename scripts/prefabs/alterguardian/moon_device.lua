assets = 
{
	Asset("ANIM", "anim/alterguardian/moon_device.zip"),
    Asset("ANIM", "anim/alterguardian/moon_device_break.zip"),
    Asset("ANIM", "anim/moonisland/moon_geyser.zip"),
}

local prefabs =
{
    "moon_device_pillar",
    "moon_device_top",
    "moon_altar_link_contained",
    "shadowmeteor",
}

local spawnpillars, spawntop
local BREAK_DELAY = 9.5
local METEOR_OFFSET_MIN = 9
local METEOR_OFFSET_VARIANCE = 10

local construction_data = {
	{level = 1, name = "moon_device_construction1"},
	{level = 2, name = "moon_device_construction2"},
	{level = 3, name = "moon_device"},
}

local function base_onbuilt(inst) --建造时播放动画
    inst.AnimState:PlayAnimation("stage1_idle_pre")
end

local function addpillar(inst, local_x, local_z, rotation) --柱子
    local pillar = SpawnPrefab("moon_device_pillar")
    pillar.entity:SetParent(inst.entity)
    pillar.Transform:SetPosition(local_x, 0, local_z)
    pillar.Transform:SetRotation(rotation)

    return pillar
end

spawnpillars = function(inst) --柱子
    if inst._pillars == nil then
        local x, y, z = inst.Transform:GetWorldPosition()

        local offset = 2.7

        inst._pillars = {}

        table.insert(inst._pillars, addpillar(inst, -offset, 0, 0))
        table.insert(inst._pillars, addpillar(inst, 0, -offset, 270))
        table.insert(inst._pillars, addpillar(inst, offset, 0, 180))
        table.insert(inst._pillars, addpillar(inst, 0, offset, 90))
    end
end

spawntop = function(inst) --顶端
    if inst._top == nil then
        inst._top = SpawnPrefab("moon_device_top")
        inst._top.entity:SetParent(inst.entity)
    end
end

local function playlinkanimation(inst, stage) --光特效
    if inst._link == nil then
        inst._link = SpawnPrefab("moon_altar_link_contained")
        inst._link.entity:SetParent(inst.entity)
    end

    inst._link:_set_stage_fn(stage)
end

local PLACER_SNAP_DISTANCE = 6
local MOON_ALTAR_LINK_TAGS = { "moon_altar_link" }
local function validate_spawn(inst)
    if not inst._has_replaced_moon_altar_link then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, PLACER_SNAP_DISTANCE, MOON_ALTAR_LINK_TAGS)
        if #ents > 0 then
            local link_x, _, link_z = ents[1].Transform:GetWorldPosition()
            inst.Transform:SetPosition(link_x, 0, link_z)

            ents[1]:Remove()

            inst._has_replaced_moon_altar_link = true
        else
            print("moon_device must be instantiated on top of a moon_altar_link -- removing instance")
            inst:Remove()
        end
    end
end

local function meteor_invitem_behaviour(inst, v)
    local x, y, z = inst.Transform:GetWorldPosition()

    if v.components.container ~= nil then
        if math.random() <= TUNING.METEOR_SMASH_INVITEM_CHANCE then
            v.components.container:DropEverything()
        end
    elseif v.components.mine ~= nil and not v.components.mine.inactive then
        v.components.mine:Deactivate()
    elseif math.random() <= TUNING.METEOR_SMASH_INVITEM_CHANCE and not v:HasTag("irreplaceable") then
        local vx, vy, vz = v.Transform:GetWorldPosition()
        v:Remove()
    end

    if not v.components.inventoryitem.nobounce then
        Launch(v, inst, TUNING.LAUNCH_SPEED_SMALL)
    elseif v.Physics ~= nil and v.Physics:IsActive() then
        local vx, vy, vz = v.Transform:GetWorldPosition()
        local dx, dz = vx - x, vz - z
        local spd = math.sqrt(dx * dx + dz * dz)
        local angle = (spd > 0 and math.atan2(dz / spd, dx / spd) + (math.random() * 20 - 10) * DEGREES)
            or math.random() * TWOPI
        spd = 3 + math.random() * 1.5
        v.Physics:Teleport(vx, 0, vz)
        v.Physics:SetVel(math.cos(angle) * spd, 0, math.sin(angle) * spd)
    end
end

local ALTAR_FX_PREFABS =
{
    moon_altar = "moon_altar_break",
    moon_altar_cosmic = "moon_altar_crown_break",
    moon_altar_astral = "moon_altar_claw_break"
}
local BREAK_CLEAR_AREA_RADIUS = 15
local BREAK_CLEAR_DAMAGE_RSQ = 30.25 -- 5.5^2
local BREAK_CLEAR_AREA_DESTROY_TAGS_CANT = {
    "FX", "ghost", "INLIMBO", "NOCLICK", "playerghost",
}
local BREAK_CLEAR_AREA_DESTROY_TAGS_ONEOF = { "_combat", "_inventoryitem", "CHOP_workable", "DIG_workable", "HAMMER_workable", "MINE_workable" }
local function ClearArea(inst)
    --ShakeAllCameras(CAMERASHAKE.FULL, 0.91, 0.026, 0.75, inst, 50)

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, BREAK_CLEAR_AREA_RADIUS, nil, BREAK_CLEAR_AREA_DESTROY_TAGS_CANT) --, BREAK_CLEAR_AREA_DESTROY_TAGS_ONEOF)
    for _, v in ipairs(ents) do
        if v ~= inst and v:IsValid() then
            local fx_prefab = ALTAR_FX_PREFABS[v.prefab]
            if fx_prefab ~= nil then
                local altar_x, altar_y, altar_z = v.Transform:GetWorldPosition()
                SpawnPrefab(fx_prefab).Transform:SetPosition(altar_x, altar_y, altar_z)
                SpawnPrefab("moon_fissure").Transform:SetPosition(altar_x, 0, altar_z)
                v:Remove()
            elseif v.components.health ~= nil and v:HasTag("smashable") then
                v.components.health:Kill()
            elseif v.components.workable ~= nil and v.components.workable:CanBeWorked()
                    and v.components.workable.action ~= ACTIONS.NET then
                if not v:HasTag("moonglass") then
                    SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
                end
                v.components.workable:Destroy(inst)
            elseif v.components.health ~= nil and v.components.combat ~= nil
                    and not v.components.health:IsDead()
                    and v:GetDistanceSqToPoint(x, y, z) < BREAK_CLEAR_DAMAGE_RSQ then
                v.components.combat:GetAttacked(inst, TUNING.ALTERGUARDIAN_PHASE1_ROLLDAMAGE)
            elseif v.components.inventoryitem ~= nil then
                meteor_invitem_behaviour(inst, v)
            end
        end
    end
end

local function spawnscorchmark(x, z, scale)
    local scorch = SpawnPrefab("burntground")
    scorch.Transform:SetPosition(x, 0, z)
    scorch.Transform:SetScale(scale, scale, scale)
end

local function stage1_break(inst)
    ClearArea(inst) --三个雕像被破坏

    local ix, _, iz = inst.Transform:GetWorldPosition()

    SpawnPrefab("moon_device_break_stage1").Transform:SetPosition(ix, 0, iz)
    SpawnPrefab("moon_geyser_explode").Transform:SetPosition(ix, 0, iz)

    spawnscorchmark(ix, iz, 1.6)

    local angle_offset = math.random() * PI
    for i = 1, 3 do
        local theta = ((2 * PI) / 3) * i + angle_offset
        local offset = 1 + math.random()
        spawnscorchmark(ix + math.cos(theta) * offset, iz + math.sin(theta) * offset, 1.1 + 0.4 * math.random())
    end
end

--破坏并生成天体英雄
local function do_boss_spawn(inst)
    local ix, _, iz = inst.Transform:GetWorldPosition()
    local boss = SpawnPrefab("alterguardian_phase1")
    boss.Transform:SetPosition(ix, 0, iz)
    boss.sg:GoToState("prespawn_idle")

    inst:Remove()
end

local function break_device(inst)
    --stage3_break(inst)
    --stage2_break(inst)
    stage1_break(inst)

    inst:DoTaskInTime(1*FRAMES, do_boss_spawn)
    inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian1/spawn_pre")
end

local function breaksequence(inst)
    local fall_fx = SpawnPrefab("alterguardian_phase1fallfx")
    fall_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())

    -- Should be timed up with the phase1fallfx anim/fx spawned above.
    inst:DoTaskInTime(9*FRAMES, break_device)
end

------调查------
local function GetVerb(inst)
    return "INVESTIGATE"
end

local function OnInvestigated(inst, doer) --生成流星
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("moon_device_meteor_spawner").Transform:SetPosition(x, y, z)
    inst:DoTaskInTime(BREAK_DELAY, breaksequence) --破坏
end
--------

local function fn()
  local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.Transform:SetEightFaced()
    inst.MiniMapEntity:SetIcon("moon_device.tex")

    inst.AnimState:SetBank("moon_device_stages")
    inst.AnimState:SetBuild("moon_device")
    inst.AnimState:PlayAnimation("stage1_idle", false) --底座
    --inst.AnimState:PlayAnimation("stage1_idle_pre") --生成底座

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst:SetPrefabNameOverride("moon_device")

    inst:AddTag("moon_device")
    inst:AddTag("structure")
    inst:AddTag("nomagic")

      playlinkanimation(inst, 3) --光特效
      spawnpillars(inst) --生成柱子
      spawntop(inst) --生成顶端
      inst:DoTaskInTime(0, validate_spawn)
      
      inst:AddComponent("activatable_dst")
      inst.components.activatable_dst.OnActivate = OnInvestigated
      inst.components.activatable_dst.inactive = true
      inst.components.activatable_dst.quickaction = true --使用泰拉瑞亚的触摸动作
      --inst.components.activatable_dst.getverb = GetVerb

  return inst
end

--底座，单独写个底座方便生成
local function fn2()
  local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.Transform:SetEightFaced()

    inst.AnimState:SetBank("moon_device_stages")
    inst.AnimState:SetBuild("moon_device")
    inst.AnimState:PlayAnimation("stage1_idle", false) --底座
    --inst.AnimState:PlayAnimation("stage1_idle_pre") --生成底座

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:SetPrefabNameOverride("moon_device")
    
    inst:ListenForEvent("onbuilt", function(inst)
        GetPlayer().components.talker:Say("长按激活月亮虹吸器！")
        
        local ix, _, iz = inst.Transform:GetWorldPosition()
        SpawnPrefab("moon_device").Transform:SetPosition(ix, 0, iz)
        inst:Remove()
    end)


  return inst
end


local function pillarfn()

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.Transform:SetEightFaced()

    inst.AnimState:SetBank("moon_device_stages")
    inst.AnimState:SetBuild("moon_device")
    inst.AnimState:PlayAnimation("stage2_idle") --柱子

    inst:SetPrefabNameOverride("moon_device")

    inst.persists = false

    return inst
end

local function topfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.Transform:SetEightFaced()
    inst.Transform:SetRotation(45)

    inst.AnimState:SetBank("moon_device_stages")
    inst.AnimState:SetBuild("moon_device")
    inst.AnimState:PlayAnimation("stage3_idle", true) --顶端

    inst:SetPrefabNameOverride("moon_device")

    inst.persists = false

    return inst
end

----建造限制
local function placer_onupdatetransform(inst)
    local pos = inst:GetPosition()
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, PLACER_SNAP_DISTANCE, { "moon_altar_link" })

    if #ents > 0 then
        local targetpos = ents[1]:GetPosition()
        inst.Transform:SetPosition(targetpos.x, 0, targetpos.z)

        inst.accept_placement = ents[1]:HasTag("can_build_moon_device")
    else
        inst.accept_placement = false
    end
end

local function placer_override_build_point(inst)
    -- Gamepad defaults to this behavior, but mouse input normally takes
    -- mouse position over placer position, ignoring the placer snapping
    -- to a nearby moon geyser
    return inst:GetPosition()
end

local function placer_override_testfn(inst)
    local can_build, mouse_blocked = true, false

    if inst.components.placer.testfn ~= nil then
        can_build, mouse_blocked = inst.components.placer.testfn(inst:GetPosition(), inst:GetRotation())
    end

    -- can_build = can_build and inst.accept_placement

    -- testfn just checks Map:CanDeployRecipeAtPoint(). If there is a valid geyser but the build
    -- position doesn't pass this check it's either because
    --      1.  The area is blocked by an item that can exist on top of the device, so building under it is fine
    --      2.  The area is blocked by a structure; it doesn't really matter if we allow building under it
    --      3.  The area is invalid (over water or something); shouldn't really be hitting this since the
    --          moon_altar_link wouldn't be valid at that point, but if something goes wrong it's better to
    --          just allow building on it than locking all further progress

    -- Better to just override can_build.

    can_build = inst.accept_placement

    return can_build, mouse_blocked
end

local function placer_postinit_fn(inst)
	inst.Transform:SetEightFaced()

    inst.components.placer.onupdatetransform = placer_onupdatetransform
    inst.components.placer.override_build_point_fn = placer_override_build_point

    inst.components.placer.override_testfn = placer_override_testfn

    inst.accept_placement = false
end
----------------

local function break_stage1_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("moon_device_break")
    inst.AnimState:SetBuild("moon_device_break")
    inst.AnimState:PlayAnimation("stage1_break", false)

    inst:AddTag("FX")

    inst.persists = false

    inst:DoTaskInTime(1.5, ErodeAway)

    return inst
end

--流星--
local function spawnmeteor(inst)
    local x, _, z = inst.Transform:GetWorldPosition()

    local offset = METEOR_OFFSET_MIN + math.random() * METEOR_OFFSET_VARIANCE
    local theta = math.random() * 2 * PI

    SpawnPrefab("shadowmeteor").Transform:SetPosition(x + math.cos(theta) * offset, 0, z + math.sin(theta) * offset)
end

local function spawnmeteorandremove(inst)
    spawnmeteor(inst)
    inst:Remove()
end

local function meteor_spawner_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst.persists = false

    inst:DoTaskInTime(BREAK_DELAY * 0.49, spawnmeteor)
    inst:DoTaskInTime(BREAK_DELAY * 0.58, spawnmeteor)
    inst:DoTaskInTime(BREAK_DELAY * 0.65, spawnmeteor)
    inst:DoTaskInTime(BREAK_DELAY * 0.72, spawnmeteor)

    inst:DoTaskInTime(BREAK_DELAY * 1.06, spawnmeteor)
    inst:DoTaskInTime(BREAK_DELAY * 1.12, spawnmeteorandremove)

    return inst
end
----光特效----
--[[
local function contained_set_stage(inst, stage)
    inst._stage = stage

    inst.AnimState:PlayAnimation("stage"..stage.."_idle_pre", false)
    inst.AnimState:PushAnimation("stage"..stage.."_idle", true)
end

local function contained_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBuild("moon_geyser")
    inst.AnimState:SetBank("moon_altar_geyser")
    inst.AnimState:PlayAnimation("stage1_idle", true)

    inst.AnimState:SetLightOverride(1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.persists = false

    inst._stage = 1
    inst._set_stage_fn = contained_set_stage

    return inst
end
--]]
return Prefab("moon_device", fn, assets, prefabs),
       Prefab("moon_device_construction1", fn2, assets, prefabs),
       Prefab("moon_device_pillar", pillarfn, assets, prefabs),
       Prefab("moon_device_top", topfn, assets, prefabs),
       Prefab("moon_device_break_stage1", break_stage1_fn, assets, prefabs),
       Prefab("moon_device_meteor_spawner", meteor_spawner_fn, assets, prefabs),
       --Prefab("moon_altar_link_contained", contained_fn, assets, prefabs),
       MakePlacer("moon_device_placer", "moon_device_stages", "moon_device", "stage1_idle", true, nil, nil, nil, nil, nil, nil, nil, nil, placer_postinit_fn),
       MakePlacer("moon_device_construction1_placer", "moon_device_stages", "moon_device", "stage1_idle", true, nil, nil, nil, nil, nil, nil, nil, nil, placer_postinit_fn)