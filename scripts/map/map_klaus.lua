
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")


--克劳斯生成
	Layouts["klaus_sack"] = 
	{
		type = LAYOUT.STATIC,
		layout = 
		{
			klaus_sack = {{x=0, y=0}},
		},
		ground_types = {GROUND.DECIDUOUS},
		start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
		fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
		layout_position = LAYOUT_POSITION.CENTER,
	}

AddLevelPreInit("SURVIVAL_DEFAULT", function(level)
    level.set_pieces["klaus_sack"] = { count = 1, tasks = {"Speak to the king"} } --克劳斯包
end)
