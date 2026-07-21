-- 光蟹 (小型发光甲壳类生物，掉落灯泡和肉)
-- 移植自 DST，适配 DS 单人生存模式

local assets =
{
    Asset("ANIM", "anim/moonisland/lightcrab.zip"),
}

local prefabs =
{
    "fish_raw",
    "lightbulb",
    "slurtle_shellpieces",
}

local brain = require("brains/lightcrabbrain")

local function OnDropped(inst)
    inst.sg:GoToState("stunned")
end

local function ShouldWake(inst)
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddDynamicShadow()

    MakeCharacterPhysics(inst, 20, 0.5)
    inst.Physics:SetCapsule(0.25, 0.5)

    inst.DynamicShadow:SetSize(0.8, 0.5)

    inst.Transform:SetSixFaced()

    inst.AnimState:SetBank("lightcrab")
    inst.AnimState:SetBuild("lightcrab")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetLightOverride(0.25)

    inst.Light:SetRadius(1)
    inst.Light:SetIntensity(.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetColour(125/255, 125/255, 125/255)
    inst.Light:Enable(true)

    inst:AddTag("animal")
    inst:AddTag("prey")
    inst:AddTag("smallcreature")
    inst:AddTag("canbetrapped")
    inst:AddTag("cattoy")
    inst:AddTag("catfood")
    inst:AddTag("stunnedbybomb")
    inst:AddTag("lightbattery")
    inst:AddTag("cookable")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = TUNING.LIGHTCRAB_WALK_SPEED or 4
    inst.components.locomotor.runspeed = TUNING.LIGHTCRAB_RUN_SPEED or 7
    inst:SetStateGraph("SGlightcrab")

    inst:SetBrain(brain)

    inst:AddComponent("eater")
    inst.components.eater:SetOmnivore()

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

    inst:AddComponent("cookable")
    inst.components.cookable.product = "fish_raw_small_cooked"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.LIGHTCRAB_HEALTH or 15)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper:AddRandomLoot("fish_raw", .25)
    inst.components.lootdropper:AddRandomLoot("lightbulb", .25)
    inst.components.lootdropper:AddRandomLoot("slurtle_shellpieces", .5)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

    MakeSmallBurnableCharacter(inst, "body")
    MakeTinyFreezableCharacter(inst, "body")

    inst:AddComponent("inspectable")
    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(nil)
    inst.components.sleeper:SetWakeTest(ShouldWake)

    --MakeHauntablePanic(inst) -- DS 无此函数

    return inst
end

return Prefab("lightcrab", fn, assets, prefabs)
