GLOBAL.setmetatable(env,{
    __index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end,
    __newindex=function(t,k,v) GLOBAL.rawset(GLOBAL,k,v) rawset(t,k,v) end
})
if GLOBAL.PLATFORM == "Android" then GLOBAL.SJ = true else GLOBAL.SJ = false end --手机判定


-- ==================== DS 兼容：DST 特有方法补丁 ====================
-- DS 没有 SetPhysicsRadiusOverride，补充为空操作
if rawget(GLOBAL, "EntityScript") and not GLOBAL.EntityScript.SetPhysicsRadiusOverride then
    GLOBAL.EntityScript.SetPhysicsRadiusOverride = function() end
end

-- ==================== 天体制作栏 ====================
RECIPETABS.DST_CELESTIAL = {
    str = "DST_CELESTIAL",
    sort = 700,
    priority = 1,
    icon = "tab_celestial.tex",
    icon_atlas = "images/tab_celestial.xml",
}

-- ==================== 天体科技树 ====================
GLOBAL.TECH = GLOBAL.TECH or {}
GLOBAL.TECH.CELESTIAL_ONE = { CELESTIAL = 1 }
GLOBAL.TECH.CELESTIAL_THREE = { CELESTIAL = 3 }
GLOBAL.TECH.CELESTIAL_NONE = { CELESTIAL = 0 }

GLOBAL.TUNING = GLOBAL.TUNING or {}
GLOBAL.TUNING.PROTOTYPER_TREES = GLOBAL.TUNING.PROTOTYPER_TREES or {}
GLOBAL.TUNING.PROTOTYPER_TREES.MOON_ALTAR = { CELESTIAL = 1 }
GLOBAL.TUNING.PROTOTYPER_TREES.MOON_ALTAR_FULL = { CELESTIAL = 3 }
GLOBAL.TUNING.PROTOTYPER_TREES.MOON_ALTAR_MAX  = { CELESTIAL = 4 }

-- ==================== 棕榈锥树 TUNING ====================
GLOBAL.TUNING.PALMCONETREE_CHOPS_SMALL = 5
GLOBAL.TUNING.PALMCONETREE_CHOPS_NORMAL = 10
GLOBAL.TUNING.PALMCONETREE_CHOPS_TALL = 15

-- ==================== 梦魇疯猪 Daywalker 注册 ====================
AddPrefabPostInit("daywalkerspawningground", function(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = rawget(GLOBAL, "TheWorld")
        if theWorld == nil then return end
        theWorld:PushEvent("ms_registerdaywalkerspawningground", inst)
    end)
end)

-- ==================== DST_CAVE 犀牛宝箱替换 ====================
-- minotaurchest 没有 Physics 组件，FindEntities 无法空间查找
-- 改用 PostInit 在 chest 创建时直接替换 cave_regenerator → atrium_key
-- 标记由 minotaur_spawner.lua 的死亡事件设置
AddPrefabPostInit("minotaurchest", function(inst)
    local dead_pos = rawget(GLOBAL, "_DST_CAVE_MINOTAUR_DEAD")
    if dead_pos then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = x - dead_pos.x
        local dz = z - dead_pos.z
        if dx*dx + dz*dz < 400 then  -- 20 单位内
            rawset(GLOBAL, "_DST_CAVE_MINOTAUR_DEAD", nil)
            inst:DoTaskInTime(0, function()
                if inst.components and inst.components.container then
                    for i = 1, inst.components.container:GetNumSlots() do
                        local item = inst.components.container:GetItemInSlot(i)
                        if item and item.prefab == "cave_regenerator" then
                            item:Remove()
                        end
                    end
                    local key = SpawnPrefab("atrium_key")
                    if key then
                        inst.components.container:GiveItem(key)
                    end
                end
            end)
        end
    end
end)

-- ==================== GetTheWorld 实体注入 ====================
-- DS 的 PrefabFiles 脚本中 GLOBAL/TheWorld 不可用（strict.lua 保护）
-- 通过 AddPrefabPostInit 立即注入 inst.GetTheWorld 惰性闭包
-- 使用 rawget(GLOBAL, "TheWorld") 绕过 strict.lua 的 __index 拦截
local _inject_getworld_prefabs = {
    -- tree_rocks.lua
    "tree_rock1", "tree_rock2",
    "tree_rock1_short", "tree_rock1_normal",
    "tree_rock2_short", "tree_rock2_normal",
    -- archive_chandelier.lua
    "archive_chandelier", "vault_chandelier", "vault_crawler_chandelier",
    -- archive_lockbox.lua
    "archive_lockbox", "archive_lockbox_dispencer",
    -- archive_orchestrina_main.lua
    "archive_orchestrina_main", "archive_orchestrina_small",
    -- archive_props.lua
    "archive_security_desk", "archive_switch", "archive_switch_base",
    "archive_security_waypoint", "archive_portal",
}
for _, prefab_name in ipairs(_inject_getworld_prefabs) do
    AddPrefabPostInit(prefab_name, function(inst)
        inst.GetTheWorld = function() return _cave_world end
    end)
end

-- ==================== 暴动循环注册 ====================
-- 暴动系统注册已移至 archive_hooks.lua（AddPrefabPostInit("cave")），避免重复
-- 梦魇疯猪生成器 daywalkerspawner 也已移至 cave postinit，见 archive_hooks.lua

-- 覆写 LoadPrefabFile：确保多返回值的 prefab 文件的所有实体都被 mod.Prefabs 捕获
-- DS 的 require() 只能拿到第一个返回值，而 LoadPrefabFile 内部用 {fn()} 捕获了全部
-- 这里在原版基础上补充 mod.Prefabs，使 meta-prefab 能列出所有实体
local _orig_LoadPrefabFile = GLOBAL.LoadPrefabFile
GLOBAL.LoadPrefabFile = function(filename)
    local ret = _orig_LoadPrefabFile(filename)
    if ret then
        for _, prefab in ipairs(ret) do
            if type(prefab) == "table" and prefab.name then
                env.Prefabs[prefab.name] = prefab
            end
        end
    end
    return ret
end

-- TUNING 常量必须在 PrefabFiles 之前加载，否则 prefab fn() 执行时 TUNING 尚未定义
modimport("scripts/dst_tuning.lua")
-- dst_global.lua 也必须在 PrefabFiles 之前加载，确保全局兼容函数（FindPlayersInRange/MakeGiantCharacterPhysics 等）可用
modimport("scripts/dst_global.lua")

