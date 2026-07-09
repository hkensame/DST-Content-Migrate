-- DST 移植熟食制作：通过数据表批量生成 DST 专属烹饪食物
local function MakePreparedFood(data)

	local assets=
	{
		Asset("ANIM", "anim/foods/"..data.name..".zip"),
	
	}
	
	local prefabs = 
	{
		"spoiled_food",
	}
	
	local function fn(Sim)
		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		MakeInventoryPhysics(inst)
		
		inst.AnimState:SetBank(data.name)
		inst.AnimState:SetBuild(data.name)
		inst.AnimState:PlayAnimation("idle", false)
	    
	    inst:AddTag("preparedfood")

		inst:AddComponent("edible")
		inst.components.edible.healthvalue = data.health
		inst.components.edible.hungervalue = data.hunger
		inst.components.edible.foodtype = data.foodtype or "GENERIC"
		inst.components.edible.foodstate = data.foodstate or "PREPARED"
		inst.components.edible.sanityvalue = data.sanity or 0
		inst.components.edible.temperaturedelta = data.temperature or 0
		inst.components.edible.temperatureduration = data.temperatureduration or 0
		inst.components.edible.naughtyvalue = data.naughtiness or 0
		inst.components.edible.caffeinedelta = data.caffeinedelta or 0
		inst.components.edible.caffeineduration = data.caffeineduration or 0
		inst.components.edible:SetOnEatenFn(data.oneatenfn)

		if data.boost_surf then
			inst.components.edible.surferdelta = TUNING.HYDRO_FOOD_BONUS_SURF
			inst.components.edible.surferduration = TUNING.FOOD_SPEED_AVERAGE		
		end
		if data.boost_dry then
			inst.components.edible.autodrydelta = TUNING.HYDRO_FOOD_BONUS_DRY
			inst.components.edible.autodryduration = TUNING.FOOD_SPEED_AVERAGE
		end
		if data.boost_cool then
			inst.components.edible.autocooldelta = TUNING.HYDRO_FOOD_BONUS_COOL_RATE
		end

		inst:AddComponent("inspectable")
		inst.wet_prefix = data.wet_prefix

		inst:AddComponent("inventoryitem")
		if data.name ~= "taffy" then
  		inst.components.inventoryitem.imagename = data.name
    	inst.components.inventoryitem.atlasname = "images/dst_boss.xml"
  	end
		
		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	if data.perishtime ~= nil and data.perishtime > 0 then
		inst:AddComponent("perishable")
		inst.components.perishable:SetPerishTime(data.perishtime)
		inst.components.perishable:StartPerishing()
		inst.components.perishable.onperishreplacement = "spoiled_food"
	end

		if data.tags then
			for i,v in pairs(data.tags) do
				inst:AddTag(v)
			end
		end
		
	    
        MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)
		if rawget(_G, 'MakeInventoryFloatable') then
			MakeInventoryFloatable(inst, "idle_water", "idle")
		end

		inst:AddComponent("bait")
	 
		inst:AddComponent("tradable")
	    
		return inst
	end

	return Prefab( "common/inventory/"..data.name, fn, assets, prefabs)
end


local prefs = {}

local foods = require("dst_foods")
for k,v in pairs(foods) do
	table.insert(prefs, MakePreparedFood(v))
end

return unpack(prefs) 

