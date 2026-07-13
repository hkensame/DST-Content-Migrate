----------------<中庭迷宫 & 档案馆迷宫：注册 hallway tile 布局到 maze_layouts>----------------
-- DS 的迷宫系统（forest_map.lua:ProcessExtraTags）通过 maze_layouts.AllLayouts 查找 tile 布局。
-- 这里动态注册 atrium_hallway / archive_hallway 系列，使迷宫任务的 maze_tiles 能加载走廊布局。
-- archive_areas 回调在 maze 单元格内随机生成额外物件（蜈蚣壳、环境音效、烹饪锅、尘蛾巢）
local MazeLayouts = require("map/maze_layouts")
local StaticLayout = require("map/static_layout")
local Layouts = require("map/layouts").Layouts

-- 档案馆 maze 单元格随机回调（摘自 DST maze_layouts.lua archive_areas，完全一致）
local archive_areas = {
    creature_area = function()
        if math.random() < 0.5 then
            return {"archive_centipede_husk"}
        end
    end,
    archive_sound_area = function()
        if math.random() < 0.3 then
            return {"archive_ambient_sfx"}
        end
    end,
    -- archive_cookpot_area = function(area, data)
    --     if math.random() < 0.3 then
    --         if data then
    --             return {{
    --                 prefab = "archive_cookpot",
    --                 x = data.x,
    --                 y = data.y,
    --                 properties = {data = {additems = {"refined_dust"}}},
    --             }}
    --         else
    --             return {"archive_cookpot"}
    --         end
    --     end
    -- end,
    -- mothden_area_low = function()
    --     if math.random() < 0.3 then
    --         return { "dustmothden" }
    --     end
    -- end,
    -- mothden_area_high = function()
    --     if math.random() < 0.7 then
    --         return { "dustmothden" }
    --     end
    -- end,
}

