-- DS 移植版：移除 net_*/AddNetwork/SetPristine/ismastersim/scrapbook
-- flower_cave.lua — 洞穴荧光花（含枯萎变种）

local assets =
{
    Asset("ANIM", "anim/bulb_plant_single.zip"),
    Asset("ANIM", "anim/bulb_plant_double.zip"),
    Asset("ANIM", "anim/bulb_plant_triple.zip"),
    Asset("ANIM", "anim/bulb_plant_springy.zip"),
    Asset("SOUND", "sound/common.fsb"),
    Asset("MINIMAP_IMAGE", "bulb_plant"),
}

local withered_assets = {
    Asset("ANIM", "anim/bulb_plant_single_withered_build.zip"),
    Asset("ANIM", "anim/bulb_plant_double_withered_build.zip"),
    Asset("ANIM", "anim/bulb_plant_triple_withered_build.zip"),
    Asset("ANIM", "anim/bulb_plant_springy_withered_build.zip"),
    Asset("MINIMAP_IMAGE", "bulb_plant_withered"),
}

local prefabs =
{
    "lightbulb",
}

local withered_prefabs =
{
    "spoiled_food",
}

local LIGHT_STATES =
{
    ON = "ON",
    CHARGED = "CHARGED",
    RECHARGING = "RECHARGING",
}

local STATE_ANIMS =
{
    [LIGHT_STATES.ON] = { "recharge", "idle" },
    [LIGHT_STATES.CHARGED] = { "revive", "off" },
    [LIGHT_STATES.RECHARGING] = { "drain", "withered" },
}

local LIGHT_MIN_TIME = 4
local LIGHT_MAX_TIME = 8

local function UpdateLight(inst, dt)
    local frame = inst._lightframe + dt
    if frame >= inst._lightmaxframe then
        inst._lightframe = inst._lightmaxframe
        if inst._lighttask then
            inst._lighttask:Cancel()
            inst._lighttask = nil
        end
    else
        inst._lightframe = frame
    end

    local k = inst._lightframe / inst._lightmaxframe

    if not inst._islighton then
        inst.Light:SetRadius(inst.light_params.radius * (1 - k))
        inst.Light:SetIntensity(inst.light_params.intensity * (1 - k))
        inst.Light:SetFalloff(k + inst.light_params.falloff * (1 - k))
    elseif k < .33 then
        k = k / .33
        inst.Light:SetRadius(inst.light_params.radius * 1.33 * k)
        inst.Light:SetIntensity(inst.light_params.intensity * k)
        inst.Light:SetFalloff(inst.light_params.falloff * .8 * k + 1 - k)
    else
        k = (k - .33) / .67
        inst.Light:SetRadius(inst.light_params.radius * (k + 1.33 * (1 - k)))
        inst.Light:SetIntensity(inst.light_params.intensity)
        inst.Light:SetFalloff(inst.light_params.falloff * (k + .8 * (1 - k)))
    end

    inst.Light:Enable(inst._islighton or inst._lightframe < inst._lightmaxframe)
end

local function StartLightTween(inst)
    if inst._lighttask == nil then
        inst._lighttask = inst:DoPeriodicTask(FRAMES, function() UpdateLight(inst, FRAMES) end, nil, 1)
    end
    inst._lightmaxframe = math.floor((inst._lighttime + LIGHT_MIN_TIME) / FRAMES + .5)
    UpdateLight(inst, 0)
end

local function EndLight(inst)
    inst._lightframe = inst._lightmaxframe
    StartLightTween(inst)
end

local function SetLightState(inst, state)
    inst.AnimState:PlayAnimation(STATE_ANIMS[state][1])
    for i=2,#STATE_ANIMS[state] do
        inst.AnimState:PushAnimation(STATE_ANIMS[state][i], STATE_ANIMS[state][i] == "idle")
    end
    inst.light_state = state
end

local function CanTurnOn(inst)
    return inst.light_state == LIGHT_STATES.CHARGED
end

