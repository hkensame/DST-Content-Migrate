-- ==================== DST Burning Timer ====================
-- 显示燃烧/营火/提灯/星杖的剩余时间
-- DS 适配版：移除 DST 的 AddGlobalClassPostConstruct/TheWorld.ismastersim 网络 Hack
--               _pulsetime:value() => _pulsetime（DS 非网络值）
-- 移植自 mod "DST Fire Spreading" (Leonidas IV, Viktor)
-- ===========================================================

-- DS 兼容：BODYTEXTFONT 是 DST 专有
if not GLOBAL.BODYTEXTFONT then
	GLOBAL.BODYTEXTFONT = GLOBAL.NEWFONT_SMALL or "fonts/number.font"
end

GLOBAL.mod_burningTimer = {}
GLOBAL.mod_burningTimer.enabled = GetModConfigData("enabledByDefault")
GLOBAL.mod_burningTimer.burntimeList = {
	blueprint = TUNING.SMALL_BURNTIME,
	magician_chest = 10,
}
GLOBAL.mod_burningTimer.burntimeRNG = {}
GLOBAL.mod_burningTimer.campfireMaxFuel = {}
GLOBAL.mod_burningTimer.campfireFuelRate = {}
GLOBAL.mod_burningTimer.campfireRainRate = {}
GLOBAL.mod_burningTimer.campfireFireLevels = {}
GLOBAL.mod_burningTimer.lanternLightTime = {}
GLOBAL.mod_burningTimer.lanternIntensityMin = {}
GLOBAL.mod_burningTimer.lanternIntensityDiff = {}

GLOBAL.mod_burningTimer.campfireReveal = GetModConfigData("showCampfireTimer") == "hidden" and 0.0 or nil
GLOBAL.mod_burningTimer.lanternReveal = GetModConfigData("showLanternTimer") == "hidden" and 0.0 or nil
GLOBAL.mod_burningTimer.starReveal = GetModConfigData("showStarTimer") == "hidden" and 0.0 or nil
GLOBAL.mod_burningTimer.revealDuration = GetModConfigData("showHiddenDuration")

GLOBAL.mod_burningTimer.burntimeTextSize = 30
GLOBAL.mod_burningTimer.campfireTextSize = 30
GLOBAL.mod_burningTimer.lanternTextSize = 30
GLOBAL.mod_burningTimer.starTextSize = 30

GLOBAL.mod_burningTimer.fetchingTimer = false
GLOBAL.mod_burningTimer.debug = false

GLOBAL.mod_burningTimer.validFueltypes = {}

-- 不复用 AddGlobalClassPostConstruct（DST 客户端专属），DS 单机不需要

local function fetchBurntime(prefab)
	if GLOBAL.mod_burningTimer.burntimeList[prefab] then return false end

	local inst
	local math_random_orig = math.random
	math.random = function(a,b) return a and b and a or a and 1 or 0.0 end
	inst = GLOBAL.SpawnPrefab(prefab)
	if inst and inst.components.burnable and inst.components.burnable.burntime then
		GLOBAL.mod_burningTimer.burntimeList[prefab] = inst.components.burnable.burntime
	else
		GLOBAL.mod_burningTimer.burntimeList[prefab] = false
	end
	inst:Remove()

	if GLOBAL.mod_burningTimer.burntimeList[prefab] then
		math.random = function(a,b) return a and b and b or a and a or 1.0 end
		inst = GLOBAL.SpawnPrefab(prefab)
		if inst and inst.components.burnable and inst.components.burnable.burntime then
			GLOBAL.mod_burningTimer.burntimeRNG[prefab] = inst.components.burnable.burntime - GLOBAL.mod_burningTimer.burntimeList[prefab]
		end
		if GLOBAL.mod_burningTimer.burntimeRNG[prefab] == 0.0 then
			GLOBAL.mod_burningTimer.burntimeRNG[prefab] = nil
		end
		inst:Remove()
	end

	math.random = math_random_orig

	return true
end

local function fetchCampfireStats(prefab)
	if GLOBAL.mod_burningTimer.campfireMaxFuel[prefab] then return false end

	local inst
	inst = GLOBAL.SpawnPrefab(prefab)
	if inst and inst.components.fueled and inst.components.fueled.rate then
		GLOBAL.mod_burningTimer.campfireMaxFuel[prefab]    = inst.components.fueled.maxfuel
		GLOBAL.mod_burningTimer.campfireFuelRate[prefab]   = inst.components.fueled.rate
		GLOBAL.mod_burningTimer.campfireFireLevels[prefab] =
			inst.components.burnable
			and inst.components.burnable.fxchildren[1]
			and inst.components.burnable.fxchildren[1].components
			and inst.components.burnable.fxchildren[1].components.firefx
			and inst.components.burnable.fxchildren[1].components.firefx.levels
			or {}
	else
		GLOBAL.mod_burningTimer.campfireMaxFuel[prefab] = false
	end
	inst:Remove()

	if GLOBAL.mod_burningTimer.campfireMaxFuel[prefab] then
		local toSave
		-- DS 单机直接 spawn 两个 prefab 测雨的影响
		inst = GLOBAL.SpawnPrefab(prefab)
		toSave = inst.components.fueled.rate
		inst:Remove()
		inst = GLOBAL.SpawnPrefab(prefab)
		GLOBAL.mod_burningTimer.campfireRainRate[prefab] = inst.components.fueled.rate - toSave
		inst:Remove()
	end

	return true
end

