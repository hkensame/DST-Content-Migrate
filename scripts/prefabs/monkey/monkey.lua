-- 普通猴子 (monkey)
-- 移植自 DST，适配 DS 单机模式
-- 移除：AddNetwork, SetPristine, ismastersim
-- 适配：nightmarephase 逻辑简化(DS洞穴无噩梦态), acidinfusible 注释
--       LuckFormulas 简化为 math.random, FOODTYPE.VEGGIE → 字符串
--       MakeHauntablePanic/AddHauntableCustomReaction 注释
--       ms_forcenightmarestate 移除, WatchWorldState("nightmarephase") 移除

-- DS 无 FindPlayersInRange，单机兼容实现
local function FindPlayersInRange(x, y, z, range, isalive)
    local player = GetPlayer()
    if player == nil then return {} end
    if isalive and player:HasTag("playerghost") then return {} end
    if player:GetDistanceSqToPoint(x, y, z) < range * range then
        return {player}
    end
    return {}
end

local assets =
{
    Asset("ANIM", "anim/monkey/kiki_basic.zip"),
    Asset("ANIM", "anim/monkey/kiki_nightmare_skin.zip"),
    Asset("SOUND", "sound/monkey.fsb"),
}

local prefabs =
{
    "poop",
    "monkeyprojectile",
    "smallmeat",
    "cave_banana",
    "beardhair",
    "nightmarefuel",
    "monkeycorpse",
}

local brain = require "brains/monkeybrain"
local nightmarebrain = require "brains/nightmaremonkeybrain"

local LOOT = { "smallmeat", "cave_banana" }
local FORCED_NIGHTMARE_LOOT = { "nightmarefuel" }
SetSharedLootTable('monkey',
{
    {'smallmeat',     1.0},
    {'cave_banana',   1.0},
    {'beardhair',     1.0},
    {'nightmarefuel', 0.5},
})

local function SetHarassPlayer(inst, player)
    if inst.harassplayer ~= player then
        if inst._harassovertask ~= nil then
            inst._harassovertask:Cancel()
            inst._harassovertask = nil
        end
        if inst.harassplayer ~= nil then
            inst:RemoveEventCallback("onremove", inst._onharassplayerremoved, inst.harassplayer)
            inst.harassplayer = nil
        end
        if player ~= nil then
            inst:ListenForEvent("onremove", inst._onharassplayerremoved, player)
            inst.harassplayer = player
            inst._harassovertask = inst:DoTaskInTime(120, SetHarassPlayer, nil)
        end
    end
end

local function IsPoop(item)
    return item.prefab == "poop"
end

local function oneat(inst)
    if inst.components.inventory ~= nil then
        local maxpoop = 3
        local poopstack = inst.components.inventory:FindItem(IsPoop)
        if not poopstack or poopstack.components.stackable.stacksize < maxpoop then
            inst.components.inventory:GiveItem(SpawnPrefab("poop"))
        end
    end
end

local function onthrow(weapon, inst)
    if inst.components.inventory ~= nil then
        inst.components.inventory:ConsumeByName("poop")
    end
end

local function hasammo(inst)
    return inst.components.inventory ~= nil and inst.components.inventory:FindItem(IsPoop) ~= nil
end

local function EquipWeapons(inst)
    if inst.components.inventory ~= nil and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local thrower = CreateEntity()
        thrower.name = "Thrower"
        thrower.entity:AddTransform()
        thrower:AddComponent("weapon")
        thrower.components.weapon:SetDamage(TUNING.MONKEY_RANGED_DAMAGE)
        thrower.components.weapon:SetRange(TUNING.MONKEY_RANGED_RANGE)
        thrower.components.weapon:SetProjectile("monkeyprojectile")
        thrower.components.weapon:SetOnProjectileLaunch(onthrow)
        thrower:AddComponent("inventoryitem")
        thrower.persists = false
        thrower.components.inventoryitem:SetOnDroppedFn(thrower.Remove)
        thrower:AddComponent("equippable")
        thrower:AddTag("nosteal")
        inst.components.inventory:GiveItem(thrower)
        inst.weaponitems.thrower = thrower

        local hitter = CreateEntity()
        hitter.name = "Hitter"
        hitter.entity:AddTransform()
        hitter:AddComponent("weapon")
        hitter.components.weapon:SetDamage(TUNING.MONKEY_MELEE_DAMAGE)
        hitter.components.weapon:SetRange(0)
        hitter:AddComponent("inventoryitem")
        hitter.persists = false
        hitter.components.inventoryitem:SetOnDroppedFn(hitter.Remove)
        hitter:AddComponent("equippable")
        hitter:AddTag("nosteal")
        inst.components.inventory:GiveItem(hitter)
        inst.weaponitems.hitter = hitter
    end
