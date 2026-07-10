local assets = { Asset("ANIM", "anim/armor_dreadstone.zip") }

local function OnBlocked(owner)
	owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_dreadstone")
end

local function GetSetBonusEquip(inst, owner)
	local hat = owner.components.inventory ~= nil and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
	return hat ~= nil and hat.prefab == "dreadstonehat" and hat or nil
end

local function DoRegen(inst, owner)
	-- DS: 低理智（<15%）时自动修复，类似 DST 的 IsInsanityMode
	if owner.components.sanity ~= nil and owner.components.sanity:GetPercent() < 0.15 then
		local setbonus = GetSetBonusEquip(inst, owner) ~= nil and TUNING.ARMOR_DREADSTONE_REGEN_SETBONUS or 1
		local rate = 1 / Lerp(1 / TUNING.ARMOR_DREADSTONE_REGEN_MAXRATE, 1 / TUNING.ARMOR_DREADSTONE_REGEN_MINRATE, owner.components.sanity:GetPercent())
		inst.components.armor:Repair(inst.components.armor.maxcondition * rate * setbonus)
	end
	if not inst.components.armor:IsDamaged() then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end

local function StartRegen(inst, owner)
	if inst.regentask == nil then
		inst.regentask = inst:DoPeriodicTask(TUNING.ARMOR_DREADSTONE_REGEN_PERIOD, DoRegen, nil, owner)
	end
end

local function StopRegen(inst)
	if inst.regentask ~= nil then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "armor_dreadstone", "swap_body")
	inst:ListenForEvent("blocked", OnBlocked, owner)

	if owner.components.sanity ~= nil and inst.components.armor:IsDamaged() then
		StartRegen(inst, owner)
	else
		StopRegen(inst)
	end
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
	inst:RemoveEventCallback("blocked", OnBlocked, owner)
	StopRegen(inst)
end

local function OnTakeDamage(inst, amount)
	if inst.regentask == nil and inst.components.equippable:IsEquipped() then
		local owner = inst.components.inventoryitem.owner
		if owner ~= nil and owner.components.sanity ~= nil then
			StartRegen(inst, owner)
		end
	end
end

local function CalcDapperness(inst, owner)
	local lowsanity = owner.components.sanity ~= nil and owner.components.sanity:GetPercent() < 0.15
	local other = GetSetBonusEquip(inst, owner)
	if other ~= nil then
		return (lowsanity and (inst.regentask ~= nil or other.regentask ~= nil) and TUNING.CRAZINESS_MED or 0) * 0.5
	end
	return lowsanity and inst.regentask ~= nil and TUNING.CRAZINESS_MED or 0
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("armor_dreadstone")
	inst.AnimState:SetBuild("armor_dreadstone")
	inst.AnimState:PlayAnimation("anim")

	inst:AddTag("dreadstone")
	inst:AddTag("hardarmor")
	inst:AddTag("shadow_item")

	inst.foleysound = "dontstarve/movement/foley/dreadstonearmour"

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")

	inst:AddComponent("armor")
	inst.components.armor:InitCondition(TUNING.ARMORDREADSTONE, TUNING.ARMORDREADSTONE_ABSORPTION)
	inst.components.armor.ontakedamage = OnTakeDamage

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable.dapperfn = CalcDapperness
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("repairable")
	inst.components.repairable.repairmaterial = "dreadstone"

	return inst
end

return Prefab("armordreadstone", fn, assets)
