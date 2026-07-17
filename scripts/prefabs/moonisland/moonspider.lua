
require "brains/moonspiderbrain_no"
--require "brains/moonspiderbrain"
require "stategraphs/SGmoonspider"

local assets =
{
    -- ds_spider_basic: DS 原版已有，无需导入
    Asset("ANIM", "anim/moonisland/ds_spider_moon.zip"),
    Asset("ANIM", "anim/moonisland/ds_spider_moon_boat_jump.zip"),
	Asset("SOUND", "sound/spider.fsb"),
}

local prefabs =
{
	"spidergland",
    "venomgland",
    "monstermeat",
    "silk",
}

local PI2 = PI*2
local TWOPI = PI2
local HOLE_TAGS = { "groundhole" }

local function shuffleArray(array)
    local arrayCount = #array
    for i = arrayCount, 2, -1 do
        local j = math.random(1, i)
        array[i], array[j] = array[j], array[i]
    end
    return array
end

local DEPLOY_EXTRA_SPACING = 0
IsPointNearHole = function(pt, range)
    range = range or .5
    for i, v in ipairs(TheSim:FindEntities(pt.x, 0, pt.z, DEPLOY_EXTRA_SPACING + range, HOLE_TAGS)) do
        local radius = v:GetPhysicsRadius(0) + range
        if v:GetDistanceSqToPoint(pt) < radius * radius then
            return true
        end
    end
    return false
end

local function ShouldAcceptItem(inst, item, giver)

    if giver.prefab ~= "webber" then
        return false
    end

    if inst.components.sleeper:IsAsleep() then
        return false
    end
    
    if inst.components.eater:CanEat(item) then
        return true
    end
end

function GetOtherSpiders(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 15,  {"spider"}, {"FX", "NOCLICK", "DECOR","INLIMBO"})
    return ents
end

local function OnGetItemFromPlayer(inst, giver, item)
    if inst.components.eater:CanEat(item) then  

        local playedfriendsfx = false
        if inst.components.combat.target and inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
        elseif giver.components.leader then
            inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
            playedfriendsfx = true
            giver.components.leader:AddFollower(inst)
            local loyaltyTime = item.components.edible:GetHunger() * TUNING.SPIDER_LOYALTY_PER_HUNGER
            inst.components.follower:AddLoyaltyTime(loyaltyTime)
        end

        local spiders = GetOtherSpiders(inst)
        local maxSpiders = 3

        for k,v in pairs(spiders) do
            if maxSpiders < 0 then
                break
            end

            if v.components.combat.target and v.components.combat.target == giver then
                v.components.combat:SetTarget(nil)
            elseif giver.components.leader then
                if not playedfriendsfx then
                    v.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
                    playedfriendsfx = true
                end
                giver.components.leader:AddFollower(v)
                local loyaltyTime = item.components.edible:GetHunger() * TUNING.SPIDER_LOYALTY_PER_HUNGER
                if v.components.follower then
                    v.components.follower:AddLoyaltyTime(loyaltyTime)
                end
            end
            maxSpiders = maxSpiders - 1

            if v.components.sleeper:IsAsleep() then
                v.components.sleeper:WakeUp()
            end
        end
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("taunt")
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function NormalRetarget(inst)
    local targetDist = TUNING.SPIDER_TARGET_DIST
    if inst.components.knownlocations:GetLocation("investigate") then
        targetDist = TUNING.SPIDER_INVESTIGATETARGET_DIST
    end
    if GetSeasonManager() and (GetSeasonManager():IsSpring() or GetSeasonManager():IsGreenSeason()) then
        targetDist = targetDist * TUNING.SPRING_COMBAT_MOD
    end
    local notags = {"FX", "NOCLICK","INLIMBO", "monster"}
    return FindEntity(inst, targetDist, 
        function(guy) 
            if inst.components.combat:CanTarget(guy)
               and not (inst.components.follower and inst.components.follower.leader == guy)
               and not (inst.components.follower and inst.components.follower.leader == GetPlayer() and guy:HasTag("companion")) then
                return (guy:HasTag("character") and not guy:HasTag("monster"))
            end
    end, nil, notags)
