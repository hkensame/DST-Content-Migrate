-- DS 适配版 cavelightmoon.lua
-- 从 DST 源码 scripts/prefabs/cavelightmoon.lua 移植
-- 改动：
--   🔴 移除 AddNetwork / SetPristine / ismastersim 守卫
--   🔴 移除 molebat 生成器（spawner 组件 + playerprox + WorldSettings）
--   🔴 移除 net_tinybyte 网络变量，改用普通字段
--   🔴 移除 WatchWorldState，改用 DoPeriodicTask 轮询
--   🟡 洞穴月相判定改用 GetClock() + GetWorld()

local assets =
{
    Asset("ANIM", "anim/cave_exit_lightsource.zip"),
}

local moonlight_params =
{
    day =
    {
        radius = 2,
        intensity = 0.2,
        falloff = 0.9,
        colour = { 10/255, 120/255, 255/255 },
        time = 2,
    },

    dusk =
    {
        radius = 3,
        intensity = 0.5,
        falloff = 0.6,
        colour = { 40/255, 164/255, 255/255 },
        time = 4,
    },

    night =
    {
        radius = 4,
        intensity = 0.7,
        falloff = 0.5,
        colour = { 90/255, 195/255, 255/255 },
        time = 6,
    },

    fullmoon =
    {
        radius = 6,
        intensity = 0.9,
        falloff = 0.3,
        colour = { 120/255, 225/255, 255/255 },
        time = 4,
    },

    off =
    {
        radius = 0,
        intensity = 0,
        falloff = 1,
        colour = { 0, 0, 0 },
        time = 6,
    },
}

-- Generate light phase ID's and tint
local light_phases = {}
for k, v in pairs(moonlight_params) do
    table.insert(light_phases, k)
    v.id = #light_phases
    v.tint = { v.colour[1] * .5, v.colour[2] * .5, v.colour[3] * .5, 1 }
end

local function pushparams(inst, params)
    inst.Light:SetRadius(params.radius * inst.widthscale)
    inst.Light:SetIntensity(params.intensity)
    inst.Light:SetFalloff(params.falloff)
    inst.Light:SetColour(unpack(params.colour))
    inst.AnimState:SetMultColour(unpack(params.tint))
    if params.intensity > 0 then
        inst.Light:Enable(true)
        inst:Show()
    else
        inst.Light:Enable(false)
        inst:Hide()
    end
end

-- Not using deepcopy because we want to copy in place
local function copyparams(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = dest[k] or {}
            copyparams(dest[k], v)
        else
            dest[k] = v
        end
    end
end

local function lerpparams(pout, pstart, pend, lerpk)
    for k, v in pairs(pend) do
        if type(v) == "table" then
            lerpparams(pout[k], pstart[k], v, lerpk)
        else
            pout[k] = pstart[k] * (1 - lerpk) + v * lerpk
        end
    end
end

local function OnUpdateLight(inst, dt)
    inst._currentlight.time = inst._currentlight.time + dt
    if inst._currentlight.time >= inst._endlight.time then
        inst._currentlight.time = inst._endlight.time
        inst._lighttask:Cancel()
        inst._lighttask = nil
    end
    lerpparams(inst._currentlight, inst._startlight, inst._endlight,
        inst._endlight.time > 0 and inst._currentlight.time / inst._endlight.time or 1)
    pushparams(inst, inst._currentlight)
end

-- DS 适配：用轮询代替 WatchWorldState
local function GetCurrentPhase(inst)
    local clock = GetClock()
    if clock == nil then return "day" end
    local world = GetWorld()
    local is_cave = world and world:IsCave()
    -- 满月优先（DS 用 GetClock():GetMoonPhase 替代 world.state.isfullmoon）
    if is_cave and GetClock():GetMoonPhase() == "full" then
        return "fullmoon"
    end
    if clock:IsNight() then
        return "night"
    elseif clock:IsDusk() then
        return "dusk"
    else
        return "day"
    end
end

local function SetPhase(inst, phase_name)
    -- 小尺寸在白天时关闭光源
    if phase_name == "day" and inst.widthscale < 0.5 then
        phase_name = "off"
    end
    local params = moonlight_params[phase_name]
    if params ~= nil and params ~= inst._endlight then
        copyparams(inst._startlight, inst._currentlight)
        inst._currentlight.time = 0
        inst._startlight.time = 0
        inst._endlight = params
        if inst._lighttask == nil then
            inst._lighttask = inst:DoPeriodicTask(FRAMES, OnUpdateLight, nil, FRAMES)
        end
    end
end

local function OnPhasePoll(inst)
    local phase = GetCurrentPhase(inst)
    SetPhase(inst, phase)
end

local function OnInit(inst)
    local phase = GetCurrentPhase(inst)
    SetPhase(inst, phase)
    -- 轮询世界状态变化（DS 没有 WatchWorldState）
    inst._phasepoll = inst:DoPeriodicTask(5, OnPhasePoll)
end

local function common_fn(widthscale)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    -- 🔴 DS 不需要 AddNetwork

    inst.AnimState:SetBank("cavelight")
    inst.AnimState:SetBuild("cave_exit_lightsource")
    inst.AnimState:PlayAnimation("idle_loop", false)
    inst.AnimState:SetLightOverride(1)

    -- teal effect to fit moon
    inst.AnimState:SetMultColour(0.3, 0.5, 1.0, 1.0)

    inst.Transform:SetScale(2*widthscale, 2, 2*widthscale)

    inst:AddTag("daylight")
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("sinkhole")

    -- DS: no EnableClientModulation

    inst.widthscale = widthscale

    inst._endlight = (widthscale > 0.5 and moonlight_params.day) or moonlight_params.off
    inst._startlight = {}
    inst._currentlight = {}
    copyparams(inst._startlight, inst._endlight)
    copyparams(inst._currentlight, inst._endlight)
    pushparams(inst, inst._currentlight)

    inst._lighttask = nil

    inst:DoTaskInTime(0, OnInit)

    -- 🔴 DS 不需要 SetPristine / ismastersim 守卫
    -- 🔴 DS 移除了 molebat spawner 组件

    return inst
end

local function normalfn()
    return common_fn(0.7)
end

local function smallfn()
    return common_fn(0.4)
end

local function tinyfn()
    return common_fn(0.2)
end

return Prefab("cavelightmoon", normalfn, assets),
       Prefab("cavelightmoon_small", smallfn, assets),
       Prefab("cavelightmoon_tiny", tinyfn, assets)
