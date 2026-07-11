
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

----------------<月岛地图生成>----------------

--静态布局
	Layouts["moontrees_2"] = StaticLayout.Get("map/static_layouts/moontrees_2", {
	    areas =
		  {
			tree_area = function() return math.random() < 0.9 and {"moon_tree"} or nil end,
			fissure_area = {"moon_fissure"},
		  }
    })

    Layouts["MoonTreeHiddenAxe"] = StaticLayout.Get("map/static_layouts/moontreehiddenaxe", {
		start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
		fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
		layout_position = LAYOUT_POSITION.CENTER,
		disable_transform = true
	})

	Layouts["MoonAltarRockGlass"] = StaticLayout.Get("map/static_layouts/moonaltarrockglass")
	Layouts["MoonAltarRockIdol"] = StaticLayout.Get("map/static_layouts/moonaltarrockidol")
	Layouts["MoonAltarRockSeed"] = StaticLayout.Get("map/static_layouts/moonaltarrockseed")
	Layouts["MoonRockShell"] = StaticLayout.Get("map/static_layouts/rockmoonshell")

    Layouts["BathbombedHotspring"] = StaticLayout.Get("map/static_layouts/bathbombedhotspring")
    Layouts["MoonFissures"] = StaticLayout.Get("map/static_layouts/fissures_1",
	{
			start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			layout_position = LAYOUT_POSITION.CENTER,
			disable_transform = true
	})

--room
AddRoom("MoonIsland_IslandShard", {
	colour={r=0.8,g=.8,b=.1,a=.50},
	value = GROUND.PEBBLEBEACH,  --海岸地皮（陆地，DS无海洋）
	contents = {
		countprefabs =
		{
		},
		distributepercent = 0.30,
		distributeprefabs =
		{
			trap_starfish = 1.0,
			lightcrab = 0.75,
			dead_sea_bones = 0.75,
			moon_fissure = 0.5,
			flint = 0.5,
			reeds = 0.75,
			twigs = 0.5,
			moonglass_rock = 0.3,
			moonglass = 0.1,
		},
	},
})

AddRoom("MoonIsland_Beach", {
	colour={r=0.3,g=0.2,b=0.1,a=0.3},
	value = GROUND.PEBBLEBEACH,  --海岸地皮
	contents = {
		countprefabs =
		{
			moonspiderden = 1,
		},
		distributepercent = 0.30,
		distributeprefabs =
		{
			lightcrab = 1.0,
			dead_sea_bones = 0.75,
			trap_starfish = 0.75,
			flint = 0.5,
			reeds = 0.75,
			twigs = 0.25,
		},
	},
})

AddRoom("MoonIsland_Forest", {
		colour={r=0.3,g=0.2,b=0.1,a=0.3},
		value = GROUND.METEOR, 
		contents = {
		countstaticlayouts =
		{
			["moontrees_2"] = 1 + math.random(1, 3), -- 减量避免放不下
            ["MoonTreeHiddenAxe"] = 1,
		},
		countprefabs =
		{
			moonspiderden = 2, --function(area) return math.max(1, math.floor(area / 100)) end,
		},
		distributepercent = 0.35,
		distributeprefabs =
		{
			moon_tree = 0.3,
			sapling_moon = 0.3,
			carrat_planted = 0.2,
			moon_tree_blossom_worldgen = 0.2,
			ground_twigs = 0.1,
			rock_avocado_bush = 0.1,
			moonglass_rock = 0.05,
			moon_fissure = 0.2,
			lightflier = 0.2,
			lightflier_flower = 0.08,
			moonbutterfly = 0.15,
		},
	},
})

AddRoom("MoonIsland_Mine", { --总MoonIsland_Mine
		colour={r=0.3,g=0.2,b=0.1,a=0.3},
		value = GROUND.METEOR, 
		contents = {
		countstaticlayouts =
		{
            ["MoonFissures"] = 1,
            ["MoonAltarRockGlass"] = 1,
            ["MoonAltarRockIdol"] = 1,
            ["MoonAltarRockSeed"] = 1,
            
		},
		distributepercent = 0.25,
		distributeprefabs =
		{
			moonglass_rock = 1,
			rock1 = 0.4,
			rock2 = 0.2,
			moonglass_rock = 0.2,
			moonglass = 0.2,
			moonrocknugget = 0.1,
			flint = 0.1,
			moon_fissure = 0.5,

		},
	},
})

AddRoom("MoonIsland_Mine1", {
		colour={r=0.3,g=0.2,b=0.1,a=0.3},
		value = GROUND.METEOR, 
		contents = {
		countstaticlayouts =
		{
            ["MoonFissures"] = 1,
            ["MoonRockShell"] = 1, --月球陨石壳（世界唯一）
            
		},
		distributepercent = 0.12,
		distributeprefabs =
		{
			moonglass_rock = 1,
			rock1 = 0.4,
			rock2 = 0.2,
			moonglass_rock = 0.2,
			moonglass = 0.2,
			moonrocknugget = 0.1,
			flint = 0.1,
			moon_fissure = 0.5,

		},
	},
})

