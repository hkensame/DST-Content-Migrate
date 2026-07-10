local assets = { Asset("ANIM", "anim/dreadstone.zip") }

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("dreadstone")
	inst.AnimState:SetBuild("dreadstone")
	inst.AnimState:PlayAnimation("idle")

	inst.pickupsound = "rock"

	inst:AddComponent("tradable")
	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst:AddComponent("repairer")
	inst.components.repairer.repairmaterial = "dreadstone"
	inst.components.repairer.healthrepairvalue = TUNING.REPAIR_DREADSTONE_HEALTH

	return inst
end

return Prefab("dreadstone", fn, assets)
