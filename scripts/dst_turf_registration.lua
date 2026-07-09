----------------<地皮注册>----------------
-- 从 modworldgenmain.lua 独立拆分，保持同一个 env 上下文

----------------<工具函数>----------------
local GetModTileID = function()
    for id=1,128 do
        if not table.contains(GLOBAL.GROUND, id) then
            print("MOD XXX GetModTileID: "..id)
            return id
        end
    end
    print("MOD XXX GetModTileID: error")
    return -1
end

----------------<地皮定义数据>----------------
-- turf：可铲起的地皮 prefab 名，注册后自动填入 DST_TURFS
local TURF_DEFS = {

    --------------------<热带三件套>--------------------
    { name = "METEOR",        sound = "meteor",             noise = "noise_meteor",             mini = "mini_meteor",             mini_name = "map_edge", run = "run_meteor", walk = "run_meteor",       turf = "turf_meteor" },
    { name = "SHELLBEACH",    sound = "cave",               noise = "ground_noise_shellbeach",   mini = "mini_shellbeach_noise",        mini_name = "map_edge", run = "run_sand",   walk = "walk_sand",       turf = "turf_shellbeach" },
    { name = "PEBBLEBEACH",   sound = "rocky",              noise = "noise_pebblebeach",         mini = "mini_pebblebeach",         mini_name = "map_edge", run = "run_sand",   walk = "walk_sand",       turf = "turf_pebblebeach" },

    --------------------<DST 移植地皮>--------------------
    { name = "ARCHIVE",       sound = "blocky",             noise = "Ground_noise_archive",      mini = "Ground_noise_archive_mini",  mini_name = "map_edge", run = "run_marble", walk = "walk_marble",  hard = true, turf = "turf_archive" },
    { name = "FUNGUSMOON",    sound = "cave",                noise = "Ground_noise_moon_fungus",  mini = "Ground_noise_moon_fungus_mini", mini_name = "map_edge", run = "run_dirt",   walk = "walk_dirt",       turf = "turf_fungus_moon" },
    { name = "MONKEY_GROUND", sound = "cave",                noise = "ground_noise_monkeyisland", mini = "mini_pebblebeach",            mini_name = "map_edge", run = "run_dirt",   walk = "walk_dirt",       turf = "turf_monkey_ground" },

    --------------------<DST 洞穴地皮>--------------------
    -- hard=true 与 DST 源码 tiledefs.lua 一致
    { name = "VENT",            sound = "cave",               noise = "ground_noise_fumarole",         mini = "ground_noise_fumarole_mini",       mini_name = "map_edge", run = "run_dirt",    walk = "walk_dirt",       hard = true, turf = "turf_vent" },
    { name = "VENT_NOISE",      sound = "cave",               noise = "ground_noise_fumarole",         mini = "ground_noise_fumarole_mini" },
    { name = "VAULT",           sound = "blocky",             noise = "Ground_noise_vault",            mini = "Ground_noise_vault_clean_mini",    mini_name = "map_edge", run = "run_stone",   walk = "walk_stone",      hard = true, turf = "turf_vault" },
    { name = "VAULT_CLEAN",     sound = "blocky",             noise = "Ground_noise_vault_clean",      mini = "Ground_noise_vault_clean_mini",    mini_name = "map_edge", run = "run_stone",   walk = "walk_stone",      hard = true },
    { name = "FUNGUSMOON_NOISE", sound = "cave",              noise = "Ground_noise_moon_fungus",       mini = "Ground_noise_moon_fungus_mini" },
    { name = "FAKE_GROUND",     sound = "blocky",             noise = "ground_noise_fumarole",         mini = "ground_noise_fumarole_mini" },
}

-- DS 缺失地皮补注册（仅在基础游戏未定义时注册）
-- 实验性地穴的 rooms_dstcave.lua 和 map_dstcave.lua 引用了它们，
-- 不注册会导致 GROUND.XXX = nil → storygen 崩溃。
local COMPAT_TILES = {
    { name = "BRICK",        sound = "cave",   noise = "noise_ruinsbrickglow", mini = "mini_ruinsbrick_noise",             run = "run_stone", walk = "walk_stone", hard = true },
    { name = "BRICK_GLOW",   sound = "cave",   noise = "noise_ruinsbrick",      mini = "mini_ruinsbrick_noise",             run = "run_stone", walk = "walk_stone", hard = true },
    { name = "TILES",        sound = "cave",   noise = "noise_ruinstileglow",   mini = "mini_ruinstile_noise",              run = "run_stone", walk = "walk_stone", hard = true },
    { name = "FUNGUS_NOISE", sound = "cave",   noise = "Ground_noise_moon_fungus",  mini = "Ground_noise_moon_fungus_mini" },
}

----------------<注册函数>----------------
local DST_TURFS = rawget(GLOBAL, "DST_TURFS") or {}

local function RegisterTiles(tiles)
    for _, def in ipairs(tiles) do
        -- 已存在则跳过注册（避免与基础游戏或其他模组冲突）
        if not GROUND[def.name] then
            local large = { noise_texture = "levels/textures/" .. def.noise .. ".tex" }
            if def.run then
                large.runsound = def.run
                large.walksound = def.walk
                large.snowsound = "run_ice"
                large.mudsound = "run_mud"
            end
            if def.hard then
                large.hard = true
            end

            local mini = {
                name = def.mini_name or def.sound,
                noise_texture = "levels/textures/" .. def.mini .. ".tex",
            }

            AddTile(def.name, GetModTileID(), def.sound, large, mini)
        end

        -- 自动维护铲地皮掉落表
        if def.turf and GROUND[def.name] then
            DST_TURFS[GROUND[def.name]] = def.turf
        end
    end
end

----------------<注册主地皮>----------------
RegisterTiles(TURF_DEFS)

----------------<注册兼容地皮>----------------
RegisterTiles(COMPAT_TILES)

----------------<GID 映射修补：static_layout 的地皮 ID 覆盖>----------------
-- DS 的 ground_types 表（base 36 项 / Shipwrecked 52 项）与 DST 的 52 项完全不同：
--   DST GID 42 = ARCHIVE, 但 DS+SW GID 42 = OCEAN_CORAL
--   DST GID 37 = PEBBLEBEACH, 但 DS+SW GID 37 = BEACH
--   DST GID 38 = METEOR, 但 DS+SW GID 38 = JUNGLE
-- 必须强制覆盖（不能用 or），否则 DLC 的已有值会阻止映射。
function PatchGroundTypes(layout)
    if not layout or type(layout.ground_types) ~= "table" then return end
    -- DST GID 映射（index = Tiled GID，value = 动态分配的 tile ID）
    -- 索引 1-36 与 DS base 一致，无需覆盖
    -- 索引 37+ 是 DST 新增，DS base 没有，DS DLC 有但映射不同
    local dst_gid_overrides = {
        [37] = GROUND.PEBBLEBEACH,
        [38] = GROUND.METEOR,
        [39] = GROUND.FUNGUSRED,
        [40] = GROUND.FUNGUSGREEN,
        [41] = GROUND.FAKE_GROUND,
        [42] = GROUND.ARCHIVE,
        [43] = GROUND.FUNGUSMOON,
        [46] = GROUND.MONKEY_GROUND,
    }
    for gid, tile_id in pairs(dst_gid_overrides) do
        if tile_id then  -- 仅当 GROUND.X 已注册时覆盖
            layout.ground_types[gid] = tile_id
        end
    end
end

GLOBAL.DST_TURFS = DST_TURFS