end

local function _ForgetTarget(inst)
    inst.components.combat:SetTarget(nil)
end

local MONKEY_TAGS = { "monkey" }
local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    SetHarassPlayer(inst, nil)
    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoTaskInTime(math.random(55, 65), _ForgetTarget)

    local x, y, z = inst.Transform:GetWorldPosition()
    local monkeys = TheSim:FindEntities(x, y, z, 30, MONKEY_TAGS)
    for _, monkey in ipairs(monkeys) do
        if monkey ~= inst and monkey.components.combat then
            monkey.components.combat:SuggestTarget(data.attacker)
            SetHarassPlayer(monkey, nil)
            if monkey.task ~= nil then
                monkey.task:Cancel()
            end
            monkey.task = monkey:DoTaskInTime(math.random(55, 65), _ForgetTarget)
        end
    end
end

local function IsBanana(item)
    return item.prefab == "cave_banana" or item.prefab == "cave_banana_cooked"
end

local function FindTargetOfInterest(inst)
    if not inst.curious then
        return
    end

    if inst.harassplayer == nil and inst.components.combat.target == nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local targets = FindPlayersInRange(x, y, z, 25)
        for _ = 1, #targets do
            local randomtarget = math.random(#targets)
            local target = targets[randomtarget]
            table.remove(targets, randomtarget)
            local chance = target.components.inventory ~= nil and target.components.inventory:FindItem(IsBanana) ~= nil and
                TUNING.MONKEY_FOLLOW_PLAYER_WITH_BANANA_CHANCE or
                TUNING.MONKEY_FOLLOW_PLAYER_CHANCE
            -- DS 无 LuckFormulas，简化为 math.random
            if math.random() < chance then
                SetHarassPlayer(inst, target)
                return
            end
        end
    end
end

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "playerghost" }
local RETARGET_ONEOF_TAGS = { "character", "monster" }
local function retargetfn(inst)
    return inst:HasTag("nightmare")
        and FindEntity(
                inst,
                20,
                function(guy)
                    return inst.components.combat:CanTarget(guy)
                end,
                RETARGET_MUST_TAGS,
                RETARGET_CANT_TAGS,
                RETARGET_ONEOF_TAGS
            )
        or nil
end

local function shouldKeepTarget(inst)
    return true
end

local function _DropAndGoHome(inst)
    if inst.components.inventory ~= nil then
        inst.components.inventory:DropEverything(false, true)
    end
    if inst.components.homeseeker ~= nil and inst.components.homeseeker.home ~= nil then
        inst.components.homeseeker.home:PushEvent("monkeydanger")
    end
end

local function OnMonkeyDeath(inst, data)
    if data.afflicter ~= nil and data.inst:HasTag("monkey") and data.afflicter:HasTag("player") then
        inst:DoTaskInTime(math.random(), _DropAndGoHome)
    end
end

local function onpickup_delayed(inst, item)
    if item:IsValid() and
            item.components.inventoryitem ~= nil and
            item.components.inventoryitem.owner == inst then
        inst.components.inventory:Equip(item)
    end
end

local function OnPickup(inst, data)
    local item = data.item
    if item ~= nil and
            item.components.equippable ~= nil and
            item.components.equippable.equipslot == EQUIPSLOTS.HEAD and
            not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) then
        inst:DoTaskInTime(0, onpickup_delayed, item)
    end
end

