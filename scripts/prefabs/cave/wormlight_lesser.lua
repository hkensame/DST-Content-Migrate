-- 小荧光果 (wormlight_lesser)
-- 移植自 DST，适配 DS 单机模式
-- wormlight_plant 的作物，可食用
-- 移除：AddNetwork, SetPristine, ismastersim 网络门控
-- 移除：MakeInventoryFloatable, vasedecoration, lightbattery, FUELTYPE.WORMLIGHT

local assets =
{
    Asset("ANIM", "anim/worm_light.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()

    inst.AnimState:SetBank("worm_light")
    inst.AnimState:SetBuild("worm_light")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    MakeInventoryPhysics(inst)

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(169 / 255, 231 / 255, 245 / 255)
    inst.Light:Enable(true)

    inst:AddTag("light")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "wormlight_lesser.tex"
    inst.components.inventoryitem.atlasname = "images/wormlight_lesser.xml"

    inst:AddComponent("tradable")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "VEGGIE"
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    return inst
end

return Prefab("wormlight_lesser", fn, assets)
