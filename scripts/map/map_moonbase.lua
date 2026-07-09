
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")


--月台
AddRoom("MoonbaseOne", {
					colour={r=.8,g=0.5,b=.6,a=.50},
					value = GROUND.FOREST,
					tags = { "RoadPoison" },
					contents =  {
									countprefabs = {
    										
    									},
									countstaticlayouts={["MoonbaseOne"]=1},
									
					                distributepercent = .8,
					                distributeprefabs=
					                {
										evergreen=6,
                                        fireflies = .5,
					                    blue_mushroom = .05,
					                    green_mushroom = .05,
					                    grass = .1,
					                    sapling=.8,
										twiggytree = 0.8,
										ground_twigs = 0.06,						                    
					                    berrybush_juicy = 0.05,
					                },
					            }
					})

	Layouts["MoonbaseOne"] = StaticLayout.Get("map/static_layouts/moonbaseone",
	{
			start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			layout_position = LAYOUT_POSITION.CENTER,
			disable_transform = true
	})

--月台生成
  AddTaskPreInit("Forest hunters", function(task)
    task.room_choices["MoonbaseOne"] = 1
  end) 
