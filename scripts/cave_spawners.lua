--============================================================================
-- cave_spawners.lua — 洞穴区域 Spawner 注册
--
-- 此文件通过 WorldSpawner 注册洞穴区域下所有 spawner。
-- 在 modmain.lua 中用 modimport 加载：
--   local WorldSpawner = require "world_spawner"
--   modimport("scripts/cave_spawners.lua")
--   WorldSpawner.Init(TheWorld)
--
-- 注册后可通过以下方式访问：
--   TheWorld.components.worldspawner
--   TheWorld.components.worldspawner:GetSpawner("cave", "mushgnome")
--   TheWorld.components.worldspawner:GetDebugString()
--============================================================================

-- WorldSpawner 应该在调用此文件前通过 require 加载
-- 但 DS 的 modimport 在 load 阶段执行，此时 require 结果可用
local WorldSpawner = require "world_spawner"

--============================================================================
-- 1. 注册洞穴区域
--============================================================================
WorldSpawner.RegisterZone("cave", {
    enabled = true,
    description = "洞穴区域（含遗迹、月蘑菇森林、档案馆、vent区等）",

    -- zone 启动回调：当洞穴区域被启用时触发
    on_zone_start = function(self, zone)
        -- 在这里可以做洞穴相关的初始化
        -- 例如监听洞穴入口/出口事件
        if self._debug then
            print("[CaveSpawners] Cave zone started")
        end
    end,

    -- zone 停止回调：当洞穴区域被禁用时触发
    on_zone_stop = function(self, zone)
        if self._debug then
            print("[CaveSpawners] Cave zone stopped")
        end
    end,
})

--============================================================================
-- 2. 注册所有洞穴 spawner
--============================================================================
WorldSpawner.RegisterSpawners("cave", {

    --=====================================================================
    -- 2-A 独立 Spawner Prefab（有独立 prefab 文件的生成器）
    --=====================================================================

    mushgnome = {
        type = "childspawner",          -- 基于 childspawner 组件
        prefab = "mushgnome_spawner",   -- 独立 prefab 文件名
        component = "childspawner",
        embedded = false,               -- 独立实体，不是嵌入在其他 prefab 中
        description = "月蘑菇地精生成器 — 玩家接近时从巢穴释放地精",
        tuning_prefix = "MUSHGNOME_",   -- TUNING.MUSHGNOME_* 相关配置
        tags = { "creature", "moon", "forest" },
        depends_on = {},                -- 无前置依赖
    },

    cave_vent_mite = {
        type = "childspawner",
        prefab = "cave_vent_mite_spawner",
        component = "childspawner",
        embedded = false,
        description = "地热螨生成器 — 玩家接近洞穴排气口时释放螨虫",
        tuning_prefix = "CAVE_MITE_",
        tags = { "creature", "vent", "mite" },
    },

    minotaur = {
        type = "ruinsrespawner",        -- 自定义重生机制
        prefab = "minotaur_spawner",    -- 返回两个 prefab（WorldGen + Inst）
        component = "objectspawner",    -- 底层使用 objectspawner
        embedded = false,
        description = "远古守卫者重生器 — 击败后重生并替换宝箱掉落",
        tags = { "boss", "ruins", "respawn" },
    },

    ruins_respawner = {
        type = "worldgen",              -- 仅在世界生成时激活
        prefab = "ruins_spawners",      -- 见 scripts/prefabs/ruins_spawners.lua
        component = nil,                -- 工厂模块，无运行时组件
        embedded = false,
        description = "遗迹 respawner 工厂 — 在 room_defs 中生成象棋怪等",
        tags = { "ruins", "worldgen", "static" },
    },

    --=====================================================================
    -- 2-B 嵌入在其他 Prefab 中的 Spawner 组件
    --=====================================================================

    mushtree_moon_spores = {
        type = "periodicspawner",
        prefab = "mushtree_moon",       -- 嵌入在 mushtree_moon prefab 中
        component = "periodicspawner",
        embedded = true,
        description = "月蘑菇树孢子生成 — 周期释放月孢子",
        tuning_prefix = "MUSHSPORE_",
        tags = { "plant", "spore", "moon" },
    },

    cave_hole_loot = {
        type = "objectspawner",
        prefab = "cave_hole",
        component = "objectspawner",
        embedded = true,
        description = "洞穴坑洞战利品生成 — 中庭/档案馆洞穴的可收集物品",
        tags = { "loot", "hole", "archive" },
    },

    dustmoth = {
        type = "childspawner",
        prefab = "dustmothden",
        component = "childspawner",
        embedded = true,
        description = "尘蛾巢穴 — 周期释放尘蛾",
        tuning_prefix = "DUSTMOTHDEN_",
        tags = { "creature", "archive", "moth" },
    },

    archive_security_pulse = {
        type = "childspawner",
        prefab = "archive_props",       -- 嵌入在 archive_props 中
        component = "childspawner",
        embedded = true,
        description = "档案馆安全脉冲 — 档案馆中的巡逻安保实体",
        tuning_prefix = "ARCHIVE_SECURITY.",
        tags = { "archive", "security", "pulse" },
    },

    cavelight_molebat = {
        type = "legacy_spawner",        -- DST 原始的 spawner.lua 组件
        prefab = "cavelightmoon",
        component = "spawner",          -- 使用 spawner.lua（非 childspawner）
        embedded = true,
        description = "月光洞穴灯（无眼蝠伴生）— 玩家靠近时召唤无眼蝠",
        tuning_prefix = "MOLEBAT_",
        tags = { "creature", "moon", "bat" },
    },

    mushgnome_spores = {
        type = "periodicspawner",
        prefab = "mushgnome",
        component = "periodicspawner",
        embedded = true,
        description = "月蘑菇地精孢子效果 — 地精自身周期的孢子粒子",
        tags = { "creature", "spore", "fx" },
    },

    --=====================================================================
    -- 2-C 自定义定时再生机制
    --=====================================================================

    moonglass_regrowth = {
        type = "custom",                -- 自定义 DoTaskInTime 再生
        prefab = "grotto_pool_moonglass",
        component = nil,
        embedded = true,
        description = "月玻璃水池资源再生 — 10天周期重置可采集月玻璃",
        tags = { "resource", "regrowth", "moonglass" },
    },

    waterfall_regrowth = {
        type = "custom",
        prefab = "grotto_waterfall_small",
        component = nil,
        embedded = true,
        description = "小瀑布资源再生 — 10天周期重置可采集瀑布",
        tags = { "resource", "regrowth", "waterfall" },
    },
})

--============================================================================
-- 调试：输出洞穴 spawner 注册摘要
--============================================================================
if WorldSpawner.debug then
    print("[CaveSpawners] Cave spawners registered:")
    for _, name in ipairs(WorldSpawner.GetSpawnerNames("cave")) do
        local s = WorldSpawner.GetSpawner("cave", name)
        print(string.format("  %-25s | %-20s | %s",
            name, s.type, s.description))
    end
end
