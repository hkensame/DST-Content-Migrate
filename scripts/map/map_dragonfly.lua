
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")



AddRoom("DragonflyArena", {
					colour={r=0.3,g=0.2,b=0.1,a=0.3},
					value = GROUND.DIRT_NOISE,
					contents =  {
									countstaticlayouts={["DragonflyArena"]=1}, -- using a static layout because this can force it to be in the center of the room
									distributepercent = 0.1,
									distributeprefabs =
									{
										rock_flintless = .8,
										marsh_bush = 0.25,
										marsh_tree = 0.75,
										cactus = .7,
										houndbone = .6,
									},
					            }
					})

	Layouts["DragonflyArena"] = StaticLayout.Get("map/static_layouts/dragonfly_arena",
	{
			start_mask = GLOBAL.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			fill_mask = GLOBAL.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			layout_position = GLOBAL.LAYOUT_POSITION.CENTER
	})

--龙蝇生成
  AddTaskPreInit("Badlands", function(task)
    task.room_choices["DragonflyArena"] = 1
  end)
