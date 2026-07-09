local assets =
{
	Asset("ANIM", "anim/hound_basic.zip"),
	Asset("ANIM", "anim/hound.zip"),
	Asset("SOUND", "sound/hound.fsb"),
    Asset("INV_IMAGE", "houndstooth"),
}

local prefabs =
{
    "houndstooth",
    "monstermeat",
    "redgem",
    "bluegem",
    "splash_green",
	"houndcorpse",
}


local gargoyles = 
{
    "gargoyle_houndatk",
    "gargoyle_hounddeath",
}
local prefabs_moon = {}
for i, v in ipairs(gargoyles) do
    table.insert(prefabs_moon, v)
end
for i, v in ipairs(prefabs) do
    table.insert(prefabs_moon, v)
end

local moonbrain = require("brains/moonbeastbrain")

local sounds =
{
    pant = "dontstarve/creatures/hound/pant",
    attack = "dontstarve/creatures/hound/attack",
    bite = "dontstarve/creatures/hound/bite",
    bark = "dontstarve/creatures/hound/bark",
    death = "dontstarve/creatures/hound/death",
    sleep = "dontstarve/creatures/hound/sleep",
    growl = "dontstarve/creatures/hound/growl",
    howl = "dontstarve/creatures/together/clayhound/howl",
    hurt = "dontstarve/creatures/hound/hurt",
}

SetSharedLootTable('hound',
{
    {'monstermeat', 1.000},
    {'houndstooth', 0.125},
})

local WAKE_TO_FOLLOW_DISTANCE = 8
local SLEEP_NEAR_HOME_DISTANCE = 10
local SHARE_TARGET_DIST = 30
local HOME_TELEPORT_DIST = 30

local NO_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO" }
local FREEZABLE_TAGS = { "freezable" }

local function ShouldWakeUp(inst)
    return DefaultWakeTest(inst) or (inst.components.follower and inst.components.follower.leader and not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE))
end

local function ShouldSleep(inst)
    return inst:HasTag("pet_hound")
        and not GetClock():IsDay()
        and not (inst.components.combat and inst.components.combat.target)
        and not (inst.components.burnable and inst.components.burnable:IsBurning())
        and (not inst.components.homeseeker or inst:IsNear(inst.components.homeseeker.home, SLEEP_NEAR_HOME_DISTANCE))
end

local function OnNewTarget(inst, data)
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end
--[[手机
local function retargetfn(inst)
    local dist = TUNING.HOUND_TARGET_DIST
    if inst:HasTag("pet_hound") then
        dist = TUNING.HOUND_TARGET_DIST
    end
    local notags = {"FX", "NOCLICK","INLIMBO", "wall", "houndmound", "hound", "houndfriend", "aquatic"}
    return FindEntity(inst, dist, function(guy) 
		local shouldtarget = inst.components.combat:CanTarget(guy)
        return shouldtarget
    end, nil, notags)
end
--]]

--联机
TUNING.HOUND_FOLLOWER_AGGRO_DIST = 8
local RETARGET_CANT_TAGS = { "wall", "houndmound", "hound", "houndfriend" }
local function retargetfn(inst)
    if inst.sg:HasStateTag("statue") then
        return
    end
    local leader = inst.components.follower.leader
    if leader ~= nil and leader.sg ~= nil and leader.sg:HasStateTag("statue") then
        return
    end
    local playerleader = leader ~= nil and leader:HasTag("player")
    local ispet = inst:HasTag("pet_hound")
    return (leader == nil or
            (ispet and not playerleader) or
            inst:IsNear(leader, TUNING.HOUND_FOLLOWER_AGGRO_DIST))
        and FindEntity(
                inst,
                (ispet or leader ~= nil) and TUNING.HOUND_TARGET_DIST or TUNING.HOUND_TARGET_DIST,
                function(guy)
                    return guy ~= leader and inst.components.combat:CanTarget(guy)
                end,
                nil,
                RETARGET_CANT_TAGS
            )
        or nil
end

