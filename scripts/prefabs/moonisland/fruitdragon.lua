-- fruitdragon.lua - 火龙果蜥蜴（移植自 DST，适配 DS）
-- 找热源→成熟→变色→火焰攻击→挑战系统

local brain = require("brains/fruitdragonbrain")

local assets = {
    Asset("ANIM", "anim/moonisland/fruit_dragon.zip"),
    Asset("ANIM", "anim/moonisland/fruit_dragon_build.zip"),
    Asset("ANIM", "anim/moonisland/fruit_dragon_ripe_build.zip"),
}

local prefabs = { "dragonfruit", "plantmeat" }

SetSharedLootTable('fruit_dragon', { {'plantmeat', 1.00} })
SetSharedLootTable('fruit_dragon_ripe', { {'dragonfruit', 1.00} })

local HEATSOURCE_MUST_TAGS = {"HASHEATER"}
local HEATSOURCE_CANT_TAGS = {"monster"}
local FRUITDRAGON_TAGS = {"fruitdragon"}

local function IsBetterHeatSource(heat_source, inst, cur_heat)
    local heat = heat_source.components.heater and heat_source.components.heater:GetHeat(inst)
    return heat and heat_source.components.heater:IsExothermic() and heat > cur_heat
end

local function FindNewHome(inst)
    if inst.components.timer:TimerExists("panicing")
        or inst.components.sleeper:IsAsleep()
        or inst.components.combat.target ~= nil then
        return
    end
    local home = inst.components.entitytracker:GetEntity("home")
    local new_home
    local cur_heat = 0
    local keep_range = TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.KEEP_HOME_RANGE or 10
    if home and home.components.heater and inst:IsNear(home, keep_range) then
        local heat = home.components.heater:GetHeat(inst)
        if heat and home.components.heater:IsExothermic() and heat > 0 then
            new_home = home
            cur_heat = heat
        end
    end
    local find_range = TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.FIND_HOME_RANGE or 15
    local x, y, z = inst.Transform:GetWorldPosition()
    local heat_sources = TheSim:FindEntities(x, y, z, find_range, HEATSOURCE_MUST_TAGS, HEATSOURCE_CANT_TAGS)
    for i, v in ipairs(heat_sources) do
        if v ~= inst and v ~= new_home and IsBetterHeatSource(v, inst, cur_heat) then
            new_home = v
            break
        end
    end
    if new_home ~= home then
        if home ~= nil then inst.components.entitytracker:ForgetEntity("home") end
        if new_home ~= nil then inst.components.entitytracker:TrackEntity("home", new_home) end
    end
end

-- 挑战系统
local function OnNewTarget(inst, data)
    if data.target:HasTag("fruitdragon") then
        inst._min_challenge_attacks = inst._is_ripe and 0 or 2
    end
end

local function KeepTarget(inst, target)
    if target:HasTag("fruitdragon") then
        local challenge_dist = TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.CHALLENGE_DIST or 15
        return (target.components.combat.target == nil or target.components.combat.target:HasTag("fruitdragon"))
            and not target.components.timer:TimerExists("panicing")
            and inst:IsNear(target, challenge_dist)
    end
    return target
end

local function ShouldTarget(target)
    return target:HasTag("fruitdragon")
        and not target.components.timer:TimerExists("panicing")
        and target.components.combat.target == nil
end

local function RetargetFn(inst)
    if (inst.components.sleeper == nil or not inst.components.sleeper:IsAsleep())
        and not inst.components.timer:TimerExists("panicing") then
        if inst.components.combat.target ~= nil and KeepTarget(inst, inst.components.combat.target) then
            return inst.components.combat.target
        elseif inst.components.entitytracker:GetEntity("home") ~= nil then
            local challenge_dist = TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.CHALLENGE_DIST or 15
            return FindEntity(inst, challenge_dist, function(guy) return ShouldTarget(guy) end, FRUITDRAGON_TAGS)
                or FindEntity(inst.components.entitytracker:GetEntity("home"), challenge_dist,
                    function(guy) return guy ~= inst and ShouldTarget(guy) end, FRUITDRAGON_TAGS)
        end
    end
    return nil
end

local function OnAttacked(inst, data)
    local home = inst.components.entitytracker:GetEntity("home")
    home = (home ~= nil and home.components.inventoryitem ~= nil) and home.components.inventoryitem:GetGrandOwner() or home
    if data.attacker == home then
        inst.components.entitytracker:ForgetEntity("home")
    end
    inst.components.combat:SetTarget(data.attacker)
