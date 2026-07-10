GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")

----------------<注入 DS 缺失的 DST 锁/钥匙>----------------
-- DS 基础版 lockandkey.lua 没有 DST 新增的锁/钥匙（BATS/MOONMUSH/ARCHIVE 等），
-- map_dstcave.lua 引用时会产生 nil，导致 storygen 锁链断裂 → effectiveLastNode 崩溃。
-- 这里统一注册所有 DST 新增但 DS 缺失的锁/钥匙。
local function EnsureLockKey(name)
	if not rawget(LOCKS, name) then
		table.insert(LOCKS_ARRAY, name)
		LOCKS[name] = #LOCKS_ARRAY
	end
	if not rawget(KEYS, name) then
		table.insert(KEYS_ARRAY, name)
		KEYS[name] = #KEYS_ARRAY
	end
	if not LOCKS_KEYS[LOCKS[name]] then
		LOCKS_KEYS[LOCKS[name]] = {KEYS[name]}
	end
end

-- 洞穴区域专属锁（DST 原版 caves.lua/ruins.lua 使用）
EnsureLockKey("BATS")           -- 蝙蝠区
EnsureLockKey("SINKHOLE")       -- 天井/森林区
EnsureLockKey("RABBIT")         -- 兔子区
EnsureLockKey("ENTRANCE_INNER") -- 近端区域控制
EnsureLockKey("ENTRANCE_OUTER") -- 远端区域控制
EnsureLockKey("RED")            -- 红色蘑菇区
EnsureLockKey("GREEN")          -- 绿色蘑菇区
EnsureLockKey("BLUE")           -- 蓝色蘑菇区
EnsureLockKey("MUSHROOM")       -- 蘑菇通用
EnsureLockKey("MOONMUSH")       -- 月蘑菇区（链：BlueMush→MoonMush→Archive）
EnsureLockKey("ARCHIVE")        -- 档案馆
EnsureLockKey("CENTIPEDE")      -- 蜈蚣区/遗迹岛
EnsureLockKey("PASSAGE")        -- 通道
EnsureLockKey("AREA")           -- 区域
EnsureLockKey("CAVERN")         -- 洞穴大厅

-- 分支区域锁（DST caves.lua/ruins.lua 使用）
EnsureLockKey("ROCKY")          -- 岩石区
EnsureLockKey("SWAMP")          -- 沼泽区
EnsureLockKey("SPIDERS")        -- 蜘蛛区
EnsureLockKey("RUINS")          -- 遗迹区
EnsureLockKey("SACRED")         -- 祭坛区（遗迹深处）

EnsureLockKey("EASY")           -- 难度：简单
EnsureLockKey("MEDIUM")         -- 难度：中等
EnsureLockKey("HARD")           -- 难度：困难

-- 月岛自锁（DST ISLAND7，DS 基础版缺失）
EnsureLockKey("ISLAND7")
-- 猴岛自锁（与月岛独立）
EnsureLockKey("ISLAND8")
-- 中庭自锁
EnsureLockKey("ATRIUM")
modimport "scripts/dst_tile.lua"
local _G = GLOBAL
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")
modimport "scripts/dst_turf_registration.lua"

do
    local _origGet = StaticLayout.Get
    StaticLayout.Get = function(layoutsrc, additionalProps)
        local ok, result = pcall(_origGet, layoutsrc, additionalProps)
        if ok and type(result) == "table" then
            PatchGroundTypes(result)
            return result
        end
        -- fallback: 去掉 areas 等可能导致崩溃的额外属性
        local clean_props = additionalProps and {force_rotation = additionalProps.force_rotation} or {}
        local ok2, result2 = pcall(_origGet, layoutsrc, clean_props)
        if ok2 and type(result2) == "table" then
            PatchGroundTypes(result2)
            return result2
        end
        -- 最终后备：完全无参数加载
        local ok3, result3 = pcall(_origGet, layoutsrc, {})
        if ok3 and type(result3) == "table" and result3.ground_types then
            PatchGroundTypes(result3)
            return result3
        end
        print("[Worldgen] WARNING: StaticLayout.Get failed for " .. tostring(layoutsrc) .. ": " .. tostring(result3))
        return nil
    end
end

----------------<补丁：注册 DLC maptags 缺失的标签>----------------
-- DLC0003（Hamlet）的 maptags.lua 缺少 "fumarolearea" / "not_mainland" 等标签，
-- GetExtrasForRoom() 遇到未知标签时 self.map_tags.Tag[tag] 为 nil → crash。
do
    local maptags_module = require("map/maptags")
    _G.package.loaded["map/maptags"] = function()
        local result = maptags_module()
        if result and result.Tag then
            result.Tag["fumarolearea"] = result.Tag["fumarolearea"] or function(td) return "TAG", "fumarolearea" end
            result.Tag["not_mainland"] = result.Tag["not_mainland"] or function(td) return "TAG", "not_mainland" end
        end
        return result
    end
end

modimport "scripts/map/map_dst_maze_layouts.lua"

modimport "scripts/dst_worldgen_config.lua"

----------------<诊断：包裹 forest_map.Generate 以定位闪退>----------------
do
    local fm = require "map/forest_map"
    local _origGen = fm.Generate
    fm.Generate = function(prefab, w, h, tasks, wgc, lt, level)
        print("[DIAG-WG] GenerateVoro START prefab="..tostring(prefab).." w="..tostring(w).." h="..tostring(h).." tasks="..tostring(#(tasks or {})))
        local ok, result = pcall(_origGen, prefab, w, h, tasks, wgc, lt, level)
        if not ok then
            print("[DIAG-WG] GenerateVoro ERROR: "..tostring(result))
            return nil
        end
        print("[DIAG-WG] GenerateVoro DONE, result="..tostring(result ~= nil))
        return result
    end
end