local function fetchLanternStats(prefab)
	if GLOBAL.mod_burningTimer.lanternLightTime[prefab] then return false end

	local inst
	inst = GLOBAL.SpawnPrefab(prefab)
	if inst and inst.components.fueled and (inst.components.fueled.updatefn or inst.components.fueled.ontakefuelfn) then
		local updatefn = inst.components.fueled.updatefn or inst.components.fueled.ontakefuelfn
		GLOBAL.mod_burningTimer.lanternLightTime[prefab] = inst.components.fueled.maxfuel
		if inst.components.machine and inst.components.machine.turnonfn then
			inst.components.machine.turnonfn(inst)
		elseif inst.components.equippable and inst.components.equippable.onequipfn then
			inst.components.equippable.onequipfn(inst, GLOBAL.ThePlayer, true)
		end
		local _light = inst._light
		if _light then
			inst.components.fueled.currentfuel = inst.components.fueled.maxfuel
			updatefn(inst)
			local maxLight = _light.Light:GetRadius()
			inst.components.fueled.currentfuel = 0.0
			updatefn(inst)
			GLOBAL.mod_burningTimer.lanternIntensityMin[prefab] = _light.Light:GetRadius()
			GLOBAL.mod_burningTimer.lanternIntensityDiff[prefab] = maxLight - GLOBAL.mod_burningTimer.lanternIntensityMin[prefab]
			if GLOBAL.mod_burningTimer.lanternIntensityDiff[prefab] == 0.0 then
				GLOBAL.mod_burningTimer.lanternLightTime[prefab] = false
			end
		else
			GLOBAL.mod_burningTimer.lanternLightTime[prefab] = false
		end
	else
		GLOBAL.mod_burningTimer.lanternLightTime[prefab] = false
	end
	inst:Remove()

	return true
end

local function getBurntime(prefab)
	if not prefab then return 0.0, nil end
	if GLOBAL.mod_burningTimer.burntimeList[prefab] == nil then fetchBurntime(prefab) end
	if not GLOBAL.mod_burningTimer.burntimeList[prefab] then return 0.0, nil end
	return GLOBAL.mod_burningTimer.burntimeList[prefab], GLOBAL.mod_burningTimer.burntimeRNG[prefab]
end

local function getCampfireStats(prefab)
	if not prefab then return false, 0.0, 0.0, {} end
	if GLOBAL.mod_burningTimer.campfireMaxFuel[prefab] == nil then fetchCampfireStats(prefab) end
	if not GLOBAL.mod_burningTimer.campfireMaxFuel[prefab] then return false, 0.0, 0.0, {} end
	return GLOBAL.mod_burningTimer.campfireMaxFuel[prefab], GLOBAL.mod_burningTimer.campfireFuelRate[prefab], GLOBAL.mod_burningTimer.campfireRainRate[prefab], GLOBAL.mod_burningTimer.campfireFireLevels[prefab]
end

local function getLanternStats(prefab)
	if not prefab then return false, 0.0, 0.0 end
	if GLOBAL.mod_burningTimer.lanternLightTime[prefab] == nil then fetchLanternStats(prefab) end
	if not GLOBAL.mod_burningTimer.lanternLightTime[prefab] then return false, 0.0, 0.0 end
	return GLOBAL.mod_burningTimer.lanternLightTime[prefab], GLOBAL.mod_burningTimer.lanternIntensityMin[prefab], GLOBAL.mod_burningTimer.lanternIntensityDiff[prefab]
end

GLOBAL.mod_burningTimer.getBurntime = getBurntime
GLOBAL.mod_burningTimer.getCampfireStats = getCampfireStats
GLOBAL.mod_burningTimer.getLanternStats = getLanternStats

-- ==================== 计时器注册 ====================

-- Burning Timer
if GetModConfigData("showBurningTimer") then
	AddPrefabPostInit("fire", function(inst)
		inst:DoTaskInTime(0.01, function()
			inst:AddComponent("burningtimer")
		end)
	end)
end

-- Campfire Timer
local function campfireTimer(inst)
	inst:DoTaskInTime(0.1, function()
		inst:AddComponent("campfiretimer")
	end)
end
if GetModConfigData("showCampfireTimer") then
	AddPrefabPostInit("campfirefire",     function(inst) return campfireTimer(inst) end)
	AddPrefabPostInit("coldfirefire",     function(inst) return campfireTimer(inst) end)
	AddPrefabPostInit("nightlight_flame", function(inst) return campfireTimer(inst) end)
	AddPrefabPostInit("obsidianfirefire", function(inst) return campfireTimer(inst) end)
end

-- Lantern Timer
local function lanternTimer(inst)
	inst:DoTaskInTime(0.01, function()
		inst:AddComponent("lanterntimer")
	end)
end
if GetModConfigData("showLanternTimer") then
	AddPrefabPostInit("lanternlight", function(inst) return lanternTimer(inst) end)
end

-- Star Timer
local function starTimer(inst)
	inst:DoTaskInTime(0.01, function()
		inst:AddComponent("startimer")
	end)
end
if GetModConfigData("showStarTimer") then
	AddPrefabPostInit("stafflight",       function(inst) return starTimer(inst) end)
	AddPrefabPostInit("staffcoldlight",   function(inst) return starTimer(inst) end)
end

-- Revealer（鼠标悬停显示隐藏的计时器）
if GetModConfigData("showCampfireTimer") == "hidden" or GetModConfigData("showLanternTimer") == "hidden" or GetModConfigData("showStarTimer") == "hidden" then
	AddPlayerPostInit(function(inst)
		inst:DoTaskInTime(1, function()
			if inst ~= GLOBAL.ThePlayer then return end
			inst:AddComponent("bt_revealer")
		end)
	end)
end