end

local function doattack(inst, data)
    if data.target and data.target:HasTag("fruitdragon") then
        if data.target:HasTag("sleeping") and data.target.components.sleeper ~= nil then
            data.target.components.sleeper:WakeUp()
            data.target:PushEvent("wake_up_to_challenge")
        end
        data.target.components.combat:SuggestTarget(inst)
    end
end

local function OnLostChallenge(inst)
    inst.components.entitytracker:ForgetEntity("home")
    inst.components.timer:StartTimer("panicing", TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.CHALLENGE_LOST_PANIC_TIME or 15)
    inst.components.combat:DropTarget()
end

local function onattackother(inst, data)
    if data.target and data.target:HasTag("fruitdragon") then
        if not KeepTarget(inst, data.target) then
            inst.components.combat:DropTarget()
        elseif inst._min_challenge_attacks <= 0 and math.random() < (TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.CHALLENGE_WIN_CHANCE or 0.3) then
            data.target:PushEvent("lostfruitdragonchallenge")
            inst.components.combat:DropTarget()
            inst.components.combat:TryRetarget()
        end
        inst._min_challenge_attacks = inst._min_challenge_attacks - 1
    end
end

local function onblocked(inst, data)
    if data.attacker and data.attacker:HasTag("fruitdragon") and not inst.components.timer:TimerExists("panicing") then
        inst.components.combat:SuggestTarget(data.attacker)
        if inst.components.sleeper ~= nil then inst.components.sleeper:WakeUp() end
    end
end

-- 作息计时器
local function GetRemainingTimeAwake(inst)
    local T = TUNING.FRUITDRAGON or {}
    local max_awake = (T.AWAKE_TIME_MIN or 40) + inst.sleep_variance * (T.AWAKE_TIME_VAR or 20)
    max_awake = max_awake * (inst._is_ripe and (T.AWAKE_TIME_RIPE_MOD or 0.67) or 1)
    max_awake = max_awake * ((inst.components.entitytracker:GetEntity("home") == nil) and (T.AWAKE_TIME_HOMELESS_MOD or 0.5) or 1)
    return max_awake - (GetTime() - inst._wakeup_time)
end

local function GetRemainingNapTime(inst)
    local T = TUNING.FRUITDRAGON or {}
    local max_nap = (T.NAP_TIME_MIN or 30) + inst.sleep_variance * (T.NAP_TIME_VAR or 15)
    max_nap = max_nap * (inst._is_ripe and (T.NAP_TIME_RIPE_MOD or 0.67) or 1)
    max_nap = max_nap * (inst.components.entitytracker:GetEntity("home") and (T.NAP_TIME_HOMELESS_MOD or 1.5) or 1)
    return max_nap - (GetTime() - inst._nap_time)
end

local function StartNextNapTimer(inst)
    inst._wakeup_time = GetTime()
    inst.sleep_variance = math.random()
end

local function StartNappingTimer(inst)
    inst._nap_time = GetTime()
    inst.sleep_variance = math.random()
end

-- 成熟/退熟排队
local function QueueRipen(inst)
    inst._ripen_pending = not inst._is_ripe
    inst._unripen_pending = false
end

local function MakeRipe(inst, force)
    if inst._ripen_pending or force then
        inst._ripen_pending = false
        inst._is_ripe = true
        inst.components.lootdropper:SetChanceLootTable('fruit_dragon_ripe')
        inst.components.combat:SetDefaultDamage(TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.RIPE_DAMAGE or 20)
        inst.AnimState:SetBuild("fruit_dragon_ripe_build")
    end
end

local function QueueUnripe(inst)
    inst._ripen_pending = false
    inst._unripen_pending = inst._is_ripe
end

local function MakeUnripe(inst, force)
    if inst._unripen_pending or force then
        inst._unripen_pending = false
        inst._is_ripe = false
        inst.components.lootdropper:SetChanceLootTable('fruit_dragon')
        inst.components.combat:SetDefaultDamage(TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.UNRIPE_DAMAGE or 10)
        inst.AnimState:SetBuild("fruit_dragon_build")
    end
end

local function IsHomeGoodEnough(inst, dist, min_temp)
    local home = inst.components.entitytracker:GetEntity("home")
    if home and home.components.heater and inst:IsNear(home, dist) then
        local heat = home.components.heater:GetHeat(inst)
        return heat and home.components.heater:IsExothermic() and heat >= min_temp
    end
    return false
