--============================================================================
-- world_spawner.lua — 层级化 Spawner 注册与管理模块
--
-- 双阶段设计：
--   阶段一「注册阶段」：modmain 加载时，通过静态 API 注册所有 zone 和 spawner
--   阶段二「运行阶段」：世界创建后，通过 Init() 安装到 TheWorld
--
-- 层级结构：
--   TheWorld.components.worldspawner  (运行期实例)
--   ├── cave          (区域)
--   │   ├── mushgnome_spawner        → childspawner
--   │   ├── cave_vent_mite_spawner   → childspawner
--   │   ├── minotaur_spawner         → ruinsrespawner
--   │   └── ...
--   ├── moon_island   (月岛)
--   │   └── ...
--   └── surface       (地表)
--       └── ...
--
-- 使用方式：
--   -- 1. 注册（modmain 加载阶段）
--   local WorldSpawner = require "world_spawner"
--   WorldSpawner.RegisterZone("cave", { enabled = true })
--   WorldSpawner.RegisterSpawner("cave", "mushgnome", { type = "childspawner", ... })
--
--   -- 2. 初始化（世界创建后）
--   AddSimPostInit(function()
--       require("world_spawner").Init(TheWorld, { debug = true })
--   end)
--
--   -- 3. 运行时访问
--   TheWorld.components.worldspawner:GetSpawner("cave", "mushgnome")
--   TheWorld.components.worldspawner:GetDebugString()
--============================================================================

local WorldSpawner = {}

--============================================================================
-- 注册阶段：模块级注册表（require 即存在，跨文件共享）
--============================================================================
local _zones = {}      -- { zone_name = { ZoneInfo } }
local _debug = false

--============================================================================
-- 类型常量（便于扩展）
--============================================================================
WorldSpawner.TYPES = {
    CHILDSPAWNER    = "childspawner",
    PERIODICSPAWNER = "periodicspawner",
    OBJECTSPAWNER   = "objectspawner",
    LEGACY_SPAWNER  = "legacy_spawner",
    CUSTOM          = "custom",
    WORLDGEN        = "worldgen",
    RUINSRESPAWNER  = "ruinsrespawner",
}

------------------------------------------------------------------------------
-- RegisterZone(zone_name, config)
-- 注册一个区域
--
-- config 支持字段：
--   enabled       = true|false        默认 true
--   description   = string            可读描述
--   on_zone_start = fn(self, zone)    zone 启用回调
--   on_zone_stop  = fn(self, zone)    zone 停用回调
------------------------------------------------------------------------------
function WorldSpawner.RegisterZone(zone_name, config)
    if _zones[zone_name] then
        return  -- 已注册，跳过
    end

    config = config or {}
    _zones[zone_name] = {
        name = zone_name,
        enabled = config.enabled ~= false,
        spawners = {},
        description = config.description or "",
        on_zone_start = config.on_zone_start,
        on_zone_stop = config.on_zone_stop,
    }
end

------------------------------------------------------------------------------
-- RegisterSpawner(zone_name, spawner_name, desc)
-- 在指定区域注册一个 spawner
--
-- desc 支持字段：
--   type          = string            生成器类型（见 TYPES）
--   prefab        = string            对应 prefab 名
--   component     = string            使用的 DST 组件名
--   embedded      = true|false        是否嵌入在其他 prefab 中，默认 true
--   enabled       = true|false        默认 true
--   description   = string            可读描述
--   tags          = { string, ... }   标签
--   depends_on    = { string, ... }   依赖的 spawner 名
--   on_start      = fn(self, desc)    启动回调
--   on_stop       = fn(self, desc)    停止回调
--   tuning_prefix = string            TUNING 配置前缀
--   config        = table             其他自定义配置
------------------------------------------------------------------------------
function WorldSpawner.RegisterSpawner(zone_name, spawner_name, desc)
    local zone = _zones[zone_name]
    if not zone then
        print("[WorldSpawner] ERROR: Zone '" .. tostring(zone_name) .. "' not registered")
        return
    end
    if zone.spawners[spawner_name] then
        return  -- 已注册，跳过
    end

    desc = desc or {}
    zone.spawners[spawner_name] = {
        name = spawner_name,
        zone = zone_name,
        type = desc.type or WorldSpawner.TYPES.CHILDSPAWNER,
        prefab = desc.prefab,
        component = desc.component,
        embedded = desc.embedded ~= false,
        enabled = desc.enabled ~= false,
        description = desc.description or "",
        tags = desc.tags or {},
        depends_on = desc.depends_on or {},
        on_start = desc.on_start,
        on_stop = desc.on_stop,
        tuning_prefix = desc.tuning_prefix or "",
        config = desc.config or {},
    }
end

------------------------------------------------------------------------------
-- RegisterSpawners(zone_name, spawner_table)
-- 批量注册
--   spawner_table = { spawner_name = desc, ... }
------------------------------------------------------------------------------
function WorldSpawner.RegisterSpawners(zone_name, spawner_table)
    for name, desc in pairs(spawner_table) do
        WorldSpawner.RegisterSpawner(zone_name, name, desc)
    end
end

------------------------------------------------------------------------------
-- GetZoneNames()
-- 获取所有已注册的 zone 名
------------------------------------------------------------------------------
function WorldSpawner.GetZoneNames()
    local names = {}
    for name in pairs(_zones) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

------------------------------------------------------------------------------
-- GetSpawnerNames(zone_name)
-- 获取某个 zone 的所有 spawner 名
------------------------------------------------------------------------------
function WorldSpawner.GetSpawnerNames(zone_name)
    local zone = _zones[zone_name]
    if not zone then return {} end
    local names = {}
    for name in pairs(zone.spawners) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

