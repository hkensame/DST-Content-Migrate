local assets =
{
    Asset("ANIM", "anim/moonisland/glasscutter.zip"),
    Asset("ANIM", "anim/moonisland/swap_glasscutter.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_glasscutter", "swap_glasscutter")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local shadow_util = require("shadow_util")

local function onattack(inst, attacker, target)
	local is_shadow = shadow_util.IsShadow(target)

	-- 对暗影生物：耐久消耗减半
	inst.components.weapon.attackwear = is_shadow and 0.7 or 1

	-- 对暗影生物：伤害提升到 80
	inst.components.weapon.damage = is_shadow and 72 or 59
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("glasscutter")
    inst.AnimState:SetBuild("glasscutter")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("pointy")
    
    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst, "idle", "idle")
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(59)
	inst.components.weapon:SetOnAttack(onattack)

    -------

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(75)
    inst.components.finiteuses:SetUses(75)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

return Prefab("glasscutter", fn, assets)