PrefabFiles = 
{
  "dst_fx",
  "toadstool/red_mushroomhat",
  "toadstool/green_mushroomhat",
  "toadstool/blue_mushroomhat",
  -- "new_hats", -- 已拆分为独立 prefab
  "turf_meteor",
  "mushtree_spores", -- 孢子（红/绿/蓝月），蘑菇帽产出  
  "rock_break_fx", --特效
  -- "fx", -- 已移除，改用 dst_fx.lua
--天体英雄
  "alterguardian/alterguardian_phase1",
  "alterguardian/alterguardian_phase2",
  "alterguardian/alterguardian_phase3",
  "alterguardian/alterguardian_summon_fx",
  "alterguardian/gestalt_alterguardian_projectile",
  "alterguardian/gestalt",
  "alterguardian/gestalt_head",
  "alterguardian/alterguardian_phase2spike",
  "alterguardian/alterguardian_phase3circle",
  "alterguardian/alterguardian_phase3trap",
  "alterguardian/alterguardian_laser",
  "alterguardian/alterguardian_phase3dead",
  "alterguardian/shadowmeteor",
  "alterguardian/alterguardianhat",
  "alterguardian/alterguardian_hat_equipped",
  --"chesspiece_guardianphase3",
  "alterguardian/moon_device", --月亮虹吸器
  
  "moonisland/hotspring", --温泉
  "moonisland/hotspring_placer",
  "moonisland/glasscutter",
  "moonisland/moonglassaxe",
  "moonisland/moonglass",

--蚁狮
  "antlion/antlion",
  "antlion/antlion_sinkhole",
  "antlion/antlion_spawner",
  "antlion/antliontrinket",
  "antlion/sand_spike",
  "antlion/glass_spike",
  "antlion/oasislake",
  "antlion/oasislake_placer",
--邪天翁
  "malbatross/malbatross",
  "malbatross/malbatross_feather",
  "malbatross/malbatross_feathered_weave",
  "malbatross/malbatross_beak",
  "malbatross/malbatross_sail",
--月台
  "moonbase/moonbase",
  "moonbase/moonrocknugget",
  "moonbase/positronbeam",
  "moonbase/stafflight",
  "moonbase/moonhound",
  "moonbase/moonpig",
  "moonbase/gargoyles",
  "moonbase/opalstaff",
  "moonbase/opalpreciousgem",
--联机龙蝇
	"dragonfly/dragonfly2",
	"dragonfly/dragonfly_spawner",
  "dragonfly/lavae",
	"dragonfly/lavae_move_fx",	
	"dragonfly/lava_pond",
	"dragonfly/scorchedground",
	"dragonfly/scorched_skeleton",
	"dragonfly/burnt_marsh_bush",
	"dragonfly/lavae_pet",
	"dragonfly/lavae_egg",
	"dragonfly/lavae_tooth",
	"dragonfly/lavae_cocoon",
	"dragonfly/dragonfurnace",
--克劳斯
  "klaus/deer",
  "klaus/deer_antler",
  "klaus/deer_fx",
  "klaus/klaus",
  "klaus/klaus_sack",
--暗影三基佬
  "shadowchess/sculpture_pieces",
  "shadowchess/sculptures",
  "shadowchess/shadowchesspieces",
  "shadowchess/shadowheart",
  "shadowchess/chesspieces_shadow", --三基佬雕像
--食物buff
  "foodbuffs",
  "dst_foods",
  "dst_veggies",
  
  "deerclops/deerclops_laser", --激光巨鹿
--水中木
  "moonisland/oceantree_pillar",
  "moonisland/oceanvine",
  "moonisland/succulent_plant", --多肉植物
  "moonisland/succulent_potted",--多肉盆栽

  
  "moonisland/moontree", --月树
  "moonisland/planted_tree", --月树苗
  "moonisland/moontree_blossom", --月树花
  "moonisland/moonbutterfly", --月娥
  "moonisland/moonbutterflywings", --月娥翅膀
  "moonisland/moon_rocks", --月光玻璃
  "moonisland/moonrockseed", --月岩种子
  "moonisland/bathbomb",--浴球
  "moonisland/rock_avocado_bush", --石果树
  "moonisland/rock_avocado_fruit", --石果
  "moonisland/sapling_moon", --月岛树枝
  "moonisland/moon_fissure", --天体裂隙
  "moonisland/moon_altar_pieces", --月岛科技
  "moonisland/moonspider", --破碎蜘蛛
  "moonisland/moonspider_spike", --蜘蛛刺
  "moonisland/moonspiderden", --蜘蛛巢
  "moonisland/moon_altar", --三个雕像
  "moonisland/moon_altar_link", --链接
  "moonisland/moon_altar_break",
  
--月岛生态（海岸区）
  "moonisland/lightcrab", --光蟹
  "moonisland/trap_starfish", --海星陷阱（包含 dug_trap_starfish）
  "moonisland/dead_sea_bones", --海骨
--月岛生态（内陆区）
  "cave/moonglass_stalactites", --月玻璃钟乳石（3种）
  "moonisland/fruitdragon", --火龙果蜥蜴
--月岛生态（草原/森林区动物）
  "moonisland/carrat", --胡萝卜鼠（包含 carrat_planted）
  "moonisland/lightflier", --光飞虫
  "moonisland/lightflier_flower", --光飞虫花
  "moonisland/lunar_grazer", --月辔
--暗影织影者
  "atrium/atrium_gate",
  "atrium/atrium_gate_activatedfx",
  "atrium/atrium_gate_pulsesfx",
  "atrium/atrium_key",
  "atrium/atrium_fence",
  "atrium/atrium_light",
  "atrium/atrium_statue",
  "atrium/atrium_overgrowth",
  "atrium/atrium_pillar",
  "atrium/atrium_rubble",
  "atrium/damp_trail",
  "atrium/fossil_mound",
  "atrium/fossil_piece",
  "atrium/stalker",
  "atrium/stalker_minions",
  "atrium/fossil_spike",
  "atrium/fossil_spike2",
  "atrium/stalker_berry",
  "atrium/stalker_bulb",
  "atrium/stalker_ferns",
  "atrium/stalker_shield",
  "atrium/shadowchanneler",
  "atrium/mindcontroller",
--猴岛内容
  "monkey/monkeyhut",
  "monkey/monkeypillar",
  "monkey/monkeytail",
  "monkey/monkeyprojectile",
  "monkey/powdermonkey",
  "monkey/bananabush",
  "monkey/cutless",
  "monkey/monkey_smallhat",
  -- 猴岛挖起植物
  "monkey/dug_monkeytail",
  "monkey/dug_bananabush",
  -- 棕榈锥树（palmconetree.lua 一次性返回 4 个 prefab）
  "monkey/palmconetree",
  -- 猴岛物品
  "monkey/palmcone_seed",
  "monkey/palmcone_scale",
  -- DST 洞穴入口/出口
  "cave/dst_cave_entrance",
  "cave/dst_cave_exit",
  -- 月蘑菇群系
  "cave/mushtree_moon",
  "cave/mushtree_moonspore",
  "cave/moon_mushroom",
  -- 月蘑菇森林（Moon Mushroom Forest）
  "cave/cavelightmoon", --月光洞穴灯（3种 prefab）
  "cave/molebat", --无眼蝠
  "cave/molebathill", --无眼蝠巢穴
  "cave/cavelight", --洞穴灯（含 cavelight_small/tiny/atrium）
  "cave/mushgnome", --月蘑菇地精
  "cave/mushgnome_spawner", --月蘑菇地精生成器
  "cave/grotto_pool_big", --大月玻璃水池
  "cave/grotto_pool_small", --小月玻璃水池
  "cave/grotto_pool_moonglass", --可采月玻璃（3种）
  "cave/grotto_waterfall_big", --大瀑布装饰
  "cave/grotto_waterfall_small", --小瀑布（3种可采）
  "cave/grottopool_sfx", --水池音效实体
  -- 毒菌蛤蟆（含金丝雀/稻草人）
  "toadstool/toadstool",
  "toadstool/toadstool_cap",
  "toadstool/shroom_skin",
  "toadstool/canary_poisoned",
  "toadstool/canary",
  "toadstool/feather_canary",
  "toadstool/scarecrow",
  "toadstool/mushroom_light",
  "toadstool/sporecloud",
  "toadstool/mushroombomb",
  "toadstool/sporebomb",
  "toadstool/mushroomsprout",
  "toadstool/blowdart",
  -- DST 洞穴内容：档案馆装饰
  "cave/archive_pillar",
  "cave/archive_chandelier",
  "cave/archive_sound_area", -- 50%概率生成 archive_ambient_sfx
  "cave/archive_props", -- 包含 12 个 prefab（statue/rune/desk/pulse/switch/portal/rubble）
  -- DST 洞穴内容：档案馆 Step 2
  "cave/refined_dust",
  "cave/dustmothden",
  "cave/dustmoth",
  "cave/thulecitebugnet",
  "cave/cave_hole", --中庭/档案馆洞穴洞
  "cave/cookpot_archive", -- 提供 archive_cookpot
  "cave/archive_lockbox", -- 提供 archive_lockbox + archive_lockbox_dispencer + archive_dispencer_sfx + archive_lockbox_dispencer_temp
  "cave/archive_orchestrina_main", -- 提供 archive_orchestrina_main + _small + _base
  "cave/archive_centipede", -- 提供 archive_centipede + archive_centipede_husk
  -- DST 洞穴内容：档案馆 Step 3
  "cave/archive_resonator", -- 提供 archive_resonator + _item + _base + _placer
  "cave/retrofit_archiveteleporter",
  "cave/turfcraftingstation", -- 造地机 Terra Firma Tamper
  -- vent 区内容
  "cave/tree_rocks",       -- tree_rock1~2 系列（7个变种），multi prefab
  "cave/tree_rock_seed",
  "cave/tree_rock_sapling",
  "cave/tree_rock_chop",    -- 巨石枝砍伐特效
  "cave/tree_rock_fall",    -- 巨石枝倒塌特效
  "cave/cave_vents",        -- cave_vent_rock
  "cave/cave_vent_ground_fx",
  "cave/cave_vent_mite",
  "cave/cave_vent_mite_spawner",
  "cave/cave_fern_withered",
  "cave/pillar_cave_rock",      -- 洞穴岩石柱（装饰性障碍物）
  "cave/flower_cave_withered",        -- 仅 3 种枯萎变种（普通荧光花由 DS 原版 cave/objects/flower_cave 提供）
  "cave/wormlight_plant",          -- 荧光果植物（可采集 wormlight_lesser）
  "cave/wormlight_lesser",         -- 小荧光果（荧光果植物作物）
  "cave/batcave",                  -- 蝙蝠洞（生产蝙蝠，原版 cave/objects/batcave 隐藏版）
  -- 遗迹 respawner（ruins _spawner 系列，DS 简化版）
  "cave/ruins_spawners",
  -- 远古守卫者 spawner（已整合到 ruins_spawners）
  -- 梦魇疯猪 Daywalker（洞穴版）
  "daywalker/daywalker",
  "daywalker/daywalker_sinkhole",
  "daywalker/daywalkerspawningground",
  "daywalker/daywalker_pillar",
  "daywalker/shadow_leech",
  "daywalker/dreadstone",
  "daywalker/horrorfuel",
  "daywalker/armor_dreadstone",
  "daywalker/hat_dreadstone",
  "daywalker/wall_dreadstone",
  "daywalker/support_pillar_dreadstone_scaffold",
}

