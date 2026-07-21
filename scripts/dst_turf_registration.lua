----------------<AddTile 定义（来自 dst_tile.lua，合并至此）>----------------
-- 注册新地皮到 GROUND + tiledefs + minimap
local tiledefs = require 'worldtiledefs'

local tile_spec_defaults = {
	noise_texture = "images/square.tex",
	runsound = "dontstarve/movement/run_dirt",
	walksound = "dontstarve/movement/walk_dirt",
	snowsound = "dontstarve/movement/run_ice",
	mudsound = "dontstarve/movement/run_mud",
}

local mini_tile_spec_defaults = {
	name = "map_edge",
	noise_texture = "levels/textures/mini_dirt_noise.tex",
}

local GroundAtlas = rawget(GLOBAL, "GroundAtlas") or function( name )
	return ("levels/tiles/%s.xml"):format(name) 
end

local GroundImage = rawget(GLOBAL, "GroundImage") or function( name )
	return ("levels/tiles/%s.tex"):format(name) 
end

local noise_locations = {
	"%s.tex",
	"levels/textures/%s.tex",
}

local function GroundNoise( name )
	local trimmed_name = name:gsub("%.tex$", "")
	for _, pattern in ipairs(noise_locations) do
		local tentative = pattern:format(trimmed_name)
		if softresolvefilepath(tentative) then
				return tentative
		end
	end
	local status, err = pcall(resolvefilepath, name)
	return error(err or "This shouldn't be thrown. But your texture path is invalid, btw.", 3)
end

local function AddAssetsTo(assets_table, specs)
	table.insert( assets_table, Asset( "IMAGE", GroundNoise( specs.noise_texture ) ) )
	table.insert( assets_table, Asset( "IMAGE", GroundImage( specs.name ) ) )
	table.insert( assets_table, Asset( "FILE", GroundAtlas( specs.name ) ) )
end

local function AddAssets(specs)
	AddAssetsTo(tiledefs.assets, specs)
end

local function validate_ground_numerical_id(numerical_id, skip_id)
	if numerical_id >= GROUND.UNDERGROUND then
		return error(("Invalid numerical id %d: values greater than or equal to %d are assumed to represent walls."):format(numerical_id, GROUND.UNDERGROUND), 3)
	end
	for k, v in pairs(GROUND) do
		if v == numerical_id and k ~= skip_id then
			return error(("The numerical id %d is already used by GROUND.%s!"):format(v, tostring(k)), 3)
		end
	end
end

function AddTile(id, numerical_id, name, specs, minispecs)
	assert( type(id) == "string" )
	assert( type(numerical_id) == "number" )
	assert( type(name) == "string" )
	if GROUND[id] ~= nil and GROUND[id] ~= numerical_id then
		error(("GROUND.%s already exists with different value!"):format(id), 2)
	end

	specs = specs or {}
	minispecs = minispecs or {}
	assert( type(specs) == "table" )
	assert( type(minispecs) == "table" )

	validate_ground_numerical_id(numerical_id, id)

	GROUND[id] = numerical_id
	GROUND_NAMES[numerical_id] = name

	local real_specs = { name = name }
	for k, default in pairs(tile_spec_defaults) do
		if specs[k] == nil then
			real_specs[k] = default
		else
			real_specs[k] = specs[k]
		end
	end
	real_specs.noise_texture = GroundNoise( real_specs.noise_texture )

	table.insert(tiledefs.ground, { GROUND[id], real_specs })
	AddAssets(real_specs)

	local real_minispecs = {}
	for k, default in pairs(mini_tile_spec_defaults) do
		if minispecs[k] == nil then
			real_minispecs[k] = default
		else
			real_minispecs[k] = minispecs[k]
		end
	end

	AddPrefabPostInit("minimap", function(inst)
		local handle = GLOBAL.MapLayerManager:CreateRenderLayer(
			GROUND[id],
			resolvefilepath( GroundAtlas(real_minispecs.name) ),
			resolvefilepath( GroundImage(real_minispecs.name) ),
			resolvefilepath( GroundNoise(real_minispecs.noise_texture) )
		)
		inst.MiniMap:AddRenderLayer( handle )
	end)

	AddAssets(real_minispecs)
	return real_specs, real_minispecs
end

