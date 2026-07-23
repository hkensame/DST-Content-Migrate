local GLASS_NAMES = {"f1", "f2", "f3"}

local function set_glass_type(inst, name)
    if inst.glassname == nil or (name ~= nil and inst.glassname ~= name) then
        if name then
            inst.glassname = name
        else
            -- 用 GUID 分散形状，避免依赖 math.random 种子状态
            local idx = (inst.GUID % #GLASS_NAMES) + 1
            inst.glassname = GLASS_NAMES[idx]
        end
        inst.AnimState:PlayAnimation(inst.glassname)
    end
end

local assets=
{
  Asset("ANIM", "anim/moonisland/moonglass.zip"),
  Asset("ANIM", "anim/moonisland/moonglass_charged.zip"),
}

local function onsave(inst, data)
	data.glassname = inst.glassname
end

local function onload(inst, data)
    if data and data.glassname then
        set_glass_type(inst, data.glassname)
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
    inst.AnimState:PlayAnimation("f1") -- 先播 f1 确保渲染初始化完成
    -- 延迟一帧切换到随机形状，防止 DS 引擎符号绑定未就绪导致贴图消失
    inst:DoTaskInTime(0, set_glass_type, nil)
    
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
    inst.AnimState:PlayAnimation("f1") -- 先播 f1 确保渲染初始化完成
    -- 延迟一帧切换到随机形状，防止 DS 引擎符号绑定未就绪导致贴图消失
    inst:DoTaskInTime(0, set_glass_type, nil)

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