local function ForceOff(inst, on_load)
    if inst.light_state == LIGHT_STATES.ON then
        inst:SetLightState(LIGHT_STATES.RECHARGING)
    elseif on_load then
        inst.AnimState:PlayAnimation(STATE_ANIMS[inst.light_state][#STATE_ANIMS[inst.light_state]])
    end
    inst._islighton = false
    EndLight(inst)
end

local function ForceOn(inst)
    if not inst.components.pickable:CanBePicked() then
        return
    end
    inst:SetLightState(LIGHT_STATES.ON)
    inst._islighton = true
    EndLight(inst)
end

local function TurnOff(inst)
    local tween_time = math.random(LIGHT_MIN_TIME, LIGHT_MAX_TIME)
    local recharge_time = inst.light_params.recharge_time and FunctionOrValue(inst.light_params.recharge_time, inst, tween_time) or TUNING.FLOWER_CAVE_RECHARGE_TIME + tween_time
    inst.components.timer:StartTimer("recharge", recharge_time)
    inst:SetLightState(LIGHT_STATES.RECHARGING)
    inst._islighton = false
    inst._lightframe = 0
    inst._lighttime = tween_time - LIGHT_MIN_TIME
    StartLightTween(inst)
end

local function TurnOn(inst)
    if not inst.components.pickable:CanBePicked() then
        return
    end
    if not inst:CanTurnOn() then return end
    inst:SetLightState(LIGHT_STATES.ON)
    local tween_time = math.random(LIGHT_MIN_TIME, LIGHT_MAX_TIME)
    inst._islighton = true
    inst._lightframe = 0
    inst._lighttime = tween_time - LIGHT_MIN_TIME
    StartLightTween(inst)
    local turn_off_time = inst.light_params.turnoff_time and FunctionOrValue(inst.light_params.turnoff_time, inst, tween_time) or TUNING.FLOWER_CAVE_LIGHT_TIME + tween_time + (math.random() * 10)
    inst.components.timer:StartTimer("turnoff", turn_off_time)
end

local function Recharge(inst)
    inst:SetLightState(LIGHT_STATES.CHARGED)
    if inst:IsInLight() then
        TurnOn(inst)
    end
end

local function ontimerdone(inst, data)
    if data.name == "recharge" then
        Recharge(inst)
    elseif data.name == "turnoff" then
        TurnOff(inst)
    end
end

local function enterlight(inst)
    TurnOn(inst)
end

local function onregenfn(inst)
    TurnOff(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

local function makefullfn(inst)
    inst.AnimState:PlayAnimation("idle", true)
end

local function onpickedfn(inst)
    ForceOff(inst)
    inst.components.timer:StopTimer("turnoff")
    inst.components.timer:StopTimer("recharge")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lightbulb")
    if inst.is_bulb_withered then
        inst.AnimState:PlayAnimation("picked_wilt")
        inst.persists = false
        inst:ListenForEvent("animover", inst.Remove)
    else
        inst.AnimState:PlayAnimation("picking")
        inst.AnimState:PushAnimation(inst.components.pickable:IsBarren() and "idle_dead" or "picked")
    end
end

local function makeemptyfn(inst)
    ForceOff(inst)
    inst.components.timer:StopTimer("turnoff")
    inst.components.timer:StopTimer("recharge")
    inst.AnimState:PlayAnimation("picked")
end

local function OnSave(inst, data)
    data.light_state = inst.light_state
    data.islighton = inst._islighton
end

local function OnLoad(inst, data)
    if data == nil then return end
    inst.light_state = data.light_state
    inst._islighton = data.islighton or false
    if inst.components.pickable:CanBePicked() then
        if inst.light_state == LIGHT_STATES.ON then
            ForceOn(inst)
        elseif inst.light_state == LIGHT_STATES.CHARGED
            or inst.light_state == LIGHT_STATES.RECHARGING then
            ForceOff(inst, true)
        end
    else
        ForceOff(inst)
    end
end

local function TurnOnInLight(inst)
    if inst:IsInLight() then
        TurnOn(inst)
    end
end

local function OnWake(inst)
    inst:DoTaskInTime(1, TurnOnInLight)
end

local function GetDebugString(inst)
    return string.format("State: %s", inst.light_state)
end

local LIGHT_COLOUR = {237/255, 237/255, 209/255}
local WITHERED_COLOUR = {201/255, 93/255, 10/255}
local function commonfn(bank, build, light_params, is_withered)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddLightWatcher()

    inst:AddTag("plant")

    inst.LightWatcher:SetLightThresh(.075)
    inst.LightWatcher:SetDarkThresh(.05)

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(0)
    inst.Light:SetRadius(0)
    inst.Light:SetColour(unpack(is_withered and WITHERED_COLOUR or LIGHT_COLOUR))
    inst.Light:Enable(false)
    if inst.Light.EnableClientModulation ~= nil then
        inst.Light:EnableClientModulation(true)
    end

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("off")

    inst.MiniMapEntity:SetIcon(is_withered and "bulb_plant_withered.png" or "bulb_plant.png")

    inst.light_params = light_params
    inst._lighttime = 0
    inst._lightframe = 0
    inst._islighton = false
    inst._lightmaxframe = math.floor(LIGHT_MIN_TIME / FRAMES + .5)
    inst._lighttask = nil

    inst:SetPrefabNameOverride(is_withered and "flower_cave_withered" or "flower_cave")

    -- === Master Simulation ===
    inst.is_bulb_withered = is_withered
    inst.light_state = LIGHT_STATES.CHARGED

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddComponent("timer")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    inst.components.pickable.makefullfn = makefullfn
    inst.components.pickable.max_cycles = 20
    inst.components.pickable.cycles_left = 20

    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)

    if not is_withered then
        -- DS 无 halloweenmoonmutable 组件，安全跳过
        local ok, err = pcall(function()
            inst:AddComponent("halloweenmoonmutable")
            inst.components.halloweenmoonmutable:SetPrefabMutated("lightflier_flower")
            inst.components.halloweenmoonmutable:SetOnMutateFn(OnMoonMutate)
        end)
        if not ok then print("[flower_cave] halloweenmoonmutable skipped:", err) end
        if rawget(_G, "AddToRegrowthManager") then AddToRegrowthManager(inst) end
    end

    inst.CanTurnOn = CanTurnOn
    inst.SetLightState = SetLightState
    inst.TurnOn = TurnOn

    -- DS 无 IsInLight 方法，用 LightWatcher 实现兼容
    if not inst.IsInLight then
        inst.IsInLight = function(self)
            return self.LightWatcher and self.LightWatcher:IsInLight() or false
        end
    end

    inst:ListenForEvent("timerdone", ontimerdone)
    inst:ListenForEvent("enterlight", enterlight)

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave
    inst.OnEntityWake = OnWake
    inst.debugstringfn = GetDebugString

    if rawget(_G, "MakeHauntableIgnite") then MakeHauntableIgnite(inst) end

    return inst
end

local plantnames = { "_single", "_springy" }

local function onsave_single(inst, data)
    OnSave(inst, data)
    data.plantname = inst.plantname
end

local function onload_single(inst, data)
    OnLoad(inst, data)
    if data ~= nil and data.plantname ~= nil then
        inst.plantname = data.plantname
        if inst.plantname ~= "_single" then
            inst.AnimState:SetBank("bulb_plant"..inst.plantname)
            inst.AnimState:SetBuild("bulb_plant"..inst.plantname)
        end
    end
end

local function onload_withered_single(inst, data)
    OnLoad(inst, data)
    if data ~= nil and data.plantname ~= nil then
        inst.plantname = data.plantname
        if inst.plantname ~= "_single" then
            inst.AnimState:SetBank("bulb_plant"..inst.plantname)
            inst.AnimState:SetBuild("bulb_plant"..inst.plantname.."_withered_build")
        end
    end
end

local lightparams_single =
{
    falloff = .5,
    intensity = .8,
    radius = 3,
}

local function single()
    local inst = commonfn("bulb_plant_single", "bulb_plant_single", lightparams_single)

    inst.plantname = plantnames[math.random(1, #plantnames)]
    if inst.plantname ~= "_single" then
        inst.AnimState:SetBank("bulb_plant"..inst.plantname)
        inst.AnimState:SetBuild("bulb_plant"..inst.plantname)
    end

    inst.components.pickable:SetUp("lightbulb", TUNING.FLOWER_CAVE_REGROW_TIME)

    inst.OnSave = onsave_single
    inst.OnLoad = onload_single

    return inst
end

local lightparams_double =
{
    falloff = .5,
    intensity = .8,
    radius = 4.5,
}

local function double()
    local inst = commonfn("bulb_plant_double", "bulb_plant_double", lightparams_double)

    inst.components.pickable:SetUp("lightbulb", TUNING.FLOWER_CAVE_REGROW_TIME * 1.5, 2)

    return inst
end

local lightparams_triple =
{
    falloff = .5,
    intensity = .8,
    radius = 4.5,
}

local function triple()
    local inst = commonfn("bulb_plant_triple", "bulb_plant_triple", lightparams_triple)

    inst.components.pickable:SetUp("lightbulb", TUNING.FLOWER_CAVE_REGROW_TIME * 2, 3)

    return inst
end

-- Withered prefabs

local function withered_turnoff_time(inst, tween_time)
    return TUNING.FLOWER_CAVE_WITHERED_LIGHT_TIME + tween_time + (math.random() * 3)
end

local function withered_recharge_time(inst, tween_time)
    return TUNING.FLOWER_CAVE_WITHERED_RECHARGE_TIME + tween_time
end

local lightparams_withered_single =
{
    falloff = 1.5,
    intensity = .2,
    radius = 2,
    turnoff_time = withered_turnoff_time,
    recharge_time = withered_recharge_time,
}

local function withered_single()
    local inst = commonfn("bulb_plant_single", "bulb_plant_single_withered_build", lightparams_withered_single, true)

    inst.plantname = plantnames[math.random(1, #plantnames)]
    if inst.plantname ~= "_single" then
        inst.AnimState:SetBank("bulb_plant"..inst.plantname)
        inst.AnimState:SetBuild("bulb_plant"..inst.plantname.."_withered_build")
    end

    inst.components.pickable:SetUp("spoiled_food", TUNING.FLOWER_CAVE_REGROW_TIME)

    inst.OnSave = onsave_single
    inst.OnLoad = onload_withered_single

    return inst
end

local lightparams_withered_double =
{
    falloff = 1.5,
    intensity = .2,
    radius = 2.5,
}

local function withered_double()
    local inst = commonfn("bulb_plant_double", "bulb_plant_double_withered_build", lightparams_withered_double, true)

    inst.components.pickable:SetUp("spoiled_food", TUNING.FLOWER_CAVE_REGROW_TIME * 1.5, 2)

    return inst
end

local lightparams_withered_triple =
{
    falloff = 1.5,
    intensity = .2,
    radius = 2.5,
}

local function withered_triple()
    local inst = commonfn("bulb_plant_triple", "bulb_plant_triple_withered_build", lightparams_withered_triple, true)

    inst.components.pickable:SetUp("spoiled_food", TUNING.FLOWER_CAVE_REGROW_TIME * 2, 3)

    return inst
end

return Prefab("flower_cave", single, assets, prefabs),
    Prefab("flower_cave_double", double, assets, prefabs),
    Prefab("flower_cave_triple", triple, assets, prefabs),
    Prefab("flower_cave_withered", withered_single, withered_assets, withered_prefabs),
    Prefab("flower_cave_double_withered", withered_double, withered_assets, withered_prefabs),
    Prefab("flower_cave_triple_withered", withered_triple, withered_assets, withered_prefabs)
