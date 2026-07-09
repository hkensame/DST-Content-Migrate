-- moon_mushroom.lua - 月蘑菇帽（移植自 DST）
-- 月岛特产食物，掉落物 from mushtree_moon

local capassets = {
    Asset("ANIM", "anim/cave/moon_cap.zip"),
}
local cookedassets = {
    Asset("ANIM", "anim/cave/moon_cap.zip"),
}
local capprefabs = { "moon_cap_cooked" }

local function mooncap_oneaten(inst, eater)
    if not (eater.components.freezable and eater.components.freezable:IsFrozen()) and
            not (eater.components.pinnable and eater.components.pinnable:IsStuck()) and
            not (eater.components.fossilizable and eater.components.fossilizable:IsFossilized()) then
        if eater.components.grogginess_dst then
            local knocktime = TUNING.MOON_MUSHROOM_SLEEPTIME or 8
            eater.components.grogginess_dst:AddGrogginess(4, knocktime)
        end
    end
end

local function mooncap_cooked_oneaten(inst, eater)
    if eater and eater:IsValid() and eater.components.grogginess_dst then
        eater.components.grogginess_dst:ResetGrogginess()
    end
end

local function MakeMoonCap(name, assets, prefabs, animname, cookresult)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("moon_cap")
        inst.AnimState:SetBuild("moon_cap")
        inst.AnimState:PlayAnimation(animname)
        inst:AddTag("cattoy")
        inst:AddTag("moonmushroom")
        inst:AddTag("mushroom")
        inst:AddTag("cookable")
        if rawget(_G, 'MakeInventoryFloatable') then
            MakeInventoryFloatable(inst, animname, animname)
        end

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = 0
        inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
        inst.components.edible.sanityvalue = TUNING.SANITY_SMALL
        inst.components.edible.foodtype = "VEGGIE"
        inst.components.edible:SetOnEatenFn(mooncap_oneaten)

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        inst:AddComponent("inspectable")
        inst:AddComponent("bait")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = "moon_cap"
        inst.components.inventoryitem.atlasname = "images/moon_cap.xml"

        inst:AddComponent("tradable")

        MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
        MakeSmallPropagator(inst)

        if cookresult ~= nil then
            inst:AddComponent("cookable")
            inst.components.cookable.product = cookresult
        end
        return inst
    end
end

local function MakeMoonCapCooked(name, assets, prefabs, animname)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("moon_cap")
        inst.AnimState:SetBuild("moon_cap")
        inst.AnimState:PlayAnimation(animname)
        inst:AddTag("cattoy")
        inst:AddTag("mushroom")
        if rawget(_G, 'MakeInventoryFloatable') then
            MakeInventoryFloatable(inst, animname, animname)
        end

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = 0
        inst.components.edible.hungervalue = -TUNING.CALORIES_SMALL
        inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL
        inst.components.edible.foodtype = "VEGGIE"
        inst.components.edible:SetOnEatenFn(mooncap_cooked_oneaten)

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = "ripe_moon_cap"
        inst.components.inventoryitem.atlasname = "images/ripe_moon_cap.xml"

        inst:AddComponent("tradable")

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.TINY_FUEL

        MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
        MakeSmallPropagator(inst)

        return inst
    end
end

return Prefab("moon_cap", MakeMoonCap("moon_cap", capassets, capprefabs, "moon_cap", "moon_cap_cooked"), capassets, capprefabs),
    Prefab("moon_cap_cooked", MakeMoonCapCooked("moon_cap_cooked", cookedassets, {}, "moon_cap_cooked"), cookedassets)
