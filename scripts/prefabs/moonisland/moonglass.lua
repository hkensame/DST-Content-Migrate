local assets=
{
  Asset("ANIM", "anim/moonisland/moonglass.zip"),
  Asset("ANIM", "anim/moonisland/moonglass_charged.zip"),
}

local function onsave(inst, data)
	data.anim = inst.animname
end

local function onload(inst, data)
    if data and data.anim then
        inst.animname = data.anim
	    inst.AnimState:PlayAnimation(inst.animname)
	end
end

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)
    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst)
    end
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.HEAVY, TUNING.WINDBLOWN_SCALE_MAX.HEAVY)
    
    inst.AnimState:SetBank("moonglass")
    inst.AnimState:SetBuild("moonglass") -- build.bin 中 build 名为 moonglass
    inst.AnimState:PlayAnimation("f"..math.random(3)) -- 随机 3 种碎片形状
    
    inst:AddTag("moonglass_piece")

    inst:AddComponent("tradable")
    
    inst:AddComponent("stackable")
   	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "moonglass"
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

    inst.OnSave = onsave 
    inst.OnLoad = onload 

    return inst
end

local function onpickup(inst)
    inst.Light:Enable(false)
end

local function ondropped(inst)
    inst.Light:Enable(true)
end

local function fn2(Sim)
	local inst = CreateEntity()
 inst.entity:AddLight()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)
    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst)
    end
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.HEAVY, TUNING.WINDBLOWN_SCALE_MAX.HEAVY)
    
    inst.AnimState:SetBank("moonglass_charged")
    inst.AnimState:SetBuild("moonglass_charged")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:PlayAnimation("f1")

    inst:AddTag("show_spoilage")

    inst.Light:SetColour(111/255, 111/255, 227/255)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(true)    

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "ELEMENTAL"
    inst.components.edible.hungervalue = 1
    inst:AddComponent("tradable")
    
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "moonglass_charged"
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.SEG_TIME * 3)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "moonglass"

    inst:ListenForEvent("onputininventory", onpickup)
    inst:ListenForEvent("ondropped", ondropped)
    
    inst.OnSave = onsave 
    inst.OnLoad = onload 
 
    return inst
end

return Prefab( "moonglass", fn, assets),
       Prefab( "moonglass_charged", fn2, assets)