--============================================================================
-- 运行阶段：安装到 TheWorld
--============================================================================

------------------------------------------------------------------------------
-- Init(theWorld, opts)
-- 将注册表安装为 TheWorld.components.worldspawner 实例
-- opts: { debug = true|false }
------------------------------------------------------------------------------
function WorldSpawner.Init(theWorld, opts)
    -- 防止重复安装
    if theWorld.components.worldspawner then
        return theWorld.components.worldspawner
    end

    opts = opts or {}

    -- 创建运行期实例（将模块表作为原型）
    local self = setmetatable({}, { __index = WorldSpawner })
    self.inst = theWorld
    self._debug = opts.debug or false
    _debug = self._debug

    -- 深拷贝注册表到实例
    self.zones = {}
    for zname, zdata in pairs(_zones) do
        local zone = {
            name = zdata.name,
            enabled = zdata.enabled,
            spawners = {},
            description = zdata.description,
            on_zone_start = zdata.on_zone_start,
            on_zone_stop = zdata.on_zone_stop,
            config = zdata.config,
        }
        for sname, sdata in pairs(zdata.spawners) do
            zone.spawners[sname] = {
                name = sdata.name,
                zone = sdata.zone,
                type = sdata.type,
                prefab = sdata.prefab,
                component = sdata.component,
                embedded = sdata.embedded,
                enabled = sdata.enabled,
                description = sdata.description,
                tags = shallow_copy(sdata.tags),
                depends_on = shallow_copy(sdata.depends_on),
                on_start = sdata.on_start,
                on_stop = sdata.on_stop,
                tuning_prefix = sdata.tuning_prefix,
                config = shallow_copy(sdata.config),
            }
        end
        self.zones[zname] = zone
    end

    -- 安装到 TheWorld
    theWorld.components.worldspawner = self

    -- 触发所有已启用 zone 的启动回调
    for zname, zone in pairs(self.zones) do
        if zone.enabled and zone.on_zone_start then
            zone.on_zone_start(self, zone)
        end
    end

    if _debug then
        print("[WorldSpawner] Installed on TheWorld")
        print(self:GetDebugString())
    end

    return self
end

--============================================================================
-- 运行期实例方法（通过 self 调用）
--============================================================================

function WorldSpawner:GetZone(zone_name)
    return self.zones[zone_name]
end

function WorldSpawner:GetSpawner(zone_name, spawner_name)
    local zone = self.zones[zone_name]
    return zone and zone.spawners[spawner_name] or nil
end

function WorldSpawner:FindByTag(tag)
    local results = {}
    for zname, zone in pairs(self.zones) do
        for sname, spawner in pairs(zone.spawners) do
            for _, t in ipairs(spawner.tags) do
                if t == tag then
                    table.insert(results, { zone = zname, spawner = sname })
                    break
                end
            end
        end
    end
    return results
end

function WorldSpawner:FindByType(type_name)
    local results = {}
    for zname, zone in pairs(self.zones) do
        for sname, spawner in pairs(zone.spawners) do
            if spawner.type == type_name then
                table.insert(results, { zone = zname, spawner = sname })
            end
        end
    end
    return results
end

function WorldSpawner:StartZone(zone_name)
    local zone = self.zones[zone_name]
    if not zone or not zone.enabled then
        return
    end
    if zone.on_zone_start then
        zone.on_zone_start(self, zone)
    end
    if _debug then
        print("[WorldSpawner] Zone started:", zone_name)
    end
end

function WorldSpawner:StopZone(zone_name)
    local zone = self.zones[zone_name]
    if not zone then return end
    if zone.on_zone_stop then
        zone.on_zone_stop(self, zone)
    end
    if _debug then
        print("[WorldSpawner] Zone stopped:", zone_name)
    end
end

function WorldSpawner:EnableZone(zone_name)
    local zone = self.zones[zone_name]
    if not zone or zone.enabled then return end
    zone.enabled = true
    self:StartZone(zone_name)
end

function WorldSpawner:DisableZone(zone_name)
    local zone = self.zones[zone_name]
    if not zone or not zone.enabled then return end
    zone.enabled = false
    self:StopZone(zone_name)
end

function WorldSpawner:GetDebugString()
    local lines = {}
    for zname, zone in sorted_pairs(self.zones) do
        local zone_status = zone.enabled and "ENABLED" or "DISABLED"
        local count = table_count(zone.spawners)
        table.insert(lines, string.format("[%s] (%s) %d spawners  %s",
            zname, zone_status, count,
            zone.description ~= "" and ("-- " .. zone.description) or ""))
        for sname, spawner in sorted_pairs(zone.spawners) do
            local status = spawner.enabled and "ON" or "OFF"
            local prefix = spawner.embedded and "  [E]" or "  [D]"
            table.insert(lines, string.format("%s %s | %-20s | %-15s | %s",
                prefix, status, sname, spawner.type, spawner.description))
        end
    end
    return table.concat(lines, "\n")
end

--============================================================================
-- 工具函数
--============================================================================

local function shallow_copy(t)
    if not t then return nil end
    local c = {}
    for k, v in pairs(t) do
        c[k] = v
    end
    return c
end

local function sorted_pairs(t)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys)
    local i = 0
    return function()
        i = i + 1
        local k = keys[i]
        if k == nil then return nil end
        return k, t[k]
    end
end

local function table_count(t)
    if type(t) ~= "table" then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

--============================================================================
-- 返回模块
--============================================================================
return WorldSpawner
