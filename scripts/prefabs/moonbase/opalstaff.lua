local assets=
{
	Asset("ANIM", "anim/moonbase/opalstaff.zip"),
	Asset("ANIM", "anim/moonbase/swap_opalstaff.zip"),
}

local function createlight(staff, target, pos)
    local light = SpawnPrefab("staffcoldlight")
    light.Transform:SetPosition(pos.x, pos.y, pos.z)
    staff.components.finiteuses:Use(1)

    local caster = staff.components.inventoryitem.owner
    if caster and caster.components.sanity then
        caster.components.sanity:DoDelta(-TUNING.SANITY_MEDLARGE)
    end

end
--]]

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "swap_opalstaff", "swap_opalstaff")
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
    MakeInventoryPhysics(inst)
    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst, "opalstaff_water", "opalstaff")
    end
    
    anim:SetBank("opalstaff")
    anim:SetBuild("opalstaff")
    anim:PlayAnimation("opalstaff")
    
    inst:AddTag("nopunch")
    inst:AddTag("allow_action_on_impassable")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.OPALSTAFF_USES or 50)
    inst.components.finiteuses:SetUses(TUNING.OPALSTAFF_USES or 50)
    inst.components.finiteuses:SetOnFinished(onfinished)
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "opalstaff"
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"
    
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )

    inst.fxcolour = {64/255, 64/255, 208/255}
    inst.castsound = "dontstarve/common/staffteleport"

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createlight)
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = function() 
        return Vector3(GetPlayer().entity:LocalToWorldSpace(5, 0.001, 0))
    end
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true


    return inst
end

return Prefab( "common/inventory/opalstaff", fn, assets) 