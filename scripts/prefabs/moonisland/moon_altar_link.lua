local assets =
{
    Asset("ANIM", "anim/moonisland/moon_geyser.zip"),
}

local contained_assets =
{
    Asset("ANIM", "anim/moonisland/moon_geyser.zip"),
}

local prefabs =
{
    "moon_altar_link_contained",
    "moonpulse_spawner",
}

local CANT_DESTROY_PREFABS = { moon_altar = true, moon_altar_cosmic = true, moon_altar_astral = true }

local DESTROY_TAGS_ONEOF = { "structure", "tree", "boulder" }

local LAUNCH_ITEMS_TAGS = { "_inventoryitem" }
local LAUNCH_ITEMS_NOTAGS = { "INLIMBO" }

local ITEM_LAUNCH_SPEED_MULTIPLIER = 1.8
local ITEM_LAUNCH_SPEED_MULTIPLIER_VARIANCE = 2.5

local function startmoonstorms(inst)
    TheWorld:PushEvent("ms_startthemoonstorms")

    if not inst:HasTag("can_build_moon_device") then
        inst:AddTag("can_build_moon_device")
    end
end

local function ClearArea(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local ents = TheSim:FindEntities(x, y, z, TUNING.MOON_ALTAR_LINK_AREA_CLEAR_RADIUS, nil, nil, DESTROY_TAGS_ONEOF)
    for i, v in ipairs(ents) do
        if v:IsValid() and v.components.workable ~= nil and v.components.workable:CanBeWorked() and not CANT_DESTROY_PREFABS[v.prefab] then
            SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
            v.components.workable:Destroy(inst)
        end
    end
end

local function moonstormexists(inst)
--[[
    return TheWorld.net.components.moonstorms ~= nil
        and (
            next(TheWorld.net.components.moonstorms:GetMoonstormNodes()) ~= nil
            or TheWorld.components.moonstormmanager.startmoonstormtask ~= nil
        )--]]
end

local function startmoonstormsequence(inst)--[[
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("moonpulse_spawner").Transform:SetPosition(x, y, z)

    -- Delay matches third (and biggest) pulse in moonpulse
    inst:DoTaskInTime(5.04, startmoonstorms)--]]
end

local function onlinkpreanimover(inst)
    inst:RemoveEventCallback("animover", onlinkpreanimover)

    inst.AnimState:PlayAnimation("stage0_low_to_high", false)
    inst.AnimState:PushAnimation("stage0_high_idle", true)

    startmoonstormsequence(inst)
end

local function OnLinkEstablished(inst, altars)
    if not POPULATING then
        for i, altar in ipairs(altars) do
            inst.components.entitytracker:TrackEntity(altar.prefab, altar)
            
            -- 三角形形成：将三个祭坛的科技等级提升到 CELESTIAL=4
            if altar.components.prototyper ~= nil then
                altar.components.prototyper.trees = { CELESTIAL = 4 }
            end
        end

        ClearArea(inst)

        -- DS 没有月风暴，三角形形成后直接允许建造月亮虹吸器
        if not inst:HasTag("can_build_moon_device") then
            inst:AddTag("can_build_moon_device")
        end

        inst.AnimState:PlayAnimation("stage0_low_pre", false)
        inst:ListenForEvent("animover", onlinkpreanimover)

        inst.SoundEmitter:PlaySound("grotto/common/moon_alter/link/start")
        --改，ShakeAllCameras(CAMERASHAKE.VERTICAL, 2.4, .02, .18, inst, 12)
    else
        inst.AnimState:PlayAnimation("stage0_high_idle", true)

        -- 加载时恢复 can_build_moon_device 标签
        if not inst:HasTag("can_build_moon_device") then
            inst:AddTag("can_build_moon_device")
        end

        if moonstormexists(inst) then
            if not inst:HasTag("can_build_moon_device") then
                inst:AddTag("can_build_moon_device")
            end
        end
    end
end

local function OnEntitySleep(inst)
    if inst.SoundEmitter:PlayingSound("loop") then
        inst.SoundEmitter:KillSound("loop")
    end
end

local function OnEntityWake(inst)
    if not inst.SoundEmitter:PlayingSound("loop") then
        inst.SoundEmitter:PlaySound("grotto/common/moon_alter/link/LP", "loop")
        inst.SoundEmitter:SetParameter("loop", "intensity", 0)
    end
end

local function mindistancetest(altar1, altar2)
    local x1, _, z1 = altar1.Transform:GetWorldPosition()
    local x2, _, z2 = altar2.Transform:GetWorldPosition()

    return VecUtil_LengthSq(x2 - x1, z2 - z1) >= TUNING.MOON_ALTAR_LINK_ALTAR_MIN_RADIUS_SQ
end

local function OnLoadPostPass(inst)
    local moon_altar = inst.components.entitytracker:GetEntity("moon_altar")
    local moon_altar_cosmic = inst.components.entitytracker:GetEntity("moon_altar_cosmic")
    local moon_altar_astral = inst.components.entitytracker:GetEntity("moon_altar_astral")

    if moon_altar ~= nil and moon_altar_cosmic ~= nil and moon_altar_astral ~= nil then
        -- DS 没有 moonstormmanager，跳过三角形有效性检查
        inst.components.moonaltarlink:EstablishLink({ moon_altar, moon_altar_cosmic, moon_altar_astral })
    else
        if moon_altar ~= nil then moon_altar._force_on = false end
        if moon_altar_cosmic ~= nil then moon_altar_cosmic._force_on = false end
        if moon_altar_astral ~= nil then moon_altar_astral._force_on = false end

        inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBuild("moon_geyser")
    inst.AnimState:SetBank("moon_altar_geyser")
    inst.AnimState:PlayAnimation("stage0_low_idle", true)
    inst.scrapbook_anim = "stage1_idle"
    inst.scrapbook_animoffsetx = 12

    inst.AnimState:SetLightOverride(1)

    inst:AddTag("NOBLOCK")
    inst:AddTag("moon_altar_link")

    inst.scrapbook_specialinfo = "MOONALTARLINK"
--[[
    if not TheNet:IsDedicated() then
        -- DS 没有 pointofinterest 组件
        --inst:AddComponent("pointofinterest")
        --inst.components.pointofinterest:SetHeight(70)
    end
--]]
    inst._spawned_from_load = POPULATING

    inst:AddComponent("inspectable")

    inst:AddComponent("entitytracker")

    inst:AddComponent("moonaltarlink")
    inst.components.moonaltarlink.onlinkfn = OnLinkEstablished

    inst:ListenForEvent("ms_moonstormwindowover", function()
        if inst._spawned_from_load then
            if not moonstormexists(inst) then
                startmoonstormsequence(inst)
            else
                inst:AddTag("can_build_moon_device")
            end
        end
    end, GetWorld())

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

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

return Prefab("moon_altar_link", fn, assets, prefabs),
    Prefab("moon_altar_link_contained", contained_fn, contained_assets)
