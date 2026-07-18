
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

--------------------------<制作栏>--------------------------
local moonglassaxe = Recipe(
    "moonglassaxe",
    { 
        Ingredient("twigs", 2), 
        Ingredient("moonglass", 3, "images/dst_boss.xml"), 
    },
    RECIPETABS.DST_CELESTIAL, TECH.CELESTIAL_ONE
)
moonglassaxe.image = "moonglassaxe.tex"
moonglassaxe.atlas = "images/dst_boss.xml"

local glasscutter = Recipe(
    "glasscutter",
    { 
        Ingredient("boards", 1), 
        Ingredient("moonglass", 6, "images/dst_boss.xml"), 
    },
    RECIPETABS.DST_CELESTIAL, TECH.CELESTIAL_ONE
)
glasscutter.image = "glasscutter.tex"
glasscutter.atlas = "images/dst_boss.xml"

local turf_meteor = Recipe(
    "turf_meteor",
    { 
        Ingredient("moonrocknugget", 1, "images/dst_boss.xml"), 
        Ingredient("moonglass", 2, "images/dst_boss.xml"), 
    },
    RECIPETABS.TOWN, { SCIENCE = 0 }
)
turf_meteor.image = "turf_meteor.tex"
turf_meteor.atlas = "images/dst_boss.xml"

local turf_pebblebeach = Recipe(
    "turf_pebblebeach",
    { 
        Ingredient("rocks", 1), 
        Ingredient("log", 1), 
    },
    RECIPETABS.TOWN, { SCIENCE = 0 }
)
turf_pebblebeach.image = "turf_pebblebeach.tex"
turf_pebblebeach.atlas = "images/dst_boss.xml"

local turf_shellbeach = Recipe(
    "turf_shellbeach",
    { 
        Ingredient("rocks", 1), 
        Ingredient("slurtle_shellpieces", 1), 
    },
    RECIPETABS.TOWN, { SCIENCE = 0 }
)
turf_shellbeach.image = "turf_shellbeach.tex"
turf_shellbeach.atlas = "images/dst_boss.xml"

-- DST 移植地皮配方（从 DST recipes.lua 移植）
local turf_archive = Recipe(
    "turf_archive",
    { 
        Ingredient("moonrocknugget", 1, "images/dst_boss.xml"), 
        Ingredient("thulecite_pieces", 1), 
    },
    RECIPETABS.TOWN, TECH.LOST
)
turf_archive.image = "turf_archive.tex"
turf_archive.atlas = "images/turf_archive.xml"

local turf_fungus_moon = Recipe(
    "turf_fungus_moon",
    { 
        Ingredient("moonrocknugget", 1, "images/dst_boss.xml"), 
        Ingredient("moonglass", 2, "images/dst_boss.xml"), 
    },
    RECIPETABS.TOWN, TECH.LOST
)
turf_fungus_moon.image = "turf_fungus_moon.tex"
turf_fungus_moon.atlas = "images/turf_fungus_moon.xml"

local turf_monkey_ground = Recipe(
    "turf_monkey_ground",
    { 
        Ingredient("rocks", 1), 
        Ingredient("marble", 1), 
    },
    RECIPETABS.TOWN, TECH.LOST
)
turf_monkey_ground.image = "turf_monkey_ground.tex"
turf_monkey_ground.atlas = "images/turf_monkey_ground.xml"

----------------<DST 洞穴地皮测试配方>----------------
local turf_vent = Recipe(
    "turf_vent",
    { 
        Ingredient("rocks", 2), 
        Ingredient("nitre", 1), 
    },
    RECIPETABS.TOWN, TECH.LOST
)
turf_vent.image = "turf_vent.tex"
turf_vent.atlas = "images/turf_vent.xml"

local turf_vault = Recipe(
    "turf_vault",
    { 
        Ingredient("thulecite_pieces", 2), 
        Ingredient("cutstone", 2), 
    },
    RECIPETABS.TOWN, TECH.LOST
)
turf_vault.image = "turf_vault.tex"
turf_vault.atlas = "images/turf_vault.xml"

