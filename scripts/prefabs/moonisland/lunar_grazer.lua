-- 月辔 (lunar_grazer)
-- 移植自 DST，适配 DS 单人生存模式
-- 移除：planar系统、gestalt捕获、碎片FX、轨迹FX、cloud FX视觉、portal生成

local brain = require("brains/lunar_grazer_brain")

local assets =
{
    Asset("ANIM", "anim/moonisland/lunar_grazer.zip"),
}

--------------------------------------------------------------------------
-- Sleep cloud (functional, puts nearby entities to sleep)
--------------------------------------------------------------------------

local CLOUD_RADIUS = 2.5
local SLEEPER_TAGS = { "player", "sleeper" }
local SLEEPER_NO_TAGS = { "playerghost", "epic", "lunar_aligned", "INLIMBO" }

local function DoCloudTask(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, CLOUD_RADIUS + 3, nil, SLEEPER_NO_TAGS, SLEEPER_TAGS)) do
        if v:IsValid() and v.entity:IsVisible()
            and not (v.components.health ~= nil and v.components.health:IsDead())
            and not (v.sg ~= nil and v.sg:HasStateTag("waking"))
        then
            local range = v:GetPhysicsRadius(0) + CLOUD_RADIUS
            if v:GetDistanceSqToPoint(x, y, z) < range * range then
                if v.components.sleeper ~= nil then
                    if not (v.sg ~= nil and v.sg:HasStateTag("sleeping")) then
                        v.components.sleeper:AddSleepiness(
                            TUNING.LUNAR_GRAZER_GROGGINESS or 5,
                            TUNING.LUNAR_GRAZER_KNOCKOUTTIME or 10
                        )
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------
-- Combat
--------------------------------------------------------------------------

local function IsTargetSleeping(inst, target)
    if target.components.sleeper ~= nil then
        return target.components.sleeper:IsAsleep()
    end
    return false
end

local function RetargetFn(inst)
    if inst.sg:HasStateTag("invisible") then return end

    local target = inst.components.combat.target
    if inst.sg:HasStateTag("debris") then
        -- In debris state: only target nearby players
        if target ~= nil then return end
        local player = GetPlayer()
        if player ~= nil and inst:IsNear(player, TUNING.LUNAR_GRAZER_WAKE_RANGE or 10) then
            return player
        end
        return nil
    end

    -- Normal retarget
    local x, y, z = inst.Transform:GetWorldPosition()
    local inrange, isplayer, asleep
    if target ~= nil then
        local range = (TUNING.LUNAR_GRAZER_ATTACK_RANGE or 3) + target:GetPhysicsRadius(0)
        inrange = target:GetDistanceSqToPoint(x, y, z) < range * range
        isplayer = target:HasTag("player")
        asleep = IsTargetSleeping(inst, target)
        if inrange and isplayer and asleep then
            return -- keep target
        end
    end

    for i, v in ipairs(TheSim:FindEntities(x, y, z, TUNING.LUNAR_GRAZER_AGGRO_RANGE or 15, nil, SLEEPER_NO_TAGS, SLEEPER_TAGS)) do
        if v.entity:IsVisible()
            and not (v.components.health ~= nil and v.components.health:IsDead())
            and (not asleep or IsTargetSleeping(inst, v))
            and (not (isplayer or inrange)
                and v.components.combat ~= nil
                and v.components.combat.target ~= nil
                and v.components.combat.target.prefab == inst.prefab
                or v:HasTag("player"))
        then
            return v, true
        end
    end
end

local function KeepTargetFn(inst, target)
    if inst.sg:HasStateTag("debris") and not target:HasTag("player") then
        return false
    end
    if not inst.components.combat:CanTarget(target) or inst.sg:HasStateTag("invisible") then
        return false
    end
    local spawnpoint = inst.components.knownlocations and inst.components.knownlocations:GetLocation("spawnpoint")
    if spawnpoint ~= nil then
        return target:GetDistanceSqToPoint(spawnpoint) < (TUNING.LUNAR_GRAZER_DEAGGRO_RANGE or 20) * (TUNING.LUNAR_GRAZER_DEAGGRO_RANGE or 20)
    end
    return inst:IsNear(target, TUNING.LUNAR_GRAZER_DEAGGRO_RANGE or 20)
end

local function OnAttacked(inst, data)
    if data.attacker ~= nil then
        local target = inst.components.combat.target
        if not (target ~= nil
            and target:HasTag("player")
            and inst:IsNear(target, (TUNING.LUNAR_GRAZER_ATTACK_RANGE or 3) + target:GetPhysicsRadius(0)))
        then
            inst.components.combat:SetTarget(data.attacker)
        end
    end
end

--------------------------------------------------------------------------
-- Despawn / Respawn
--------------------------------------------------------------------------

local function OnSave(inst, data)
    data.debris = inst.sg:HasStateTag("debris")
end

local function OnLoad(inst, data)
    if data ~= nil and data.debris then
        inst.sg:GoToState("dissipated")
    end
end

--------------------------------------------------------------------------
-- Main prefab
--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("notraptrigger")
    inst:AddTag("lunar_aligned")

    MakeCharacterPhysics(inst, 10, .5)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("lunar_grazer")
    inst.AnimState:SetBuild("lunar_grazer")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(1, 1, 1, .4) -- semi-transparent
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.1)

    -- inspectable
    inst:AddComponent("inspectable")

    -- health (min 1, can't die normally)
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.LUNAR_GRAZER_HEALTH or 200)
    inst.components.health:SetMinHealth(1)
    inst.components.health.nofadeout = true

    -- combat
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.LUNAR_GRAZER_DAMAGE or 30)
    inst.components.combat:SetRange(TUNING.LUNAR_GRAZER_ATTACK_RANGE or 3, TUNING.LUNAR_GRAZER_HIT_RANGE or 5)
    inst.components.combat:SetAttackPeriod(TUNING.LUNAR_GRAZER_ATTACK_PERIOD or 2)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.hiteffectsymbol = "blob_body"
    inst:ListenForEvent("attacked", OnAttacked)

    -- locomotor
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.LUNAR_GRAZER_WALKSPEED or 4
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.softstop = true
    inst.components.locomotor.pathcaps = { ignorecreep = true }

    -- knownlocations (for spawnpoint / wander home)
    inst:AddComponent("knownlocations")

    -- sleeper cloud (periodic)
    inst._cloudtask = inst:DoPeriodicTask(1, DoCloudTask, math.random())

    -- StateGraph + Brain
    inst:SetStateGraph("SGlunar_grazer")
    inst:SetBrain(brain)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("lunar_grazer", fn, assets)
