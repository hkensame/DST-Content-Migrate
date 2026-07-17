--[[
调试工具集合
用法：在 modmain.lua 中添加 modimport("scripts/debug_ppapi.lua")
搜索日志标签：
  [PPAPI]    - PostProcessor API 枚举
  [SNDREG]   - 音频文件注册检查
  [TURFSND]  - 地皮音效注册验证
]]

----------------<SNDREG> 音频文件注册检查</SNDREG>----------------
-- safe_resolvefilepath：resolvefilepath 在 DS 中使用 assert，文件不存在会直接崩溃，故包装为安全版本
local function safe_resolvefilepath(path)
    local ok, result = pcall(resolvefilepath, path)
    return ok and result or nil
end
do
    local sound_files = {
        fev = {
            "sound/antlion.fev", "sound/grotto.fev", "sound/monkeyisland.fev",
            "sound/moonstorm.fev", "sound/rifts.fev", "sound/rifts6.fev",
            "sound/toadstool.fev", "sound/turf_crafting_station.fev",
            "sound/turnoftides.fev", "sound/daywalker.fev", "sound/saltydog.fev",
            "sound/waterlogged2.fev", "sound/hookline.fev", "sound/hookline_2.fev",
        },
        fsb = {
            "sound/antlion.fsb", "sound/grotto_amb.fsb", "sound/grotto_sfx.fsb",
            "sound/monkey.fsb", "sound/monkeyisland.fsb", "sound/monkeyisland_amb.fsb",
            "sound/monkeyisland_music.fsb", "sound/moonstorm.fsb",
            "sound/rifts.fsb", "sound/rifts6.fsb", "sound/toadstool.fsb",
            "sound/turf_crafting_station.fsb", "sound/turnoftides.fsb",
            "sound/turnoftides_amb.fsb", "sound/turnoftides_music.fsb",
            "sound/daywalker.fsb", "sound/saltydog.fsb", "sound/waterlogged2.fsb",
            "sound/waterlogged2_amb.fsb", "sound/hookline.fsb", "sound/hookline_2.fsb",
        },
    }

    print("[SNDREG] === Sound File Registration Check ===")
    local fev_ok, fev_missing = 0, 0
    for _, path in ipairs(sound_files.fev) do
        if safe_resolvefilepath(path) ~= nil then
            print(string.format("[SNDREG]   FEV ✅ %s", path)); fev_ok = fev_ok + 1
        else
            print(string.format("[SNDREG]   FEV ❌ %s NOT FOUND", path)); fev_missing = fev_missing + 1
        end
    end
    local fsb_ok, fsb_missing = 0, 0
    for _, path in ipairs(sound_files.fsb) do
        if safe_resolvefilepath(path) ~= nil then
            print(string.format("[SNDREG]   FSB ✅ %s", path)); fsb_ok = fsb_ok + 1
        else
            print(string.format("[SNDREG]   FSB ❌ %s NOT FOUND", path)); fsb_missing = fsb_missing + 1
        end
    end
    if safe_resolvefilepath("sound/monkey.fsb") ~= nil and safe_resolvefilepath("sound/monkey.fev") == nil then
        print("[SNDREG] NOTE: monkey.fsb has no monkey.fev (known, does not affect turfs)")
    end
    print(string.format("[SNDREG] FEV: %d ok / %d missing  FSB: %d ok / %d missing", fev_ok, fev_missing, fsb_ok, fsb_missing))
    print("[SNDREG] ===================================")
end