local function GetLayoutsForType(name, areas)
    local layouts = {
        ["SINGLE_NORTH"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/one", {force_rotation = LAYOUT_ROTATION.NORTH, areas = areas}),
        ["SINGLE_EAST"]  = StaticLayout.Get("map/static_layouts/rooms/"..name.."/one", {force_rotation = LAYOUT_ROTATION.EAST, areas = areas}),
        ["SINGLE_SOUTH"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/one", {force_rotation = LAYOUT_ROTATION.SOUTH, areas = areas}),
        ["SINGLE_WEST"]  = StaticLayout.Get("map/static_layouts/rooms/"..name.."/one", {force_rotation = LAYOUT_ROTATION.WEST, areas = areas}),
        ["L_NORTH"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/two", {force_rotation = LAYOUT_ROTATION.NORTH, areas = areas}),
        ["L_EAST"]  = StaticLayout.Get("map/static_layouts/rooms/"..name.."/two", {force_rotation = LAYOUT_ROTATION.EAST, areas = areas}),
        ["L_SOUTH"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/two", {force_rotation = LAYOUT_ROTATION.SOUTH, areas = areas}),
        ["L_WEST"]  = StaticLayout.Get("map/static_layouts/rooms/"..name.."/two", {force_rotation = LAYOUT_ROTATION.WEST, areas = areas}),
        ["THREE_WAY_N"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/three", {force_rotation = LAYOUT_ROTATION.NORTH, areas = areas}),
        ["THREE_WAY_E"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/three", {force_rotation = LAYOUT_ROTATION.EAST, areas = areas}),
        ["THREE_WAY_S"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/three", {force_rotation = LAYOUT_ROTATION.SOUTH, areas = areas}),
        ["THREE_WAY_W"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/three", {force_rotation = LAYOUT_ROTATION.WEST, areas = areas}),
        ["FOUR_WAY"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/four", {force_rotation = LAYOUT_ROTATION.NORTH, areas = areas}),
        ["TUNNEL_NS"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/long", {force_rotation = LAYOUT_ROTATION.NORTH, areas = areas}),
        ["TUNNEL_EW"] = StaticLayout.Get("map/static_layouts/rooms/"..name.."/long", {force_rotation = LAYOUT_ROTATION.EAST, areas = areas}),
    }
    return layouts
end

MazeLayouts.AllLayouts["atrium_hallway"]      = GetLayoutsForType("atrium_hallway")
MazeLayouts.AllLayouts["atrium_hallway_two"]   = GetLayoutsForType("atrium_hallway_two")
MazeLayouts.AllLayouts["atrium_hallway_three"] = GetLayoutsForType("atrium_hallway_three")
MazeLayouts.AllLayouts["archive_hallway"]      = GetLayoutsForType("archive_hallway", archive_areas)
MazeLayouts.AllLayouts["archive_hallway_two"]   = GetLayoutsForType("archive_hallway_two", archive_areas)

-- 档案馆特殊布局（起点/终点/钥匙房）
local function GetSpecialLayoutsForType(layout_dir, name)
    local path = "map/static_layouts/rooms/" .. layout_dir .. "/" .. name
    local layouts = {
        ["SINGLE_NORTH"] = StaticLayout.Get(path, {force_rotation = LAYOUT_ROTATION.NORTH}),
        ["SINGLE_EAST"]  = StaticLayout.Get(path, {force_rotation = LAYOUT_ROTATION.EAST}),
        ["SINGLE_SOUTH"] = StaticLayout.Get(path, {force_rotation = LAYOUT_ROTATION.SOUTH}),
        ["SINGLE_WEST"]  = StaticLayout.Get(path, {force_rotation = LAYOUT_ROTATION.WEST}),
    }
    return layouts
end

MazeLayouts.AllLayouts["archive_start"]       = GetSpecialLayoutsForType("archive_start", "archive_start")
MazeLayouts.AllLayouts["archive_end"]         = GetSpecialLayoutsForType("archive_end", "archive_end")
MazeLayouts.AllLayouts["archive_keyroom"]     = GetSpecialLayoutsForType("archive_keyroom", "keyroom_1")
MazeLayouts.AllLayouts["archive_supplyroom"]  = GetSpecialLayoutsForType("archive_supplyroom", "supply")

-- 档案馆特殊布局只注册了 SINGLE_* 变体，但 DS 迷宫系统可能使用其他连接类型。
-- 为所有缺失的连接类型以 SINGLE_NORTH 填充，避免 LayoutForDefinition 因 key 不存在而 crash。
local function patch_special_layouts(name)
    local layouts = MazeLayouts.AllLayouts[name]
    if not layouts then return end
    local fallback = layouts["SINGLE_NORTH"]
    local missing = {"L_NORTH","L_EAST","L_SOUTH","L_WEST","THREE_WAY_N","THREE_WAY_E","THREE_WAY_S","THREE_WAY_W","FOUR_WAY","TUNNEL_NS","TUNNEL_EW"}
    for _, conn in ipairs(missing) do
        if not layouts[conn] then
            layouts[conn] = fallback
        end
    end
end
patch_special_layouts("archive_start")
patch_special_layouts("archive_end")
patch_special_layouts("archive_keyroom")
patch_special_layouts("archive_supplyroom")

-- 注册到 objs.Layouts，使 countstaticlayouts 可以引用这些特殊房间布局
Layouts["ArchiveStart"] = StaticLayout.Get("map/static_layouts/rooms/archive_start/archive_start")
Layouts["ArchiveEnd"] = StaticLayout.Get("map/static_layouts/rooms/archive_end/archive_end")
Layouts["ArchiveKeyroom"] = StaticLayout.Get("map/static_layouts/rooms/archive_keyroom/keyroom_1")
Layouts["ArchiveSupplyRoom"] = StaticLayout.Get("map/static_layouts/rooms/archive_supplyroom/supply")

-- 中庭特殊布局
Layouts["AtriumEnd"] = StaticLayout.Get("map/static_layouts/rooms/atrium_end/atrium_end")

Layouts["TentaclePillarToAtrium"] = StaticLayout.Get("map/static_layouts/tentacle_pillar_atrium")
Layouts["TentaclePillarToAtriumOuter"] = StaticLayout.Get("map/static_layouts/tentacle_pillar_atrium_outer")

-- ==================== 洞穴 / 遗迹静态布局注册 ====================
-- 这些布局被 room_defs.lua 的 countstaticlayouts 引用，必须注册到 Layouts 表

-- 洞穴布局
Layouts["CaveExit"] = StaticLayout.Get("map/static_layouts/cave_exit", {
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
})
Layouts["RabbitTown"] = StaticLayout.Get("map/static_layouts/rabbittown")
Layouts["RabbitHermit"] = StaticLayout.Get("map/static_layouts/rabbithermit")
Layouts["Mudlights"] = StaticLayout.Get("map/static_layouts/mudlights")
Layouts["RabbitCity"] = StaticLayout.Get("map/static_layouts/rabbitcity")
Layouts["EvergreenSinkhole"] = StaticLayout.Get("map/static_layouts/evergreensinkhole", {
    areas = {
        lights = {"cavelight", "cavelight"},
        innertrees = function(area) return PickSomeWithDups(area*.5, {"evergreen"}) end,
        outertrees = function(area) return PickSomeWithDups(area*.2, {"evergreen", "sapling"}) end,
    },
})
Layouts["GrassySinkhole"] = StaticLayout.Get("map/static_layouts/grasssinkhole", {
    areas = {
        lights = {"cavelight", "cavelight"},
        grassarea = function(area) return PickSomeWithDups(area*.4, {"grass"}) end,
    },
})
Layouts["PondSinkhole"] = StaticLayout.Get("map/static_layouts/pondsinkhole", {
    areas = {
        lights = {"cavelight", "cavelight"},
        pondarea = { "pond", "grass", "grass", "berrybush", "sapling", "sapling" },
    },
})

-- 遗迹布局
Layouts["WalledGarden"] = StaticLayout.Get("map/static_layouts/walledgarden", {
    areas = {
        plants = function(area) return PickSomeWithDups(0.3 * area, {"cave_fern", "lichen", "cave/objects/flower_cave", "cave/objects/flower_cave_double", "cave/objects/flower_cave_triple"}) end,
    },
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
})
Layouts["MilitaryEntrance"] = StaticLayout.Get("map/static_layouts/military_entrance", {
    areas = {
        cave_hole_area = function(area) return {"cave_hole"} end,
    },
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
})
Layouts["AltarRoom"] = StaticLayout.Get("map/static_layouts/altar", {
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
})
Layouts["SacredBarracks"] = StaticLayout.Get("map/static_layouts/sacred_barracks", {
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
})
Layouts["Barracks"] = StaticLayout.Get("map/static_layouts/barracks", {
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
})
Layouts["Barracks2"] = StaticLayout.Get("map/static_layouts/barracks_two", {
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
})
Layouts["Spiral"] = StaticLayout.Get("map/static_layouts/spiral", {
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
    areas = {
        relics = function() return PickSomeWithDups(15, {"ruins_plate", "ruins_bowl", "ruins_chair", "ruins_chipbowl", "ruins_vase", "ruins_table", "ruins_rubble_table", "ruins_rubble_chair", "ruins_rubble_vase", "thulecite_pieces", "rocks"}) end,
    },
})
Layouts["BrokenAltar"] = StaticLayout.Get("map/static_layouts/brokenaltar", {
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
})
Layouts["CornerWall"] = StaticLayout.Get("map/static_layouts/walls_corner")
Layouts["StraightWall"] = StaticLayout.Get("map/static_layouts/walls_straight")
Layouts["CornerWall2"] = StaticLayout.Get("map/static_layouts/walls_corner2")
Layouts["StraightWall2"] = StaticLayout.Get("map/static_layouts/walls_straight2")