Assets = {
  -- ========== ANIM ==========
  Asset("ANIM", "anim/dst_turf.zip"),
  Asset("ANIM", "anim/burntground.zip"),
  -- 启蒙系统：月灵理智徽章（需从 DST 提取 status_sanity.zip）
  Asset("ANIM", "anim/status_sanity.zip"),
  
  Asset("ANIM", "anim/alterguardian/alterguardian_spike.zip"),
  Asset("ANIM", "anim/alterguardian/alterguardian_laser_hit_sparks_fx.zip"),
  Asset("ANIM", "anim/alterguardian/swap_altar_crownpiece.zip"), -- moon_altar_crown 碎片
  Asset("ANIM", "anim/moonisland/moon_altar_pieces.zip"), -- 祭坛碎片共用 bank
  Asset("ANIM", "anim/atrium/mind_control_overlay.zip"), --暗影织影者

  Asset("ANIM", "anim/cave/archive_centipede.zip"),
  Asset("ANIM", "anim/cave/archive_centipede_actions.zip"),
  Asset("ANIM", "anim/cave/archive_centipede_build.zip"),
  Asset("ANIM", "anim/cave/archive_knowledge_dispensary.zip"),
  Asset("ANIM", "anim/cave/archive_lockbox.zip"),
  Asset("ANIM", "anim/cave/archive_moon_statue.zip"),
  Asset("ANIM", "anim/cave/archive_orchestrina_main.zip"),
  Asset("ANIM", "anim/cave/archive_portal.zip"),
  Asset("ANIM", "anim/cave/archive_portal_base.zip"),
  Asset("ANIM", "anim/cave/archive_resonator.zip"),
  Asset("ANIM", "anim/cave/archive_runes.zip"),
  Asset("ANIM", "anim/cave/archive_security_desk.zip"),
  Asset("ANIM", "anim/cave/archive_security_pulse.zip"),
  Asset("ANIM", "anim/cave/archive_sigil.zip"),
  Asset("ANIM", "anim/cave/archive_switch.zip"),
  Asset("ANIM", "anim/cave/archive_switch_ground.zip"),
  Asset("ANIM", "anim/cave/archive_switch_ground_small.zip"),
  Asset("ANIM", "anim/cave/chandelier_archives.zip"),
  Asset("ANIM", "anim/cave/chandelier_fire.zip"),
  Asset("ANIM", "anim/cave/cookpot_archive.zip"),
  Asset("ANIM", "anim/cave/dst_cave_entrance.zip"),
  Asset("ANIM", "anim/cave/dst_cave_exit_rope.zip"),
  Asset("ANIM", "anim/cave/dustmoth.zip"),
  Asset("ANIM", "anim/cave/dustmothden.zip"),
  Asset("ANIM", "anim/cave/grotto_mushgnome.zip"),
  Asset("ANIM", "anim/cave/moon_cap.zip"),
  Asset("ANIM", "anim/cave/mushroom_spore_moon.zip"),
  Asset("ANIM", "anim/cave/mutatedmushroom_tree_build.zip"),
  Asset("ANIM", "anim/cave/pillar_archive.zip"),
  Asset("ANIM", "anim/cave/pillar_archive_broken.zip"),
  Asset("ANIM", "anim/cave/refined_dust.zip"),
  Asset("ANIM", "anim/thulecitebugnet.zip"),
  Asset("ANIM", "anim/cave/spore_moon.zip"),
  Asset("ANIM", "anim/cave/turf_archives.zip"),
  Asset("ANIM", "anim/cave/turf_fungus_moon.zip"),
  Asset("ANIM", "anim/cave/turfcraftingstation.zip"),
  Asset("ANIM", "anim/cave/molebat.zip"),
  Asset("ANIM", "anim/cave/molebathill.zip"),

  -- vent 区动画
  Asset("ANIM", "anim/tree_rock_short.zip"),
  Asset("ANIM", "anim/tree_rock_normal.zip"),
  Asset("ANIM", "anim/tree_rock2_short.zip"),
  Asset("ANIM", "anim/tree_rock2_normal.zip"),
  Asset("ANIM", "anim/tree_rock_fx.zip"),
  Asset("ANIM", "anim/tree_rock_seed.zip"),
  Asset("ANIM", "anim/cave_vent.zip"),
  Asset("ANIM", "anim/cave_vent_fx.zip"),
  Asset("ANIM", "anim/cave_vent_ground.zip"),
  Asset("ANIM", "anim/mite_cave.zip"),
  Asset("ANIM", "anim/mite_gland.zip"),
  Asset("ANIM", "anim/cave_ferns_withered_build.zip"),
  Asset("ANIM", "anim/bulb_plant_single_withered_build.zip"),
  Asset("ANIM", "anim/bulb_plant_double_withered_build.zip"),
  Asset("ANIM", "anim/bulb_plant_triple_withered_build.zip"),
  Asset("ANIM", "anim/bulb_plant_springy_withered_build.zip"),

  -- vent 区音效
  Asset("SOUND", "sound/rifts6.fsb"),
  Asset("SOUNDPACKAGE", "sound/rifts6.fev"),

  Asset("ANIM", "anim/lavaarena_staff_smoke_fx.zip"),
  Asset("ANIM", "anim/dst_leaves_canopy.zip"), --水中木叶片
 
  Asset("ANIM", "anim/monkey/bananabush.zip"),
  Asset("ANIM", "anim/monkey/cutless.zip"),
  Asset("ANIM", "anim/monkey/hat_monkey_small.zip"),
  -- kiki_basic / kiki_nightmare_skin: DS 原版已有，无需导入
  Asset("ANIM", "anim/monkey/dst_monkey_barrel.zip"),
  Asset("ANIM", "anim/monkey/monkey_small.zip"),
  Asset("ANIM", "anim/monkey/monkeyhut.zip"),
  Asset("ANIM", "anim/monkey/pillar_monkey.zip"),
  Asset("ANIM", "anim/monkey/reeds_monkeytails.zip"),
  Asset("ANIM", "anim/monkey/turf_monkey_ground.zip"),
  Asset("ANIM", "anim/monkey/dst_palmcone_short.zip"),
  Asset("ANIM", "anim/monkey/dst_palmcone_nomal.zip"),
  Asset("ANIM", "anim/monkey/dst_palmcone_tall.zip"),
  Asset("ANIM", "anim/monkey/palmcone_seed.zip"),
  Asset("ANIM", "anim/monkey/palmcone_scale.zip"),

  -- bulb_plant_single / bulb_plant_springy: DS 原版已有，无需导入
  Asset("ANIM", "anim/moonisland/butterfly_moon.zip"),
  Asset("ANIM", "anim/moonisland/carrat_basic.zip"),
  Asset("ANIM", "anim/moonisland/carrat_build.zip"),
  Asset("ANIM", "anim/moonisland/fishbones.zip"),
  Asset("ANIM", "anim/moonisland/fruit_dragon.zip"),
  Asset("ANIM", "anim/moonisland/fruit_dragon_build.zip"),
  Asset("ANIM", "anim/moonisland/fruit_dragon_ripe_build.zip"),
  Asset("ANIM", "anim/moonisland/lightcrab.zip"),
  Asset("ANIM", "anim/moonisland/lightflier.zip"),
  Asset("ANIM", "anim/moonisland/lunar_grazer.zip"),
  Asset("ANIM", "anim/moonisland/moonglass_bigwaterfall.zip"),
  Asset("ANIM", "anim/moonisland/moonglass_bigwaterfall_steam.zip"),
  Asset("ANIM", "anim/moonisland/moonglasspool_tile.zip"),
  Asset("ANIM", "anim/moonisland/star_trap.zip"),
  Asset("ANIM", "anim/moonisland/moonrock_shell.zip"), --月球陨石壳
  Asset("ANIM", "anim/moonisland/moonrock_seed.zip"), --月岩种子动画

  Asset("ANIM", "anim/moonbase/dst_gems.zip"),

  Asset("ANIM", "anim/player_attackss.zip"),
  Asset("ANIM", "anim/player_encumbered.zip"), --背大理石
  Asset("ANIM", "anim/player_encumbered_jump.zip"), --背大理石跳船
  --走得慢: DS 原版 data/anim 已有 player_groggy bank
  
  Asset("ANIM", "anim/toadstool/canary.zip"),
  Asset("ANIM", "anim/toadstool/canary_build.zip"),
  Asset("ANIM", "anim/toadstool/feather_canary.zip"),
  Asset("ANIM", "anim/toadstool/scarecrow.zip"),
  Asset("ANIM", "anim/toadstool/shadow_skinchangefx.zip"),
  Asset("ANIM", "anim/toadstool/new_blow_dart.zip"),
  Asset("ANIM", "anim/toadstool/new_swap_blowdart.zip"),
  Asset("ANIM", "anim/toadstool/new_swap_blowdart_pipe.zip"),
  Asset("ANIM", "anim/toadstool/toadstool_actions.zip"),
  Asset("ANIM", "anim/toadstool/toadstool_basic.zip"),
  Asset("ANIM", "anim/toadstool/toadstool_build.zip"),
  Asset("ANIM", "anim/toadstool/toadstool_dark_build.zip"),
  Asset("ANIM", "anim/toadstool/toadstool_dark_upg_build.zip"),
  Asset("ANIM", "anim/toadstool/toadstool_upg_build.zip"),

  -- 梦魇疯猪 Daywalker（洞穴版）
  Asset("ANIM", "anim/daywalker_build.zip"),
  Asset("ANIM", "anim/daywalker_buried.zip"),
  Asset("ANIM", "anim/daywalker_defeat.zip"),
  Asset("ANIM", "anim/daywalker_hole.zip"),
  Asset("ANIM", "anim/daywalker_imprisoned.zip"),
  Asset("ANIM", "anim/daywalker_phase1.zip"),
  Asset("ANIM", "anim/daywalker_phase2.zip"),
  Asset("ANIM", "anim/daywalker_phase3.zip"),
  Asset("ANIM", "anim/daywalker_pillar.zip"),
  Asset("ANIM", "anim/daywalker_swipe_fx.zip"),
  Asset("ANIM", "anim/shadow_leech.zip"),

  -- 梦魇疯猪掉落物
  Asset("ANIM", "anim/dreadstone.zip"),
  Asset("ANIM", "anim/horrorfuel.zip"),
  Asset("ANIM", "anim/armor_dreadstone.zip"),
  Asset("ANIM", "anim/hat_dreadstone.zip"),
  Asset("ANIM", "anim/wall_dreadstone.zip"),
  Asset("ANIM", "anim/support_pillar_dreadstone.zip"),

  -- 绝望石套装图片（后续由用户放入 .tex/.xml）
  Asset("IMAGE", "images/dreadstone.tex"),
  Asset("ATLAS", "images/dreadstone.xml"),
  Asset("IMAGE", "images/horrorfuel.tex"),
  Asset("ATLAS", "images/horrorfuel.xml"),
  Asset("IMAGE", "images/armordreadstone.tex"),
  Asset("ATLAS", "images/armordreadstone.xml"),
  Asset("IMAGE", "images/dreadstonehat.tex"),
  Asset("ATLAS", "images/dreadstonehat.xml"),
  Asset("IMAGE", "images/wall_dreadstone.tex"),
  Asset("ATLAS", "images/wall_dreadstone.xml"),


  -- ========== SOUND ==========
  Asset("SOUND", "sound/antlion.fsb"),
  Asset("SOUND", "sound/grotto_amb.fsb"),
  Asset("SOUND", "sound/grotto_sfx.fsb"),
  Asset("SOUND", "sound/monkey.fsb"),
  Asset("SOUND", "sound/monkeyisland.fsb"),
  Asset("SOUND", "sound/monkeyisland_amb.fsb"),
  Asset("SOUND", "sound/monkeyisland_music.fsb"),
  Asset("SOUND", "sound/moonstorm.fsb"),
  Asset("SOUND", "sound/rifts.fsb"),
  Asset("SOUND", "sound/toadstool.fsb"),
  Asset("SOUND", "sound/turf_crafting_station.fsb"),
  Asset("SOUND", "sound/turnoftides.fsb"),
  Asset("SOUND", "sound/turnoftides_amb.fsb"),
  Asset("SOUND", "sound/turnoftides_music.fsb"),
  Asset("SOUND", "sound/daywalker.fsb"),
  Asset("SOUND", "sound/saltydog.fsb"),
  Asset("SOUND", "sound/waterlogged2.fsb"),
  Asset("SOUND", "sound/waterlogged2_amb.fsb"),
  Asset("SOUND", "sound/hookline.fsb"),
  Asset("SOUND", "sound/hookline_2.fsb"),
  Asset("SOUND", "sound/mushroom_light.fsb"),

  -- ========== SOUNDPACKAGE ==========
  Asset("SOUNDPACKAGE", "sound/antlion.fev"),
  Asset("SOUNDPACKAGE", "sound/grotto.fev"),
  Asset("SOUNDPACKAGE", "sound/monkeyisland.fev"),
  Asset("SOUNDPACKAGE", "sound/moonstorm.fev"),
  Asset("SOUNDPACKAGE", "sound/rifts.fev"),
  Asset("SOUNDPACKAGE", "sound/toadstool.fev"),
  Asset("SOUNDPACKAGE", "sound/turf_crafting_station.fev"),
  Asset("SOUNDPACKAGE", "sound/turnoftides.fev"),
  Asset("SOUNDPACKAGE", "sound/daywalker.fev"),
  Asset("SOUNDPACKAGE", "sound/saltydog.fev"),
  Asset("SOUNDPACKAGE", "sound/waterlogged2.fev"),
  Asset("SOUNDPACKAGE", "sound/hookline.fev"),
  Asset("SOUNDPACKAGE", "sound/hookline_2.fev"),
  Asset("SOUNDPACKAGE", "sound/mushroom_light.fev"),

  Asset("IMAGE", "images/tab_celestial.tex"),
  Asset("ATLAS", "images/tab_celestial.xml"),

  -- ========== ATLAS ==========
  Asset("IMAGE", "images/banner_bg.tex"),
  Asset("ATLAS", "images/banner_bg.xml"),
  Asset("IMAGE", "images/carrat_altas.tex"),
  Asset("ATLAS", "images/carrat_altas.xml"),
  Asset("IMAGE", "images/archive_resonator.tex"),
  Asset("ATLAS", "images/archive_resonator.xml"),
  Asset("IMAGE", "images/moon_cap.tex"),
  Asset("ATLAS", "images/moon_cap.xml"),
  Asset("IMAGE", "images/rf_dust.tex"),
  Asset("ATLAS", "images/rf_dust.xml"),
  Asset("IMAGE", "images/ripe_moon_cap.tex"),
  Asset("ATLAS", "images/ripe_moon_cap.xml"),
  Asset("IMAGE", "images/turf_archive.tex"),
  Asset("ATLAS", "images/turf_archive.xml"),
  Asset("IMAGE", "images/turf_fungus_moon.tex"),
  Asset("ATLAS", "images/turf_fungus_moon.xml"),
  Asset("IMAGE", "images/turf_vent.tex"),
  Asset("ATLAS", "images/turf_vent.xml"),
  Asset("IMAGE", "images/turf_vault.tex"),
  Asset("ATLAS", "images/turf_vault.xml"),
  Asset("IMAGE", "images/dst_boss.tex"),
  Asset("ATLAS", "images/dst_boss.xml"),
  Asset("IMAGE", "images/lightflier.tex"),
  Asset("ATLAS", "images/lightflier.xml"),
  Asset("IMAGE", "images/opalgem.tex"),
  Asset("ATLAS", "images/opalgem.xml"),
  Asset("IMAGE", "images/cutless.tex"),
  Asset("ATLAS", "images/cutless.xml"),
  Asset("IMAGE", "images/dug_bananabush.tex"),
  Asset("ATLAS", "images/dug_bananabush.xml"),
  Asset("IMAGE", "images/dug_monkeytails.tex"),
  Asset("ATLAS", "images/dug_monkeytails.xml"),
  Asset("IMAGE", "images/wormlight_lesser.tex"),
  Asset("ATLAS", "images/wormlight_lesser.xml"),
  Asset("IMAGE", "images/moonrockseed.tex"),
  Asset("ATLAS", "images/moonrockseed.xml"),
  Asset("IMAGE", "images/turf_monkey_ground.tex"),
  Asset("ATLAS", "images/turf_monkey_ground.xml"),
  Asset("IMAGE", "images/star_trap_atlas.tex"),
  Asset("ATLAS", "images/star_trap_atlas.xml"),
  Asset("IMAGE", "images/blowdart_yellow.tex"),
  Asset("ATLAS", "images/blowdart_yellow.xml"),
  Asset("IMAGE", "images/feather_canary.tex"),
  Asset("ATLAS", "images/feather_canary.xml"),
  Asset("IMAGE", "images/hat_blue_mushroom.tex"),
  Asset("ATLAS", "images/hat_blue_mushroom.xml"),
  Asset("IMAGE", "images/hat_green_mushroom.tex"),
  Asset("ATLAS", "images/hat_green_mushroom.xml"),
  Asset("IMAGE", "images/hat_red_mushroom.tex"),
  Asset("ATLAS", "images/hat_red_mushroom.xml"),
  Asset("IMAGE", "images/mushroom_light.tex"),
  Asset("ATLAS", "images/mushroom_light.xml"),
  Asset("IMAGE", "images/dustmeringue.tex"),
  Asset("ATLAS", "images/dustmeringue.xml"),
  Asset("IMAGE", "images/thulecitebugnet.tex"),
  Asset("ATLAS", "images/thulecitebugnet.xml"),
  Asset("IMAGE", "images/mushroom_light2.tex"),
  Asset("ATLAS", "images/mushroom_light2.xml"),
  Asset("IMAGE", "images/shroom_skin.tex"),
  Asset("ATLAS", "images/shroom_skin.xml"),
  Asset("IMAGE", "images/spore_medium.tex"),
  Asset("ATLAS", "images/spore_medium.xml"),
  Asset("IMAGE", "images/spore_small.tex"),
  Asset("ATLAS", "images/spore_small.xml"),
  Asset("IMAGE", "images/spore_tall.tex"),
  Asset("ATLAS", "images/spore_tall.xml"),

  
  -- minimap icons in images/ (IMAGE before ATLAS)
  Asset("IMAGE", "images/antlion.tex"),
  Asset("ATLAS", "images/antlion.xml"),
  Asset("IMAGE", "images/sinkhole.tex"),
  Asset("ATLAS", "images/sinkhole.xml"),
  Asset("IMAGE", "images/oasis.tex"),
  Asset("ATLAS", "images/oasis.xml"),
  Asset("IMAGE", "images/atrium_gate.tex"),
  Asset("ATLAS", "images/atrium_gate.xml"),
  Asset("IMAGE", "images/atrium_gate_active.tex"),
  Asset("ATLAS", "images/atrium_gate_active.xml"),
  Asset("IMAGE", "images/atrium_key.tex"),
  Asset("ATLAS", "images/atrium_key.xml"),
  Asset("IMAGE", "images/atrium_light.tex"),
  Asset("ATLAS", "images/atrium_light.xml"),
  Asset("IMAGE", "images/atrium_overgrowth.tex"),
  Asset("ATLAS", "images/atrium_overgrowth.xml"),
  Asset("IMAGE", "images/atrium_rubble.tex"),
  Asset("ATLAS", "images/atrium_rubble.xml"),
  Asset("IMAGE", "images/atrium_statue.tex"),
  Asset("ATLAS", "images/atrium_statue.xml"),
  Asset("IMAGE", "images/archive_knowledge_dispensary.tex"),
  Asset("ATLAS", "images/archive_knowledge_dispensary.xml"),
  Asset("IMAGE", "images/archive_knowledge_dispensary_b.tex"),
  Asset("ATLAS", "images/archive_knowledge_dispensary_b.xml"),
  Asset("IMAGE", "images/archive_knowledge_dispensary_c.tex"),
  Asset("ATLAS", "images/archive_knowledge_dispensary_c.xml"),
  Asset("IMAGE", "images/archive_knowledge_dispensary_d.tex"),
  Asset("ATLAS", "images/archive_knowledge_dispensary_d.xml"),
  Asset("IMAGE", "images/archive_knowledge_dispensary_e.tex"),
  Asset("ATLAS", "images/archive_knowledge_dispensary_e.xml"),
  Asset("IMAGE", "images/archive_moon_statue1.tex"),
  Asset("ATLAS", "images/archive_moon_statue1.xml"),
  Asset("IMAGE", "images/archive_moon_statue2.tex"),
  Asset("ATLAS", "images/archive_moon_statue2.xml"),
  Asset("IMAGE", "images/archive_moon_statue3.tex"),
  Asset("ATLAS", "images/archive_moon_statue3.xml"),
  Asset("IMAGE", "images/archive_moon_statue4.tex"),
  Asset("ATLAS", "images/archive_moon_statue4.xml"),
  Asset("IMAGE", "images/archive_orchestrina_main.tex"),
  Asset("ATLAS", "images/archive_orchestrina_main.xml"),
  Asset("IMAGE", "images/archive_portal.tex"),
  Asset("ATLAS", "images/archive_portal.xml"),
  Asset("IMAGE", "images/archive_power_switch.tex"),
  Asset("ATLAS", "images/archive_power_switch.xml"),
  Asset("IMAGE", "images/archive_resonator.tex"),
  Asset("ATLAS", "images/archive_resonator.xml"),
  Asset("IMAGE", "images/archive_runes.tex"),
  Asset("ATLAS", "images/archive_runes.xml"),
  Asset("IMAGE", "images/cave_closed.tex"),
  Asset("ATLAS", "images/cave_closed.xml"),
  Asset("IMAGE", "images/cave_hole.tex"),
  Asset("ATLAS", "images/cave_hole.xml"),
  Asset("IMAGE", "images/cave_open.tex"),
  Asset("ATLAS", "images/cave_open.xml"),
  Asset("IMAGE", "images/cave_open2.tex"),
  Asset("ATLAS", "images/cave_open2.xml"),
  Asset("IMAGE", "images/cookpot_archive.tex"),
  Asset("ATLAS", "images/cookpot_archive.xml"),
  Asset("IMAGE", "images/dustmothden.tex"),
  Asset("ATLAS", "images/dustmothden.xml"),
  Asset("IMAGE", "images/grotto_pool_big.tex"),
  Asset("ATLAS", "images/grotto_pool_big.xml"),
  Asset("IMAGE", "images/grotto_pool_small.tex"),
  Asset("ATLAS", "images/grotto_pool_small.xml"),
  Asset("IMAGE", "images/mushroom_tree_stump.tex"),
  Asset("ATLAS", "images/mushroom_tree_stump.xml"),
  Asset("IMAGE", "images/pillar_archive.tex"),
  Asset("ATLAS", "images/pillar_archive.xml"),
  Asset("IMAGE", "images/pond_cave.tex"),
  Asset("ATLAS", "images/pond_cave.xml"),
  Asset("IMAGE", "images/turfcraftingstation.tex"),
  Asset("ATLAS", "images/turfcraftingstation.xml"),
  Asset("IMAGE", "images/dragonfly_furnace.tex"),
  Asset("ATLAS", "images/dragonfly_furnace.xml"),
  Asset("IMAGE", "images/lava_pond.tex"),
  Asset("ATLAS", "images/lava_pond.xml"),
  Asset("IMAGE", "images/klaus_sack.tex"),
  Asset("ATLAS", "images/klaus_sack.xml"),
  Asset("IMAGE", "images/bananabush.tex"),
  Asset("ATLAS", "images/bananabush.xml"),
  Asset("IMAGE", "images/monkeyhut.tex"),
  Asset("ATLAS", "images/monkeyhut.xml"),
  Asset("IMAGE", "images/monkeytail.tex"),
  Asset("ATLAS", "images/monkeytail.xml"),
  Asset("IMAGE", "images/palmcone_seed.tex"),
  Asset("ATLAS", "images/palmcone_seed.xml"),
  Asset("IMAGE", "images/palmcone_scale.tex"),
  Asset("ATLAS", "images/palmcone_scale.xml"),
  Asset("IMAGE", "images/moonbase.tex"),
  Asset("ATLAS", "images/moonbase.xml"),
  Asset("IMAGE", "images/hotspring.tex"),
  Asset("ATLAS", "images/hotspring.xml"),
  Asset("IMAGE", "images/moon_tree.tex"),
  Asset("ATLAS", "images/moon_tree.xml"),
  Asset("IMAGE", "images/moon_tree_burnt.tex"),
  Asset("ATLAS", "images/moon_tree_burnt.xml"),
  Asset("IMAGE", "images/moon_tree_stump.tex"),
  Asset("ATLAS", "images/moon_tree_stump.xml"),
  Asset("IMAGE", "images/oceantree_pillar_small.tex"),
  Asset("ATLAS", "images/oceantree_pillar_small.xml"),
  Asset("IMAGE", "images/oceanvine.tex"),
  Asset("ATLAS", "images/oceanvine.xml"),
  Asset("IMAGE", "images/rock_avocado.tex"),
  Asset("ATLAS", "images/rock_avocado.xml"),
  Asset("IMAGE", "images/rock_moonglass.tex"),
  Asset("ATLAS", "images/rock_moonglass.xml"),
  Asset("IMAGE", "images/spidermoonden.tex"),
  Asset("ATLAS", "images/spidermoonden.xml"),
  Asset("IMAGE", "images/sculpture_bishopbody_fixed.tex"),
  Asset("ATLAS", "images/sculpture_bishopbody_fixed.xml"),
  Asset("IMAGE", "images/sculpture_bishopbody_full.tex"),
  Asset("ATLAS", "images/sculpture_bishopbody_full.xml"),
  Asset("IMAGE", "images/sculpture_bishophead.tex"),
  Asset("ATLAS", "images/sculpture_bishophead.xml"),
  Asset("IMAGE", "images/sculpture_knightbody_fixed.tex"),
  Asset("ATLAS", "images/sculpture_knightbody_fixed.xml"),
  Asset("IMAGE", "images/sculpture_knightbody_full.tex"),
  Asset("ATLAS", "images/sculpture_knightbody_full.xml"),
  Asset("IMAGE", "images/sculpture_knighthead.tex"),
  Asset("ATLAS", "images/sculpture_knighthead.xml"),
  Asset("IMAGE", "images/sculpture_rookbody_fixed.tex"),
  Asset("ATLAS", "images/sculpture_rookbody_fixed.xml"),
  Asset("IMAGE", "images/sculpture_rookbody_full.tex"),
  Asset("ATLAS", "images/sculpture_rookbody_full.xml"),
  Asset("IMAGE", "images/sculpture_rooknose.tex"),
  Asset("ATLAS", "images/sculpture_rooknose.xml"),
  Asset("IMAGE", "images/scarecrow.tex"),
  Asset("ATLAS", "images/scarecrow.xml"),
  Asset("IMAGE", "images/toadstool_cap.tex"),
  Asset("ATLAS", "images/toadstool_cap.xml"),
  Asset("IMAGE", "images/toadstool_cap_dark.tex"),
  Asset("ATLAS", "images/toadstool_cap_dark.xml"),
  Asset("IMAGE", "images/toadstool_hole.tex"),
  Asset("ATLAS", "images/toadstool_hole.xml"),

  -- ========== NEW MINIMAP ICONS ==========
  Asset("IMAGE", "images/beefalo_groomer.tex"),
  Asset("ATLAS", "images/beefalo_groomer.xml"),
  Asset("IMAGE", "images/bulb_plant_withered.tex"),
  Asset("ATLAS", "images/bulb_plant_withered.xml"),
  Asset("IMAGE", "images/cave_vent_rock.tex"),
  Asset("ATLAS", "images/cave_vent_rock.xml"),
  Asset("IMAGE", "images/daywalker_pillar.tex"),
  Asset("ATLAS", "images/daywalker_pillar.xml"),
  Asset("IMAGE", "images/mushtree_moon.tex"),
  Asset("ATLAS", "images/mushtree_moon.xml"),
  Asset("IMAGE", "images/palmcone_tree.tex"),
  Asset("ATLAS", "images/palmcone_tree.xml"),
  Asset("IMAGE", "images/palmcone_tree_burnt.tex"),
  Asset("ATLAS", "images/palmcone_tree_burnt.xml"),
  Asset("IMAGE", "images/palmcone_tree_stump.tex"),
  Asset("ATLAS", "images/palmcone_tree_stump.xml"),
  Asset("IMAGE", "images/support_pillar_dreadstone.tex"),
  Asset("ATLAS", "images/support_pillar_dreadstone.xml"),
  Asset("IMAGE", "images/tree_rock.tex"),
  Asset("ATLAS", "images/tree_rock.xml"),
}

