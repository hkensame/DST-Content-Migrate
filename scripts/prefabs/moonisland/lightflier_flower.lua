-- 光飞虫的花 (lightflier_flower)
-- 移植自 DST，适配 DS 单人生存模式
-- 完整移植：灯光状态机、childspawner 追踪光飞虫、timer 充能周期、homeseeker 回家
-- DS 适配：移除 net_* 网络变量、TheWorld.ismastersim、SetPristine、AddNetwork

local assets =
{
    Asset("ANIM", "anim/moonisland/bulb_plant_single.zip"),
    Asset("ANIM", "anim/moonisland/bulb_plant_springy.zip"),
    Asset("SOUND", "sound/common.fsb"),
    Asset("MINIMAP_IMAGE", "bulb_plant"),
}

local prefabs =
{
    "lightflier",
}

---------------------------------------------------------------------------
-- 灯光状态机（与 flower_cave DS 移植版一致）
---------------------------------------------------------------------------

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
local MAX_CHILDREN = 1
local FIND_LIGHTFLIER_DISTANCE = 16
local RECALL_FREQUENCY = 8

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
        -- 关灯渐变：radius→0, intensity→0, falloff→1
        inst.Light:SetRadius(inst.light_params.radius * (1 - k))
        inst.Light:SetIntensity(inst.light_params.intensity * (1 - k))
        inst.Light:SetFalloff(k + inst.light_params.falloff * (1 - k))
    elseif k < .33 then
        k = k / .33
        -- 开灯前半：radius 0→1.33x, intensity 0→1x, falloff 1→0.8x
        inst.Light:SetRadius(inst.light_params.radius * 1.33 * k)
        inst.Light:SetIntensity(inst.light_params.intensity * k)
        inst.Light:SetFalloff(inst.light_params.falloff * .8 * k + 1 - k)
    else
        k = (k - .33) / .67
        -- 开灯后半：radius 1.33x→1x, intensity 保持, falloff 0.8x→1x
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
    for i = 2, #STATE_ANIMS[state] do
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
    inst.components.timer:StartTimer("recharge", TUNING.LIGHTFLIER_FLOWER_RECHARGE_TIME + tween_time)
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

    if not inst.components.timer:TimerExists("turnoff") then
        inst.components.timer:StartTimer("turnoff",
            TUNING.LIGHTFLIER_FLOWER_LIGHT_TIME + tween_time
            + (math.random() * TUNING.LIGHTFLIER_FLOWER_LIGHT_TIME_VARIANCE))
    end
end

local function Recharge(inst)
    inst:SetLightState(LIGHT_STATES.CHARGED)
    if inst:IsInLight() then
        TurnOn(inst)
    end
end

---------------------------------------------------------------------------
-- childspawner 回调
---------------------------------------------------------------------------

local function SpawnLightflierFromStalk(inst)
    local lightflier = SpawnPrefab("lightflier")
    inst.components.childspawner:TakeOwnership(lightflier)
    lightflier.Transform:SetPosition(inst:GetPosition():Get())
    lightflier:PushEvent("startled")
    inst.components.childspawner.childreninside = math.max(inst.components.childspawner.childreninside - 1, 0)

    -- [FIX] 直接在此监听死亡/移除，因 SetSpawnedFn 对手动 SpawnPrefab + TakeOwnership 路径不会触发
    local function OnChildDeath() OnChildKilled(inst, lightflier) end
    lightflier:ListenForEvent("death", OnChildDeath)
    lightflier:ListenForEvent("onremove", OnChildDeath)
end

local function OnChildKilled(inst, child)
    -- 光飞虫死亡或被捕 → 恢复采摘
    inst.components.pickable:Resume()
end

local function OnGoHome(inst, child)
    -- 光飞虫回家 → 恢复满状态
    if not inst.components.pickable:CanBePicked() then
        inst.components.pickable:Regen()
    end
    ForceOn(inst)
end

---------------------------------------------------------------------------
-- 召回逻辑
---------------------------------------------------------------------------

local function CancelCallForLightflierTask(inst)
    if inst._call_for_lightflier_task ~= nil then
        inst._call_for_lightflier_task:Cancel()
        inst._call_for_lightflier_task = nil
    end
end