local function KeepTarget(inst, target)
    local shouldkeep = inst.components.combat:CanTarget(target) and (not inst:HasTag("pet_hound") or inst:IsNear(target, TUNING.HOUND_FOLLOWER_TARGET_KEEP))
    local onboat = target.components.driver and target.components.driver:GetIsDriving()
    return shouldkeep and not onboat
end

local function IsNearMoonBase(inst, dist)
    local moonbase = inst.components.entitytracker:GetEntity("moonbase")
    return moonbase == nil or inst:IsNear(moonbase, dist)
end

local MOON_RETARGET_CANT_TAGS = { "FX", "NOCLICK","INLIMBO", "wall", "houndmound", "hound", "houndfriend", "aquatic", "moonbeast" }

local function moon_retargetfn(inst)
    return IsNearMoonBase(inst, TUNING.MOONHOUND_AGGRO_DIST)
        and FindEntity(
                inst,
                TUNING.HOUND_TARGET_DIST,
                function(guy)
                    return inst.components.combat:CanTarget(guy)
                end,
                nil,
                MOON_RETARGET_CANT_TAGS
            )
        or nil
end

local function moon_keeptargetfn(inst, target)
    return IsNearMoonBase(inst, TUNING.MOONHOUND_RETURN_DIST)
        and inst.components.combat:CanTarget(target)
        and inst:IsNear(target, TUNING.HOUND_FOLLOWER_TARGET_KEEP)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST,
        function(dude)
            return not (dude.components.health ~= nil and dude.components.health:IsDead())
                and (dude:HasTag("hound") or dude:HasTag("houndfriend"))
                and data.attacker ~= (dude.components.follower ~= nil and dude.components.follower.leader or nil)
        end, 5)
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST,
        function(dude)
            return not (dude.components.health ~= nil and dude.components.health:IsDead())
                and (dude:HasTag("hound") or dude:HasTag("houndfriend"))
                and data.target ~= (dude.components.follower ~= nil and dude.components.follower.leader or nil)
        end, 5)
end

local function GetReturnPos(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local rad = 2
    local angle = math.random() * 2 * PI
    return x + rad * math.cos(angle), y, z - rad * math.sin(angle)
end

local function DoReturn(inst)
    --print("DoReturn", inst)
    if inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome() then
        if inst:HasTag("pet_hound") then
            if inst.components.homeseeker.home:IsAsleep() and not inst:IsNear(inst.components.homeseeker.home, HOME_TELEPORT_DIST) then
                inst.Physics:Teleport(GetReturnPos(inst.components.homeseeker.home))
            end
        elseif inst.components.homeseeker.home.components.childspawner ~= nil then
            inst.components.homeseeker.home.components.childspawner:GoHome(inst)
        end
    end
end

local function OnEntitySleep(inst)
    --print("OnEntitySleep", inst)
    if not GetClock():IsDay() then
        DoReturn(inst)
    end
end

local function OnNight(inst)
    --print("OnNight", inst)
    if inst:IsAsleep() then
        DoReturn(inst)  
    end
end

local function OnSave(inst, data)
    data.ispet = inst:HasTag("pet_hound") or nil
    --print("OnSave", inst, data.ispet)
end

local function OnLoad(inst, data)
    --print("OnLoad", inst, data.ispet)
    if data ~= nil and data.ispet then
        inst:AddTag("pet_hound")
        if inst.sg ~= nil then
            inst.sg:GoToState("idle")
        end
    end
end

local function fncommon(bank, build, morphlist, custombrain, tag, data)
	data = data or {}

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()

    MakeCharacterPhysics(inst, 10, .5)

    inst.DynamicShadow:SetSize(2.5, 1.5)
    inst.Transform:SetFourFaced()

    inst:AddTag("scarytoprey")
    inst:AddTag("scarytooceanprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("hound")
    inst:AddTag("canbestartled")

    if tag ~= nil then
        inst:AddTag(tag)
    end

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")


    inst.sounds = sounds

    inst:AddComponent("spawnfader")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.HOUND_SPEED

    inst:SetStateGraph("SGhound")

    if data.amphibious then
		inst:AddComponent("embarker")
		inst.components.embarker.embark_speed = inst.components.locomotor.runspeed
        inst.components.embarker.antic = true

	    inst.components.locomotor:SetAllowPlatformHopping(true)

		inst:AddComponent("amphibiouscreature")
		inst.components.amphibiouscreature:SetBanks(bank, bank.."_water")
        inst.components.amphibiouscreature:SetEnterWaterFn(
            function(inst)
                inst.landspeed = inst.components.locomotor.runspeed
                inst.components.locomotor.runspeed = TUNING.HOUND_SWIM_SPEED
                inst.hop_distance = inst.components.locomotor.hop_distance
                inst.components.locomotor.hop_distance = 4
            end)            
        inst.components.amphibiouscreature:SetExitWaterFn(
            function(inst)
                if inst.landspeed then
                    inst.components.locomotor.runspeed = inst.landspeed 
                end
                if inst.hop_distance then
                    inst.components.locomotor.hop_distance = inst.hop_distance
                end
            end)

		inst.components.locomotor.pathcaps = { allowocean = true }
	end
--]]
    

    inst:SetBrain(moonbrain)

    inst:AddComponent("follower")
    inst:AddComponent("entitytracker")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.HOUND_HEALTH)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.HOUND_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.HOUND_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetHurtSound("dontstarve/creatures/hound/hurt")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('hound')

    inst:AddComponent("inspectable")

       inst:AddComponent("eater")
        inst.components.eater:SetCarnivore()
        inst.components.eater:SetCanEatHorrible()
        inst.components.eater.strongstomach = true -- can eat monster meat!

        inst:AddComponent("sleeper")
        inst.components.sleeper:SetResistance(3)
        inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
        inst.components.sleeper:SetSleepTest(ShouldSleep)
        inst.components.sleeper:SetWakeTest(ShouldWakeUp)
        inst:ListenForEvent("newcombattarget", OnNewTarget)

    inst:ListenForEvent( "dusktime", function() OnNight( inst ) end, GetWorld()) 
    inst:ListenForEvent( "nighttime", function() OnNight( inst ) end, GetWorld()) 
    inst.OnEntitySleep = OnEntitySleep

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onattackother", OnAttackOther)

    return inst
