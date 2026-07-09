local assets =
{
    Asset("ANIM", "anim/moonbase/moonrock_nugget.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst, "idle", "idle")
    end

    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetBank("moonrocknugget")
    inst.AnimState:SetBuild("moonrock_nugget")
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "ELEMENTAL"
    inst.components.edible.hungervalue = 1
    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "moonrocknugget"
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"
    --inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = "moonrock"
    inst.components.repairer.healthrepairvalue = TUNING.REPAIR_MOONROCK_NUGGET_HEALTH or 40
    inst.components.repairer.workrepairvalue = TUNING.REPAIR_MOONROCK_NUGGET_WORK or 2

    return inst
end

return Prefab("moonrocknugget", fn, assets)