-- 档案馆奖励配方（蓝图驱动）
local turfcraftingstation = Recipe(
    "turfcraftingstation",
    {
        Ingredient("thulecite", 1),
        Ingredient("cutstone", 3),
        Ingredient("wetgoop", 1),
    },
    RECIPETABS.TOWN, TECH.LOST, nil, "turfcraftingstation_placer"
)
turfcraftingstation.image = "turfcraftingstation.tex"
turfcraftingstation.atlas = "images/turfcraftingstation.xml"

local archive_resonator_item = Recipe(
    "archive_resonator_item",
    { 
        Ingredient("moonrocknugget", 1, "images/dst_boss.xml"), 
        Ingredient("thulecite", 1), 
    },
    RECIPETABS.SCIENCE, TECH.LOST
)
archive_resonator_item.image = "archive_resonator.tex"
archive_resonator_item.atlas = "images/archive_resonator.xml"

local refined_dust = Recipe(
    "refined_dust",
    { 
        Ingredient("goldnugget", 2), 
        Ingredient("rocks", 2), 
        Ingredient("nitre", 1), 
    },
    RECIPETABS.REFINE, TECH.LOST
)
refined_dust.image = "rf_dust.tex"
refined_dust.atlas = "images/rf_dust.xml"

local malbatross_feathered_weave = Recipe(
    "malbatross_feathered_weave",
    { 
        Ingredient("malbatross_feather", 6, "images/dst_boss.xml"), 
        Ingredient("silk", 1), 
    },
    RECIPETABS.REFINE, TECH.LOST
)
malbatross_feathered_weave.image = "malbatross_feathered_weave.tex"
malbatross_feathered_weave.atlas = "images/dst_boss.xml"

local malbatross_sail = Recipe(
    "malbatross_sail",
    { 
        Ingredient("log", 3), 
        Ingredient("rope", 3), 
        Ingredient("malbatross_feathered_weave", 4, "images/dst_boss.xml"), 
    },
    RECIPETABS.NAUTICAL, TECH.LOST
)
malbatross_sail.image = "malbatross_sail.tex"
malbatross_sail.atlas = "images/dst_boss.xml"

local dragonflyfurnace = Recipe(
    "dragonflyfurnace",
    {
        Ingredient("dragon_scales", 1),
        Ingredient("redgem", 2),
        Ingredient("charcoal", 10),
    },
    RECIPETABS.TOWN, TECH.LOST, RECIPE_GAME_TYPE.COMMON, "dragonflyfurnace_placer"
)
dragonflyfurnace.image = "dragonflyfurnace.tex"
dragonflyfurnace.atlas = "images/dst_boss.xml"

local succulent_potted = Recipe(
    "succulent_potted",
    {
        Ingredient("succulent_picked", 2, "images/dst_boss.xml"),
        Ingredient("cutstone", 1),
    },
    RECIPETABS.TOWN, TECH.NONE, RECIPE_GAME_TYPE.COMMON, "succulent_potted_placer", 1
)
succulent_potted.atlas = "images/dst_boss.xml"
succulent_potted.image = "succulent_potted.tex"

local chesspiece_rook = Recipe(
    "chesspiece_rook",
    { 
        Ingredient("marble", 1), 
    },
    RECIPETABS.TOWN, TECH.LOST
)
chesspiece_rook.image = "chesspiece_rook.tex"
chesspiece_rook.atlas = "images/dst_boss.xml"

local chesspiece_knight = Recipe(
    "chesspiece_knight",
    { 
        Ingredient("marble", 1), 
    },
    RECIPETABS.TOWN, TECH.LOST
)
chesspiece_knight.image = "chesspiece_knight.tex"
chesspiece_knight.atlas = "images/dst_boss.xml"

local chesspiece_bishop = Recipe(
    "chesspiece_bishop",
    { 
        Ingredient("marble", 1), 
    },
    RECIPETABS.TOWN, TECH.LOST
)
chesspiece_bishop.image = "chesspiece_bishop.tex"
chesspiece_bishop.atlas = "images/dst_boss.xml"

local oceantree_pillar = Recipe(
    "oceantree_pillar",
    { },
    RECIPETABS.FARM, TECH.NONE, RECIPE_GAME_TYPE.COMMON, "oceantree_pillar_placer", 2.5
)
oceantree_pillar.image = "oceantree_pillar_small.tex"
oceantree_pillar.atlas = "images/oceantree_pillar_small.xml"


