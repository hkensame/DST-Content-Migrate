
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
if GLOBAL.PLATFORM == "Android" then GLOBAL.SJ = true else GLOBAL.SJ = false end --手机判定

-- DST 移植地皮：GROUND 常量在 modworldgenmain.lua 用 AddTile() + GetModTileID() 动态分配
-- 不使用硬编码ID，避免与DLC地皮ID冲突

-- TUNING 安全兜底：防止 prefab 沙箱未读取到 dst_tuning.lua 中的常量
GLOBAL.TUNING.ALTERGUARDIAN_PHASE2_SPIKE_RANGE  = GLOBAL.TUNING.ALTERGUARDIAN_PHASE2_SPIKE_RANGE  or 10
GLOBAL.TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE = GLOBAL.TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE or 14
GLOBAL.TUNING.GESTALTGUARD_DAMAGE               = GLOBAL.TUNING.GESTALTGUARD_DAMAGE               or 180
GLOBAL.TUNING.ALTERGUARDIAN_PHASE2_TARGET_DIST  = GLOBAL.TUNING.ALTERGUARDIAN_PHASE2_TARGET_DIST  or 30
GLOBAL.TUNING.ALTERGUARDIAN_PHASE3_TARGET_DIST  = GLOBAL.TUNING.ALTERGUARDIAN_PHASE3_TARGET_DIST  or 20
GLOBAL.TUNING.ALTERGUARDIAN_PHASE2_MAXHEALTH    = GLOBAL.TUNING.ALTERGUARDIAN_PHASE2_MAXHEALTH    or 20000
GLOBAL.TUNING.ALTERGUARDIAN_PHASE2_STARTHEALTH  = GLOBAL.TUNING.ALTERGUARDIAN_PHASE2_STARTHEALTH  or 13000
GLOBAL.TUNING.ALTERGUARDIAN_PHASE3_MAXHEALTH    = GLOBAL.TUNING.ALTERGUARDIAN_PHASE3_MAXHEALTH    or 22500
GLOBAL.TUNING.ALTERGUARDIAN_PHASE3_STARTHEALTH  = GLOBAL.TUNING.ALTERGUARDIAN_PHASE3_STARTHEALTH  or 14000
GLOBAL.TUNING.SANITYAURA_SUPERHUGE = GLOBAL.TUNING.SANITYAURA_SUPERHUGE or 100/(GLOBAL.TUNING.SEG_TIME*.25)
-- 档案馆安全设施常量（archive_props.lua 引用）
GLOBAL.TUNING.ARCHIVE_SECURITY = GLOBAL.TUNING.ARCHIVE_SECURITY or { REGEN_TIME = 120, RELEASE_TIME = 15, WALK_SPEED = 4 }
GLOBAL.TUNING.MAX_SECURITY_PULSE_FOLLOWING = GLOBAL.TUNING.MAX_SECURITY_PULSE_FOLLOWING or 3

----------------<安全蓝图：防止世界加载时蓝图崩溃>----------------
-- 修复 blueprint.lua:113 attempt to index local 'inst' (a nil value)
-- 对所有 _blueprint 结尾的预制体应用 pcall 安全包装，防止 nil inst 冒泡崩溃
do
    local wrapped_count = 0
    for name, prefab in pairs(GLOBAL.Prefabs or {}) do
        if name:match("_blueprint$") or name == "blueprint" then
            local orig_fn = prefab.fn
            prefab.fn = function(...)
                local ok, result = pcall(orig_fn, ...)
                if ok and result then
                    return result
                end
                if not ok then
                    print("[DST Boss] SafeBlueprint: " .. name .. " 构造出错 " .. tostring(result))
                end
                return nil
            end
            wrapped_count = wrapped_count + 1
        end
    end
    if wrapped_count > 0 then
        print("[DST Boss] SafeBlueprint: 已安全包装" .. wrapped_count .. " 个蓝图预制体")
    end
end

-- ==================== 暴动循环注册 ====================
-- 仅挂载到 DST_CAVE 自定义层级，不影响 DS 原版洞穴
-- 原版洞穴自己有 nightmareclock 且事件名不同（phasechange vs nightmarephasechanged）
AddSimPostInit(function(inst)
    if inst.meta and inst.meta.level_id == "DST_CAVE" then
        if not inst.components.nightmareclock then
            inst:AddComponent("nightmareclock")
        end
    end
end)

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