----------------<地皮注册>----------------

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
    { name = "METEOR",        sound = "meteor",             noise = "noise_meteor",             mini = "mini_meteor",             mini_name = "map_edge", run = "turnoftides/movement/run_meteor", walk = "turnoftides/movement/run_meteor",       turf = "turf_meteor" },
    { name = "SHELLBEACH",    sound = "cave",               noise = "ground_noise_shellbeach",   mini = "mini_shellbeach_noise",        mini_name = "map_edge", run = "turnoftides/movement/run_pebblebeach", walk = "turnoftides/movement/run_pebblebeach",       turf = "turf_shellbeach" },
    { name = "PEBBLEBEACH",   sound = "rocky",              noise = "noise_pebblebeach",         mini = "mini_pebblebeach",         mini_name = "map_edge", run = "turnoftides/movement/run_pebblebeach", walk = "turnoftides/movement/run_pebblebeach",       turf = "turf_pebblebeach" },

    --------------------<DST 移植地皮>--------------------
    { name = "ARCHIVE",       sound = "blocky",             noise = "Ground_noise_archive",      mini = "Ground_noise_archive_mini",  mini_name = "map_edge", run = "dontstarve/movement/run_marble", walk = "dontstarve/movement/walk_marble",  hard = true, turf = "turf_archive" },
    { name = "FUNGUSMOON",    sound = "cave",                noise = "Ground_noise_moon_fungus",  mini = "Ground_noise_moon_fungus_mini", mini_name = "map_edge", run = "grotto/movement/grotto_footstep", walk = "grotto/movement/grotto_footstep",       turf = "turf_fungus_moon" },
    { name = "MONKEY_GROUND", sound = "cave",                noise = "ground_noise_monkeyisland", mini = "mini_pebblebeach",            mini_name = "map_edge", run = "turnoftides/movement/run_pebblebeach", walk = "turnoftides/movement/run_pebblebeach",       turf = "turf_monkey_ground" },

    --------------------<DST 洞穴地皮>--------------------
    -- hard=true 与 DST 源码 tiledefs.lua 一致
    { name = "VENT",            sound = "cave",               noise = "ground_noise_fumarole",         mini = "ground_noise_fumarole_mini",       mini_name = "map_edge", run = "dontstarve/movement/run_dirt",    walk = "dontstarve/movement/walk_dirt",       hard = true, turf = "turf_vent" },
    { name = "VENT_NOISE",      sound = "cave",               noise = "ground_noise_fumarole",         mini = "ground_noise_fumarole_mini" },
    { name = "VAULT",           sound = "blocky",             noise = "Ground_noise_vault",            mini = "Ground_noise_vault_clean_mini",    mini_name = "map_edge", run = "dontstarve/movement/run_marble", walk = "dontstarve/movement/run_marble",      hard = true, turf = "turf_vault" },
    { name = "VAULT_CLEAN",     sound = "blocky",             noise = "Ground_noise_vault_clean",      mini = "Ground_noise_vault_clean_mini",    mini_name = "map_edge", run = "dontstarve/movement/run_marble", walk = "dontstarve/movement/run_marble",      hard = true },
    { name = "FUNGUSMOON_NOISE", sound = "cave",              noise = "Ground_noise_moon_fungus",       mini = "Ground_noise_moon_fungus_mini" },
    { name = "FAKE_GROUND",     sound = "blocky",             noise = "ground_noise_fumarole",         mini = "ground_noise_fumarole_mini" },
}

-- DS 缺失地皮补注册（仅在基础游戏未定义时注册）
-- 实验性地穴的 rooms_dstcave.lua 和 map_dstcave.lua 引用了它们，
-- 不注册会导致 GROUND.XXX = nil → storygen 崩溃。
local COMPAT_TILES = {
    { name = "BRICK",        sound = "cave",   noise = "noise_ruinsbrickglow", mini = "mini_ruinsbrick_noise",             run = "dontstarve/movement/run_dirt", walk = "dontstarve/movement/walk_dirt", hard = true },
    { name = "BRICK_GLOW",   sound = "cave",   noise = "noise_ruinsbrick",      mini = "mini_ruinsbrick_noise",             run = "dontstarve/movement/run_dirt", walk = "dontstarve/movement/walk_dirt", hard = true },
    { name = "TILES",        sound = "cave",   noise = "noise_ruinstileglow",   mini = "mini_ruinstile_noise",              run = "dontstarve/movement/run_dirt", walk = "dontstarve/movement/walk_dirt", hard = true },
    { name = "FUNGUS_NOISE", sound = "cave",   noise = "Ground_noise_moon_fungus",  mini = "Ground_noise_moon_fungus_mini" },
}