local bathbomb = Recipe(
    "bathbomb",
    { 
        Ingredient("moon_tree_blossom", 6, "images/dst_boss.xml"), 
        Ingredient("nitre", 1), 
    },
    RECIPETABS.DST_CELESTIAL, TECH.CELESTIAL_ONE
)
bathbomb.image = "bathbomb.tex"
bathbomb.atlas = "images/dst_boss.xml"

--------------------------<蘑菇相关配方>--------------------------
-- 蘑菇帽配方
local repice_blue_mushroomhat = Recipe("blue_mushroomhat", {Ingredient("blue_cap", 6)}, RECIPETABS.DRESS, TECH.LOST)
repice_blue_mushroomhat.atlas = "images/hat_blue_mushroom.xml"
repice_blue_mushroomhat.image = "hat_blue_mushroom.tex"

local repice_red_mushroomhat = Recipe("red_mushroomhat", {Ingredient("red_cap", 6)}, RECIPETABS.DRESS, TECH.LOST)
repice_red_mushroomhat.atlas = "images/hat_red_mushroom.xml"
repice_red_mushroomhat.image = "hat_red_mushroom.tex"

local repice_green_mushroomhat = Recipe("green_mushroomhat", {Ingredient("green_cap", 6)}, RECIPETABS.DRESS, TECH.LOST)
repice_green_mushroomhat.atlas = "images/hat_green_mushroom.xml"
repice_green_mushroomhat.image = "hat_green_mushroom.tex"

-- 蘑菇灯：shroom_skin + fertilizer
local mushroom_light = Recipe(
    "mushroom_light",
    {
        Ingredient("shroom_skin", 1, "images/shroom_skin.xml"),
        Ingredient("fertilizer", 1),
    },
    RECIPETABS.LIGHT, TECH.NONE, RECIPE_GAME_TYPE.COMMON, "mushroom_light_placer", 1
)
mushroom_light.image = "mushroom_light.tex"
mushroom_light.atlas = "images/mushroom_light.xml"

-- 蘑菇灯2号：shroom_skin + fertilizer + boards
local mushroom_light2 = Recipe(
    "mushroom_light2",
    {
        Ingredient("shroom_skin", 1, "images/shroom_skin.xml"),
        Ingredient("fertilizer", 1),
        Ingredient("boards", 1),
    },
    RECIPETABS.LIGHT, TECH.NONE, RECIPE_GAME_TYPE.COMMON, "mushroom_light2_placer", 1
)
mushroom_light2.image = "mushroom_light2.tex"
mushroom_light2.atlas = "images/mushroom_light2.xml"

-- 孢子吹箭：cutreeds + goldnugget + feather_canary
local blowdart_yellow = Recipe(
    "blowdart_yellow",
    {
        Ingredient("cutreeds", 2),
        Ingredient("goldnugget", 1),
        Ingredient("feather_canary", 1, "images/feather_canary.xml"),
    },
    RECIPETABS.WAR, TECH.SCIENCE_TWO
)
blowdart_yellow.image = "blowdart_yellow.tex"
blowdart_yellow.atlas = "images/blowdart_yellow.xml"


  --local dug_rock_avocado_bush = Recipe("dug_rock_avocado_bush",{ }, RECIPETABS.SCIENCE, {SCIENCE=0})

  --local rock_avocado_fruit_ripe = Recipe("rock_avocado_fruit_ripe",{ }, RECIPETABS.SCIENCE, {SCIENCE=0}, nil, nil, nil, 10)
  --[[
--未完成的实验
  local moon_device_construction1 = Recipe("moon_device_construction1", {Ingredient("transistor", 2)}, RECIPETABS.SCIENCE, {SCIENCE=0}, "moon_device_construction1_placer", 2.5)
  moon_device_construction1.atlas = "images/dst_boss.xml"
--地图上找的
  local moon_altar_icon = Recipe("moon_altar_icon",{ }, RECIPETABS.SCIENCE, {SCIENCE=0})
  local moon_altar_ward = Recipe("moon_altar_ward",{ }, RECIPETABS.SCIENCE, {SCIENCE=0})
--帝王蟹掉落的
  local moon_altar_crown = Recipe("moon_altar_crown",{ }, RECIPETABS.SCIENCE, {SCIENCE=0})
  --]]