local function DoFx(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("statue_transition_2")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(.8, .8, .8)
    end
    fx = SpawnPrefab("statue_transition")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(.8, .8, .8)
    end
end

local function SetNormalMonkey(inst)
    inst:RemoveTag("nightmare")
    inst:RemoveTag("shadow_aligned")

    inst:SetBrain(brain)
    inst.AnimState:SetBuild("kiki_basic")
    inst.AnimState:SetMultColour(1, 1, 1, 1)
    inst.curious = true
    inst.soundtype = ""
    inst.components.lootdropper:SetLoot(LOOT)
    inst.components.lootdropper:SetChanceLootTable(nil)

    -- acidinfusible 组件在 DS 不存在
    --inst.components.acidinfusible:SetMultipliers(TUNING.ACID_INFUSION_MULT.WEAKER)

    inst.components.combat:SetTarget(nil)

    inst:ListenForEvent("entity_death", inst.listenfn, GetWorld())
end

local function SetNightmareMonkey(inst)
    inst:AddTag("nightmare")
    inst:AddTag("shadow_aligned")

    inst.AnimState:SetMultColour(1, 1, 1, .6)
    inst:SetBrain(nightmarebrain)
    inst.AnimState:SetBuild("kiki_nightmare_skin")
    inst.soundtype = "_nightmare"
    SetHarassPlayer(inst, nil)
    inst.curious = false
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end

    --inst.components.acidinfusible:SetMultipliers(TUNING.ACID_INFUSION_MULT.BERSERKER)

    inst.components.combat:SetTarget(nil)

    inst:RemoveEventCallback("entity_death", inst.listenfn, GetWorld())
end

local function SetNightmareMonkeyLoot(inst, forced)
    if forced then
        inst.components.lootdropper:SetLoot(FORCED_NIGHTMARE_LOOT)
    else
        inst.components.lootdropper:SetLoot(nil)
    end
    inst.components.lootdropper:SetChanceLootTable("monkey")
end

local function OnSave(inst, data)
    data.nightmare = inst:HasTag("nightmare") or nil
end

local function OnLoad(inst, data)
    if data ~= nil and data.nightmare then
        SetNightmareMonkey(inst)
        SetNightmareMonkeyLoot(inst, false)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()

    inst.DynamicShadow:SetSize(2, 1.25)

    inst.Transform:SetSixFaced()

    MakeCharacterPhysics(inst, 10, 0.25)

    inst.AnimState:SetBank("kiki")
    inst.AnimState:SetBuild("kiki_basic")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("cavedweller")
    inst:AddTag("monkey")
    inst:AddTag("animal")

    inst.override_combat_fx_height = "high"
    inst.soundtype = ""

    MakeMediumBurnableCharacter(inst)
    MakeMediumFreezableCharacter(inst)

    inst:AddComponent("bloomer")

    inst:AddComponent("inventory")

    inst:AddComponent("inspectable")

    inst:AddComponent("thief")

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = false }
    inst.components.locomotor.walkspeed = TUNING.MONKEY_MOVE_SPEED

    inst:AddComponent("combat")
    inst.components.combat:SetAttackPeriod(TUNING.MONKEY_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.MONKEY_MELEE_RANGE)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)
    inst.components.combat:SetDefaultDamage(0)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.MONKEY_HEALTH)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("poop")
    inst.components.periodicspawner:SetRandomTimes(200,400)
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:SetMinimumSpacing(15)
    inst.components.periodicspawner:Start()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(LOOT)

    inst:AddComponent("eater")
    inst.components.eater:SetOmnivore()
    inst.components.eater:SetOnEatFn(oneat)

    inst:AddComponent("sleeper")
    -- DS 无 NocturnalSleepTest/WakeTest 全局函数，用 rawget 安全访问(strict.lua 兼容)
    local _sleepTest = rawget(_G, "NocturnalSleepTest")
    local _wakeTest = rawget(_G, "NocturnalWakeTest")
    inst.components.sleeper.sleeptestfn = _sleepTest or function(inst)
        local world = rawget(_G, "TheWorld")
        return world and world.state.isday or false
    end
    inst.components.sleeper.waketestfn = _wakeTest or function(inst)
        local world = rawget(_G, "TheWorld")
        return world and not world.state.isday or true
    end

    --inst:AddComponent("areaaware") -- DST-only, DS 无此组件

    -- acidinfusible 组件在 DS 不存在
    --inst:AddComponent("acidinfusible")
    --inst.components.acidinfusible:SetFXLevel(1)
    --inst.components.acidinfusible:SetMultipliers(TUNING.ACID_INFUSION_MULT.WEAKER)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGmonkey")

    inst.FindTargetOfInterestTask = inst:DoPeriodicTask(10, FindTargetOfInterest)

    inst.HasAmmo = hasammo
    inst.curious = true
    inst.harassplayer = nil
    inst._onharassplayerremoved = function() SetHarassPlayer(inst, nil) end

    inst:AddComponent("knownlocations")
    inst:AddComponent("timer")

    inst.listenfn = function(listento, data) OnMonkeyDeath(inst, data) end

    inst:ListenForEvent("onpickupitem", OnPickup)
    inst:ListenForEvent("attacked", OnAttacked)

    -- DS 洞穴无忧梦态变化，保留 areaaware 监听
    inst:ListenForEvent("changearea", function(inst)
        -- 简化：DS 无忧梦态系统，不做噩梦形态切换
    end)

    -- shadow_trap 交互移除 (DS 无 ms_forcenightmarestate)

    --MakeHauntablePanic(inst) -- DS 无幽灵系统
    --AddHauntableCustomReaction(inst, OnCustomHaunt, true, false, true)

    inst.weaponitems = {}
    EquipWeapons(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("monkey", fn, assets, prefabs)
