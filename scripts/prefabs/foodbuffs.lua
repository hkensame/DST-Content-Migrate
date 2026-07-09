
-- 食物增益效果：攻击加成（3档）、生命回复、锁定饥饿、无僵直等 buff 预制体

local prefabs = {}

local total_day_time = 480
local day_time = 300
TUNING.JELLYBEAN_DURATION = 60*2
TUNING.HUNGER_DURATION = 60*8

TUNING.BUFF_ATTACK_DURATION = 60*4
TUNING.BUFF_PLAYERABSORPTION_DURATION = 60*4
TUNING.BUFF_WORKEFFECTIVENESS_DURATION = 60*4
TUNING.BUFF_MOISTUREIMMUNITY_DURATION = 60*5
TUNING.BUFF_ELECTRICATTACK_DURATION = 60*5
TUNING.BUFF_FOOD_TEMP_DURATION = 60*5

TUNING.BUFF_ATTACK_MULTIPLIER = 1.2
TUNING.BUFF_PLAYERABSORPTION_MODIFIER = 1 / 3
TUNING.BUFF_WORKEFFECTIVENESS_MODIFIER = 2

-------------------------------------------------------------------------
---------------------- Attach and dettach functions ---------------------
-------------------------------------------------------------------------

--攻击加成
local function attack_attach(inst, target)
    local attachedmult = inst.attachedmult
    if target.components.combat ~= nil then
        target.components.combat:AddDamageModifier(inst, attachedmult)
    end
end

local function attack_detach(inst, target)
    if target.components.combat ~= nil then
        target.components.combat:RemoveDamageModifier(inst)
    end
end

--2秒回复2点生命
local function health_attach(inst, target)
    local attachedmult = inst.attachedmult
    if target.components.health ~= nil then
        target.components.health:StartRegen(2, 2)
    end
end

local function health_detach(inst, target)
    if target.components.health ~= nil then
        target.components.health:StartRegen(0, 0)
    end
end

--锁定饥饿？
local function hunger_attach(inst, target)
    if target.components.hunger ~= nil then
      target.components.hunger:Pause()
    end
end

local function hunger_detach(inst, target)
    if target.components.hunger ~= nil then
      target.components.hunger:Resume()
    end
end

--无僵直
local function stun_attach(inst, target)
    if not target:HasTag("not_hit_stunned") then
      target:AddTag("not_hit_stunned")
    end
end

local function stun_detach(inst, target)
    if target:HasTag("not_hit_stunned") then
      target:RemoveTag("not_hit_stunned")
    end
end

-------------------------------------------------------------------------
----------------------- Prefab building functions -----------------------
-------------------------------------------------------------------------

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function MakeBuff(name, onattachedfn, attachedmult, onextendedfn, ondetachedfn, duration, priority, prefabs)
    local function OnAttached(inst, target)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_"..string.upper(name), priority = priority })
        if onattachedfn ~= nil then
            onattachedfn(inst, target)
        end
    end

    local function OnExtended(inst, target)
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", duration)

        target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_"..string.upper(name), priority = priority })
        if onextendedfn ~= nil then
            onextendedfn(inst, target)
        end
    end

    local function OnDetached(inst, target)
        if ondetachedfn ~= nil then
            ondetachedfn(inst, target)
        end

        target:PushEvent("foodbuffdetached", { buff = "ANNOUNCE_DETACH_BUFF_"..string.upper(name), priority = priority })
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()

        inst.entity:Hide()
        inst.persists = false
        inst.attachedmult = attachedmult

        inst:AddTag("CLASSIFIED")
        inst:AddTag("buff_"..name)

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("buffover", duration)
        inst:ListenForEvent("timerdone", OnTimerDone)

        return inst
    end

    return Prefab("buff_"..name, fn, nil, prefabs)
end

--local function MakeBuff(name, onattachedfn, attachedmult, onextendedfn, ondetachedfn, duration, priority, prefabs)
                         --名字   buff函数      攻击倍数      延期？        移除buff函数   持续时间  优先级  预设物
return MakeBuff("attack", attack_attach, 0.2, nil, attack_detach, TUNING.BUFF_ATTACK_DURATION, 1),
       MakeBuff("attack2", attack_attach, 0.5, nil, attack_detach, TUNING.BUFF_ATTACK_DURATION, 1),
       MakeBuff("attack3", attack_attach, 1, nil, attack_detach, TUNING.BUFF_ATTACK_DURATION, 1),
       MakeBuff("health", health_attach, nil, nil, health_detach, TUNING.JELLYBEAN_DURATION, 1),
       MakeBuff("hunger", hunger_attach, nil, nil, hunger_detach, TUNING.HUNGER_DURATION, 1),
       MakeBuff("stun", stun_attach, nil, nil, stun_detach, 30, 1)
       --MakeBuff("playerabsorption", playerabsorption_attach, nil, playerabsorption_detach, TUNING.BUFF_PLAYERABSORPTION_DURATION, 1),
       --MakeBuff("workeffectiveness", work_attach, nil, nil, work_detach, TUNING.BUFF_WORKEFFECTIVENESS_DURATION, 1),
       --MakeBuff("moistureimmunity", moisture_attach, nil, nil, moisture_detach, TUNING.BUFF_MOISTUREIMMUNITY_DURATION, 2)
       --MakeBuff("electricattack", electric_attach, nil, electric_extend, electric_detach, TUNING.BUFF_ELECTRICATTACK_DURATION, 2, { "electrichitsparks", "electricchargedfx" })
       --MakeBuff("sleepresistance", sleepless_attach, nil, sleepless_detach, TUNING.SLEEPRESISTBUFF_TIME, 2)