--------------------------<用于旧档的测试功能>--------------------------
if GetModConfigData("beta") == true then
    local klaus_sack = Recipe(
        "klaus_sack",
        { },
        RECIPETABS.REFINE, { SCIENCE = 0 }
    )
    klaus_sack.image = "klaus_sack.tex"
        klaus_sack.atlas = "images/dst_boss.xml"

    local deer_antler1 = Recipe(
        "deer_antler1",
        { },
        RECIPETABS.REFINE, { SCIENCE = 0 }
    )
    deer_antler1.image = "deer_antler1.tex"
        deer_antler1.atlas = "images/dst_boss.xml"

    local klaussackkey = Recipe(
        "klaussackkey",
        { },
        RECIPETABS.REFINE, { SCIENCE = 0 }
    )
    klaussackkey.image = "klaussackkey.tex"
        klaussackkey.atlas = "images/dst_boss.xml"

    local moon_device = Recipe(
        "moon_device",
        { 
            Ingredient("cutstone", 2),
            Ingredient("boards", 2),
        },
        RECIPETABS.REFINE, { SCIENCE = 0 }, RECIPE_GAME_TYPE.COMMON, "moon_device_placer", 1.5
    )
    moon_device.image = "moon_device.tex"
        moon_device.atlas = "images/dst_boss.xml"

    local hotspring = Recipe(
        "hotspring",
        { },
        RECIPETABS.REFINE, { SCIENCE = 0 }, RECIPE_GAME_TYPE.COMMON, "hotspring_placer", 1.5
    )
    hotspring.image = "hotspring.tex"
        hotspring.atlas = "images/dst_boss.xml"

    local oasislake = Recipe(
        "oasislake",
        { },
        RECIPETABS.REFINE, { SCIENCE = 0 }, RECIPE_GAME_TYPE.COMMON, "oasislake_placer", 1.5
    )
    oasislake.image = "oasislake.tex"
        oasislake.atlas = "images/dst_boss.xml"

    local moonbase = Recipe(
        "moonbase",
        { },
        RECIPETABS.REFINE, { SCIENCE = 0 }
    )
    moonbase.image = "moonbase.tex"
        moonbase.atlas = "images/dst_boss.xml"

    local shadowheart = Recipe(
        "shadowheart",
        { },
        RECIPETABS.REFINE, { SCIENCE = 0 }
    )
    shadowheart.image = "shadowheart.tex"
        shadowheart.atlas = "images/dst_boss.xml"

    local sculpture_rooknose = Recipe(
        "sculpture_rooknose",
        { },
        RECIPETABS.REFINE, { SCIENCE = 0 }
    )
    sculpture_rooknose.image = "sculpture_rooknose.tex"
        sculpture_rooknose.atlas = "images/dst_boss.xml"

    local sculpture_knighthead = Recipe(
        "sculpture_knighthead",
        { },
        RECIPETABS.REFINE, { SCIENCE = 0 }
    )
    sculpture_knighthead.image = "sculpture_knighthead.tex"
        sculpture_knighthead.atlas = "images/dst_boss.xml"

    local sculpture_bishophead = Recipe(
        "sculpture_bishophead",
        { },
        RECIPETABS.REFINE, { SCIENCE = 0 }
    )
    sculpture_bishophead.image = "sculpture_bishophead.tex"
        sculpture_bishophead.atlas = "images/dst_boss.xml"

    -- 食物buff
    local pepper = Recipe(
        "pepper",
        { },
        RECIPETABS.TOWN, { SCIENCE = 0 }
    )
    pepper.image = "pepper.tex"
        pepper.atlas = "images/dst_boss.xml"

    local onion = Recipe(
        "onion",
        { },
        RECIPETABS.TOWN, { SCIENCE = 0 }
    )
    onion.image = "onion.tex"
        onion.atlas = "images/dst_boss.xml"

    local jellybean = Recipe(
        "jellybean",
        { },
        RECIPETABS.TOWN, { SCIENCE = 0 }
    )
    jellybean.image = "jellybean.tex"
        jellybean.atlas = "images/dst_boss.xml"

    local bonesoup = Recipe(
        "bonesoup",
        { },
        RECIPETABS.TOWN, { SCIENCE = 0 }
    )
    bonesoup.image = "bonesoup.tex"
        bonesoup.atlas = "images/dst_boss.xml"

    local frogfishbowl = Recipe(
        "frogfishbowl",
        { },
        RECIPETABS.TOWN, { SCIENCE = 0 }
    )
    frogfishbowl.image = "frogfishbowl.tex"
        frogfishbowl.atlas = "images/dst_boss.xml"

    local pepperpopper = Recipe(
        "pepperpopper",
        { },
        RECIPETABS.TOWN, { SCIENCE = 0 }
    )
    pepperpopper.image = "pepperpopper.tex"
        pepperpopper.atlas = "images/dst_boss.xml"

    local dragonchilisalad = Recipe(
        "dragonchilisalad",
        { },
        RECIPETABS.TOWN, { SCIENCE = 0 }
    )
    dragonchilisalad.image = "dragonchilisalad.tex"
        dragonchilisalad.atlas = "images/dst_boss.xml"

    local glowberrymousse = Recipe(
        "glowberrymousse",
        { },
        RECIPETABS.TOWN, { SCIENCE = 0 }
    )
    glowberrymousse.image = "glowberrymousse.tex"
        glowberrymousse.atlas = "images/dst_boss.xml"

    local freshfruitcrepes = Recipe(
        "freshfruitcrepes",
        { },
        RECIPETABS.TOWN, { SCIENCE = 0 }
    )
    freshfruitcrepes.image = "freshfruitcrepes.tex"
        freshfruitcrepes.atlas = "images/dst_boss.xml"

    local voltgoatjelly = Recipe(
        "voltgoatjelly",
        { },
        RECIPETABS.TOWN, { SCIENCE = 0 }
    )
    voltgoatjelly.image = "voltgoatjelly.tex"
        voltgoatjelly.atlas = "images/dst_boss.xml"

    -- 稻草人：南瓜 + 木板 + 草
    local scarecrow = Recipe(
        "scarecrow",
        {
            Ingredient("pumpkin", 1),
            Ingredient("boards", 3),
            Ingredient("cutgrass", 3),
        },
        RECIPETABS.TOWN, TECH.SCIENCE_ONE, nil, "scarecrow_placer", 1.5
    )
    scarecrow.image = "scarecrow.tex"
    scarecrow.atlas = "images/scarecrow.xml"

    --[[
    local sculpture_bishop = Recipe("sculpture_bishop",{ }, RECIPETABS.REFINE, {SCIENCE=0})
      sculpture_bishop.atlas = "images/dst_boss.xml"
    local sculpture_knight = Recipe("sculpture_knight",{ }, RECIPETABS.REFINE, {SCIENCE=0})
      sculpture_knight.atlas = "images/dst_boss.xml"
    local sculpture_rook = Recipe("sculpture_rook",{ }, RECIPETABS.REFINE, {SCIENCE=0})
      sculpture_rook.atlas = "images/dst_boss.xml"

      local  = Recipe("",{ }, RECIPETABS.REFINE, {SCIENCE=0})
        .atlas = "images/dst_boss.xml"

    --]]