end

local function WarriorRetarget(inst)
    local targetDist = TUNING.SPIDER_WARRIOR_TARGET_DIST
    if GetSeasonManager() and (GetSeasonManager():IsSpring() or GetSeasonManager():IsGreenSeason()) then
        targetDist = targetDist * TUNING.SPRING_COMBAT_MOD
    end
    local notags = {"FX", "NOCLICK","INLIMBO"}
    return FindEntity(inst, targetDist, function(guy)
		return ((guy:HasTag("character") and not guy:HasTag("monster")) or guy:HasTag("pig"))
               and inst.components.combat:CanTarget(guy)
               and not (inst.components.follower and inst.components.follower.leader == guy)
               and not (inst.components.follower and inst.components.follower.leader == GetPlayer() and guy:HasTag("companion"))
	end, nil, notags)
end

local function FindWarriorTargets(guy)
	return ((guy:HasTag("character") and not guy:HasTag("monster")) or guy:HasTag("pig"))
               and inst.components.combat:CanTarget(guy)
               and not (inst.components.follower and inst.components.follower.leader == guy)
end

local function keeptargetfn(inst, target)
   return target
          and target.components.combat
          and target.components.health
          and not target.components.health:IsDead()
          and not (inst.components.follower and inst.components.follower.leader == target)
          and not (inst.components.follower and inst.components.follower.leader == GetPlayer() and target:HasTag("companion"))
end