-- ==================== DS 音效兼容：强制预加载所有自定义 FEV ====================
-- DS 仅靠 Asset("SOUNDPACKAGE") 可能不加载 FEV，需要显式预加载
TheSim:PreloadFile("sound/antlion.fev")
TheSim:PreloadFile("sound/grotto.fev")
TheSim:PreloadFile("sound/monkeyisland.fev")
TheSim:PreloadFile("sound/moonstorm.fev")
TheSim:PreloadFile("sound/rifts.fev")
TheSim:PreloadFile("sound/rifts6.fev")
TheSim:PreloadFile("sound/toadstool.fev")
TheSim:PreloadFile("sound/turf_crafting_station.fev")
TheSim:PreloadFile("sound/turnoftides.fev")
TheSim:PreloadFile("sound/daywalker.fev")
TheSim:PreloadFile("sound/saltydog.fev")
TheSim:PreloadFile("sound/waterlogged2.fev")
TheSim:PreloadFile("sound/hookline.fev")
TheSim:PreloadFile("sound/hookline_2.fev")
TheSim:PreloadFile("sound/mushroom_light.fev")

-- ==================== 事件路径重映射（DST→DS 兼容）====================
-- dontstarve/AMB/caves/main 已在 dst_turf_registration.lua 中直接改用 dontstarve/cave/caveAMB
-- grotto.fev 中没有 _small/_large 脚步变体，回退到基础事件
RemapSoundEvent("grotto/movement/grotto_footstep_small", "grotto/movement/grotto_footstep")
RemapSoundEvent("grotto/movement/grotto_footstep_large", "grotto/movement/grotto_footstep")