end

-- 月岛科技6大碎片（测试用，固定放在建筑栏 RECIPETABS.TOWN）
for _, name in ipairs({"idol", "glass", "seed", "crown", "ward", "icon"}) do
    local r = Recipe("moon_altar_"..name, { }, RECIPETABS.TOWN, { SCIENCE = 0 })
    r.image = "moon_altar_"..name..".tex"
    r.atlas = "images/dst_boss.xml"
end

-- 月亮虹吸器（测试用，1 石砖+1 树枝，科学栏）
do
    local r = Recipe("moon_device_construction1",
        { Ingredient("cutstone", 1), Ingredient("twigs", 1) },
        RECIPETABS.SCIENCE, { SCIENCE = 0 },
        RECIPE_GAME_TYPE.COMMON, "moon_device_construction1_placer", 2.5
    )
    r.image = "moon_device.tex"
    r.atlas = "images/dst_boss.xml"
    print("[RECIPE] moon_device test recipe added")
end

-- 彩虹宝石：6 色宝石合成（DST transmute_opalpreciousgem 移植）
local opalpreciousgem_recipe = Recipe(
    "opalpreciousgem",
    {
        Ingredient("redgem", 1),
        Ingredient("bluegem", 1),
        Ingredient("purplegem", 1),
        Ingredient("orangegem", 1),
        Ingredient("yellowgem", 1),
        Ingredient("greengem", 1),
    },
    RECIPETABS.MAGIC, TECH.LOST
)
opalpreciousgem_recipe.image = "opalgem.tex"
opalpreciousgem_recipe.atlas = "images/opalgem.xml"
--[[
-- 唤月者法杖不能制作，只能拆解，不注册配方
local opalstaff_deconst = Recipe("opalstaff",{
    Ingredient("nightmarefuel", 4),
    Ingredient("livinglog", 2),
    Ingredient("opalpreciousgem", 1, "images/dst_boss.xml"),
}, RECIPETABS.MAGIC, TECH.LOST)
  opalstaff_deconst.atlas = "images/dst_boss.xml"
--]]

