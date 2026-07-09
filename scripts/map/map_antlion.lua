
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")



--蚁狮
AddRoom("BGLightningBluff", {
					colour={r=0.3,g=0.2,b=0.1,a=0.3},
					value = GROUND.DIRT_NOISE,
					--tags = {"RoadPoison", "sandstorm"},
					contents =  {
									distributepercent = 0.06,
									distributeprefabs =
									{
										marsh_bush = 0.15,
										rock_flintless = .5,
										houndbone = 0.2,
										oasis_cactus = 0.2,
										buzzardspawner = .05,
									},
					            }
					})

AddRoom("LightningBluffAntlion", {
					colour={r=0.3,g=0.2,b=0.1,a=0.3},
					value = GROUND.DIRT_NOISE,
					--tags = {"RoadPoison", "sandstorm"},
					contents =  {
									countstaticlayouts={["AntlionSpawningGround"]=1}, -- using a static layout because this can force it to be in the center of the room
									distributepercent = 0.1,
									distributeprefabs =
									{
										marsh_bush = .66,
										oasis_cactus = 0.1,
										houndbone = .5,
									},
					            }
					})

AddRoom("LightningBluffOasis", {
					colour={r=0.3,g=0.2,b=0.1,a=0.3},
					value = GROUND.DIRT_NOISE,
					--tags = {"RoadPoison", "sandstorm"},
					contents =  {
									countstaticlayouts={["Oasis"]=1}, -- using a static layout because this can force it to be in the center of the room
									distributepercent = 0.06,
									distributeprefabs =
									{
										marsh_bush = 0.15,
										houndbone = 0.2,
										oasis_cactus = 0.02,
										buzzardspawner = .05,
									},
					            }
					})

AddRoom("LightningBluffLightning", {
					colour={r=0.3,g=0.2,b=0.1,a=0.3},
					value = GROUND.DIRT_NOISE,
					--tags = {"RoadPoison", "sandstorm"},
					contents =  {
					                countprefabs= {
					                    lightninggoat = function () return 2 + math.random(4) end,
					                },
									distributepercent = 0.08,
									distributeprefabs =
									{
										marsh_bush = .8,
										oasis_cactus = 0.8,
									},
								}
					})

--蚁狮task
AddTask("Lightning Bluff", { 
		locks={LOCKS.SPIDERS_DEFEATED},
		keys_given={KEYS.PICKAXE, KEYS.TIER2},
		room_choices={
			["LightningBluffAntlion"] = 1,
			["LightningBluffLightning"] = 1,
			["LightningBluffOasis"] = 1,
			["BGLightningBluff"] = 2,
		},  
		room_bg=GROUND.DIRT,
		background_room="BGLightningBluff",
		colour={r=.05,g=.5,b=.05,a=1},
	})

--layouts
--蚁狮地形三点一竖
	Layouts["AntlionSpawningGround"] = 
	{
		type = LAYOUT.STATIC,
		layout = 
		{
			antlion_spawner = {{x=0, y=0}},
		},
		ground_types = {GROUND.DESERT_DIRT, GROUND.DIRT},
		ground =
			{
				{1, 2, 1, 2},
				{1, 1, 1, 2},
				{1, 1, 1, 1},
				{2, 1, 2, 1},
			},
		start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
		fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
		layout_position = LAYOUT_POSITION.CENTER,
	}
	
--沙漠绿洲
	Layouts["Oasis"] = StaticLayout.Get("map/static_layouts/oasis",
	{
		start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
		fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
		layout_position = LAYOUT_POSITION.CENTER,
		disable_transform = true
	})

--蚁狮生成
  AddLevelPreInit("SURVIVAL_DEFAULT", function(level)
    table.insert(level.tasks, "Lightning Bluff")
  end)