end

local function OnMoonPetrify(inst)
    if not inst.components.health:IsDead() and (not inst.sg:HasStateTag("busy") or inst:IsAsleep()) then
        local x, y, z = inst.Transform:GetWorldPosition()
        local rot = inst.Transform:GetRotation()
        inst:Remove()
        local gargoyle = SpawnPrefab(gargoyles[math.random(#gargoyles)])
        gargoyle.Transform:SetPosition(x, y, z)
        gargoyle.Transform:SetRotation(rot)
        gargoyle:Petrify()
    end
end

local function OnMoonTransformed(inst, data)
    if data.old.prefab ~= "hound" then
        SpawnPrefab("small_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
    inst.sg:GoToState("taunt")
end

local function fnmoon()
    local inst = fncommon("hound", "hound", nil, moonbrain, "moonbeast", false)
    
    inst:SetStateGraph("SGmoonhound")

    --inst:SetPrefabNameOverride("hound")
    inst:SetPrefabName("hound")

    MakeMediumFreezableCharacter(inst, "hound_body")
    MakeMediumBurnableCharacter(inst, "hound_body")

    inst.components.freezable:SetDefaultWearOffTime(TUNING.MOONHOUND_FREEZE_WEAR_OFF_TIME)

    inst.components.combat:SetDefaultDamage(TUNING.MOONHOUND_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.MOONHOUND_ATTACK_PERIOD)
    inst.components.combat:SetTarget(nil)
    inst.components.combat:SetRetargetFunction(3, moon_retargetfn)
    inst.components.combat:SetKeepTargetFunction(moon_keeptargetfn)
    inst.components.locomotor.runspeed = TUNING.MOONHOUND_SPEED
    inst.components.health:SetMaxHealth(TUNING.MOONHOUND_HEALTH)

    inst:ListenForEvent("moonpetrify", OnMoonPetrify)
    inst:ListenForEvent("moontransformed", OnMoonTransformed)

    return inst
end

return Prefab("moonhound", fnmoon, assets, prefabs_moon)