local function CallForLightflier(inst)
    if inst.components.pickable:CanBePicked()
        or inst.components.childspawner.numchildrenoutside < TUNING.LIGHTFLIER_FLOWER_TARGET_NUM_CHILDREN_OUTSIDE then
        CancelCallForLightflierTask(inst)
        return
    end

    -- DS 适配：无 formationfollower，用 homeseeker 判断是否正在回家
    if inst._lightflier_returning_home ~= nil
        and inst._lightflier_returning_home:IsValid() then
        return
    end

    for k, v in pairs(inst.components.childspawner.childrenoutside) do
        if v:IsValid() then
            inst._lightflier_returning_home = v
            return
        end
    end

    inst._lightflier_returning_home = nil
end

local function StartCallForLightflierTask(inst)
    CancelCallForLightflierTask(inst)
    inst._call_for_lightflier_task = inst:DoPeriodicTask(RECALL_FREQUENCY, CallForLightflier,
        TUNING.LIGHTFLIER_FLOWER_RECALL_DELAY + math.random() * TUNING.LIGHTFLIER_FLOWER_RECALL_DELAY_VARIANCE)
end

---------------------------------------------------------------------------
-- pickable 回调
---------------------------------------------------------------------------

local function ontimerdone(inst, data)
    if data.name == "recharge" then
        Recharge(inst)
    elseif data.name == "turnoff" then
        TurnOff(inst)
        if inst.components.pickable:CanBePicked() then
            inst.components.pickable:Pick()
        end
    end
end

local function enterlight(inst)
    TurnOn(inst)
end