AddRoom("MoonIsland_Mine2", {
		colour={r=0.3,g=0.2,b=0.1,a=0.3},
		value = GROUND.METEOR, 
		contents = {
		countstaticlayouts =
		{
            ["MoonAltarRockGlass"] = 1,
            
		},
		distributepercent = 0.12,
		distributeprefabs =
		{
			moonglass_rock = 1,
			rock1 = 0.4,
			rock2 = 0.2,
			moonglass_rock = 0.2,
			moonglass = 0.2,
			moonrocknugget = 0.1,
			flint = 0.1,
			moon_fissure = 0.5,

		},
	},
})

AddRoom("MoonIsland_Mine3", {
		colour={r=0.3,g=0.2,b=0.1,a=0.3},
		value = GROUND.METEOR, 
		contents = {
		countstaticlayouts =
		{
            ["MoonAltarRockIdol"] = 1,
            
		},
		distributepercent = 0.12,
		distributeprefabs =
		{
			moonglass_rock = 1,
			rock1 = 0.4,
			rock2 = 0.2,
			moonglass_rock = 0.2,
			moonglass = 0.2,
			moonrocknugget = 0.1,
			flint = 0.1,
			moon_fissure = 0.5,

		},
	},
})

AddRoom("MoonIsland_Mine4", {
		colour={r=0.3,g=0.2,b=0.1,a=0.3},
		value = GROUND.METEOR, 
		contents = {
		countstaticlayouts =
		{
            ["MoonAltarRockSeed"] = 1,
            
		},
		distributepercent = 0.12,
		distributeprefabs =
		{
			moonglass_rock = 1,
			rock1 = 0.4,
			rock2 = 0.2,
			moonglass_rock = 0.2,
			moonglass = 0.2,
			moonrocknugget = 0.1,
			flint = 0.1,
			moon_fissure = 0.5,

		},
	},
})

AddRoom("MoonIsland_Baths", {
		colour={r=0.3,g=0.2,b=0.1,a=0.3},
		value = GROUND.METEOR, 
		contents = {
		countstaticlayouts =
		{
            ["BathbombedHotspring"] = 1,
		},
		countprefabs =
		{
			hotspring = 1 + math.random(1, 8), --function(area) return math.max(1, math.floor(area / 50)) end,
			fruitdragon = 1 + math.random(1, 10), --function(area) return math.max(1, math.floor(area / 25)) end,
		},
		distributepercent = 0.30,
		distributeprefabs =
		{
			sapling_moon = 1.0,
			rock_avocado_bush = 1.0,
			moon_tree = 1.0,
			moonglass_rock = 1.0,
			moon_fissure = 1,
		},
	},
})

AddRoom("MoonIsland_Meadows", {
		colour={r=0.3,g=0.2,b=0.1,a=0.3},
		value = GROUND.SHELLBEACH, 
		contents = {
		distributepercent = 0.25,
		distributeprefabs =
		{
			moon_fissure = 1.5,
			moon_tree = 1,
			sapling_moon = 1,
			ground_twigs = 1,
			carrat_planted = 2,
			rock_avocado_bush = 1,
			moon_tree_blossom_worldgen = 0.5,
			moonglass_rock = 0.5,
			twigs = 0.5,
			purplemooneye = 0.02,
			bluemooneye = 0.02,
			greenmooneye = 0.02,
			lunar_grazer = 0.15,
			lightflier_flower = 0.05,
		},
	},
})

AddRoom("ForceDisconnectedRoom2", {
					colour={r=.45,g=.75,b=.45,a=.50},
					type = "blank",
					tags = {"ForceDisconnected"},
					value = GROUND.IMPASSABLE,
					contents = {},
			})

--tasks
----------------------------------
 AddTask("MoonIsland", { --只用一个tasks方便生成岛屿
		locks={LOCKS.ISLAND7},
		keys_given={KEYS.ISLAND7},
		entrance_room = "ForceDisconnectedRoom",
		make_loop = true, --圆形？
		room_choices={
			--海岸区 PEBBLEBEACH 地皮（对应DST的IslandShards+Beach）
			["MoonIsland_IslandShard"] = 2,
			["MoonIsland_Beach"] = 2,
			--内陆区 METEOR 地皮（对应DST的Forest/Mine/Baths/Meadows）
			["MoonIsland_Forest"] = 3,
			-- 使用独立Mine房间，每个房间只放1个祭坛碎片，避免重复
			["MoonIsland_Mine1"] = 1, -- 仅裂隙
			["MoonIsland_Mine2"] = 1, -- 玻璃祭坛碎片
			["MoonIsland_Mine3"] = 1, -- 神像祭坛碎片
			["MoonIsland_Mine4"] = 1, -- 种子祭坛碎片
			["MoonIsland_Baths"] = 2,
			["MoonIsland_Meadows"] = 2,
			["ForceDisconnectedRoom2"] = 1, -- 空房间缓冲，降低密度
		},
		room_bg=GROUND.METEOR,
		--background_room="ForceDisconnectedRoom", --有这个很容易连到出生地
		colour={r=1,g=1,b=0,a=1}
	})
