-- ============================================================
-- [已废弃] DST 移植蓝图：已迁移至 scripts/system/tech_manager.lua 统一管理
--
-- 所有蓝图注册已移至 modmain.lua 的 BLUEPRINT_RECIPES 表中，
-- 由 tech_manager.lua 在运行时动态生成 Prefab。
-- 此文件保留仅作参考，不再从 PrefabFiles 引用。
-- ============================================================
-- DST 移植蓝图：龙鳞火炉、邪天翁帆、象棋部件、蘑菇帽、档案馆物品等专属蓝图
local assets = 
{
	Asset("ANIM", "anim/blueprint.zip"),
}

local function onload(inst, data)
	if data then
		if data.recipetouse then
			inst.recipetouse = data.recipetouse
			inst.components.teacher:SetRecipe(inst.recipetouse)
	    	inst.components.named:SetName((STRINGS.NAMES[string.upper(inst.recipetouse)] or STRINGS.NAMES.UNKNOWN).." "..STRINGS.NAMES.BLUEPRINT)
	    end
	end
end

local function onsave(inst, data)
	if inst.recipetouse then
		data.recipetouse = inst.recipetouse
	end
end

local function selectrecipe_any(recipes)
	if next(recipes) then
		return recipes[math.random(1, #recipes)]
	end
end

local function OnTeach(inst, learner)
	if learner.SoundEmitter then
		learner.SoundEmitter:PlaySound("dontstarve/HUD/get_gold")    
	end
end

local function fn()

	local inst = CreateEntity()
	inst.entity:AddTransform()
    MakeInventoryPhysics(inst)
	inst.entity:AddAnimState()
    inst.AnimState:SetBank("blueprint")
	inst.AnimState:SetBuild("blueprint")
	inst.AnimState:PlayAnimation("idle")
	
	if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst, 'idle_water', 'idle')
    end
    
    inst:AddComponent("inspectable")    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("blueprint")
    inst:AddComponent("named")
    inst:AddComponent("teacher")
    inst.components.teacher.onteach = OnTeach
    
    inst.OnLoad = onload
    inst.OnSave = onsave

   	return inst
end

local function MakeAnyBlueprint()
	local inst = fn()

	local recipes = {}
    local player = GetPlayer()   
    for k,v in pairs(GetAllRecipes()) do
    	if v and not player.components.builder:KnowsRecipe(v.name) then
    		table.insert(recipes, v)  		
    	end
    end
    local r = selectrecipe_any(recipes)
    
    if r then
		if not inst.recipetouse then
			inst.recipetouse = r.name or "Unknown"
		end

		inst.components.teacher:SetRecipe(inst.recipetouse)
		inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." "..STRINGS.NAMES.BLUEPRINT)
	end
	
    return inst
end

local function MakeAnySpecificBlueprint(specific_item)
	local ctor = function()
		local inst = fn()

		local recipes = {}
	    local player = GetPlayer()   
	    for k,v in pairs(GetAllKnownRecipes()) do
	    	if v and ((specific_item ~= nil and v.name == specific_item) or
	    			 (specific_item == nil and not player.components.builder:KnowsRecipe(v.name)) )then	    		
	    		table.insert(recipes, v)  		
	    	end
	    end
	    local r = selectrecipe_any(recipes)
		if r then
		    if not inst.recipetouse then
			    inst.recipetouse = r.name
			end
		    inst.components.teacher:SetRecipe(inst.recipetouse)
		    inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." "..STRINGS.NAMES.BLUEPRINT)
		end
	    return inst
	end
	return ctor
end

local function MakeSpecificBlueprint(recipetab)
	local ctor = function()
		local inst = fn()

		local recipes = {}
	    local player = GetPlayer()   
	    for k,v in pairs(GetAllRecipes()) do
	    	if v and v.tab == recipetab and not player.components.builder:KnowsRecipe(v.name) then
	    		table.insert(recipes, v)  		
	    	end
	    end
	    local r = selectrecipe_any(recipes)
	    if r then
			if not inst.recipetouse then
			    inst.recipetouse = r.name
			end
			inst.components.teacher:SetRecipe(inst.recipetouse)
			inst.components.named:SetName(STRINGS.NAMES[string.upper(inst.recipetouse)].." "..STRINGS.NAMES.BLUEPRINT)
		end
	    return inst
	end
	return ctor
end

local prefabs = {}
table.insert(prefabs,Prefab("dragonflyfurnace_blueprint", MakeAnySpecificBlueprint("dragonflyfurnace"),assets))
table.insert(prefabs,Prefab("malbatross_sail_blueprint", MakeAnySpecificBlueprint("malbatross_sail"),assets))
table.insert(prefabs,Prefab("chesspiece_rook_blueprint", MakeAnySpecificBlueprint("chesspiece_rook"),assets))
table.insert(prefabs,Prefab("chesspiece_knight_blueprint", MakeAnySpecificBlueprint("chesspiece_knight"),assets))
table.insert(prefabs,Prefab("chesspiece_bishop_blueprint", MakeAnySpecificBlueprint("chesspiece_bishop"),assets))
-- 蘑菇帽蓝图（蛤蟆掉落）
table.insert(prefabs,Prefab("red_mushroomhat_blueprint", MakeAnySpecificBlueprint("red_mushroomhat"),assets))
table.insert(prefabs,Prefab("green_mushroomhat_blueprint", MakeAnySpecificBlueprint("green_mushroomhat"),assets))
table.insert(prefabs,Prefab("blue_mushroomhat_blueprint", MakeAnySpecificBlueprint("blue_mushroomhat"),assets))
-- 档案馆蓝图
table.insert(prefabs,Prefab("turfcraftingstation_blueprint", MakeAnySpecificBlueprint("turfcraftingstation"),assets))
table.insert(prefabs,Prefab("turf_archive_blueprint", MakeAnySpecificBlueprint("turf_archive"),assets))
table.insert(prefabs,Prefab("archive_resonator_item_blueprint", MakeAnySpecificBlueprint("archive_resonator_item"),assets))
table.insert(prefabs,Prefab("refined_dust_blueprint", MakeAnySpecificBlueprint("refined_dust"),assets))

--table.insert(prefabs,Prefab("", MakeAnySpecificBlueprint(""),assets))
--for k,v in pairs(RECIPETABS) do
--	table.insert(prefabs, Prefab("common/blueprints/"..string.lower(v.str or "NONAME").."_blueprint", MakeSpecificBlueprint(v), assets))
--end
--for k,v in pairs(GetAllKnownRecipes()) do
--	table.insert(prefabs, Prefab("common/blueprints/"..string.lower(k or "NONAME").."_blueprint", MakeAnySpecificBlueprint(k), assets))
--end
return unpack(prefabs) 