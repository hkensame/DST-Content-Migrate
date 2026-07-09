local assets=
{
    Asset("ANIM", "anim/moonisland/glassaxe.zip"),
    Asset("ANIM", "anim/moonisland/swap_glassaxe.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
}

local function onequip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_object", "swap_glassaxe", "swap_glassaxe")
  owner.AnimState:Show("ARM_carry")
  owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
  owner.AnimState:Hide("ARM_carry")
  owner.AnimState:Show("ARM_normal")
end

local function onattack(inst, attacker, target)
	inst.components.weapon.attackwear = target ~= nil and target:IsValid() 
		and (target:HasTag("shadow") or target:HasTag("shadowminion") or target:HasTag("shadowchesspiece") or target:HasTag("stalker") or target:HasTag("stalkerminion"))
		and 0.5
		or 2
end

local function fn(Sim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

   MakeInventoryPhysics(inst)
   MakeInventoryFloatable(inst, "idle", "idle")

    inst.AnimState:SetBank("glassaxe")
    inst.AnimState:SetBuild("glassaxe")
    inst.AnimState:PlayAnimation("idle")
 
    inst:AddTag("sharp")
    inst:AddTag("possessable_axe")
    inst:AddTag("tool")

   inst:AddComponent("weapon")
   inst.components.weapon:SetDamage(34)
   inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"
 -----
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, 2.5)
 -------
        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(TUNING.AXE_USES)
        inst.components.finiteuses:SetUses(TUNING.AXE_USES)
        inst.components.finiteuses:SetOnFinished(inst.Remove)
        inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1.25)
 -------
    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)


 return inst
end

return Prefab("moonglassaxe", fn, assets)