----------------------------------
--[[
 AddTask("MoonIsland_Forest", {
		locks={LOCKS.ISLAND7},
		keys_given={KEYS.ISLAND7},
		entrance_room = "ForceDisconnectedRoom",
		make_loop = true, --圆形？
		room_choices={
			["MoonIsland_Forest"] = 3,
		},
		room_bg=GROUND.METEOR,
		--background_room="ForceDisconnectedRoom", --有这个很容易连到出生地
		colour={r=1,g=1,b=0,a=1}
	})

 AddTask("MoonIsland_Mine", {
		locks={LOCKS.ISLAND7},
		keys_given={KEYS.ISLAND7},
		entrance_room = "ForceDisconnectedRoom",
		make_loop = true, --圆形？
		room_choices={
			["MoonIsland_Mine"] = 3,
		},
		room_bg=GROUND.METEOR,
		colour={r=1,g=1,b=0,a=1}
	})

 AddTask("MoonIsland_Baths", {
		locks={LOCKS.ISLAND7},
		keys_given={KEYS.ISLAND7},
		entrance_room = "ForceDisconnectedRoom",
		make_loop = true, --圆形？
		room_choices={
			["MoonIsland_Baths"] = 2,
			["MoonIsland_Meadows"] = 2,
		},
		room_bg=GROUND.METEOR,
		colour={r=1,g=1,b=0,a=1}
	})
--]]

AddTask("NoneTasks", {
		locks={LOCKS.ISLAND7},
		keys_given={KEYS.TIER2},
		room_choices={ 
			["DummyExitRoom"] = 1, 
		},  
		room_bg=GROUND.METEOR,
		colour={r=0.3,g=0.3,b=0.5,a=0.3}
}) 

--tasks在世界生成
    AddLevelPreInit("SURVIVAL_DEFAULT", function(level)
      -- 不能直接在 LevelPreInit 中 table.insert(level.tasks)！！！
      -- AddSetPeices 会遍历 level.tasks 并用 GetTaskByName 在 sampletasks 中查找，
      -- 但 mod 任务不在 sampletasks 中，导致崩溃。
      -- 解决：钩住 GetTasksForLevel，它在 AddSetPeices 之后运行，在这里加任务安全。
      local _GetTasksForLevel = level.GetTasksForLevel
      level.GetTasksForLevel = function(self, sampletasks)
          -- 检查并添加月岛任务
          local found_moon, found_none = false, false
          for _, t in ipairs(self.tasks) do
              if t == "MoonIsland" then found_moon = true end
              if t == "NoneTasks" then found_none = true end
          end
          if not found_moon then table.insert(self.tasks, "MoonIsland") end
          if not found_none then table.insert(self.tasks, "NoneTasks") end
          return _GetTasksForLevel(self, sampletasks)
      end
      
      --虫洞连接：把月岛加入主大陆虫洞网络，通过虫洞唯一连接
      if level.set_pieces["WormholeGrass"] then
          local wg = level.set_pieces["WormholeGrass"]
          local found = false
          for _, t in ipairs(wg.tasks) do
              if t == "MoonIsland" then found = true; break end
          end
          if not found then
              table.insert(wg.tasks, "MoonIsland")
              wg.count = (wg.count or 1) + 1
          end
      else
          level.set_pieces["WormholeGrass"] = { count = 1, tasks = {"MoonIsland"} }
      end
    end)

--------
local RoG_tasks = {
--固定的八大板块
				"Make a pick",
				"Dig that rock",
				"Great Plains",
				"Squeltch",
				"Beeeees!",
				"Speak to the king",
				"Forest hunters",
				"Badlands",
--[[再随便加一点
				"Befriend the pigs",
				"For a nice walk",
				"The hunters",
				"Magic meadow",
				"Frogs and bugs",
				"Oasis",
				--"Mole Colony Deciduous", --第二片桦树林，感觉没必要
				"Mole Colony Rocks",
--]]
}

--[[
AddLevelPreInit("SHIPWRECKED_DEFAULT", function(level)
  --table.insert(level.tasks, "MoonIsland")
  
  local RoG = (#RoG_tasks)
  for i = 1,RoG do
	   table.insert(level.tasks, RoG_tasks[i])
  end
  level.set_pieces["ResurrectionStone"] = { count=2, tasks={"Make a pick", "Dig that rock", "Great Plains", "Squeltch", "Beeeees!", "Speak to the king", "Forest hunters", "Badlands", } }
  level.set_pieces["WormholeGrass"] = { count=8, tasks={"Make a pick", "Dig that rock", "Great Plains", "Squeltch", "Beeeees!", "Speak to the king", "Forest hunters", "Befriend the pigs", "For a nice walk", "Kill the spiders", "Killer bees!", "Make a Beehat", "The hunters", "Magic meadow", "Frogs and bugs", "Badlands",} }
end)
--]]

----------------<月岛地图生成>----------------