----------------<TURFSND> 地皮音效注册验证</TURFSND>----------------
-- 检查 tiledefs.ground 表中所有地皮的 runsound/walksound 是否已正确注册
-- 检查每个音效路径是否能找到对应的 FEV/FSB 文件
do
    print("[TURFSND] === Turf Sound Path Verification ===")
    local tiledefs = require "worldtiledefs"

    -- 定义：各地皮使用的音效路径 → 需要的 FEV/FSB 映射
    local sound_source_map = {
        ["turnoftides"]  = { fev = "sound/turnoftides.fev", fsb = {"sound/turnoftides.fsb", "sound/turnoftides_amb.fsb"} },
        ["grotto"]       = { fev = "sound/grotto.fev",      fsb = {"sound/grotto_sfx.fsb", "sound/grotto_amb.fsb"} },
        ["hookline_2"]   = { fev = "sound/hookline_2.fev",  fsb = {"sound/hookline_2.fsb"} },
        ["monkeyisland"] = { fev = "sound/monkeyisland.fev",fsb = {"sound/monkeyisland.fsb", "sound/monkeyisland_amb.fsb"} },
        ["dontstarve"]   = { fev = "(DS native dontstarve.fev)", fsb = {"(DS base bank)"} },
    }

    local function get_sound_source(event_path)
        if event_path == nil then return nil end
        local ns = event_path:match("^([^/]+)")
        return ns, sound_source_map[ns]
    end

    for i, entry in ipairs(tiledefs.ground) do
        local tile_id = entry[1]
        local info = entry[2]
        if info and (info.runsound or info.walksound) then
            local name = info.name or "?"
            -- 找到 GROUND 表中对应的名字
            local ground_name = "?"
            for k, v in pairs(GROUND) do
                if v == tile_id and type(k) == "string" then
                    ground_name = k; break
                end
            end

            -- 检查 runsound
            local ns, src = get_sound_source(info.runsound)
            local fev_status = ""
            if src and src.fev then
                if src.fev:find("%.fev$") then
                    fev_status = safe_resolvefilepath(src.fev) ~= nil and "✅" or "❌"
                else
                    fev_status = "🔵" -- DS native, always available
                end
                fev_status = fev_status .. " " .. src.fev
            end

            print(string.format("[TURFSND] %s (GROUND=%s): soundsource='%s' runsound='%s' walksound='%s'",
                ground_name, tostring(tile_id), name, info.runsound or "(none)", info.walksound or "(none)"))
            if ns and src then
                print(string.format("[TURFSND]   -> FEV namespace: %s  FEV: %s", ns, fev_status))
                for _, fsb_path in ipairs(src.fsb) do
                    if fsb_path:find("%.fsb$") then
                        local ok = safe_resolvefilepath(fsb_path) ~= nil and "✅" or "❌"
                        print(string.format("[TURFSND]   -> FSB: %s %s", ok, fsb_path))
                    else
                        print(string.format("[TURFSND]   -> FSB: 🔵 %s", fsb_path))
                    end
                end
            else
                print(string.format("[TURFSND]   -> WARNING: unknown namespace '%s', no FEV mapping!", ns or "nil"))
            end
        end
    end
    print("[TURFSND] ===================================")
end

----------------<环境音注册检查（延迟执行，等世界创建后）</TURFSND>----------------
-- 等 ambientsoundmixer 创建后检查它的 ambient_sounds 表
AddPrefabPostInit("world", function(inst)
	if inst.components and inst.components.ambientsoundmixer then
		local as = inst.components.ambientsoundmixer.ambient_sounds
		local ps = inst.components.ambientsoundmixer.playing_sounds
		local count_as = 0; for _,_ in pairs(as) do count_as = count_as + 1 end
		local count_ps = 0; for _,_ in pairs(ps) do count_ps = count_ps + 1 end

		print("[TURFSND] === Ambient Sound Mixer Check ===")
		print(string.format("[TURFSND] ambient_sounds: %d entries, playing_sounds: %d entries", count_as, count_ps))

		for tile_id, v in pairs(as) do
			-- 找到 GROUND 名字
			local name = tostring(tile_id)
			for k, vid in pairs(GROUND) do
				if vid == tile_id and type(k) == "string" then
					name = k; break
				end
			end
			local in_ps = ps[v.sound] and "✅" or "❌"
			print(string.format("[TURFSND]   %s (GROUND=%s): sound='%s'  in_playing_sounds=%s",
				name, tostring(tile_id), v.sound or "(nil)", in_ps))
		end
		print("[TURFSND] ===================================")
	end
end)

----------------<PPAPI> PostProcessor API 自检</PPAPI>----------------
if GLOBAL.PostProcessor ~= nil then
    local mt = getmetatable(GLOBAL.PostProcessor)
    local idx = mt and mt.__index
    if idx ~= nil then
        print("[PPAPI] === PostProcessor API Dump ===")
        local api_list = {}
        for k, v in pairs(idx) do
            table.insert(api_list, string.format("  %s: %s", k, type(v)))
        end
        table.sort(api_list)
        for _, line in ipairs(api_list) do
            print(line)
        end
        print(string.format("[PPAPI] Total %d methods", #api_list))

        local key_apis = {
            "AddUniformVariable", "AddPostProcessEffect", "SetEffectUniformVariables",
            "AddTextureSampler", "AddSampler", "AddSamplerEffect", "EnablePostProcessEffect",
            "SetPostProcessEffectBefore", "SetPostProcessEffectAfter", "SetBasePostProcessEffect",
        }
        for _, name in ipairs(key_apis) do
            if idx[name] ~= nil then
                print(string.format("[PPAPI] ✅ %s EXISTS", name))
            else
                print(string.format("[PPAPI] ❌ %s NOT FOUND", name))
            end
        end
        print("[PPAPI] ==============================")
    end
end
