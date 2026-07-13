local assets = { Asset("ANIM", "anim/armor_dreadstone.zip") }

local DREADSTONE_SHADOW_TAG = "shadow_aligned"	-- 暗影阵营标签，用户可自行修改

local function OnBlocked(inst, owner, data)
	owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_dreadstone")
	if data and data.attacker and data.attacker:HasTag(DREADSTONE_SHADOW_TAG) then
		-- 暗影阵营减伤：受伤 -10%（回血 10%）
		if owner.components.health and not owner.components.health:IsDead() then
			owner.components.health:DoDelta(data.damage * 0.1)
		end
		-- 暗影阵营减伤：耐久消耗 -10%（修回 10%）
		if inst._last_dur_loss ~= nil then
			inst.components.armor:Repair(inst._last_dur_loss * 0.1)
		end
	end
end

local function HasSetBonus(owner)
	return owner:HasTag("dreadstone_helm")
end

local function DoRegen(inst, owner)
	-- DS: 低理智（<15%）时自动修复，类似 DST 的 IsInsanityMode
	if owner.components.sanity ~= nil and owner.components.sanity:GetPercent() < 0.15 then
		local setbonus = HasSetBonus(owner) and TUNING.ARMOR_DREADSTONE_REGEN_SETBONUS or 1
		local rate = 1 / Lerp(1 / TUNING.ARMOR_DREADSTONE_REGEN_MAXRATE, 1 / TUNING.ARMOR_DREADSTONE_REGEN_MINRATE, owner.components.sanity:GetPercent())
		inst.components.armor:Repair(inst.components.armor.maxcondition * rate * setbonus)
	end
	if inst.components.armor.condition >= inst.components.armor.maxcondition then
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
	owner:AddTag("dreadstone_armor")

	-- 套装检测 + 暗影减伤（用闭包捕获 inst）
	if inst._blocked_fn == nil then
		inst._blocked_fn = function(owner_, data) OnBlocked(inst, owner_, data) end
	end
	inst:ListenForEvent("blocked", inst._blocked_fn, owner)

	if owner.components.sanity ~= nil and inst.components.armor.condition < inst.components.armor.maxcondition then
		StartRegen(inst, owner)
	else
		StopRegen(inst)
	end
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
	owner:RemoveTag("dreadstone_armor")
	if inst._blocked_fn ~= nil then
		inst:RemoveEventCallback("blocked", inst._blocked_fn, owner)
	end
	StopRegen(inst)
end

local function OnTakeDamage(inst, amount)
	inst._last_dur_loss = amount	-- 记录耐久消耗，供 OnBlocked 暗影减伤使用
	if inst.regentask == nil and inst.components.equippable:IsEquipped() then
		local owner = inst.components.inventoryitem.owner
		if owner ~= nil and owner.components.sanity ~= nil then
			StartRegen(inst, owner)
		end
	end
end

local function CalcDapperness(inst, owner)
	local lowsanity = owner.components.sanity ~= nil and owner.components.sanity:GetPercent() < 0.15
	if not lowsanity then return 0 end

	local my_regen = inst.regentask ~= nil
	if HasSetBonus(owner) then
		-- 套装：任意一件在修就扣理智，消耗减半
		local other_regen = false
		if owner.components.inventory then
			local slot = inst.components.equippable.equipslot == EQUIPSLOTS.HEAD and EQUIPSLOTS.BODY or EQUIPSLOTS.HEAD
			local other = owner.components.inventory:GetEquippedItem(slot)
			if other then other_regen = other.regentask ~= nil end
		end
		if my_regen or other_regen then
			return TUNING.CRAZINESS_MED * 0.5
		end
		return 0
	end

	return my_regen and TUNING.CRAZINESS_MED or 0
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	MakeInventoryPhysics(inst)
	if rawget(_G, 'MakeInventoryFloatable') then
		MakeInventoryFloatable(inst, "anim", "anim")
	end

	inst.AnimState:SetBank("armor_dreadstone")
	inst.AnimState:SetBuild("armor_dreadstone")
	inst.AnimState:PlayAnimation("anim")

	inst:AddTag("dreadstone")
	inst:AddTag("hardarmor")
	inst:AddTag("shadow_item")

	inst.foleysound = "dontstarve/movement/foley/dreadstonearmour"

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/armordreadstone.xml"
	inst.components.inventoryitem.imagename = "armordreadstone"

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
