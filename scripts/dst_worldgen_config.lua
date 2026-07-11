----------------<配置文件加载>----------------
-- 根据 mod 配置项条件加载对应的世界生成脚本

if GetModConfigData("antlion") == true then
    modimport "scripts/map/map_antlion.lua"
end


if GetModConfigData("dragonfly") == true then
    modimport "scripts/map/map_dragonfly.lua"
end

if GetModConfigData("klaus") == true then
    modimport "scripts/map/map_klaus.lua"
end

if GetModConfigData("moonbase") == true then
    modimport "scripts/map/map_moonbase.lua"
end

if GetModConfigData("moonisland") == true then
    modimport "scripts/map/map_moonisland.lua"
end

if GetModConfigData("sculptures") == true then
    modimport "scripts/map/map_sculptures.lua"
end

if GetModConfigData("monkeyisland") == true then
    modimport "scripts/map/map_monkeyisland.lua"
end

if GetModConfigData("dstcave") == true then
    -- 确保洞穴出口 prefab 在 worldgen 时可用
    modimport "scripts/prefabs/cave/dst_cave_exit.lua"
    modimport "scripts/map/map_dstcave.lua"
    modimport "scripts/map/map_toadstool.lua"

    -- 地表放置 DST 洞穴入口
    AddLevelPreInit("SURVIVAL_DEFAULT", function(level)
        level.set_pieces["DSTCaveEntrance"] = {
            count = 1,
            tasks = {"Make a pick"},
        }
    end)
end

-- astral marker 布景（谐振器搜索目标，始终注入）
modimport "scripts/map/map_moon_altar_astral_marker.lua"