PrefabFiles = 
{
  "dst_fx",
  "dst_blueprint",
  "moonisland/dug_plantables",
  "toadstool/red_mushroomhat",
  "toadstool/green_mushroomhat",
  "toadstool/blue_mushroomhat",
  -- "new_hats", -- 已拆分为独立 prefab
  "turf_meteor",
  "mushtree_spores", -- 孢子（红/绿/蓝月），蘑菇帽产出  
  "rock_break_fx", --特效
  "cave_hole",
  "sacred_chest",
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
  "shadowchess/bishop_nightmare_spawner",
  "shadowchess/rook_nightmare_spawner",
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
  "moonisland/mooneye", --月眼（蓝色）
  "cave/moonglass_stalactites", --月玻璃钟乳石（3种）
  "moonisland/fruitdragon", --火龙果蜥蜴
--月岛生态（草原/森林区动物）
  "moonisland/carrat", --胡萝卜鼠（包含 carrat_planted）
  "moonisland/lightflier", --光飞虫
  "moonisland/lightflier_flower", --光飞虫花
  "moonisland/lunar_grazer", --月辔
--暗影织影者
  "atrium/tentacle_pillar",
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
  "monkey/monkey",
  "monkey/monkeybarrel",
  "monkey/monkeyhut",
  "monkey/monkeypillar",
  "monkey/monkeytail",
  "monkey/monkeyprojectile",
  "monkey/powdermonkey",
  "monkey/bananabush",
  "monkey/cutless",
  "monkey/monkey_smallhat",
  "monkey/cave_banana_tree",
  -- 猴岛挖起植物
  "monkey/dug_monkeytail",
  "monkey/dug_bananabush",
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
  "cave/cavelight", --洞穴灯（含 cavelight_atrium）
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
  "cave/tree_rock_chop",    -- 巨石枝砍伐特效
  "cave/tree_rock_fall",    -- 巨石枝倒塌特效
  "cave/cave_vents",        -- cave_vent_rock
  "cave/cave_vent_ground_fx",
  "cave/cave_vent_mite",
  "cave/cave_vent_mite_spawner",
  "cave/cave_fern_withered",
  "cave/pillar_cave_rock",      -- 洞穴岩石柱（装饰性障碍物）
  "cave/flower_cave_withered",        -- 仅 3 种枯萎变种（普通荧光花由 DS 原版 cave/objects/flower_cave 提供）
  -- 远古守卫者 spawner（重生机制）
  "cave/minotaur_spawner",
} 