----------------<注册函数>----------------
local DST_TURFS = rawget(GLOBAL, "DST_TURFS") or {}

local function RegisterTiles(tiles)
    for _, def in ipairs(tiles) do
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
function PatchGroundTypes(layout)
    if not layout or type(layout.ground_types) ~= "table" then return end
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
        if tile_id then
            layout.ground_types[gid] = tile_id
        end
    end
end

GLOBAL.DST_TURFS = DST_TURFS

----------------<环境背景音：扩展 DS ambientsoundmixer>----------------
-- DS 的 ambientsoundmixer 组件根据玩家脚下的地皮类型播放环境音。
-- 新增地皮类型需在此注册，否则对应群系无背景环境音。
-- 事件路径来自 DST 源码 ambientsound.lua 的 AMBIENT_SOUNDS 表。
AddComponentPostInit("ambientsoundmixer", function(self)
    local G = GLOBAL

    -- 月岛区域（turnoftides.fev 中 fall 事件无音频，改用 Hamlet monkeyisland）
    self.ambient_sounds[G.GROUND.METEOR] = { sound = "monkeyisland/amb/island_amb" }
    self.ambient_sounds[G.GROUND.PEBBLEBEACH] = { sound = "monkeyisland/amb/island_amb" }
    self.ambient_sounds[G.GROUND.SHELLBEACH] = { sound = "hookline_2/amb/hermit_island" }

    -- 猴岛区域
    self.ambient_sounds[G.GROUND.MONKEY_GROUND] = { sound = "monkeyisland/amb/island_amb" }

    -- 档案馆区域（grotto.fev 中 archive 事件无音频，改用 DS 洞穴 ruins 环境音）
    self.ambient_sounds[G.GROUND.ARCHIVE] = { sound = "dontstarve/cave/ruinsAMB" }
    self.ambient_sounds[G.GROUND.VAULT] = { sound = "dontstarve/cave/ruinsAMB" }
    self.ambient_sounds[G.GROUND.VAULT_CLEAN] = { sound = "dontstarve/cave/ruinsAMB" }

    -- 月蘑菇林（grotto.fev 中 grotto 事件无音频，改用 DS 原生蘑菇林环境音）
    self.ambient_sounds[G.GROUND.FUNGUSMOON] = { sound = "dontstarve/cave/fungusforestAMB" }

    -- Vent 区
    self.ambient_sounds[G.GROUND.VENT] = { sound = "dontstarve/cave/caveAMB" }

    -- 兼容地皮
    self.ambient_sounds[G.GROUND.BRICK] = { sound = "dontstarve/cave/ruinsAMB" }
    self.ambient_sounds[G.GROUND.BRICK_GLOW] = { sound = "dontstarve/cave/ruinsAMB" }
    self.ambient_sounds[G.GROUND.TILES] = { sound = "dontstarve/cave/civruinsAMB" }

    -- 关键：将新增环境音同步到 playing_sounds 表
    -- DS 的 ambientsoundmixer 构造函数只在创建时同步了一次 ambient_sounds -> playing_sounds
    -- PostInit 新增的条目不会自动进入 playing_sounds，而 UpdateAmbientVolumes 只遍历
    -- playing_sounds 来设音量——不在里面则音量永远为 0，不会播放。
    for k, v in pairs(self.ambient_sounds) do
        if v.sound and not self.playing_sounds[v.sound] then
            self.playing_sounds[v.sound] = { sound = v.sound, volume = 0, playing = false }
        end
        if v.wintersound and not self.playing_sounds[v.wintersound] then
            self.playing_sounds[v.wintersound] = { sound = v.wintersound, volume = 0, playing = false }
        end
        if v.rainsound and not self.playing_sounds[v.rainsound] then
            self.playing_sounds[v.rainsound] = { sound = v.rainsound, volume = 0, playing = false }
        end
    end
end)

