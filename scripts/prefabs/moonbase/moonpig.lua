require "brains/pigbrain"
require "brains/pigguardbrain"
require "brains/werepigbrain"
require "stategraphs/SGpig"
require "stategraphs/SGwerepig"

local assets =
{
	Asset("ANIM", "anim/ds_pig_basic.zip"),
	Asset("ANIM", "anim/ds_pig_actions.zip"),
	Asset("ANIM", "anim/ds_pig_attacks.zip"),
	Asset("ANIM", "anim/pig_build.zip"),
	Asset("ANIM", "anim/pigspotted_build.zip"),
	Asset("ANIM", "anim/pig_guard_build.zip"),
	Asset("ANIM", "anim/werepig_build.zip"),
	Asset("ANIM", "anim/werepig_basic.zip"),
	Asset("ANIM", "anim/werepig_actions.zip"),
	Asset("SOUND", "sound/pig.fsb"),
}

local prefabs =
{
    "meat",
    "monstermeat",
    "poop",
    "tophat",
    "strawhat",
    "pigskin",
}

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local function CalcSanityAura(inst, observer)
    return (inst.prefab == "moonpig" and -TUNING.SANITYAURA_LARGE)
        or (inst.components.werebeast ~= nil and inst.components.werebeast:IsInWereState() and -TUNING.SANITYAURA_LARGE)
        or (inst.components.follower ~= nil and inst.components.follower.leader == observer and TUNING.SANITYAURA_SMALL)
        or 0
end

local function OnEat(inst, food)
    if food.components.edible
       and food.components.edible.foodtype == "MEAT"
       and inst.components.werebeast
       and not inst.components.werebeast:IsInWereState() then
        if food.components.edible:GetHealth() < 0 then
            inst.components.werebeast:TriggerDelta(1)
        end
    end
    
    if food.components.edible and food.components.edible.foodtype == "VEGGIE" then
		local poo = SpawnPrefab("poop")
		poo.Transform:SetPosition(inst.Transform:GetWorldPosition())		
	end
    
end

local function IsWerePig(dude)
    return dude:HasTag("werepig")
end

local function OnAttackedByDecidRoot(inst, attacker)
    local fn = function(dude) return dude:HasTag("pig") and not dude:HasTag("werepig") and not dude:HasTag("guard") end

    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = nil
    if GetSeasonManager() and (GetSeasonManager():IsSpring() or GetSeasonManager():IsGreenSeason()) then
        ents = TheSim:FindEntities(x,y,z, (SHARE_TARGET_DIST * TUNING.SPRING_COMBAT_MOD) / 2)
    else
        ents = TheSim:FindEntities(x,y,z, SHARE_TARGET_DIST / 2)
    end
    
    if ents then
        local num_helpers = 0
        for k,v in pairs(ents) do
            if v ~= inst and v.components.combat and not (v.components.health and v.components.health:IsDead()) and fn(v) then
                if v:PushEvent("suggest_tree_target", {tree=attacker}) then
                    num_helpers = num_helpers + 1
                end
            end
            if num_helpers >= MAX_TARGET_SHARES then
                break
            end     
        end
    end
end

local function OnAttacked(inst, data)
    --print(inst, "OnAttacked")
    local attacker = data.attacker
    inst:ClearBufferedAction()

    if attacker.prefab == "deciduous_root" and attacker.owner then 
        OnAttackedByDecidRoot(inst, attacker.owner)
    elseif attacker.prefab ~= "deciduous_root" then
        inst.components.combat:SetTarget(attacker)

        if inst:HasTag("werepig") then
            inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("werepig") end, MAX_TARGET_SHARES)
        elseif inst:HasTag("guard") then
                inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("pig") and (dude:HasTag("guard") or not attacker:HasTag("pig")) end, MAX_TARGET_SHARES)
        else
            if not (attacker:HasTag("pig") and attacker:HasTag("guard") ) then
                inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("pig") and not dude:HasTag("werepig") end, MAX_TARGET_SHARES)
            end
        end
    end
end

local function OnNewTarget(inst, data)
    if inst:HasTag("werepig") then
        inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, IsWerePig, MAX_TARGET_SHARES)
    end
end


local function WerepigKeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
           and not target:HasTag("werepig")
           and not target:HasTag("wereplayer")
           and not (target.sg ~= nil and target.sg:HasStateTag("transform"))
end

local function IsNearMoonBase(inst, dist)
    local moonbase = inst.components.entitytracker:GetEntity("moonbase")
    return moonbase == nil or inst:IsNear(moonbase, dist)
end

local MOONPIG_RETARGET_CANT_TAGS = { "werepig", "alwaysblock", "wereplayer", "moonbeast" }
local RETARGET_MUST_TAGS = { "_combat" }

local function MoonpigRetargetFn(inst)
    return IsNearMoonBase(inst, TUNING.MOONPIG_AGGRO_DIST)
        and FindEntity(
                inst,
                TUNING.PIG_TARGET_DIST,
                function(guy)
                    return inst.components.combat:CanTarget(guy)
                        and not (guy.sg ~= nil and guy.sg:HasStateTag("transform"))
                end,
                RETARGET_MUST_TAGS, --See entityreplica.lua (re: "_combat" tag)
                MOONPIG_RETARGET_CANT_TAGS
            )
        or nil