Assets = {
  -- ========== ANIM ==========
  Asset("ANIM", "anim/turf.zip"),
  Asset("ANIM", "anim/burntground.zip"),
  -- 启蒙系统：月灵理智徽章（需从 DST 提取 status_sanity.zip）
  Asset("ANIM", "anim/status_sanity.zip"),
  
  Asset("ANIM", "anim/alterguardian/alterguardian_spike.zip"),
  Asset("ANIM", "anim/alterguardian/alterguardian_laser_hit_sparks_fx.zip"),
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
  Asset("ANIM", "anim/rock_stalagmite.zip"),
  Asset("ANIM", "anim/rock_stalagmite_tall.zip"),
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
  Asset("ANIM", "anim/leaves_canopy.zip"), --水中木叶片
 
  Asset("ANIM", "anim/monkey/bananabush.zip"),
  Asset("ANIM", "anim/monkey/cave_banana_tree.zip"),
  Asset("ANIM", "anim/monkey/cutless.zip"),
  Asset("ANIM", "anim/monkey/hat_monkey_small.zip"),
  Asset("ANIM", "anim/monkey/kiki_basic.zip"),
  Asset("ANIM", "anim/monkey/kiki_nightmare_skin.zip"),
  Asset("ANIM", "anim/monkey/monkey_barrel.zip"),
  Asset("ANIM", "anim/monkey/monkey_small.zip"),
  Asset("ANIM", "anim/monkey/monkeyhut.zip"),
  Asset("ANIM", "anim/monkey/pillar_monkey.zip"),
  Asset("ANIM", "anim/monkey/reeds_monkeytails.zip"),
  Asset("ANIM", "anim/monkey/turf_monkey_ground.zip"),

  Asset("ANIM", "anim/moonisland/bulb_plant_single.zip"), --光飞虫花
  Asset("ANIM", "anim/moonisland/bulb_plant_springy.zip"), --光飞虫花变体
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
  Asset("ANIM", "anim/moonisland/mooneyes.zip"),
  Asset("ANIM", "anim/moonisland/star_trap.zip"),

  Asset("ANIM", "anim/moonbase/dst_gems.zip"),

  Asset("ANIM", "anim/player_attackss.zip"),
  Asset("ANIM", "anim/player_encumbered.zip"), --背大理石
  Asset("ANIM", "anim/player_encumbered_jump.zip"), --背大理石跳船
  Asset("ANIM", "anim/player_groggy.zip"), --走得慢
  
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

  -- ========== SOUNDPACKAGE ==========
  Asset("SOUNDPACKAGE", "sound/antlion.fev"),
  Asset("SOUNDPACKAGE", "sound/grotto.fev"),
  Asset("SOUNDPACKAGE", "sound/monkeyisland.fev"),
  Asset("SOUNDPACKAGE", "sound/moonstorm.fev"),
  Asset("SOUNDPACKAGE", "sound/rifts.fev"),
  Asset("SOUNDPACKAGE", "sound/toadstool.fev"),
  Asset("SOUNDPACKAGE", "sound/turf_crafting_station.fev"),
  Asset("SOUNDPACKAGE", "sound/turnoftides.fev"),

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
  Asset("IMAGE", "images/mooneye_images.tex"),
  Asset("ATLAS", "images/mooneye_images.xml"),
  Asset("IMAGE", "images/cutless.tex"),
  Asset("ATLAS", "images/cutless.xml"),
  Asset("IMAGE", "images/dug_bananabush.tex"),
  Asset("ATLAS", "images/dug_bananabush.xml"),
  Asset("IMAGE", "images/dug_monkeytails.tex"),
  Asset("ATLAS", "images/dug_monkeytails.xml"),
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
  Asset("IMAGE", "images/tentacle_pillar.tex"),
  Asset("ATLAS", "images/tentacle_pillar.xml"),
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
  Asset("IMAGE", "images/cave_banana_tree.tex"),
  Asset("ATLAS", "images/cave_banana_tree.xml"),
  Asset("IMAGE", "images/cave_banana_tree_burnt.tex"),
  Asset("ATLAS", "images/cave_banana_tree_burnt.xml"),
  Asset("IMAGE", "images/cave_banana_tree_stump.tex"),
  Asset("ATLAS", "images/cave_banana_tree_stump.xml"),
  Asset("IMAGE", "images/monkeybarrel.tex"),
  Asset("ATLAS", "images/monkeybarrel.xml"),
  Asset("IMAGE", "images/monkeyhut.tex"),
  Asset("ATLAS", "images/monkeyhut.xml"),
  Asset("IMAGE", "images/monkeytail.tex"),
  Asset("ATLAS", "images/monkeytail.xml"),
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
}

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
AddMinimapAtlas("images/tentacle_pillar.xml")
-- 猴岛
AddMinimapAtlas("images/bananabush.xml")
AddMinimapAtlas("images/cave_banana_tree.xml")
AddMinimapAtlas("images/cave_banana_tree_burnt.xml")
AddMinimapAtlas("images/cave_banana_tree_stump.xml")
AddMinimapAtlas("images/monkeybarrel.xml")
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

modimport("scripts/dst_foods.lua")
modimport("scripts/dst_global.lua")
modimport("scripts/dst_recipes.lua")
modimport("scripts/dst_sg.lua")
modimport("scripts/dst_strings.lua")
modimport("scripts/dst_tuning.lua")

-- 启蒙系统组件无需显式注册：DS 的 entityscript.lua 在 inst:AddComponent("enlightenment") 时
-- 会自动 require("components/enlightenment") 延迟加载，只要文件在 scripts/components/ 下即可。

-- 启蒙系统 (Enlightenment)
modimport("scripts/prefabs/enlightenment/enlightenment_triggers.lua")
modimport("scripts/prefabs/enlightenment/enlightenment_hud.lua")

require("physics")
require("behaviourtree")

-- ==================== DST 模组功能补丁 ====================
-- 原 modmain.lua 中的功能代码已拆分为独立文件，通过 modimport 加载
modimport("scripts/dst_init.lua")           -- 模组初始化（信息覆盖 + Android 检查）
modimport("scripts/dst_player.lua")         -- 玩家初始化（grogginess + 标签注入）
modimport("scripts/dst_widget_patches.lua")  -- 容器缩放（启迪之冠）
modimport("scripts/dst_component_api.lua")   -- 所有组件 API 扩展
modimport("scripts/dst_entity_patches.lua")  -- 实体级补丁（金丝雀/稻草人/鹿等）
modimport("scripts/archive_hooks.lua")   -- 档案馆 prefab 运行时 Hook 注入
modimport("scripts/dst_dlc_patch.lua")       -- DLC 兼容补丁

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