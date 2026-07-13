local assets =
{
    Asset("ANIM", "anim/antlion/antliontrinket.zip"),
    --Asset("ANIM", "anim/mining_fx.zip"),
    Asset("ANIM", "anim/moonisland/mining_ice_fx.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("antliontrinket")
    inst.AnimState:SetBuild("antliontrinket")
    inst.AnimState:PlayAnimation("1")

    inst:AddTag("molebait")

	if rawget(_G, 'MakeInventoryFloatable') then
		MakeInventoryFloatable(inst, "1", "1")
	end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 1 --TUNING.GOLD_VALUES.ANTLION
    inst.components.tradable.rocktribute = 4

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    
    --MakeHauntableLaunch(inst)

    return inst
end

local function glass_fx()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	
   inst.AnimState:SetBank("mining_fx")
   inst.AnimState:SetBuild("mining_ice_fx")
   inst.AnimState:PlayAnimation("anim")
 
 inst:AddTag("FX")
 inst:AddTag("NOCLICK")
 
 inst:ListenForEvent("animover", function(inst) 
   inst:Remove() 
 end)
 
  return inst
end

return Prefab("antliontrinket", fn, assets),
       Prefab("glass_fx", glass_fx, assets)