----------------<绝望石基础材料配方>----------------
-- 基础材料，无需蓝图解锁
----------------<绝望石基础材料配方>----------------
-- 基础材料，无需蓝图解锁
local dreadstone_recipe = Recipe("dreadstone", {
    Ingredient("nightmarefuel", 5),
    Ingredient("cutstone", 2),
}, RECIPETABS.MAGIC, TECH.SCIENCE_ONE)
    dreadstone_recipe.image = "dreadstone.tex"
    dreadstone_recipe.atlas = "images/dreadstone.xml"

local horrorfuel_recipe = Recipe("horrorfuel", {
    Ingredient("nightmarefuel", 2),
    Ingredient("livinglog", 1),
}, RECIPETABS.MAGIC, TECH.SCIENCE_ONE)
    horrorfuel_recipe.image = "horrorfuel.tex"
    horrorfuel_recipe.atlas = "images/horrorfuel.xml"

----------------<绝望石套装配方（蓝图解锁）>----------------
-- 蓝图从 Daywalker 掉落，学习后在暗影操控器附近制作

----------------<绝望石套装配方（蓝图解锁）>----------------
-- 蓝图从 Daywalker 掉落，学习后在暗影操控器附近制作

local armordreadstone_recipe = Recipe("armordreadstone", {
    Ingredient("dreadstone", 6, "images/dreadstone.xml"),
    Ingredient("horrorfuel", 3, "images/horrorfuel.xml"),
}, RECIPETABS.MAGIC, TECH.LOST)
    armordreadstone_recipe.image = "armordreadstone.tex"
    armordreadstone_recipe.atlas = "images/armordreadstone.xml"
    armordreadstone_recipe.nounlock = true

local dreadstonehat_recipe = Recipe("dreadstonehat", {
    Ingredient("dreadstone", 4, "images/dreadstone.xml"),
    Ingredient("horrorfuel", 2, "images/horrorfuel.xml"),
}, RECIPETABS.MAGIC, TECH.LOST)
    dreadstonehat_recipe.image = "dreadstonehat.tex"
    dreadstonehat_recipe.atlas = "images/dreadstonehat.xml"
    dreadstonehat_recipe.nounlock = true

local wall_dreadstone_item_recipe = Recipe("wall_dreadstone_item", {
    Ingredient("dreadstone", 2, "images/dreadstone.xml"),
}, RECIPETABS.MAGIC, TECH.LOST)
    wall_dreadstone_item_recipe.image = "wall_dreadstone.tex"
    wall_dreadstone_item_recipe.atlas = "images/wall_dreadstone.xml"
    wall_dreadstone_item_recipe.nounlock = true

----------------<远古钥匙配方>----------------
-- 毁灭之种 + 铥矿 → 远古钥匙
local atrium_key_recipe = Recipe("atrium_key", {
    Ingredient("cave_regenerator", 1),
    Ingredient("thulecite", 3),
}, RECIPETABS.ANCIENT, TECH.ANCIENT_TWO)
    atrium_key_recipe.image = "atrium_key.tex"
    atrium_key_recipe.atlas = "images/dst_boss.xml"

----------------<铥矿捕虫网配方（蓝图解锁）>----------------
local thulecitebugnet_recipe = Recipe("thulecitebugnet", {
    Ingredient("thulecite", 3),
    Ingredient("thulecite_pieces", 2),
}, RECIPETABS.ANCIENT, TECH.ANCIENT_TWO)
    thulecitebugnet_recipe.nounlock = true
