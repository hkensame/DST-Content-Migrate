-- 绿蘑菇帽：产出 spore_small
-- DS 风格精简版：移除 DST skin/headbase_hat/tradable 冗余

local fname = "hat_green_mushroom"
local symname = "green_mushroomhat"
local prefabname = symname
local spore_prefab = "spore_small"
local imagename = "hat_green_mushroom"

---------------------------------------------------------------------------
-- 装备 / 卸下
---------------------------------------------------------------------------
local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", fname, "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Show("HEAD")
		owner.AnimState:Hide("HEAD_HAIR")
	end

    owner:AddTag("spoiler")

    inst.components.periodicspawner:Start()

    if owner.components.hunger ~= nil then
        owner.components.hunger.burnrate = TUNING.MUSHROOMHAT_SLOW_HUNGER
    end
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Show("HEAD")
		owner.AnimState:Hide("HEAD_HAIR")
	end

    owner:RemoveTag("spoiler")
    inst.components.periodicspawner:Stop()

    if owner.components.hunger ~= nil then
        owner.components.hunger.burnrate = 1
    end
end

---------------------------------------------------------------------------
-- 创建 Prefab
---------------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(symname)
    inst.AnimState:SetBuild(fname)
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("show_spoilage")

    inst:SetPrefabNameOverride("mushroomhat")

    if IsDLCEnabled(CAPY_DLC) or IsDLCEnabled(PORKLAND_DLC) then
        MakeInventoryFloatable(inst, "anim", "anim")
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = imagename
    inst.components.inventoryitem.atlasname = "images/"..imagename..".xml"

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(inst.Remove)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab(spore_prefab)
    inst.components.periodicspawner:SetRandomTimes(TUNING.MUSHROOMHAT_SPORE_TIME, 1, true)

    if IsDLCEnabled(REIGN_OF_GIANTS) or IsDLCEnabled(CAPY_DLC) or IsDLCEnabled(PORKLAND_DLC) then
        inst:AddComponent("insulator")
        inst.components.insulator:SetSummer()
        inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
    end

    return inst
end

local assets = { Asset("ANIM", "anim/toadstool/"..fname..".zip") }

return Prefab(prefabname, fn, assets)