end

-- 睡眠/唤醒
local function Sleeper_SleepTest(inst)
    if (inst.components.combat and inst.components.combat.target) or inst.sg:HasStateTag("busy") or inst.components.timer:TimerExists("panicing") then
        return false
    end
    local T = TUNING.FRUITDRAGON or {}
    local nap_dist = T.NAP_DIST_FROM_HOME or 6
    local nap_min_heat = T.NAP_MIN_HEAT or 15
    local ripe_nap_min_heat = T.RIPEN_NAP_MIN_HEAT or 40
    if inst.components.entitytracker:GetEntity("home") then
        if (GetClock():IsNight() or GetRemainingTimeAwake(inst) <= 0) and IsHomeGoodEnough(inst, nap_dist, nap_min_heat) then
            if inst._is_ripe and not IsHomeGoodEnough(inst, nap_dist, ripe_nap_min_heat) then
                QueueUnripe(inst)
            end
            return true
        end
    else
        if GetClock():IsNight() or GetRemainingTimeAwake(inst) <= 0 then
            if inst._is_ripe then QueueUnripe(inst) end
            return true
        end
    end
    return false
end

local function Sleeper_WakeTest(inst)
    if inst.components.combat ~= nil and inst.components.combat.target ~= nil then return true end
    if GetClock():IsNight() then return false end
    if GetRemainingNapTime(inst) <= 0 then
        inst._sleep_interrupted = false
        return true
    end
    return false
end

local function Sleeper_OnSleep(inst)
    StartNappingTimer(inst)
    local T = TUNING.FRUITDRAGON or {}
    if not inst.components.health:IsDead() then
        inst.components.health:StartRegen(T.NAP_REGEN_AMOUNT or 2, T.NAP_REGEN_INTERVAL or 5)
    end
end

local function Sleeper_OnWakeUp(inst)
    local T = TUNING.FRUITDRAGON or {}
    local nap_dist = T.NAP_DIST_FROM_HOME or 6
    local ripe_nap_min_heat = T.RIPEN_NAP_MIN_HEAT or 40
    if not inst._sleep_interrupted then
        if not inst._ripen_pending and not inst._is_ripe
            and IsHomeGoodEnough(inst, nap_dist, ripe_nap_min_heat) then
            QueueRipen(inst)
        end
    end
    -- 执行排队中的切换
    if inst._ripen_pending then
        inst.sg:GoToState("do_ripen")
    elseif inst._unripen_pending then
        inst.sg:GoToState("do_unripen")
    end
    if not inst.components.health:IsDead() then inst.components.health:StopRegen() end
    StartNextNapTimer(inst)
    inst._sleep_interrupted = true
end

-- 存档
local function OnSave(inst, data)
    data._is_ripe = inst._is_ripe
end
local function OnLoad(inst, data)
    if data ~= nil and data._is_ripe then MakeRipe(inst, true) end
end

-- 离线时间模拟
local function OnEntitySleep(inst)
    if not inst.components.health:IsDead() then inst.components.health:StopRegen() end
    if inst._findnewhometask ~= nil then inst._findnewhometask:Cancel(); inst._findnewhometask = nil end
    inst._entitysleeptime = GetTime()
end

local function OnEntityWake(inst)
    if inst._entitysleeptime == nil then return end
    local dt = GetTime() - inst._entitysleeptime
    local T = TUNING.FRUITDRAGON or {}
    local keep_range = T.KEEP_HOME_RANGE or 10
    local ripe_nap_min_heat = T.RIPEN_NAP_MIN_HEAT or 40
    if dt > 1 then
        if inst.components.entitytracker:GetEntity("home") == nil then FindNewHome(inst) end
        if IsHomeGoodEnough(inst, keep_range, ripe_nap_min_heat) then
            if not inst._is_ripe then MakeRipe(inst, true) end
        else
            if inst._is_ripe then MakeUnripe(inst, true) end
        end
        if not inst.components.health:IsDead() and inst.components.health:IsHurt() then
            local nap_time_min = T.NAP_TIME_MIN or 30
            local nap_regen_interval = T.NAP_REGEN_INTERVAL or 5
            local nap_regen_amount = T.NAP_REGEN_AMOUNT or 2
            local estimated_naps = math.floor(dt / (nap_time_min + math.random() * 20))
            inst.components.health:DoDelta(estimated_naps * (nap_time_min / nap_regen_interval) * nap_regen_amount)
        end
    end
    inst._findnewhometask = inst:DoPeriodicTask(3, FindNewHome, 0.1 + math.random())
    if not inst.components.health:IsDead() and inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
        inst.components.health:StartRegen(T.NAP_REGEN_AMOUNT or 2, T.NAP_REGEN_INTERVAL or 5)
    end
