local assets = { Asset("ANIM", "anim/horrorfuel.zip") }

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("horrorfuel")
	inst.AnimState:SetBuild("horrorfuel")
	inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:SetMultColour(1, 1, 1, 0.5)

	inst:AddTag("purehorror")
	inst:AddTag("waterproofer")

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
	inst:AddComponent("inspectable")
	inst:AddComponent("fuel")
	inst.components.fuel.fueltype = "NIGHTMARE"
	inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL * 2
	inst:AddComponent("repairer")
	inst.components.repairer.repairmaterial = "nightmare"
	inst.components.repairer.finiteusesrepairvalue = TUNING.NIGHTMAREFUEL_FINITEUSESREPAIRVALUE * 2
	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(0)
	inst:AddComponent("inventoryitem")

	return inst
end

return Prefab("horrorfuel", fn, assets)
