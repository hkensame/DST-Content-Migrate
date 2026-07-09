local assets =
{
    Asset("ANIM", "anim/malbatross/malbatross_feathered_weave.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    --inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("malbatross_feathered_weave")
    inst.AnimState:SetBuild("malbatross_feathered_weave")
    inst.AnimState:PlayAnimation("idle")

    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst, "idle", "idle")
    end
--[[
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
]]
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    --inst.components.inventoryitem:SetSinks(false)
    inst.components.inventoryitem.imagename = "malbatross_feathered_weave"
	inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    --MakeHauntableLaunch(inst)

    return inst
end

return Prefab("malbatross_feathered_weave", fn, assets)
