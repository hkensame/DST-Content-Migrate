local assets =
{
    Asset("ANIM", "anim/cave/refined_dust.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("refined_dust")
    inst.AnimState:SetBuild("refined_dust")
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "ELEMENTAL"
    inst.components.edible.hungervalue = 1

    inst:AddComponent("tradable")
    inst.components.tradable.rocktribute = 1

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/rf_dust.xml"
    inst.components.inventoryitem.imagename = "rf_dust"
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("bait")

    return inst
end

return Prefab("refined_dust", fn, assets)