end

local function MoonpigKeepTargetFn(inst, target)
    return IsNearMoonBase(inst, TUNING.MOONPIG_RETURN_DIST)
        and not target:HasTag("moonbeast")
        and WerepigKeepTargetFn(inst, target)
end

local function WerepigSleepTest(inst)
    return false
end

local function WerepigWakeTest(inst)
    return true
end

local function displaynamefn(inst)
    return inst.name
end

local function common(moonbeast)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()

    MakeCharacterPhysics(inst, 50, .5)

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    inst:AddTag("character")
    inst:AddTag("pig")
    inst:AddTag("scarytoprey")
    inst.AnimState:SetBank("pigman")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:Hide("hat")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

        inst:AddTag("werepig")
        inst:AddTag("moonbeast")
        inst:AddTag("hostile")
        inst.AnimState:SetBuild("werepig_build")
        --Since we override prefab name, we will need to use the higher
        --priority displaynamefn to return us back plain old .name LOL!
        inst:SetPrefabNameOverride("pigman")
        inst.displaynamefn = displaynamefn

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED --5
    inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED --3

    inst:AddComponent("bloomer")

    inst:AddComponent("spawnfader")
    inst:AddComponent("eater")
    --inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
    inst.components.eater:SetOmnivore()
    inst.components.eater:SetCanEatHorrible()
    --inst.components.eater:SetCanEatRaw()
    inst.components.eater.strongstomach = true -- can eat monster meat!
    inst.components.eater:SetOnEatFn(OnEat)
    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "pig_torso"

    MakeMediumBurnableCharacter(inst, "pig_torso")

    inst:AddComponent("named")
    inst.components.named.possiblenames = STRINGS.PIGNAMES
    inst.components.named:PickNewName()

    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.PIG_LOYALTY_MAXTIME

    inst:AddComponent("inventory")


    inst:AddComponent("lootdropper")


    inst:AddComponent("knownlocations")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura


    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true

    MakeMediumFreezableCharacter(inst, "pig_torso")


    inst:AddComponent("inspectable")

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    return inst
end

local gargoyles =
{
    "gargoyle_werepigatk",
    "gargoyle_werepigdeath",
    "gargoyle_werepighowl",
}
local moonpigprefabs = {}
for i, v in ipairs(gargoyles) do
    table.insert(moonpigprefabs, v)
end
for i, v in ipairs(prefabs) do
    table.insert(moonpigprefabs, v)
end

local moonbeastbrain = require "brains/moonbeastbrain"

local function OnMoonPetrify(inst)
    if not inst.components.health:IsDead() and (not inst.sg:HasStateTag("busy") or inst:IsAsleep()) then
        local x, y, z = inst.Transform:GetWorldPosition()
        local rot = inst.Transform:GetRotation()
        local name = inst.components.named.name
        inst:Remove()
        local gargoyle = SpawnPrefab(gargoyles[math.random(#gargoyles)])
        gargoyle.components.named:SetName(name)
        gargoyle.Transform:SetPosition(x, y, z)
        gargoyle.Transform:SetRotation(rot)
        gargoyle:Petrify()
    end
end

local function OnMoonTransformed(inst, data)
    inst.components.named:SetName(data.old.components.named.name)
    inst.sg:GoToState("howl")
end

local function moon()
    local inst = common(true)

    inst:AddTag("monster")
    
    inst:AddComponent("entitytracker")

    inst:SetBrain(moonbeastbrain)
    inst:SetStateGraph("SGmoonpig")

    inst.components.sleeper:SetResistance(3)
    inst.components.freezable:SetDefaultWearOffTime(TUNING.MOONPIG_FREEZE_WEAR_OFF_TIME)

    inst.components.combat:SetDefaultDamage(TUNING.WEREPIG_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.WEREPIG_ATTACK_PERIOD)
    inst.components.locomotor.runspeed = TUNING.WEREPIG_RUN_SPEED 
    inst.components.locomotor.walkspeed = TUNING.WEREPIG_WALK_SPEED 

    inst.components.sleeper:SetSleepTest(WerepigSleepTest)
    inst.components.sleeper:SetWakeTest(WerepigWakeTest)

    inst.components.lootdropper:SetLoot({ "meat", "meat", "pigskin" })
    inst.components.lootdropper.numrandomloot = 0

    inst.components.health:SetMaxHealth(TUNING.WEREPIG_HEALTH)
    inst.components.combat:SetTarget(nil)
    inst.components.combat:SetRetargetFunction(3, MoonpigRetargetFn)
    inst.components.combat:SetKeepTargetFunction(MoonpigKeepTargetFn)

    inst:ListenForEvent("moonpetrify", OnMoonPetrify)
    inst:ListenForEvent("moontransformed", OnMoonTransformed)

    return inst
end

return Prefab("moonpig", moon, assets, moonpigprefabs)
