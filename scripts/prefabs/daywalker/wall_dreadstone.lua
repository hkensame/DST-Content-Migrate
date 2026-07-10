local assets = { Asset("ANIM", "anim/wall_dreadstone.zip") }

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("wall_dreadstone")
	inst.AnimState:SetBuild("wall_dreadstone")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("dreadstone")

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
	inst:AddComponent("tradable")

	return inst
end

return Prefab("wall_dreadstone_item", fn, assets)
