
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

----------------<猴岛地图生成（参照月岛模式）>----------------

-- 猴岛海岸区
AddRoom("MonkeyIsland_Beach", {
    colour={r=0.5,g=0.4,b=0.2,a=0.5},
    value = GROUND.MONKEY_GROUND,
    contents = {
        countprefabs =
        {
            ["cave/objects/monkeybarrel"] = 1 + math.random(2),
        },

        distributepercent = 0.20,
        distributeprefabs =
        {
            ["cave/cave_banana_tree"] = 0.3,
            flint = 0.4,
            reeds = 0.5,
            grass = 0.5,
            rocks = 0.3,
        },
    },
})

-- 猴岛丛林区（主区）
AddRoom("MonkeyIsland_Jungle", {
    colour={r=0.4,g=0.3,b=0.1,a=0.5},
    value = GROUND.MONKEY_GROUND,
    contents = {
        countprefabs =
        {
            monkeyhut = 1 + math.random(2),
        },
        distributepercent = 0.25,
        distributeprefabs =
        {
            bananabush = 0.8,
            ["cave/cave_banana_tree"] = 0.2,
            monkeytail = 0.5,
            ["cave/objects/monkeybarrel"] = 0.3,
            monkeypillar = 0.1,
            grass = 0.5,
            sapling = 0.3,
            flint = 0.2,
            rocks = 0.2,
            twigs = 0.3,
            evergreen = 0.3,
        },
    },
})

-- 猴岛中心区（密集区）
AddRoom("MonkeyIsland_Center", {
    colour={r=0.6,g=0.3,b=0.0,a=0.5},
    value = GROUND.MONKEY_GROUND,
    contents = {
        countprefabs =
        {
            monkeyhut = 2 + math.random(3),
            ["cave/objects/monkeybarrel"] = 1 + math.random(2),
        },
        distributepercent = 0.30,
        distributeprefabs =
        {
            bananabush = 1.0,
            monkeytail = 0.6,
            ["cave/cave_banana_tree"] = 0.3,
            monkeypillar = 0.2,
            grass = 0.4,
            sapling = 0.2,
            flint = 0.1,
            rocks = 0.1,
        },
    },
})

-- 猴岛缓冲房间（MonkeyNoneTasks 的 ExitPiece 放置点，接收机械零件）
AddRoom("MonkeyDummyExitRoom", {
    colour={r=0.5,g=0.4,b=0.1,a=0.4},
    tags = {"ExitPiece"},
    value = GROUND.MONKEY_GROUND,
    contents = {
        distributepercent = 0.10,
        distributeprefabs = {
            ["cave/cave_banana_tree"] = 0.2,
            flint = 0.3,
            rocks = 0.2,
            twigs = 0.2,
            grass = 0.15,
        },
    },
})

-- Task（ISLAND8 自锁，与月岛独立）
AddTask("MonkeyIsland", {
    locks = {LOCKS.ISLAND8},
    keys_given = {KEYS.ISLAND8},
    entrance_room = "ForceDisconnectedRoom",
    make_loop = true,
    room_choices = {
        ["MonkeyIsland_Beach"] = 2,
        ["MonkeyIsland_Jungle"] = 2,
        ["MonkeyIsland_Center"] = 1,
    },
    room_bg = GROUND.MONKEY_GROUND,
    colour = {r=0.8,g=0.6,b=0.0,a=1},
})

----------------<猴岛生成入口>----------------
-- MonkeyNoneTasks（消费 ISLAND8 锁，维持锁链完整）
local MonkeyNoneTasks_registered
if not MonkeyNoneTasks_registered then
    MonkeyNoneTasks_registered = true
    AddTask("MonkeyNoneTasks", {
        locks={LOCKS.ISLAND8},
        keys_given={KEYS.TIER2},
        room_choices={ 
            ["MonkeyDummyExitRoom"] = 1, 
        },  
        room_bg=GROUND.MONKEY_GROUND,
        colour={r=1,g=1,b=1,a=0.3}
    }) 
end

if GetModConfigData("monkeyisland") == true then
    AddLevelPreInit("SURVIVAL_DEFAULT", function(level)
        -- 安全注入：钩住 GetTasksForLevel，避免 AddSetPeices 崩溃
        local _GetTasksForLevel = level.GetTasksForLevel
        level.GetTasksForLevel = function(self, sampletasks)
            local found_monkey, found_none = false, false
            for _, t in ipairs(self.tasks) do
                if t == "MonkeyIsland" then found_monkey = true end
                if t == "MonkeyNoneTasks" then found_none = true end
            end
            if not found_monkey then table.insert(self.tasks, "MonkeyIsland") end
            if not found_none then table.insert(self.tasks, "MonkeyNoneTasks") end
            return _GetTasksForLevel(self, sampletasks)
        end

        -- 虫洞连接：把猴岛加入主大陆虫洞网络
        if level.set_pieces["WormholeGrass"] then
            local wg = level.set_pieces["WormholeGrass"]
            local found = false
            for _, t in ipairs(wg.tasks) do
                if t == "MonkeyIsland" then found = true; break end
            end
            if not found then
                table.insert(wg.tasks, "MonkeyIsland")
                wg.count = (wg.count or 1) + 1
            end
        else
            level.set_pieces["WormholeGrass"] = { count = 1, tasks = {"MonkeyIsland"} }
        end
    end)
end
