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
-- 中庭End（迷宫完成后解锁）
EnsureLockKey("ATRIUM_END")

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

modimport "scripts/map/map_dst_maze_layouts.lua"

modimport "scripts/dst_worldgen_config.lua"

modimport "scripts/dst_tuning.lua"

-- 覆写 LoadPrefabFile：确保多返回值的 prefab 文件的所有实体都被 PREFABDEFINITIONS 捕获
-- DS 的 worldgen 处理 PrefabFiles 时可能只捕获首返回值，导致 palmconetree_short/normal/tall 等变体丢失
-- 注：必须用 rawget/rawset 绕过 strict.lua，因为 LoadPrefabFile 不在 __declared 白名单中
local _orig_LoadPrefabFile = rawget(GLOBAL, "LoadPrefabFile")
rawset(GLOBAL, "LoadPrefabFile", function(filename)
    local ret = _orig_LoadPrefabFile(filename)
    if ret then
        for _, prefab in ipairs(ret) do
            if type(prefab) == "table" and prefab.name then
                -- print(string.format("[WG-PREFAB] registered: %s (from %s)", prefab.name, filename))
            end
        end
    end
    return ret
end)

-- 注册世界生成时需加载的 prefab（countprefabs 引用的须在这里注册）
PrefabFiles = {
	"daywalker/daywalkerspawningground",
	"monkey/palmconetree",
	"monkey/palmcone_seed",
	"monkey/palmcone_scale",
}

----------------<诊断：包裹 forest_map.Generate + 注入缺失的 room tags + 抑制洞穴虫洞错误 + 绕过 disconnected tiles PANIC>----------------
do
    local fm = require "map/forest_map"
    -- 洞穴虫洞抑制（延迟到 fm.Generate 内执行，因为 Graph 在 mod 加载时未定义）
    local _origSwapWormholes = nil
    local suppress_wormhole = false
    local function PatchGraphWormholes()
        if _origSwapWormholes ~= nil then
            return  -- 只打一次补丁
        end
        _origSwapWormholes = Graph.SwapWormholesAndRoadsExtra
        Graph.SwapWormholesAndRoadsExtra = function(self, entities, width, height)
            if suppress_wormhole then
                if entities["wormhole"] == nil then
                    entities["wormhole"] = {}
                end
                return
            end
            return _origSwapWormholes(self, entities, width, height)
        end
    end
    -- forest_map.lua 内部的 SKIP_GEN_CHECKS 是 local 变量（第2行），
    -- 外面的全局赋值无效！必须通过 debug.setupvalue 直接修改 upvalue。
    local _skip_idx = nil
    for i = 1, 100 do
        local name = debug.getupvalue(fm.Generate, i)
        if name == nil then break end
        if name == "SKIP_GEN_CHECKS" then
            _skip_idx = i
            break
        end
    end
    if _skip_idx == nil then
        print("[DIAG-WG] WARNING: could not find SKIP_GEN_CHECKS upvalue in fm.Generate")
    else
        print("[DIAG-WG] Found SKIP_GEN_CHECKS upvalue at index "..tostring(_skip_idx))
    end
    -- 包裹 forest_map.Generate，注入洞穴 wormhole 抑制 + 跳过 disconnected tiles 检查
    local _origGen = fm.Generate
    -- 注入缺失的 room tags 处理：在 DLC storygen 加载完毕后替换 GetExtrasForRoom
    -- 注：不能放在 mod 顶层，因为 DLC 的 require 在 mod 初始化期间可能尚未激活
    local function PatchGetExtrasForRoom()
        -- 确保 DLC 版 storygen（1653 行）已加载，覆盖基础版（776 行）
        local pkg = type(package) == "table" and package or nil
        if pkg and type(pkg.loaded) == "table" then
            pkg.loaded["map/storygen"] = nil
        end
        require "map/storygen"
        Story.GetExtrasForRoom = function(self, next_room)
            local extra_contents = {}
            local extra_tags = {}
            if next_room.tags ~= nil then
                for i,tag in ipairs(next_room.tags) do
                    local tagFn = self.map_tags.Tag[tag]
                    if tagFn == nil then
                        print("[WG-TAG] auto-register missing tag "..tostring(tag).." (room: "..tostring(next_room.type or next_room.id)..")")
                        self.map_tags.Tag[tag] = function(td) return "TAG", tag end
                        tagFn = self.map_tags.Tag[tag]
                    end
                    local typ, extra = tagFn(self.map_tags.TagData)
                    if typ == "STATIC" then
                        if extra_contents.static_layouts == nil then
                            extra_contents.static_layouts = {}
                        end
                        table.insert(extra_contents.static_layouts, extra)
                    end
                    if typ == "ITEM" then
                        if extra_contents.prefabs == nil then
                            extra_contents.prefabs = {}
                        end
                        table.insert(extra_contents.prefabs, extra)
                    end
                    if typ == "TAG" then
                        table.insert(extra_tags, extra)
                    end
                    if typ == "GLOBALTAG" then
                        if self.GlobalTags[extra] == nil then
                            self.GlobalTags[extra] = {}
                        end
                        if self.GlobalTags[extra][next_room.task] == nil then
                            self.GlobalTags[extra][next_room.task] = {}
                        end
                        table.insert(self.GlobalTags[extra][next_room.task], next_room.id)
                    end
                end
            end
            return extra_contents, extra_tags
        end
    end

    fm.Generate = function(prefab, w, h, tasks, wgc, lt, level)
        local isCave = (lt == "cave")  -- prefab 始终是 "forest"（即使洞穴），用 lt 判断层级类型
        suppress_wormhole = isCave
        if isCave and _skip_idx then
            -- DST 洞穴房间产生大量不连通区块（遗迹/档案馆/中庭等独立区域），DS 默认检查会拒绝。
            -- 这些区域在 DST 中通过虫洞连接，DS 模式不需要连通性。
            -- 使用 debug.setupvalue 绕过 forest_map.lua 内部的 local SKIP_GEN_CHECKS
            debug.setupvalue(_origGen, _skip_idx, true)
        end
        -- 先加载 storygen（内含 require "map/network"，定义 Graph），再打其他补丁
        PatchGetExtrasForRoom()
        PatchGraphWormholes()
        print("[DIAG-WG] GenerateVoro START prefab="..tostring(prefab).." w="..tostring(w).." h="..tostring(h).." tasks="..tostring(#(tasks or {})))
        local ok, result = pcall(_origGen, prefab, w, h, tasks, wgc, lt, level)
        if isCave and _skip_idx then
            debug.setupvalue(_origGen, _skip_idx, false)
        end
        suppress_wormhole = false
        if not ok then
            print("[DIAG-WG] GenerateVoro ERROR: "..tostring(result))
            return nil
        end
        print("[DIAG-WG] GenerateVoro DONE, result="..tostring(result ~= nil))
        return result
    end
end

