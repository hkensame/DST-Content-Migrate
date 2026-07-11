
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

-- 两个 astral marker 作为静态布景注入地表房间
-- 谐振器 scanfordevice 会在 9999 范围内搜索它们
Layouts["MoonAltarAstralMarker"] = 
{
	type = LAYOUT.STATIC,
	layout = 
	{
		moon_altar_astral_marker_1 = {{x=0, y=0}},
		moon_altar_astral_marker_2 = {{x=2, y=1}},
	},
	ground_types = {GROUND.FOREST, GROUND.GRASS, GROUND.DECIDUOUS, GROUND.SAVANNA, GROUND.DIRT, GROUND.MEADOW, GROUND.MUD, GROUND.ROCKY, GROUND.DESERT_DIRT},
	start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
	fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
	layout_position = LAYOUT_POSITION.CENTER,
}

-- 注入多个地表任务，确保总能生成
AddLevelPreInit("SURVIVAL_DEFAULT", function(level)
	level.set_pieces["MoonAltarAstralMarker"] = { 
		count = 1,
		tasks = {
			"Make a pick",
			"Dig that rock",
			"Great Plains",
			"Speak to the king",
			"Forest hunters",
			"Badlands",
			"Beeeees!",
			"Squeltch",
		}
	}
end)