local function makefullfn(inst)
    CancelCallForLightflierTask(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
    ForceOn(inst)
    inst.components.timer:StopTimer("recharge")
    inst.components.timer:StopTimer("turnoff")
    local tween_time = math.random(LIGHT_MIN_TIME, LIGHT_MAX_TIME)
    inst.components.timer:StartTimer("turnoff", TUNING.LIGHTFLIER_FLOWER_RECHARGE_TIME + tween_time)
end

local function onregenfn(inst)
    TurnOff(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

local function onpickedfn(inst, picker, loot)
    SpawnLightflierFromStalk(inst)
    ForceOff(inst)
    inst.components.timer:StopTimer("turnoff")
    inst.components.timer:StopTimer("recharge")

    if picker ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lightbulb")
    end
    inst.AnimState:PlayAnimation("picking")

    if inst.components.pickable:IsBarren() then
        inst.AnimState:PushAnimation("idle_dead")
    else
        inst.AnimState:PushAnimation("picked")
    end

    inst.components.pickable:Pause() -- 等光飞虫回来才再生
    StartCallForLightflierTask(inst)
end

local function makeemptyfn(inst)
    ForceOff(inst)
    inst.components.timer:StopTimer("turnoff")
    inst.components.timer:StopTimer("recharge")
    inst.AnimState:PlayAnimation("picked")
end

---------------------------------------------------------------------------
-- 点燃处理
---------------------------------------------------------------------------

local function OnIgnite(inst)
    TurnOff(inst)
    if inst.components.pickable:CanBePicked() then
        inst.components.pickable:Pick()
    else
        if inst.AnimState:IsCurrentAnimation("picking") then
            inst.AnimState:PushAnimation("picked")
        else
            inst.AnimState:PlayAnimation("picked")
        end
    end
end

---------------------------------------------------------------------------
-- 存档
---------------------------------------------------------------------------

local function OnSave(inst, data)
    data.light_state = inst.light_state
    data.islighton = inst._islighton
    data.plantname = inst.plantname
end

local function OnLoad(inst, data)
    if data == nil then return end
    inst.light_state = data.light_state
    inst._islighton = data.islighton or false

    if data.plantname ~= nil then
        inst.plantname = data.plantname
        inst.AnimState:SetBank("bulb_plant" .. inst.plantname)
        inst.AnimState:SetBuild("bulb_plant" .. inst.plantname)
    end

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

local function OnLoadPostPass(inst, ents, data)
    if not inst.components.pickable:CanBePicked()
        and inst.components.childspawner.numchildrenoutside >= TUNING.LIGHTFLIER_FLOWER_TARGET_NUM_CHILDREN_OUTSIDE then
        StartCallForLightflierTask(inst)
    end
end

---------------------------------------------------------------------------
-- 唤醒 / 环境光感知
---------------------------------------------------------------------------

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

---------------------------------------------------------------------------
-- DS 兼容：IsInLight（用 LightWatcher 实现）
---------------------------------------------------------------------------

local function IsInLight(inst)
    return inst.LightWatcher and inst.LightWatcher:IsInLight() or false
end

---------------------------------------------------------------------------
-- 主 Prefab
---------------------------------------------------------------------------

local plantnames = { "_single", "_springy" }

local lightparams_single =
{
    falloff = .5,
    intensity = .8,
    radius = 3,
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddLightWatcher()

    inst:AddTag("plant")
    inst:AddTag("lightflier_home")

    -- LightWatcher：感知环境光
    inst.LightWatcher:SetLightThresh(.075)
    inst.LightWatcher:SetDarkThresh(.05)

    -- 灯光初始关闭，由状态机控制
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(0)
    inst.Light:SetRadius(0)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(false)
    if inst.Light.EnableClientModulation ~= nil then
        inst.Light:EnableClientModulation(true)
    end

    -- 随机花形态
    inst.plantname = plantnames[math.random(1, #plantnames)]
    inst.AnimState:SetBank("bulb_plant" .. inst.plantname)
    inst.AnimState:SetBuild("bulb_plant" .. inst.plantname)
    inst.AnimState:PlayAnimation("off")

    -- 小地图图标
    inst.MiniMapEntity:SetIcon("bulb_plant.png")

    -- 灯光参数 & 状态变量（DS 无 net_*，用普通字段）
    inst.light_params = lightparams_single
    inst.light_state = LIGHT_STATES.CHARGED  -- [FIX] 必须初始化，否则 CanTurnOn 永远返回 false
    inst._lighttime = 0
    inst._lightmaxframe = math.floor(LIGHT_MIN_TIME / FRAMES + .5)
    inst._lightframe = inst._lightmaxframe  -- [FIX] 初始为 maxframe（灯光完全关闭），而不是 0
    inst._islighton = false
    inst._lighttask = nil

    -- 颜色随机
    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    -- DS 兼容方法
    inst.IsInLight = IsInLight
    inst.CanTurnOn = CanTurnOn
    inst.SetLightState = SetLightState
    inst.TurnOn = TurnOn

    -- timer 组件
    inst:AddComponent("timer")

    -- pickable 组件
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    inst.components.pickable.makefullfn = makefullfn
    inst.components.pickable:SetUp(nil, TUNING.LIGHTFLIER_FLOWER_REGROW_TIME)
    inst.components.pickable.canbepicked = TUNING.LIGHTFLIER_FLOWER_PICKABLE

    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

    -- childspawner：追踪光飞虫归属
    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "lightflier"
    inst.components.childspawner:SetMaxChildren(MAX_CHILDREN)
    -- DS 没有 SetOnChildKilledFn，用 SetSpawnedFn 手动监听子实体死亡
    inst.components.childspawner:SetSpawnedFn(function(child)
        if child then
            child:ListenForEvent("death", function() OnChildKilled(inst, child) end)
            child:ListenForEvent("onremove", function() OnChildKilled(inst, child) end)
        end
    end)
    inst.components.childspawner:SetGoHomeFn(OnGoHome)

    -- 可燃
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)

    -- DST 专属系统（DS 安全跳过）
    if rawget(_G, "AddToRegrowthManager") then AddToRegrowthManager(inst) end

    -- 事件监听
    inst:ListenForEvent("timerdone", ontimerdone)
    inst:ListenForEvent("enterlight", enterlight)
    inst:ListenForEvent("onignite", OnIgnite)

    -- 存档
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass
    inst.OnEntityWake = OnWake
    inst.debugstringfn = GetDebugString

    -- [FIX] DS 中 OnEntityWake 对新创建实体不会触发，此处兜底检查环境光
    --      LightWatcher 需要几帧稳定，所以延迟 2 帧
    inst:DoTaskInTime(2, function() TurnOnInLight(inst) end)

    -- 幽灵互动（DS 安全跳过）
    if rawget(_G, "MakeHauntableIgnite") then MakeHauntableIgnite(inst) end

    return inst
end

return Prefab("lightflier_flower", fn, assets, prefabs)