-- ==================== mushroom_light（独立 FEV，需重映射路径）====================
-- 代码使用 dontstarve/common/together/mushroom_lamp/xxxx 但 mushroom_light.fev 事件名不同
RemapSoundEvent("dontstarve/common/together/mushroom_lamp/lantern_1_on", "mushroom_light/mushroom_lamp_1_on")
RemapSoundEvent("dontstarve/common/together/mushroom_lamp/lantern_2_on", "mushroom_light/mushroom_lamp_2_on")
RemapSoundEvent("dontstarve/common/together/mushroom_lamp/craft_1", "mushroom_light/mushlamp__craft_1")
RemapSoundEvent("dontstarve/common/together/mushroom_lamp/craft_2", "mushroom_light/mushlamp__craft_2")
RemapSoundEvent("dontstarve/common/together/mushroom_lamp/change_colour", "mushroom_light/mushlamp_change_colour_2")

-- ==================== Alter Guardian Boss 音效重映射（DST→DS 兼容）====================
-- moonstorm.fev 中的事件路径和代码路径一致，不需要重映射。
-- 之前错误地将有效事件映射到 SoundDef 内部名，导致所有声音失效。

-- ==================== turnoftides 额外重映射 ====================
-- fruit_dragon 组没有 footstep 事件，回退到 stretch（移动声）
RemapSoundEvent("turnoftides/creatures/together/fruit_dragon/footstep", "turnoftides/creatures/together/fruit_dragon/stretch")

