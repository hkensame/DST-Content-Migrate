local assets =
{
    Asset("ANIM", "anim/thulecitebugnet.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "thulecitebugnet", "swap_object")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("thulecitebugnet")
    inst.AnimState:SetBuild("thulecitebugnet")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("tool")
    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "med", 0.09, {0.9, 0.4, 0.9}, true, -14.5)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(4)
    inst.components.weapon.attackwear = 3

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.NET)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(100)
    inst.components.finiteuses:SetUses(100)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.NET, 1)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("thulecitebugnet", fn, assets)
