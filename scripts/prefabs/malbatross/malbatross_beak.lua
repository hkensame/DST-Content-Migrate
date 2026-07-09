local assets=
{
	Asset("ANIM", "anim/malbatross/malbatross_beak.zip"),
	Asset("ANIM", "anim/malbatross/swap_malbatross_beak.zip"),
}


local function onfinished(inst)
    inst:Remove()
end
 
local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "swap_malbatross_beak", "swap_malbatross_beak")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 
end

local function onunequip(inst, owner) 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal") 
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
		 inst.entity:AddMiniMapEntity()
 		inst.MiniMapEntity:SetIcon( "malbatross_beak.tex" )
    MakeInventoryPhysics(inst)
    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst, "idle", "idle")
    end
    
    anim:SetBank("malbatross_beak")
    anim:SetBuild("malbatross_beak")
    anim:PlayAnimation("idle")
    
    inst:AddTag("sharp")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(34)
    
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(300)
    inst.components.finiteuses:SetUses(300)
    inst.components.finiteuses:SetOnFinished( onfinished )

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "malbatross_beak"
	inst.components.inventoryitem.atlasname = "images/dst_boss.xml"
    
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )
    
    return inst
end

return Prefab( "common/inventory/malbatross_beak", fn, assets) 
