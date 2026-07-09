-- 火药猴 (powder_monkey)
-- 移植自 DST，适配 DS 单机模式
-- 移除：AddNetwork, SetPristine, ismastersim
-- 适配：FOODTYPE.VEGGIE → SetOmnivore(), MakeHauntablePanic 注释
--       CraftMonkeySpeech 移除, crewmember/boat 系统移除
--       drownable/embarker 注释(DS无海洋系统), ms_seamlesscharacterspawned 移除

local assets =
{
    Asset("ANIM", "anim/monkey/monkey_small.zip"),
    Asset("SOUND", "sound/monkey.fsb"),
}

local prefabs =
{
    "poop",
    "monkeyprojectile",
    "smallmeat",
    "cave_banana",
    "cutless",
    "monkey_smallhat",
}

local brain = require "brains/powdermonkeybrain"

SetSharedLootTable('powdermonkey',
{
    {'smallmeat',     1.0},
})

local function IsPoop(item)
    return item.prefab == "poop"
end

local function oneat(inst)
    if inst.components.inventory ~= nil then
        local maxpoop = 3
        local poopstack = inst.components.inventory:FindItem(IsPoop)
        if poopstack == nil or poopstack.components.stackable.stacksize < maxpoop then
            inst.components.inventory:GiveItem(SpawnPrefab("poop"))
        end
    end
end

local function _ForgetTarget(inst)
    inst.components.combat:SetTarget(nil)
end

local MONKEY_TAGS = { "monkey" }
local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoTaskInTime(math.random(55, 65), _ForgetTarget)

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, MONKEY_TAGS)
    for i, v in ipairs(ents) do
        if v ~= inst and v.components.combat then
            v.components.combat:SuggestTarget(data.attacker)
            if v.task ~= nil then
                v.task:Cancel()
            end
            v.task = v:DoTaskInTime(math.random(55, 65), _ForgetTarget)
        end
    end
end

local function retargetfn(inst)
    return nil
end

local function shouldKeepTarget(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function OnPickup(inst, data)
    local item = data ~= nil and data.item or nil
    if item ~= nil and
        item.components.equippable ~= nil and
        item.components.equippable.equipslot == EQUIPSLOTS.HEAD and
        not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) then
        inst:DoTaskInTime(0, function()
            if item:IsValid() and
                item.components.inventoryitem ~= nil and
                item.components.inventoryitem.owner == inst then
                inst.components.inventory:Equip(item)
            end
        end)
    end
end

local function OnDropItem(inst, data)
    if data ~= nil and data.item ~= nil then
        data.item:RemoveTag("personal_possession")
    end
end

local function OnSave(inst, data)
    local personal_item = {}
    for k, v in pairs(inst.components.inventory.itemslots) do
        if v.persists and v:HasTag("personal_possession") then
            personal_item[k] = v.prefab
        end
    end
    data.personal_item = (next(personal_item) ~= nil and personal_item) or nil

    local personal_equip = {}
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v.persists and v:HasTag("personal_possession") then
            personal_equip[k] = v.prefab
        end
    end
    data.personal_equip = (next(personal_equip) ~= nil and personal_equip) or nil
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.personal_item ~= nil then
            for k, v in pairs(data.personal_item) do
                local item = inst.components.inventory:GetItemInSlot(k)
                if item ~= nil and item.prefab == v then
                    item:AddTag("personal_possession")
                end
            end
        end
        if data.personal_equip ~= nil then
            for k, v in pairs(data.personal_equip) do
                local item = inst.components.inventory:GetEquippedItem(k)
                if item ~= nil and item.prefab == v then
                    item:AddTag("personal_possession")
                end
            end
        end
    end
end

local function OnDeath(inst,data)
    -- 死亡时掉落物品
end

local function OnGotItem(inst,data)
    if data.item and (data.item.prefab == "cave_banana" or data.item.prefab == "cave_banana_cooked") then
        inst:PushEvent("victory", {
            item = data.item,
            say = STRINGS["MONKEY_BATTLECRY_VICTORY"] and STRINGS["MONKEY_BATTLECRY_VICTORY"][math.random(#STRINGS["MONKEY_BATTLECRY_VICTORY"])] or nil
        })
    end
end

local function ontalk(inst, script)
    inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/speak")
end

local function onhit(inst)
    inst:ClearBufferedAction()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()

    inst.DynamicShadow:SetSize(2, 1.25)

    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 10, 0.25)

    inst.AnimState:SetBank("monkey_small")
    inst.AnimState:SetBuild("monkey_small")
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:Hide("ARM_carry")

    inst:AddTag("character")
    inst:AddTag("monkey")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("pirate")

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -400, 0)
    --inst.components.talker:MakeChatter() -- DST-only, DS 无网络原语
    inst.components.talker.ontalk = ontalk

    -----------------------------------------------------------
    inst.soundtype = ""

    MakeMediumBurnableCharacter(inst,"m_skirt")
    MakeMediumFreezableCharacter(inst)

    inst:AddComponent("bloomer")

    inst:AddComponent("inventory")
    inst.components.inventory.maxslots = 20

    inst:AddComponent("inspectable")

    inst:AddComponent("thief")

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = false }
    inst.components.locomotor.walkspeed = TUNING.MONKEY_MOVE_SPEED

    inst:AddComponent("combat")
    inst.components.combat:SetAttackPeriod(TUNING.MONKEY_ATTACK_PERIOD)
    inst.components.combat:SetDefaultDamage(TUNING.POWDER_MONKEY_DAMAGE)
    inst.components.combat:SetRange(TUNING.MONKEY_MELEE_RANGE)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetOnHit(onhit)
    inst.components.combat.GetBattleCryString = function(combatcmp, target)
        if target ~= nil then
            local strtbl = (target:HasTag("monkey") and "MONKEY_MONKEY_BATTLECRY")
                or (target.components.inventory ~= nil
                    and target.components.inventory:NumItems() > 0
                    and "MONKEY_STUFF_BATTLECRY")
                or "MONKEY_BATTLECRY"
            if STRINGS[strtbl] then
                return strtbl, math.random(#STRINGS[strtbl])
            end
        end
    end

    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.POWDER_MONKEY_HEALTH)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('powdermonkey')

    inst:AddComponent("eater")
    inst.components.eater:SetOmnivore()
    inst.components.eater:SetOnEatFn(oneat)

    inst:AddComponent("sleeper")
    inst.components.sleeper.sleeptestfn = DefaultSleepTest
    inst.components.sleeper.waketestfn = DefaultWakeTest

    -- embarker/drownable 组件在 DS 不存在
    --inst:AddComponent("embarker")
    --inst:AddComponent("drownable")
    --inst.components.locomotor:SetAllowPlatformHopping(true)

    --inst:AddComponent("areaaware") -- DST-only, DS 无此组件

    inst:AddComponent("timer")

    inst:ListenForEvent("onpickupitem", OnPickup)
    inst:ListenForEvent("dropitem", OnDropItem)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("itemget", OnGotItem)

    --MakeHauntablePanic(inst) -- DS 无幽灵系统

    inst:SetBrain(brain)
    inst:SetStateGraph("SGpowdermonkey")

    inst:AddComponent("knownlocations")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("powder_monkey", fn, assets, prefabs)