end

local function GetStatus(inst)
    return inst._is_ripe and "RIPE" or nil
end

-- 主函数
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddDynamicShadow()

    inst.DynamicShadow:SetSize(2, 0.75)
    inst.Transform:SetFourFaced()
    MakeCharacterPhysics(inst, 1, 0.5)

    inst.AnimState:SetBank("fruit_dragon")
    inst.AnimState:SetBuild("fruit_dragon_build")
    inst.AnimState:PlayAnimation("idle_loop")

    inst.Light:Enable(false)
    inst.Light:SetRadius(1.25)
    inst.Light:SetFalloff(.98)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetColour(235/255, 121/255, 12/255)

    inst:AddTag("smallcreature")
    inst:AddTag("animal")
    inst:AddTag("scarytoprey")
    inst:AddTag("fruitdragon")
    inst:AddTag("lunar_aligned")

    -- 声音表
    inst.sounds = {
        idle = "turnoftides/creatures/together/fruit_dragon/idle",
        death = "turnoftides/creatures/together/fruit_dragon/death",
        eat = "turnoftides/creatures/together/fruit_dragon/eat",
        onhit = "turnoftides/creatures/together/fruit_dragon/hit",
        sleep_loop = "turnoftides/creatures/together/fruit_dragon/sleep",
        stretch = "turnoftides/creatures/together/fruit_dragon/stretch",
        do_unripen = "turnoftides/creatures/together/fruit_dragon/stretch",
        attack = "turnoftides/creatures/together/fruit_dragon/attack",
        attack_fire = "turnoftides/creatures/together/fruit_dragon/attack_fire",
        challenge_pre = "turnoftides/creatures/together/fruit_dragon/challenge_pre",
        challenge = "turnoftides/creatures/together/fruit_dragon/challenge",
        challenge_pst = "turnoftides/creatures/together/fruit_dragon/eat",
        challenge_win = "turnoftides/creatures/together/fruit_dragon/eat",
        challenge_lose = "turnoftides/creatures/together/fruit_dragon/eat",
    }

    inst._sleep_interrupted = true
    inst._is_ripe = false
    inst._wakeup_time = GetTime()
    inst._nap_time = -math.huge
    inst.sleep_variance = math.random()

    inst:AddComponent("timer")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.HEALTH or 50)
    inst.components.health.fire_damage_scale = 0

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "gecko_torso_middle"
    inst.components.combat:SetAttackPeriod(TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.ATTACK_PERIOD or 2)
    inst.components.combat:SetDefaultDamage(TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.UNRIPE_DAMAGE or 10)
    inst.components.combat:SetRange(TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.ATTACK_RANGE or 2, TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.HIT_RANGE or 1.5)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst:ListenForEvent("doattack", doattack)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onattackother", onattackother)
    inst:ListenForEvent("blocked", onblocked)
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    inst:AddComponent("entitytracker")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('fruit_dragon')

    inst:AddComponent("sleeper")
    inst.components.sleeper.testperiod = 3
    inst.components.sleeper:SetWakeTest(Sleeper_WakeTest)
    inst.components.sleeper:SetSleepTest(Sleeper_SleepTest)
    inst:ListenForEvent("gotosleep", Sleeper_OnSleep)
    inst:ListenForEvent("onwakeup", Sleeper_OnWakeUp)

    StartNextNapTimer(inst)

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.RUN_SPEED or 6
    inst.components.locomotor.walkspeed = TUNING.FRUITDRAGON and TUNING.FRUITDRAGON.WALK_SPEED or 3

    MakeSmallFreezableCharacter(inst)

    inst.MakeRipe = MakeRipe
    inst.MakeUnripe = MakeUnripe

    inst:SetBrain(brain)
    inst:SetStateGraph("SGfruitdragon")

    inst:ListenForEvent("lostfruitdragonchallenge", OnLostChallenge)

    inst._findnewhometask = inst:DoPeriodicTask(3, FindNewHome, 0.1 + math.random())

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake
    if inst:IsAsleep() then OnEntitySleep(inst) end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end


return Prefab("fruitdragon", fn, assets, prefabs)
