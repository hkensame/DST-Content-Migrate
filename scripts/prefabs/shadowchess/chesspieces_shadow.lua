
local PIECES =
{
    { name = "rook", moonevent=true, },
    { name = "knight", moonevent=true, },
    { name = "bishop", moonevent=true, },
}

local MOON_EVENT_RADIUS = 12
local MOONCHESS_MUST_TAGS = { "chess_moonevent" }
local PHYSICS_RADIUS = .45

local function makepiece(data)
  local build = "swap_chesspiece_"..data.name.."_marble"

local MOONCHESS_MUST_TAGS = { "chess_moonevent" }
local MOONCHESS_CANT_TAGS = { "INLIMBO" }
  local function DoStruggle(inst, count)
    if inst.forcebreak then
        if inst.components.workable ~= nil then
            inst.AnimState:PlayAnimation("jiggle")
            inst.SoundEmitter:PlaySound("dontstarve/common/together/sculptures/shake")
            inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() * 0.8, function(inst)
                if inst and inst.components.workable then
                    inst.components.workable:Destroy(inst)
                end
            end)
        end
    else
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, MOON_EVENT_RADIUS, MOONCHESS_MUST_TAGS, MOONCHESS_CANT_TAGS)
        inst.AnimState:PlayAnimation("jiggle")
        inst.SoundEmitter:PlaySound("dontstarve/common/together/sculptures/shake")
        inst._task =
            count > 1 and
            inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), DoStruggle, count - 1) or
            inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + math.random() + .6, DoStruggle, math.max(1, math.random(3) - 1))
    end
  end

  local function StartStruggle(inst)
    if inst._task == nil then
        inst._task = inst:DoTaskInTime(math.random(), DoStruggle, 1)
    end
  end

local function StopStruggle(inst)
    if inst._task ~= nil and inst.forcebreak ~= true then
        inst._task:Cancel()
        inst._task = nil
    end
end

local function CheckMorph(inst)
  local isnewmoon = (GetClock():IsNight() and GetClock():GetMoonPhase() == "new")
    if data.moonevent and isnewmoon and not inst:IsAsleep() then
        StartStruggle(inst)
    else
        StopStruggle(inst)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", build, "swap_body")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function onworkfinished(inst)

    if inst._task ~= nil or inst.forcebreak then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")

        local creature = SpawnPrefab("shadow_"..data.name)
        creature.Transform:SetPosition(inst.Transform:GetWorldPosition())
        creature.Transform:SetRotation(inst.Transform:GetRotation())
        creature.sg:GoToState("taunt")

        local player = GetPlayer() --creature:GetNearestPlayer(true)
        if player ~= nil and creature:IsNear(player, 20) then
            creature.components.combat:SetTarget(player)
        end

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, MOON_EVENT_RADIUS, MOONCHESS_MUST_TAGS)
        for i, v in ipairs(ents) do
            v.forcebreak = true
        end
    end

    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    --fx:SetMaterial("stone")
    inst:Remove()
end

local function getstatus(inst)
    return (inst._task ~= nil and "STRUGGLE")
        or nil
end

local function OnShadowChessRoar(inst, forcebreak)
    inst.forcebreak = true
    StartStruggle(inst)
end


    local prefabs =
    {
      "collapse_small",
    }

    local assets = 
        {
          Asset("ANIM", "anim/shadowchess/chesspiece.zip"),
            Asset("ANIM", "anim/shadowchess/"..build..".zip")
        }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()

        --MakeHeavyObstaclePhysics(inst, PHYSICS_RADIUS)
        MakeInventoryPhysics(inst, PHYSICS_RADIUS)
        inst:SetPhysicsRadiusOverride(PHYSICS_RADIUS)

        inst.AnimState:SetBank("chesspiece")
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("heavy")
        if data.moonevent then
            inst:AddTag("chess_moonevent")
            inst:AddTag("event_trigger")
        end

        --inst:SetPrefabName("chesspiece_"..data.name)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus

        inst:AddComponent("lootdropper")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.cangoincontainer = false
        inst.components.inventoryitem.imagename = "chesspiece_"..data.name
        inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.BODY
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        inst.components.equippable.walkspeedmult = -0.85

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(onworkfinished)

      if data.moonevent and GetWorld() and not GetWorld():IsCave() and not GetWorld():IsVolcano() then
        inst.OnEntityWake = CheckMorph
        inst.OnEntitySleep = CheckMorph

        inst:ListenForEvent( "daytime", function()
          inst:DoTaskInTime(1/30, function() CheckMorph(inst) end)
        end, GetWorld())
        inst:ListenForEvent( "dusktime", function()
          inst:DoTaskInTime(1/30, function() CheckMorph(inst) end)
        end, GetWorld())
        inst:ListenForEvent( "nighttime", function()
          inst:DoTaskInTime(1/30, function() CheckMorph(inst) end)
        end, GetWorld())

        inst:ListenForEvent("shadowchessroar", OnShadowChessRoar)
      end

        return inst
    end

    return Prefab("chesspiece_"..data.name, fn, assets, prefabs)
end

local chesspieces = {}
for k,v in pairs(PIECES) do
    table.insert(chesspieces, makepiece(v))
end

return unpack(chesspieces)
