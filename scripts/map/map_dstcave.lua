
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

-- 导入房间定义（DST 洞穴房间 + 蛤蟆竞技场房间）
modimport "scripts/map/rooms/room_defs.lua"

----------------<地表入口布局>----------------
Layouts["DSTCaveEntrance"] = {
    type = LAYOUT.STATIC,
    layout = {
        dst_cave_entrance = {{x=0, y=0}},
    },
    ground_types = {GROUND.GRASS},
    ground = {
        {1, 1, 1},
        {1, 1, 1},
        {1, 1, 1},
    },
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
}

----------------<洞穴出生点静态布局>----------------
Layouts["DSTCaveSpawn"] = StaticLayout.Get("map/static_layouts/dst_cave_spawn")

----------------<月蘑菇水池静态布局>----------------
Layouts["GrottoPoolBig"] = StaticLayout.Get("map/static_layouts/grotto_pool_large")
Layouts["GrottoPoolSmall"] = StaticLayout.Get("map/static_layouts/grotto_pool_small")

----------------<DST 洞穴 Task 定义>----------------

--===========================================================
-- 入口区（出生点）
--===========================================================
AddTask("DST_EntranceTask", {
    locks = LOCKS.NONE,
    keys_given = {KEYS.LIGHT, KEYS.CAVE, KEYS.TIER1},
    room_choices = {
        ["DST_Entrance"] = 2,
    },
    background_room = "DST_EntranceBG",
    room_bg = GROUND.GRASS,
    colour={r=0.2,g=0.8,b=0.2,a=1},
})