----------------<PlayFootstep 补丁：兼容完整 event path 和 DLC3 短名>----------------
-- DLC3（Hamlet）的 PlayFootstep 会给所有音效路径加 "dontstarve/movement/" 前缀，
-- 导致 mod 定义的完整 event path（如 "turnoftides/movement/run_pebblebeach"）变成
-- "dontstarve/movement/turnoftides/movement/run_pebblebeach" 而无声。
-- 此补丁判断音效路径是否已是完整 event path（含 /），是则直接播放，否则按原逻辑加前缀。
local function PatchPlayFootstep()
    local G = GLOBAL
    local CREATURE_SIZE = G.CREATURE_SIZE

    -- Web 音效名（DLC3 风格短名，始终需要 footstep_path 前缀）
    local WEB_SOUNDS = {
        [CREATURE_SIZE.SMALL]  = { runsound = "run_web_small" },
        [CREATURE_SIZE.MEDIUM] = { runsound = "run_web" },
        [CREATURE_SIZE.LARGE]  = { runsound = "run_web_large" },
    }

    local function get_creature_size(inst)
        if inst:HasTag("smallcreature") then return CREATURE_SIZE.SMALL end
        if inst:HasTag("largecreature") then return CREATURE_SIZE.LARGE end
        return CREATURE_SIZE.MEDIUM
    end

    -- 路径解析：完整 event path 直接播，短名加 footstep_path 前缀
    local function resolve_path(path, footstep_path, size_affix)
        if path and path:find("/") then
            return path .. size_affix
        end
        return footstep_path .. (path or "") .. size_affix
    end

    G.PlayFootstep = function(inst, volume)
        volume = volume or 1

        local sound = inst.SoundEmitter
        if not sound then return end

        local tile, tileinfo = inst:GetCurrentTileType()
        if not tile or not tileinfo then return end

        local x, y, z = inst.Transform:GetWorldPosition()
        local ontar = inst.slowing_objects and next(inst.slowing_objects)
        local oncreep = G.GetWorld().GroundCreep:OnCreep(x, y, z)
        local onflood = G.GetWorld().Flooding and G.GetWorld().Flooding:OnFlood(x, y, z)
        local onsnow = G.GetSeasonManager() and G.GetSeasonManager():GetSnowPercent() > 0.15
        local onmud = G.GetWorld().components.moisturemanager:GetWorldMoisture() > 15
        local ininterior = tile == G.GROUND.INTERIOR
        local onroad = inst:HasTag("player") and G.RoadManager ~= nil and G.RoadManager:IsOnRoad(x, 0, z)

        if onroad then
            tile = G.GROUND.ROAD
            tileinfo = G.GetTileInfo(G.GROUND.ROAD)
        end

        local footstep_path = inst.footstep_path_override or "dontstarve/movement/"
        local size_affix = ""
        if inst:HasTag("smallcreature") then
            size_affix = "_small"
        elseif inst:HasTag("largecreature") then
            size_affix = "_large"
        end

        if ininterior then
            local interiorSpawner = G.GetWorld().components.interiorspawner
            if interiorSpawner.current_interior then
                tileinfo = G.GetTileInfo(interiorSpawner.current_interior.groundsound)
                if not tileinfo then
                    tileinfo = G.GetTileInfo("DIRT")
                end
            end
        end

        if onsnow then
            sound:PlaySound(resolve_path(tileinfo.snowsound, footstep_path, size_affix), nil, volume)
        elseif onmud then
            sound:PlaySound(resolve_path(tileinfo.mudsound, footstep_path, size_affix), nil, volume)
        else
            local running = inst.sg and inst.sg:HasStateTag("running")
            if running then
                sound:PlaySound(resolve_path(tileinfo.runsound, footstep_path, size_affix), nil, volume)
            else
                sound:PlaySound(resolve_path(tileinfo.walksound, footstep_path, size_affix), nil, volume)
            end
        end

        if oncreep or onflood then
            local size = get_creature_size(inst)
            sound:PlaySound(footstep_path .. WEB_SOUNDS[size].runsound, nil, volume)
        end
        if ontar then
            sound:PlaySound(resolve_path(tileinfo.mudsound, footstep_path, size_affix), nil, volume)
        end
    end
end

PatchPlayFootstep()