-- ==================== 蘑菇地精（mushgnome）路径修正 ====================
-- grotto.fev 中 mushgnome 是顶层事件组，且 taunt 事件不存在
RemapSoundEvent("grotto/creatures/mushgnome/taunt", "grotto/mushgnome/surpise")

-- ==================== DS 原版脚步变体修正 ====================
-- DS 原版 dontstarve.fev 没有 _small 变体脚步，回退到基础事件
RemapSoundEvent("walk_dirt_small", "dontstarve/movement/walk_dirt")
RemapSoundEvent("walk_moss_small", "dontstarve/movement/walk_dirt")

-- ==================== mushtree_tall_spore 孢子弹射 ====================
RemapSoundEvent("dontstarve/cave/mushtree_tall_spore_fart", "toadstool/DST_spor_shoot_1")
RemapSoundEvent("dontstarve/cave/mushtree_tall_spore_land", "toadstool/DST_spore_explode_1")

-- ==================== 地皮环境音已在 dst_turf_registration.lua 中直接改用有效事件路径 ====================

-- minimap atlas registration
AddMinimapAtlas("images/turfcraftingstation.xml")
AddMinimapAtlas("images/dst_boss.xml")
AddMinimapAtlas("images/scarecrow.xml")
AddMinimapAtlas("images/turfcraftingstation.xml")