--===========================================================
-- 泥地中心区（TIER1 → TIER2）
--===========================================================
AddTask("DST_MudWorld", {
    locks={ LOCKS.TIER1 },
    keys_given={ KEYS.CAVE, KEYS.TIER1 },
    room_choices={
        ["DST_LightPlantField"] = 2,
        ["DST_WormPlantField"] = 1,
        ["DST_FernGully"] = 1,
        ["DST_SlurtlePlains"] = 1,
        ["DST_MudWithRabbit"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGMud",
    room_bg=GROUND.MUD,
    colour={r=0.6,g=0.4,b=0.0,a=0.9},
})

AddTask("DST_MudCave", {
    locks={ LOCKS.CAVE, LOCKS.TIER1 },
    keys_given={ KEYS.CAVE, KEYS.TIER2 },
    room_choices={
        ["DST_WormPlantField"] = 1,
        ["DST_SlurtlePlains"] = 1,
        ["DST_MudWithRabbit"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGBatCaveRoom",
    room_bg=GROUND.MUD,
    colour={r=0.7,g=0.5,b=0.0,a=0.9},
})

AddTask("DST_MudLights", {
    locks={ LOCKS.CAVE, LOCKS.TIER1 },
    keys_given={ KEYS.CAVE, KEYS.TIER2 },
    room_choices={
        ["DST_LightPlantField"] = 3,
        ["DST_WormPlantField"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_WormPlantField",
    room_bg=GROUND.MUD,
    colour={r=0.7,g=0.5,b=0.0,a=0.9},
})

AddTask("DST_MudPit", {
    locks={ LOCKS.CAVE, LOCKS.TIER1 },
    keys_given={ KEYS.CAVE, KEYS.TIER2 },
    room_choices={
        ["DST_SlurtlePlains"] = 1,
        ["DST_PitRoom"] = 4,
    },
    background_room="DST_FernGully",
    room_bg=GROUND.MUD,
    colour={r=0.6,g=0.4,b=0.0,a=0.9},
})

--===========================================================
-- 主洞穴分支（TIER2 → TIER3）
--===========================================================
AddTask("DST_BigBatCave", {
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3, KEYS.BATS },
    room_choices={
        ["DST_BatCave"] = 3,
        ["DST_BattyCave"] = 1,
        ["DST_FernyBatCave"] = 2,
        ["DST_PitRoom"] = 4,
    },
    background_room="DST_BGBatCaveRoom",
    room_bg=GROUND.CAVE,
    colour={r=0.8,g=0.8,b=0.8,a=0.9},
})

AddTask("DST_RockyLand",{
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3, KEYS.ROCKY },
    room_choices={
        ["DST_SlurtleCanyon"] = 1,
        ["DST_BatsAndSlurtles"] = 1,
        ["DST_RockyPlains"] = 2,
        ["DST_RockyHatchingGrounds"] = 1,
        ["DST_BatsAndRocky"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGRockyCaveRoom",
    room_bg=GROUND.CAVE,
    colour={r=0.5,g=0.5,b=0.5,a=0.9},
})

AddTask("DST_RedForest",{
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3, KEYS.RED, KEYS.ENTRANCE_INNER },
    room_choices={
        ["DST_RedMushForest"] = 2,
        ["DST_RedSpiderForest"] = 1,
        ["DST_RedMushPillars"] = 1,
        ["DST_StalagmiteForest"] = 1,
        ["DST_SpillagmiteMeadow"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGRedMush",
    room_bg=GROUND.FUNGUSRED,
    colour={r=1.0,g=0.5,b=0.5,a=0.9},
})

AddTask("DST_GreenForest",{
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3, KEYS.GREEN, KEYS.ENTRANCE_INNER },
    room_choices={
        ["DST_GreenMushForest"] = 2,
        ["DST_GreenMushNoise"] = 1,
        ["DST_GreenMushPonds"] = 1,
        ["DST_GreenMushSinkhole"] = 1,
        ["DST_GreenMushMeadow"] = 1,
        ["DST_GreenMushRabbits"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGGreenMush",
    room_bg=GROUND.FUNGUSGREEN,
    colour={r=0.5,g=1.0,b=0.5,a=0.9},
})

AddTask("DST_BlueForest",{
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.TIER3, KEYS.MOONMUSH, KEYS.ENTRANCE_INNER },
    room_choices={
        ["DST_BlueMushForest"] = 1,
        ["DST_BlueMushMeadow"] = 2,
        ["DST_BlueSpiderForest"] = 1,
        ["DST_BlueDropperDesolation"] = 1,
    },
    entrance_room = "DST_PitRoom",
    background_room="DST_BGBlueMush",
    room_bg=GROUND.FUNGUS,
    colour={r=0.5,g=0.5,b=1.0,a=0.9},
})

AddTask("DST_SpillagmiteCaverns",{
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ KEYS.CAVE, KEYS.TIER3 },
    room_choices={
        ["DST_SpillagmiteForest"] = 1,
        ["DST_DropperCanyon"] = 1,
        ["DST_StalagmitesAndLights"] = 1,
        ["DST_SpidersAndBats"] = 1,
        ["DST_ThuleciteDebris"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGSpillagmiteRoom",
    room_bg=GROUND.UNDERROCK,
    colour={r=0.3,g=0.3,b=0.3,a=0.9},
})

--===========================================================
-- 特殊区域
--===========================================================
-- 月蘑菇森林（链：BlueForest → MoonCave → Archive）
AddTask("DST_MoonCaveForest",{
    locks={ LOCKS.MOONMUSH },
    keys_given={ KEYS.ARCHIVE },
    room_tags = { },
    room_choices={
        ["DST_MoonMushForest"] = 9,
        ["DST_MoonMushForest_entrance"] = 1,
    },
    background_room="DST_MoonMushForest",
    room_bg=GROUND.FUNGUSMOON,
    colour={r=0.3,g=0.3,b=0.3,a=0.9},
})

-- 档案馆区域（普通房间连接，取消迷宫生成）
AddTask("DST_ArchiveArea", {
    locks={LOCKS.ARCHIVE},
    keys_given= {},
    room_tags = {"nocavein"},
    required_prefabs = {"archive_orchestrina_main", "archive_lockbox_dispencer"},
    room_choices = {
        ["DST_ArchiveStart"] = 1,
        ["DST_ArchiveEnd"] = 1,
        ["DST_ArchiveKeyroom"] = 1,
        ["DST_ArchiveSupplyRoom"] = 2,
        ["DST_ArchiveDistillery"] = 1,
    },
    room_bg = GROUND.ARCHIVE,
    cove_room_chance = 0,
    cove_room_max_edges = 0,
    make_loop = true,
    colour={r=0.4,g=0.4,b=0.5,a=0.9},
})

-- 蛤蟆竞技场（由 DST 的 ToadStoolTask 定义）
AddTask("DST_ToadStoolTask1", {
    locks={ LOCKS.CAVE, LOCKS.TIER2 },
    keys_given={ },
    room_choices={
        ["ToadstoolArenaBGMud"] = 2,
        ["ToadstoolArenaMud"] = 1,
    },
    room_bg=GROUND.MUD,
    colour={r=1.0,g=0.0,b=0.0,a=0.9},
})

AddTask("DST_ToadStoolTask2", {
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ },
    room_choices={
        ["ToadstoolArenaBGCave"] = 2,
        ["ToadstoolArenaCave"] = 1,
    },
    room_bg=GROUND.CAVE,
    colour={r=1.0,g=0.0,b=0.0,a=0.9},
})

AddTask("DST_ToadStoolTask3", {
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ },
    room_choices={
        ["ToadstoolArenaBGMud"] = 2,
        ["ToadstoolArenaMud"] = 1,
    },
    room_bg=GROUND.MUD,
    colour={r=1.0,g=0.0,b=0.0,a=0.9},
})

-- 蜈蚣洞穴（需要 TIER4，通往遗迹岛）
AddTask("DST_CentipedeCaveTask", {
    locks={ LOCKS.CAVE, LOCKS.TIER4, },
    keys_given={ KEYS.CAVE, KEYS.TIER5, KEYS.CENTIPEDE },
    room_choices={
        ["DST_VentsRoom"] = 3,
        ["DST_RockTreeRoom"] = 3,
        ["DST_VentsRoom_exit"] = 3,
        ["DST_CentipedeNest"] = 1,
    },
    background_room="DST_BGVentsRoom",
    room_bg=GROUND.VENT,
    colour={r=0.8,g=0.8,b=0.8,a=0.9},
    cove_room_name = "DST_Blank",
    make_loop = true,
    cove_room_chance = 1,
    cove_room_max_edges = 50,
})

-- 遗迹岛（可选，由蜈蚣区解锁）
AddTask("DST_CentipedeCaveIslandTask",{
    locks={ LOCKS.CENTIPEDE },
    keys_given={ },
    room_tags = { },
    level_set_piece_blocker = true,
    room_choices={
        ["DST_RuinsIsland"] = 1,
        ["DST_RuinsIsland_entrance"] = 1,
    },
    background_room="DST_PitRoom",
    room_bg=GROUND.TILES,
    colour={r=0.3,g=0.3,b=0.3,a=0.9},
})

--===========================================================
-- 可选深层分支及遗迹（TIER3 → TIER4 / RUINS）
--===========================================================
-- 沼泽天井
AddTask("DST_SwampySinkhole",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SWAMP, KEYS.TIER4 },
    room_choices={
        ["DST_SinkholeSwamp"] = 1,
        ["DST_TentacleMud"] = 1,
        ["DST_TentaclesAndTrees"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGSinkholeSwampRoom",
    room_bg=GROUND.MARSH,
    colour={r=0.6,g=0.1,b=0.7,a=0.9},
})

-- 暗黑沼泽
AddTask("DST_CaveSwamp",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SWAMP, KEYS.TIER4 },
    room_choices={
        ["DST_DarkSwamp"] = 2,
        ["DST_TentacleMud"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGSinkholeSwamp",
    room_bg=GROUND.MARSH,
    colour={r=0.7,g=0.1,b=0.6,a=0.9},
})

-- 潮湿天井
AddTask("DST_SoggySinkhole",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SINKHOLE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["DST_SinkholeOasis"] = 3,
        ["DST_SinkholeCopses"] = 1,
        ["DST_SparseSinkholes"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGSinkhole",
    room_bg=GROUND.SINKHOLE,
    colour={r=0.0,g=0.5,b=0.0,a=0.9},
})

-- 地下森林
AddTask("DST_UndergroundForest",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SINKHOLE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["DST_SinkholeForest"] = 3,
        ["DST_SinkholeCopses"] = 1,
        ["DST_SparseSinkholes"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGSinkhole",
    room_bg=GROUND.SINKHOLE,
    colour={r=0.0,g=0.3,b=0.0,a=0.9},
})

-- 草天井
AddTask("DST_PleasantSinkhole",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SINKHOLE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["DST_GrasslandSinkhole"] = 3,
        ["DST_SinkholeOasis"] = 1,
        ["DST_SparseSinkholes"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGSinkhole",
    room_bg=GROUND.SINKHOLE,
    colour={r=0.0,g=0.5,b=0.0,a=0.9},
})

-- 真菌噪声森林
AddTask("DST_FungalNoiseForest",{
    locks={ LOCKS.CAVE, LOCKS.TIER3, LOCKS.ROCKY },
    keys_given={ KEYS.CAVE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["DST_FungusNoiseForest"] = 3,
        ["DST_RedMushForest"] = 2,
        ["DST_BlueMushForest"] = 1,
        ["DST_GreenMushForest"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_FungusNoiseMeadow",
    room_bg=GROUND.FUNGUS,
    colour={r=0.0,g=0.5,b=1.0,a=0.9},
})

-- 真菌噪声草地
AddTask("DST_FungalNoiseMeadow",{
    locks={ LOCKS.CAVE, LOCKS.TIER3, LOCKS.BATS },
    keys_given={ KEYS.CAVE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["DST_FungusNoiseMeadow"] = 3,
        ["DST_SpillagmiteMeadow"] = 1,
        ["DST_BlueMushMeadow"] = 1,
        ["DST_GreenMushMeadow"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_FungusNoiseMeadow",
    room_bg=GROUND.FUNGUS,
    colour={r=0.0,g=0.5,b=0.8,a=0.9},
})

-- 蝙蝠回廊
AddTask("DST_BatCloister",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.TIER4 },
    room_choices={
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BatCave",
    room_bg=GROUND.CAVE,
    colour={r=0.7,g=0.7,b=0.7,a=0.9},
})

-- 兔子镇
AddTask("DST_RabbitTown",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.RABBIT, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["DST_RabbitTown"] = 1,
        ["DST_RabbitArea"] = 1,
        ["DST_RabbitSinkhole"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGSinkhole",
    room_bg=GROUND.SINKHOLE,
    colour={r=2.0,g=0.6,b=0.0,a=0.9},
})

-- 兔子城
AddTask("DST_RabbitCity",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.RABBIT, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["DST_RabbitCity"] = 1,
        ["DST_RabbitTown"] = 2,
        ["DST_RabbitArea"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_BGSinkhole",
    room_bg=GROUND.SINKHOLE,
    colour={r=1.0,g=0.8,b=0.2,a=0.9},
})

-- 蜘蛛领土
AddTask("DST_SpiderLand",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SPIDERS, KEYS.TIER4 },
    room_choices={
        ["DST_SpiderIncursion"] = 1,
        ["DST_SpiderSinkholeMarsh"] = 1,
        ["DST_SpidersAndBats"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_PitRoom",
    room_bg=GROUND.SINKHOLE,
    colour={r=0.2,g=0.5,b=0.2,a=0.9},
})

-- 兔蛛战争
AddTask("DST_RabbitSpiderWar",{
    locks={ LOCKS.CAVE, LOCKS.TIER3 },
    keys_given={ KEYS.CAVE, KEYS.SPIDERS, KEYS.RABBIT, KEYS.TIER4 },
    room_choices={
        ["DST_SpiderIncursion"] = 1,
        ["DST_RabbitArea"] = 1,
        ["DST_PitRoom"] = 2,
    },
    background_room="DST_SparseSinkholes",
    room_bg=GROUND.SINKHOLE,
    colour={r=0.6,g=0.2,b=0.0,a=0.9},
})

--===========================================================
-- 遗迹 RUINS（从 TIER4 接入，用 RUINS 锁隔离）
--===========================================================
AddTask("DST_LichenLand", {
    locks={LOCKS.TIER4},
    keys_given= {KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices={
        ["DST_WetWilds"] = 1,
        ["DST_LichenMeadow"] = 1,
        ["DST_LichenLand"] = 4,
        ["DST_PitRoom"] = 2,
    },
    room_bg=GROUND.MUD,
    background_room="DST_BGWilds",
    colour={r=0.5,g=0.3,b=0.1,a=0.9},
})

AddTask("DST_Residential", {
    locks={LOCKS.RUINS},
    keys_given= {KEYS.RUINS},
    room_tags = {"Nightmare"},
    entrance_room = "DST_RuinedCityEntrance",
    room_choices = {
        ["DST_Vacant"] = 4,
        ["DST_PitRoom"] = 2,
    },
    room_bg = GROUND.TILES,
    background_room="DST_RuinedCity",
    colour={r=0.6,g=0.4,b=0.2,a=0.9},
})

AddTask("DST_Military", {
    locks={LOCKS.RUINS},
    keys_given= {KEYS.RUINS},
    room_tags = {"Nightmare"},
    entrance_room = "DST_MilitaryEntrance",
    room_choices = {
        ["DST_BGMilitary"] = 4,
        ["DST_Barracks"] = 1,
    },
    room_bg = GROUND.TILES,
    background_room="DST_BGMilitary",
    colour={r=0.6,g=0.2,b=0.2,a=0.9},
})

AddTask("DST_Sacred", {
    locks={LOCKS.RUINS},
    keys_given= {KEYS.RUINS, KEYS.SACRED},
    room_tags = {"Nightmare"},
    entrance_room = "DST_BridgeEntrance",
    room_choices = {
        ["DST_SacredBarracks"] = 2,
        ["DST_Bishops"] = 2,
        ["DST_Spiral"] = 2,
        ["DST_BrokenAltar"] = 2,
        ["DST_PitRoom"] = 2,
    },
    room_bg = GROUND.TILES,
    background_room="DST_Blank",
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
})

AddTask("DST_TheLabyrinth", {
    locks={LOCKS.RUINS},
    keys_given= {KEYS.RUINS},
    room_tags = {"Nightmare"},
    entrance_room="DST_LabyrinthEntrance",
    room_choices={
        ["DST_Labyrinth"] = 6,
        ["DST_RuinedGuarden"] = 1,
    },
    room_bg=GROUND.BRICK,
    background_room="DST_Labyrinth",
    colour={r=0.3,g=0.2,b=0.1,a=0.9},
})

AddTask("DST_SacredAltar",{
    locks={LOCKS.RUINS, LOCKS.SACRED},
    keys_given= {KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices = {
        ["DST_PitRoom"] = 3,
    },
    room_bg = GROUND.TILES,
    entrance_room="DST_BridgeEntrance",
    background_room="DST_Blank",
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
})

-- 中庭迷宫（可选，ATRIUM 自锁）
AddTask("DST_AtriumMaze", {
    locks={LOCKS.ATRIUM},
    keys_given= {KEYS.ATRIUM},
    room_tags = {"Atrium", "Nightmare"},
    entrance_room = "DST_AtriumMazeEntrance",
    room_choices = {
        ["DST_AtriumMazeRooms"] = 6,
        ["DST_AtriumEnd"] = 1,
    },
    room_bg = GROUND.TILES,
    background_room="DST_AtriumMazeRooms",
    maze_tiles = {rooms = {"atrium_hallway", "atrium_hallway_two", "atrium_hallway_three"}, bosses = {"atrium_hallway_three"}},
    make_loop = true,
    colour={r=0.2,g=0.1,b=0.2,a=0.9},
})

-- AtriumNoneTasks（消费 ATRIUM 锁，维持锁链完整）
local AddTask_AtriumNoneTasks_registered
if not AddTask_AtriumNoneTasks_registered then
    AddTask_AtriumNoneTasks_registered = true
    AddTask("AtriumNoneTasks", {
        locks={LOCKS.ATRIUM},
        keys_given={KEYS.TIER4},
        room_choices={ 
            ["DST_PitRoom"] = 1, 
        },  
        room_bg=GROUND.IMPASSABLE,
        colour={r=0.2,g=0.1,b=0.2,a=0.3}
    })
end

--===========================================================
-- 遗迹可选扩展任务
--===========================================================

-- 丛林遗迹
AddTask("DST_CaveJungle", {
    locks={LOCKS.TIER4},
    keys_given= {KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices={
        ["DST_WetWilds"] = 2,
        ["DST_LichenMeadow"] = 1,
        ["DST_CaveJungle"] = 2,
        ["DST_MonkeyMeadow"] = 2,
        ["DST_PitRoom"] = 2,
    },
    room_bg=GROUND.MUD,
    background_room="DST_BGWildsRoom",
    colour={r=0.5,g=0.3,b=0.1,a=0.9},
})

-- 更多祭坛
AddTask("DST_MoreAltars", {
    locks = {LOCKS.RUINS, KEYS.SACRED},
    keys_given = {KEYS.SACRED, KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices = {
        ["DST_BrokenAltar"] = 1,
        ["DST_PitRoom"] = 2,
    },
    room_bg = GROUND.TILES,
    background_room="DST_Blank",
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
})

-- 神圣危险区
AddTask("DST_SacredDanger", {
    locks = {LOCKS.RUINS, KEYS.SACRED},
    keys_given = {KEYS.SACRED, KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices = {
        ["DST_SacredBarracks"] = 2,
        ["DST_Barracks"] = 2,
    },
    room_bg = GROUND.TILES,
    background_room="DST_BGSacred",
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
})

-- 军事深坑
AddTask("DST_MilitaryPits", {
    locks={LOCKS.RUINS},
    keys_given= {KEYS.RUINS},
    room_tags = {"Nightmare"},
    entrance_room = "DST_MilitaryEntrance",
    room_choices = {
        ["DST_BGMilitary"] = 3,
        ["DST_Barracks"] = 3,
    },
    room_bg = GROUND.TILES,
    background_room="DST_BGMilitary",
    colour={r=0.6,g=0.2,b=0.2,a=0.9},
})

-- 泥泞神圣
AddTask("DST_MuddySacred", {
    locks = {LOCKS.RUINS, KEYS.SACRED},
    keys_given = {KEYS.SACRED, KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices = {
        ["DST_SacredBarracks"] = 1,
        ["DST_Bishops"] = 1,
        ["DST_Spiral"] = 1,
        ["DST_BrokenAltar"] = 1,
        ["DST_WetWilds"] = 1,
        ["DST_MonkeyMeadow"] = 1,
    },
    room_bg = GROUND.TILES,
    background_room="DST_BGWildsRoom",
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
})

-- 住宅区扩展2
AddTask("DST_Residential2", {
    locks = {LOCKS.RUINS},
    keys_given = {KEYS.RUINS},
    room_tags = {"Nightmare"},
    entrance_room = "DST_RuinedCityEntrance",
    room_choices = {
        ["DST_CaveJungle"] = 1,
        ["DST_Vacant"] = 1,
        ["DST_RuinedCity"] = 2,
    },
    room_bg = GROUND.TILES,
    background_room="DST_BGWilds",
    colour={r=0.6,g=0.4,b=0.2,a=0.9},
})

-- 住宅区扩展3
AddTask("DST_Residential3", {
    locks = {LOCKS.RUINS},
    keys_given = {KEYS.RUINS},
    room_tags = {"Nightmare"},
    room_choices = {
        ["DST_Vacant"] = 4,
    },
    room_bg = GROUND.TILES,
    background_room="DST_BGWilds",
    colour={r=0.6,g=0.4,b=0.2,a=0.9},
})

----------------<注册 DST_CAVE 层级>----------------
AddLevel(LEVELTYPE.CAVE, {
    id = "DST_CAVE",
    name = "DST_CAVE",
    overrides = {
        {"world_size",      "huge"},
        {"location",        "cave"},
        {"start_setpeice",  "CaveStart"},
        {"start_node",      "DST_Entrance"},
        {"wormholes",       "never"},
    },
    tasks = {
        -- 入口
        "DST_EntranceTask",
        -- 泥地中心（TIER1→TIER2）
        "DST_MudWorld",
        "DST_MudCave",
        "DST_MudLights",
        "DST_MudPit",
        -- 主分支（TIER2→TIER3）
        "DST_BigBatCave",
        "DST_RockyLand",
        "DST_RedForest",
        "DST_GreenForest",
        "DST_BlueForest",
        "DST_SpillagmiteCaverns",
        -- 特殊区域
        "DST_MoonCaveForest",
        "DST_ArchiveArea",
        "DST_CentipedeCaveTask",
        -- 蛤蟆竞技场
        "DST_ToadStoolTask1",
        "DST_ToadStoolTask2",
        "DST_ToadStoolTask3",
        -- 遗迹（TIER4→RUINS）
        "DST_LichenLand",
        "DST_Residential",
        "DST_Military",
        "DST_Sacred",
        "DST_TheLabyrinth",
        "DST_SacredAltar",
        "DST_AtriumMaze",
    },
    numoptionaltasks = 8,
    optionaltasks = {
        -- 深层分支（TIER3→TIER4）
        "DST_SwampySinkhole",
        "DST_CaveSwamp",
        "DST_UndergroundForest",
        "DST_PleasantSinkhole",
        "DST_FungalNoiseForest",
        "DST_FungalNoiseMeadow",
        "DST_BatCloister",
        "DST_RabbitTown",
        "DST_RabbitCity",
        "DST_SpiderLand",
        "DST_RabbitSpiderWar",
        -- 特殊可选
        "DST_CentipedeCaveIslandTask",
        -- 潮湿天井
        "DST_SoggySinkhole",
        -- 遗迹可选扩展
        "DST_CaveJungle",
        "DST_MoreAltars",
        "DST_SacredDanger",
        "DST_MilitaryPits",
        "DST_MuddySacred",
        "DST_Residential2",
        "DST_Residential3",
    },
    -- 不设置 background_node_range，使用 DS 默认值（0~2 个背景节点填充随机资源）
    set_pieces = {
        DSTCaveSpawn = {
            tasks = {"DST_EntranceTask"},
            count = 1,
        },
    },
})

AddLevelPreInit("DST_CAVE", function(level)
end)