local function ShouldSleep(inst)
    return GetClock():IsDay()
           and not (inst.components.combat and inst.components.combat.target)
           and not (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
           and not (inst.components.burnable and inst.components.burnable:IsBurning() )
           and not (inst.components.follower and inst.components.follower.leader)
end

local function ShouldWake(inst)
    local wakeRadius = TUNING.SPIDER_WARRIOR_WAKE_RADIUS
    if GetSeasonManager() and (GetSeasonManager():IsSpring() or GetSeasonManager():IsGreenSeason()) then
        wakeRadius = wakeRadius * TUNING.SPRING_COMBAT_MOD
    end
    return GetClock():IsNight()
           or (inst.components.combat and inst.components.combat.target)
           or (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
           or (inst.components.burnable and inst.components.burnable:IsBurning() )
           or (inst.components.follower and inst.components.follower.leader)
           or (inst:HasTag("spider_warrior") and FindEntity(inst, wakeRadius, function(...) return FindWarriorTargets(inst, ...) end ))
end

local function DoReturn(inst)
	if inst.components.homeseeker and not (inst.components.follower and inst.components.follower.leader) then
		inst.components.homeseeker:ForceGoHome()
	end
end

local function StartDay(inst)
	if inst:IsAsleep() then
		DoReturn(inst)	
	end
end


local function OnEntitySleep(inst)
	if GetClock():IsDay() then
		DoReturn(inst)
	end
end

local function SummonFriends(inst, attacker)
    local summonDist = TUNING.SPIDER_SUMMON_WARRIORS_RADIUS
    if GetSeasonManager() and (GetSeasonManager():IsSpring() or GetSeasonManager():IsGreenSeason()) then
        summonDist = summonDist * TUNING.SPRING_COMBAT_MOD
    end
	local den = GetClosestInstWithTag("spiderden",inst, TUNING.SPIDER_SUMMON_WARRIORS_RADIUS)
	if den and den.components.combat and den.components.combat.onhitfn then
		den.components.combat.onhitfn(den, attacker)
	end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, function(dude)
        return dude:HasTag("spider")
               and not dude.components.health:IsDead()
               and dude.components.follower
               and dude.components.follower.leader == inst.components.follower.leader
    end, 10)
end

local function StartNight(inst)
    inst.components.sleeper:WakeUp()
end

local function SanityAura(inst, observer)

    if observer.prefab == "webber" then
        return 0
    end

    return -TUNING.SANITYAURA_SMALL

end

-- Used by the moon spider
local variations = {1, 2, 3, 4, 5}
local function DoSpikeAttack(inst, pt)
    local x, y, z = pt:Get()
    local inital_r = 1

    x = GetRandomWithVariance(x, inital_r)
    z = GetRandomWithVariance(z, inital_r)

    shuffleArray(variations)

    local num = math.random(2, 4)
    local dtheta = TWOPI / num

    for i = 1, num do
        local r = 1.1 + math.random() * 1.75
        local theta = i * dtheta + math.random() * dtheta * 0.8 + dtheta * 0.2
        local x1 = x + r * math.cos(theta)
        local z1 = z + r * math.sin(theta)

        if not inst:GetIsOnWater() and not IsPointNearHole(Vector3(x1, 0, z1)) then
            local spike = SpawnPrefab("moonspider_spike")
            spike.Transform:SetPosition(x1, 0, z1)
            spike:SetOwner(inst)
            if variations[i + 1] ~= 1 then
                spike.AnimState:OverrideSymbol("spike01", "spider_spike", "spike0"..tostring(variations[i + 1]))
            end
        end
    end
end

local function create_common(Sim)
	local inst = CreateEntity()
	
	inst:ListenForEvent( "daytime", function(i, data) StartDay( inst ) end, GetWorld())
	inst.OnEntitySleep = OnEntitySleep
	
    inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLightWatcher()
	local shadow = inst.entity:AddDynamicShadow()
	shadow:SetSize( 1.5, .5 )
    inst.Transform:SetFourFaced()
    
    
    ----------
    
    inst:AddTag("monster")
    inst:AddTag("hostile")
	inst:AddTag("scarytoprey")    
    inst:AddTag("canbetrapped")
    inst:AddTag("smallcreature")
    
    MakeCharacterPhysics(inst, 10, .5)
    MakePoisonableCharacter(inst)

    
    inst:AddTag("spider")
    inst.AnimState:SetBank("spider")
    inst.AnimState:PlayAnimation("idle")
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.TOTAL_DAY_TIME
    
    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }

  
    inst:SetStateGraph("SGmoonspider")
    
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("monstermeat", 1)
    inst.components.lootdropper:AddRandomLoot("silk", .5)
    inst.components.lootdropper.numrandomloot = 1
    
    ---------------------        
    MakeMediumBurnableCharacter(inst, "body")
    MakeMediumFreezableCharacter(inst, "body")
    inst.components.burnable.flammability = TUNING.SPIDER_FLAMMABILITY
    ---------------------       
    

    ------------------
    inst:AddComponent("health")

    ------------------
    
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetOnHit(SummonFriends)
    
    ------------------
    
    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)
    ------------------
    
    inst:AddComponent("knownlocations")

    ------------------
    
    inst:AddComponent("eater")
    inst.components.eater:SetCarnivore()
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater.strongstomach = true -- can eat monster meat!
    
    ------------------
    
    inst:AddComponent("inspectable")
    
    ------------------

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem

    ------------------

	inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = SanityAura
    
    
    local brain = require "brains/moonspiderbrain_no"
    --local brain = require "brains/spiderbrain"
    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("dusktime", function() StartNight(inst) end, GetWorld())

    return inst
end

local function create_moon(Sim)
    local inst = create_common(Sim)

    inst:AddTag("spider_warrior")
    inst:AddTag("spider_moon")
    
    inst.AnimState:SetBank("spider_moon")
    inst.AnimState:SetBuild("ds_spider_moon")
    inst.AnimState:PlayAnimation("idle")


    inst.DoSpikeAttack = DoSpikeAttack

    inst.components.health:SetMaxHealth(TUNING.SPIDER_MOON_HEALTH)

    inst.components.combat:SetDefaultDamage(TUNING.SPIDER_MOON_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.SPIDER_MOON_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.SPIDER_WARRIOR_ATTACK_RANGE, TUNING.SPIDER_WARRIOR_HIT_RANGE)
    inst.components.combat:SetRetargetFunction(1, WarriorRetarget)
    
    
    inst.components.locomotor.walkspeed = TUNING.SPIDER_HIDER_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SPIDER_HIDER_RUN_SPEED
    
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    return inst
end


return Prefab("spider_moon", create_moon, assets, prefabs)