-- ===== Migrated DST minimap icons =====
-- 蚁狮
AddMinimapAtlas("images/antlion.xml")
AddMinimapAtlas("images/sinkhole.xml")
AddMinimapAtlas("images/oasis.xml")
-- 档案馆
AddMinimapAtlas("images/archive_knowledge_dispensary.xml")
AddMinimapAtlas("images/archive_knowledge_dispensary_b.xml")
AddMinimapAtlas("images/archive_knowledge_dispensary_c.xml")
AddMinimapAtlas("images/archive_knowledge_dispensary_d.xml")
AddMinimapAtlas("images/archive_knowledge_dispensary_e.xml")
AddMinimapAtlas("images/archive_moon_statue1.xml")
AddMinimapAtlas("images/archive_moon_statue2.xml")
AddMinimapAtlas("images/archive_moon_statue3.xml")
AddMinimapAtlas("images/archive_moon_statue4.xml")
AddMinimapAtlas("images/archive_orchestrina_main.xml")
AddMinimapAtlas("images/archive_portal.xml")
AddMinimapAtlas("images/archive_power_switch.xml")
AddMinimapAtlas("images/archive_resonator.xml")
AddMinimapAtlas("images/archive_runes.xml")
AddMinimapAtlas("images/cookpot_archive.xml")
AddMinimapAtlas("images/dustmothden.xml")
AddMinimapAtlas("images/grotto_pool_big.xml")
AddMinimapAtlas("images/grotto_pool_small.xml")
AddMinimapAtlas("images/mushroom_tree_stump.xml")
AddMinimapAtlas("images/pillar_archive.xml")
AddMinimapAtlas("images/pond_cave.xml")
-- 中庭
AddMinimapAtlas("images/atrium_gate.xml")
AddMinimapAtlas("images/atrium_gate_active.xml")
AddMinimapAtlas("images/atrium_key.xml")
AddMinimapAtlas("images/atrium_light.xml")
AddMinimapAtlas("images/atrium_overgrowth.xml")
AddMinimapAtlas("images/atrium_rubble.xml")
AddMinimapAtlas("images/atrium_statue.xml")
-- 猴岛
AddMinimapAtlas("images/bananabush.xml")
AddMinimapAtlas("images/monkeyhut.xml")
AddMinimapAtlas("images/monkeytail.xml")
-- 洞穴入口
AddMinimapAtlas("images/cave_closed.xml")
AddMinimapAtlas("images/cave_hole.xml")
AddMinimapAtlas("images/cave_open.xml")
AddMinimapAtlas("images/cave_open2.xml")
-- 月岛
AddMinimapAtlas("images/moonbase.xml")
AddMinimapAtlas("images/moon_tree.xml")
AddMinimapAtlas("images/moon_tree_burnt.xml")
AddMinimapAtlas("images/moon_tree_stump.xml")
AddMinimapAtlas("images/rock_avocado.xml")
AddMinimapAtlas("images/rock_moonglass.xml")
AddMinimapAtlas("images/spidermoonden.xml")
-- BOSS
AddMinimapAtlas("images/klaus_sack.xml")
AddMinimapAtlas("images/lava_pond.xml")
AddMinimapAtlas("images/dragonfly_furnace.xml")
AddMinimapAtlas("images/toadstool_cap.xml")
AddMinimapAtlas("images/toadstool_cap_dark.xml")
AddMinimapAtlas("images/toadstool_hole.xml")
-- 雕像
AddMinimapAtlas("images/sculpture_bishopbody_fixed.xml")
AddMinimapAtlas("images/sculpture_bishopbody_full.xml")
AddMinimapAtlas("images/sculpture_bishophead.xml")
AddMinimapAtlas("images/sculpture_knightbody_fixed.xml")
AddMinimapAtlas("images/sculpture_knightbody_full.xml")
AddMinimapAtlas("images/sculpture_knighthead.xml")
AddMinimapAtlas("images/sculpture_rookbody_fixed.xml")
AddMinimapAtlas("images/sculpture_rookbody_full.xml")
AddMinimapAtlas("images/sculpture_rooknose.xml")
-- 其他
AddMinimapAtlas("images/hotspring.xml")
AddMinimapAtlas("images/oceantree_pillar_small.xml")
AddMinimapAtlas("images/oceanvine.xml")
-- NEW ICONS
AddMinimapAtlas("images/beefalo_groomer.xml")
AddMinimapAtlas("images/bulb_plant_withered.xml")
-- Vent区
AddMinimapAtlas("images/cave_vent_rock.xml")
AddMinimapAtlas("images/tree_rock.xml")
-- 梦魇疯猪洞穴版
AddMinimapAtlas("images/daywalker_pillar.xml")
AddMinimapAtlas("images/support_pillar_dreadstone.xml")
-- 月岛
AddMinimapAtlas("images/mushtree_moon.xml")
AddMinimapAtlas("images/palmcone_tree.xml")
AddMinimapAtlas("images/palmcone_tree_burnt.xml")
AddMinimapAtlas("images/palmcone_tree_stump.xml")

