-- 海盗短剑 (cutless)
-- 移植自 DST，适配 DS 单机模式
-- 移除：AddNetwork, SetPristine, ismastersim, MakeHauntableLaunch

local assets =
{
    Asset("ANIM", "anim/monkey/cutless.zip"),
    Asset("INV_IMAGE", "cutless")
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "cutless", "swap_cutless")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onattack(inst, attacker, target)
    inst.components.thief:StealItem(target)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)
    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst, "idle", "idle")
    end

    inst.AnimState:SetBank("cutless")
    inst.AnimState:SetBuild("cutless")
    inst.AnimState:PlayAnimation("idle")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    inst:AddComponent("thief")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.CUTLESS_DAMAGE or 27)
    inst.components.weapon:SetOnAttack(onattack)

    -------

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    --------

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.CUTLESS_USES or 75)
    inst.components.finiteuses:SetUses(TUNING.CUTLESS_USES or 75)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "cutless"
    inst.components.inventoryitem.atlasname = "images/cutless.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

return Prefab("cutless", fn, assets)
