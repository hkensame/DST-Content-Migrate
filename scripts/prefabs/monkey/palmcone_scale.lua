-- 棕榈锥鳞片 (palmcone_scale)
-- 移植自 DST，适配 DS 单机模式
-- 棕榈锥树的独特掉落物

local assets = {
    Asset("ANIM", "anim/monkey/palmcone_scale.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("palmcone_scale")
    inst.AnimState:SetBuild("palmcone_scale")
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("tradable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("common/inventory/palmcone_scale", fn, assets)