-- ==================== 天体制作栏标签注册 ====================
STRINGS.TABS.DST_CELESTIAL = "天体"

AddClassPostConstruct("widgets/crafttabs", function(self)
    self.tabnames = self.tabnames or {}
    table.insert(self.tabnames, RECIPETABS.DST_CELESTIAL)
end)

-- ==================== 科技树 + 蓝图统一管理 ====================
modimport("scripts/system/tech_manager.lua")

modimport("scripts/dst_foods.lua")
--modimport("scripts/dst_global.lua")  -- 已移至 PrefabFiles 之前
modimport("scripts/dst_recipes.lua")
modimport("scripts/dst_sg.lua")
modimport("scripts/dst_strings.lua")
-- dst_tuning.lua 已移至 PrefabFiles 之前加载

-- 启蒙系统组件无需显式注册：DS 的 entityscript.lua 在 inst:AddComponent("enlightenment") 时
-- 会自动 require("components/enlightenment") 延迟加载，只要文件在 scripts/components/ 下即可。

-- 启蒙系统 (Enlightenment)
modimport("scripts/prefabs/enlightenment/enlightenment_triggers.lua")
modimport("scripts/prefabs/enlightenment/enlightenment_hud.lua")

require("physics")
require("behaviourtree")

-- ==================== 蝙蝠大脑覆写 ====================
-- DS 原版蝙蝠大脑的 GoHomeAction 用 GetClock():IsDay() 判断，
-- 洞穴环境下表面白天会导致蝙蝠立即回家消失。
-- 用自定义大脑替换，改用 iscaveday + 支持 panic 事件处理。
AddPrefabPostInit("bat", function(inst)
    local DstBatBrain = require("brains/dst_batbrain")
    inst:SetBrain(DstBatBrain)
end)

-- ==================== DST 模组功能补丁 ====================
-- 原 modmain.lua 中的功能代码已拆分为独立文件，通过 modimport 加载
modimport("scripts/dst_init.lua")           -- 模组初始化（信息覆盖 + Android 检查）
modimport("scripts/dst_player.lua")         -- 玩家初始化（grogginess + 标签注入）
modimport("scripts/dst_compat_patches.lua")  -- 兼容补丁合集（实体/Widget/DLC）
modimport("scripts/dst_component_api.lua")   -- 所有组件 API 扩展
modimport("scripts/archive_hooks.lua")   -- 档案馆 prefab 运行时 Hook 注入
modimport("scripts/dst_nightmare_init.lua")     -- 暴动时钟 + daywalkerspawner 初始化（从 archive_hooks 拆分）
modimport("scripts/dst_nightmare_postinits.lua") -- 暴动预制体延迟注册 + Colour Cube 滤镜

-- ==================== DST 火焰蔓延系统 ====================
-- DST 式蓄火→点燃火焰蔓延机制，移植自 DST Fire Spreading mod
modimport("scripts/dst_fire_spreading.lua")

-- ==================== DST 燃烧计时器 ====================
-- 显示燃烧/营火/提灯/星杖剩余时间
modimport("scripts/dst_burning_timer.lua")


-- ==================== 缺失 DST prefab 虚拟实体 ====================
-- 世界存档中引用了 DST 独有 prefab（如 oasis_cactus, twiggytree 等），
-- 没有这些实体会导致 SpawnSaveRecord FAILED → OUTOFSPACE 占位符。
-- 这里注册最小虚拟实体，加载后立即自毁，避免存档加载崩溃。
do
    local dummy_prefabs = {
        "oasis_cactus",
        "berrybush_juicy",
        "twiggytree",
        "ground_twigs",
        "moonrock_pieces",
        "pillar_cave_flintless",
        "wall_ruins_2",
        "chessjunk",
        "brokenwall_ruins",
    }
    for _, name in ipairs(dummy_prefabs) do
        if not GLOBAL.Prefabs[name] then
            GLOBAL.Prefabs[name] = {
                name = name,
                modfns = {},
                fn = function()
                    local inst = GLOBAL.CreateEntity()
                    inst.entity:AddTransform()
                    inst.persists = false
                    inst:DoTaskInTime(0, function(i)
                        if i:IsValid() then i:Remove() end
                    end)
                    return inst
                end
            }
        end
    end
end