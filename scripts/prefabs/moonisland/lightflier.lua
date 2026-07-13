-- 光飞虫 (lightflier)
-- 移植自 DST，适配 DS 单人生存模式
-- 移除：formationfollower、MakeFeedableSmallLivestock、MakeInventoryFloatable
-- 保留：homeseeker（由 childspawner:TakeOwnership 自动添加，需 knownlocations）

local brain = require("brains/lightflierbrain")

local assets =
{
    Asset("ANIM", "anim/moonisland/lightflier.zip"),
    Asset("INV_IMAGE", "lightflier"),
}

SetSharedLootTable("lightflier",
{
    {"lightbulb",    1},
})

local function OnPerished(inst)
    -- 新鲜度耗尽 → 死亡，掉落 lightbulb
    if inst.components.lootdropper then
        inst.components.lootdropper:DropLoot()
    end
    inst:Remove()
end

local function OnPickedUp(inst)
    inst.components.perishable:StartPerishing() -- 放入背包才开始新鲜度衰减
    inst:AddTag("show_spoilage") -- 背包中显示新鲜度条
end

local function OnWorked(inst, worker)
    -- 捕虫网捕获后保持当前新鲜度（与 moonbutterfly 行为一致）
    if worker.components.inventory ~= nil then
        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
    end
end

local function OnDropped(inst)
    inst.components.perishable:StopPerishing() -- 野外暂停新鲜度衰减
    inst:RemoveTag("show_spoilage") -- 野外隐藏新鲜度条
    inst.sg:GoToState("idle")
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
    end
    -- Unstack: drop all
    if inst.components.stackable ~= nil and inst.components.stackable:IsStack() then
        local x, y, z = inst.Transform:GetWorldPosition()
        while inst.components.stackable:IsStack() do
            local item = inst.components.stackable:Get()
            if item ~= nil then
                if item.components.inventoryitem ~= nil then
                    item.components.inventoryitem:OnDropped()
                end
                item.Physics:Teleport(x, y, z)
            end
        end
    end
end

local function SleepTest(inst)
    return false -- doesn't sleep naturally, just lands
end

local function GoToSleep(inst)
    -- landed
end

local function OnWakeUp(inst)
    -- took off
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()

    MakeGhostPhysics(inst, 1, .5)

    inst.DynamicShadow:SetSize(1, .5)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("lightflier")
    inst.AnimState:SetBuild("lightflier")
    inst.AnimState:SetLightOverride(0.1)

    -- Light
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(.75)
    inst.Light:SetRadius(1)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)

    inst:AddTag("lightflier")
    inst:AddTag("cavedweller")
    inst:AddTag("flying")
    inst:AddTag("insect")
    inst:AddTag("smallcreature")
    inst:AddTag("lunar_aligned")
    inst:AddTag("show_spoilage")
    -- 野外不显示新鲜度条（放入背包时由 OnPickedUp 添加）

    -- stackable
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM or 10

    -- inventoryitem
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true
    inst.components.inventoryitem.pushlandedevents = false
    inst.components.inventoryitem.imagename = "lightflier"
    inst.components.inventoryitem.atlasname = "images/lightflier.xml"
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPickedUp)
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

    -- tradable
    inst:AddComponent("tradable")

    -- workable (catch with bug net)
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnWorked)

    -- eater (DS 无 SetDiet/FOODTYPE，用 SetVegetarian)
    inst:AddComponent("eater")
    inst.components.eater:SetVegetarian()

    -- health
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.LIGHTFLIER_HEALTH or 15)

    -- combat
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "lightbulb"

    -- lootdropper
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("lightflier")

    -- locomotor
    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = TUNING.LIGHTFLIER_WALK_SPEED or 5

    -- sleeper
    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true
    inst.components.sleeper.sleeptestfn = SleepTest

    -- knownlocations：配合 homeseeker 记忆家的位置（由 childspawner:TakeOwnership 设置）
    inst:AddComponent("knownlocations")
    -- [FIX] TakeOwnership 可能已自动添加 homeseeker，需先检查
    if inst.components.homeseeker == nil then
        inst:AddComponent("homeseeker")
    end

    -- inspectable
    inst:AddComponent("inspectable")

    -- burnable + freezable
    MakeSmallBurnableCharacter(inst, "lightbulb")
    MakeSmallFreezableCharacter(inst, "lightbulb")
    inst.components.burnable:SetBurnTime(6 * (TUNING.PLANTMOB_BURNTIME_MULT or 0.25))
    inst.components.health.fire_damage_scale = TUNING.PLANTMOB_FIRE_DAMAGE_SCALE or 1.5

    -- perishable (1 天新鲜度，野外不降背包才开始衰减，与 DST MakeSmallPerishableCreature 一致)
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.TOTAL_DAY_TIME or 480)
    inst.components.perishable:StopPerishing() -- 野外不降新鲜度，放入背包才开始
    inst:RemoveTag("show_spoilage") -- 初始状态（野外）不显示新鲜度条
    inst.components.perishable:SetOnPerishFn(OnPerished)

    -- hauntable
    --MakeHauntablePanic(inst) -- DS 无此函数

    -- StateGraph + Brain
    inst:SetStateGraph("SGlightflier")
    inst:SetBrain(brain)

    -- Events
    inst:ListenForEvent("gotosleep", GoToSleep)
    inst:ListenForEvent("onwakeup", OnWakeUp)

    return inst
end

return Prefab("lightflier", fn, assets)
