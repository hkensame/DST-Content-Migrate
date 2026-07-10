-- room_defs.lua - 所有 DST 风格房间定义合集
-- 包含：DST 洞穴房间 + 毒菌蛤蟆竞技场房间

-- DS 没有 Roomify 函数（DST 专有），这里提供兼容 shim
-- Roomify 的作用：复制 room table 并设置 type = NODE_TYPE.Room
if not Roomify then
    Roomify = function(room)
        local new_room = {}
        for k, v in pairs(room) do
            if type(v) == "table" then
                new_room[k] = {}
                for k2, v2 in pairs(v) do
                    new_room[k][k2] = v2
                end
            else
                new_room[k] = v
            end
        end
        new_room.type = NODE_TYPE.Room
        return new_room
    end
end

-- ======================== 入口区 ENTRANCE ========================
AddRoom("DST_Entrance", {
    colour={r=0.2,g=0.8,b=0.2,a=1},
    value = GROUND.GRASS,

    contents = {
        distributepercent = .2,
        distributeprefabs = {
            cavelight = 0.05,
            ["cave/objects/flower_cave"] = 0.5,
        },
    },
})
AddRoom("DST_EntranceBG", {
    colour={r=0.2,g=0.8,b=0.2,a=1},
    value = GROUND.GRASS,

    contents = {},
})

-- ======================== 泥地区 MUD ========================
AddRoom("DST_LightPlantField", {
    colour={r=0.7,g=0.5,b=0.3,a=0.9},
    value = GROUND.MUD,

    contents =  {
        countprefabs= {
            daywalkerspawningground = 1,
        },
        distributepercent = .2,
        distributeprefabs=
        {
            ["cave/objects/flower_cave"] = 1.0,
            ["cave/objects/flower_cave_double"] = 0.5,
            ["cave/objects/flower_cave_triple"] = 0.5,

            stalagmite_tall=0.05,
            stalagmite_tall_med=0.05,
            stalagmite_tall_low=0.1,
            pillar_cave_rock = 0.01,

            cave_fern = 0.1,
            wormlight_plant = 0.02,

            slurtlehole = 0.01,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_WormPlantField", {
    colour={r=0.7,g=0.5,b=0.3,a=0.9},
    value = GROUND.MUD,

    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            ["cave/objects/flower_cave"] = 0.5,
            ["cave/objects/flower_cave_double"] = 0.1,
            ["cave/objects/flower_cave_triple"] = 0.1,

            stalagmite_tall=0.05,
            stalagmite_tall_med=0.05,
            stalagmite_tall_low=0.1,
            pillar_cave_rock = 0.01,

            cave_fern = 0.1,
            wormlight_plant = 0.2,

            slurtlehole = 0.01,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_FernGully", {
    colour={r=0.7,g=0.5,b=0.3,a=0.9},
    value = GROUND.MUD,

    contents =  {
        distributepercent = .25,
        distributeprefabs=
        {
            ["cave/objects/flower_cave"] = 0.2,
            ["cave/objects/flower_cave_double"] = 0.1,
            ["cave/objects/flower_cave_triple"] = 0.1,

            stalagmite_tall=0.5,
            stalagmite_tall_med=0.3,
            stalagmite_tall_low=0.2,
            pillar_cave_rock = 0.1,

            cave_fern = 2.0,
            wormlight_plant = 0.05,

            slurtlehole = 0.01,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_SlurtlePlains", {
    colour={r=0.7,g=0.5,b=0.3,a=0.9},
    value = GROUND.MUD,

    contents =  {
        distributepercent = .20,
        distributeprefabs=
        {
            ["cave/objects/flower_cave"] = 0.2,
            ["cave/objects/flower_cave_double"] = 0.1,
            ["cave/objects/flower_cave_triple"] = 0.1,

            stalagmite_tall=1.5,
            stalagmite_tall_med=0.5,
            stalagmite_tall_low=0.5,
            pillar_cave_rock = 0.1,

            cave_fern = 0.5,
            wormlight_plant = 0.01,

            slurtlehole = 0.5,
        },
    }
})

AddRoom("DST_MudWithRabbit", {
    colour={r=0.7,g=0.5,b=0.3,a=0.9},
    value = GROUND.MUD,

    contents =  {
        countstaticlayouts =
        {
            ["RabbitHermit"] = 1,
        },
        distributepercent = .15,
        distributeprefabs=
        {
            ["cave/objects/flower_cave"] = 0.5,
            ["cave/objects/flower_cave_double"] = 0.3,
            ["cave/objects/flower_cave_triple"] = 0.2,

            stalagmite_tall=0.5,
            stalagmite_tall_med=0.3,
            stalagmite_tall_low=0.2,
            pillar_cave_rock = 0.1,

            cave_fern = 1.0,

            slurper = 0.001,
        },
    }
})

local bgmud = {
    colour={r=0.7,g=0.5,b=0.3,a=0.9},
    value = GROUND.MUD,

    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            flower_cave = 0.1,

            stalagmite_tall=1.5,
            stalagmite_tall_med=1.0,
            stalagmite_tall_low=0.5,
            pillar_cave_rock = 0.1,

            cave_fern = 1.0,

            slurtlehole = 0.05,

            slurper = 0.001,
        },
    }
}
AddRoom("DST_BGMud", bgmud)
AddRoom("DST_BGMudRoom", Roomify(bgmud))

-- ======================== 蝙蝠洞 BAT ========================
AddRoom("DST_BatCave", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.CAVE,
    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            batcave = 0.05,
            guano = 0.27,
            goldnugget=.05,
            flint=0.05,
            stalagmite_tall=0.4,
            stalagmite_tall_med=0.4,
            stalagmite_tall_low=0.4,
            pillar_cave_rock = 0.08,
            fissure = 0.05,
        }
    }
})

AddRoom("DST_BattyCave", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.CAVE,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .25,
        distributeprefabs=
        {
            batcave = 0.15,
            guano = 0.27,
            goldnugget=.05,
            flint=0.05,
            stalagmite_tall=0.4,
            stalagmite_tall_med=0.4,
            stalagmite_tall_low=0.4,
            pillar_cave_rock = 0.08,
            fissure = 0.05,
        }
    }
})

AddRoom("DST_FernyBatCave", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.CAVE,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .25,
        distributeprefabs=
        {
            cave_fern = 0.5,
            batcave = 0.05,
            guano = 0.27,
            goldnugget=.05,
            flint=0.05,
            stalagmite_tall=0.1,
            stalagmite_tall_med=0.1,
            stalagmite_tall_low=0.1,
            pillar_cave_rock = 0.08,
            fissure = 0.05,
        }
    }
})

local bgbatcave = {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.CAVE,

    contents =  {
        distributepercent = .13,
        distributeprefabs=
        {
            batcave = 0.05,
            stalagmite_tall=0.4,
            stalagmite_tall_med=0.4,
            stalagmite_tall_low=0.4,
            pillar_cave_rock = 0.01,
            fissure = 0.05,
        }
    }
}
AddRoom("DST_BGBatCave", bgbatcave)
AddRoom("DST_BGBatCaveRoom", Roomify(bgbatcave))

-- ======================== 岩石区 ROCKY ========================
AddRoom("DST_SlurtleCanyon", {
    colour={r=0.7,g=0.7,b=0.7,a=0.9},
    value = GROUND.CAVE,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            rock_flintless = 1.0,
            rock_flintless_med = 1.0,
            rock_flintless_low = 1.0,
            pillar_cave_flintless = 1.2,

            slurtlehole = 0.5,

            fissure = 0.01,
        },
    }
})

AddRoom("DST_BatsAndSlurtles", {
    colour={r=0.7,g=0.7,b=0.7,a=0.9},
    value = GROUND.CAVE,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            rock_flintless = 1.0,
            rock_flintless_med = 1.0,
            rock_flintless_low = 1.0,
            pillar_cave_flintless = 0.2,

            stalagmite_tall=0.5,
            stalagmite_tall_med=0.2,
            stalagmite_tall_low=0.2,
            pillar_cave_rock = 0.1,

            slurtlehole = 0.5,
            batcave = 0.1,

            fissure = 0.01,
        },
    }
})

AddRoom("DST_RockyPlains", {
    colour={r=0.7,g=0.7,b=0.7,a=0.9},
    value = GROUND.CAVE,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .10,
        distributeprefabs=
        {
            rock_flintless = 1.0,
            rock_flintless_med = 1.0,
            rock_flintless_low = 1.0,
            pillar_cave_flintless = 0.2,

            rocky = 0.5,
            goldnugget=.05,
            rocks=.1,
            flint=0.05,

            slurtlehole = 0.05,

            fissure = 0.01,
        },
    }
})

AddRoom("DST_RockyHatchingGrounds", {
    colour={r=0.7,g=0.7,b=0.7,a=0.9},
    value = GROUND.CAVE,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .25,
        distributeprefabs=
        {
            rock_flintless = 1.0,
            rock_flintless_med = 1.0,
            rock_flintless_low = 1.0,
            pillar_cave_flintless = 0.2,

            rocky = 1.0,
            goldnugget=.05,
            rocks=.1,
            flint=0.05,

            slurtlehole = 0.05,

            fissure = 0.01,
        },
    }
})

AddRoom("DST_BatsAndRocky", {
    colour={r=0.7,g=0.7,b=0.7,a=0.9},
    value = GROUND.CAVE,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .20,
        distributeprefabs=
        {
            rock_flintless = 1.0,
            rock_flintless_med = 1.0,
            rock_flintless_low = 1.0,
            pillar_cave_flintless = 0.8,

            stalagmite_tall=0.5,
            stalagmite_tall_med=0.2,
            stalagmite_tall_low=0.2,
            pillar_cave_rock = 0.1,

            rocky = 0.5,
            goldnugget=.05,
            rocks=.1,
            flint=0.05,

            slurtlehole = 0.05,
            batcave = 0.10,

            fissure = 0.01,
        },
    }
})

local bgrocky = {
    colour={r=0.7,g=0.7,b=0.7,a=0.9},
    value = GROUND.CAVE,

    contents =  {
        distributepercent = .10,
        distributeprefabs=
        {
            rock_flintless = 1.0,
            rock_flintless_med = 1.0,
            rock_flintless_low = 1.0,
            pillar_cave_flintless = 0.2,

            slurtlehole = 0.05,

            fissure = 0.01,
        },
    }
}
AddRoom("DST_BGRockyCave", bgrocky)
AddRoom("DST_BGRockyCaveRoom", Roomify(bgrocky))

-- ======================== 红色蘑菇区 RED MUSH ========================
AddRoom("DST_RedMushForest", {
    colour={r=0.8,g=0.1,b=0.1,a=0.9},
    value = GROUND.FUNGUSRED,

    contents =  {
        distributepercent = .3,
        distributeprefabs=
        {
            mushtree_medium = 6.0,
            red_mushroom = 0.5,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            stalagmite = 0.35,
            stalagmite_med = 0.1,
            stalagmite_low = 0.05,
            pillar_cave = 0.1,
            spiderhole = 0.05,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_RedSpiderForest", {
    colour={r=0.8,g=0.1,b=0.4,a=0.9},
    value = GROUND.FUNGUSRED,

    contents =  {
        distributepercent = .3,
        distributeprefabs=
        {
            mushtree_medium = 3.0,
            red_mushroom = 0.25,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            stalagmite = 1.0,
            stalagmite_med = 0.4,
            stalagmite_low = 0.1,
            pillar_cave = 0.2,
            spiderhole = 0.4,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_RedMushPillars", {
    colour={r=0.8,g=0.1,b=0.4,a=0.9},
    value = GROUND.FUNGUSRED,

    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            mushtree_medium = 2.0,
            red_mushroom = 1.5,
            flower_cave = 0.5,
            flower_cave_double = 0.2,
            flower_cave_triple = 0.2,

            stalagmite = 0.35,
            stalagmite_med = 0.1,
            stalagmite_low = 0.05,
            pillar_cave = 0.5,
            spiderhole = 0.01,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_StalagmiteForest", {
    colour={r=0.8,g=0.1,b=0.1,a=0.9},
    value = GROUND.FUNGUSRED,

    contents =  {
        distributepercent = .3,
        distributeprefabs=
        {
            mushtree_medium = 1.0,
            red_mushroom = 0.25,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            stalagmite = 2.5,
            stalagmite_med = 0.7,
            stalagmite_low = 0.3,
            pillar_cave = 1.0,
            spiderhole = 0.15,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_SpillagmiteMeadow", {
    colour={r=0.8,g=0.1,b=0.1,a=0.9},
    value = GROUND.FUNGUSRED,

    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            mushtree_medium = 0.5,
            red_mushroom = 0.25,
            flower_cave = 0.5,
            flower_cave_double = 0.2,
            flower_cave_triple = 0.2,

            stalagmite = 1.0,
            stalagmite_med = 0.4,
            stalagmite_low = 0.1,
            pillar_cave = 0.05,
            spiderhole = 0.45,

            slurper = 0.001,
        },
    }
})

local bgredmush = {
    colour={r=0.8,g=0.1,b=0.1,a=0.9},
    value = GROUND.FUNGUSRED,

    contents =  {
        distributepercent = .3,
        distributeprefabs=
        {
            mushtree_medium = 6.0,
            red_mushroom = 0.5,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            stalagmite = 0.1,
            stalagmite_med = 0.07,
            stalagmite_low = 0.03,
            pillar_cave = 0.05,
            spiderhole = 0.01,

            slurper = 0.001,
        },
    }
}
AddRoom("DST_BGRedMush", bgredmush)
AddRoom("DST_BGRedMushRoom", Roomify(bgredmush))

-- ======================== 绿色蘑菇区 GREEN MUSH ========================
AddRoom("DST_GreenMushForest", {
    colour={r=0.1,g=0.8,b=0.1,a=0.9},
    value = GROUND.FUNGUSGREEN,

    contents =  {
        distributepercent = .35,
        distributeprefabs=
        {
            mushtree_small = 6.0,
            green_mushroom = 0.5,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            rabbithouse = 0.02,

            cave_fern = 2.5,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_GreenMushPonds", {
    colour={r=0.1,g=0.8,b=0.3,a=0.9},
    value = GROUND.FUNGUSGREEN,

    contents =  {
        distributepercent = .3,
        distributeprefabs=
        {
            mushtree_small = 3.0,
            green_mushroom = 0.5,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            pond = 0.5,

            cave_fern = 2.5,

            slurper = 0.001,
            rabbithouse = 0.005,
        },
    }
})

AddRoom("DST_GreenMushSinkhole", {
    colour={r=0.1,g=0.8,b=0.3,a=0.9},
    value = GROUND.FUNGUSGREEN,

    contents =  {
        countstaticlayouts={
            ["EvergreenSinkhole"]=1,
        },
        distributepercent = .2,
        distributeprefabs=
        {
            mushtree_small = 1.0,
            green_mushroom = 0.5,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            cavelight = 0.05,
            cavelight_small = 0.05,

            evergreen = 0.1,
            grass = 0.1,
            sapling = 0.1,
            twiggytree = 0.04,
            berrybush = 0.05,
            berrybush_juicy = 0.025,

            cave_fern = 3.5,

            slurper = 0.001,
            rabbithouse = 0.005,
        },
    }
})

AddRoom("DST_GreenMushMeadow", {
    colour={r=0.1,g=0.8,b=0.3,a=0.9},
    value = GROUND.FUNGUSGREEN,

    contents =  {
        distributepercent = .25,
        distributeprefabs=
        {
            mushtree_small = 2.0,
            green_mushroom = 2.0,
            flower_cave = 0.5,
            flower_cave_double = 0.2,
            flower_cave_triple = 0.2,

            cave_fern = 3.5,

            slurper = 0.001,
            rabbithouse = 0.005,
        },
    }
})

AddRoom("DST_GreenMushRabbits", {
    colour={r=0.1,g=0.8,b=0.3,a=0.9},
    value = GROUND.FUNGUSGREEN,

    contents =  {
        countstaticlayouts={
            ["RabbitTown"]=1,
        },
        distributepercent = .2,
        distributeprefabs=
        {
            mushtree_small = 2.0,
            green_mushroom = 0.5,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            cavelight = 0.05,
            cavelight_small = 0.05,

            evergreen = 0.1,
            grass = 0.1,
            sapling = 0.1,
            twiggytree = 0.04,
            berrybush = 0.05,
            berrybush_juicy = 0.025,

            cave_fern = 3.5,

            slurper = 0.001,
            rabbithouse = 0.005,
        },
    }
})

AddRoom("DST_GreenMushNoise", {
    colour={r=0.1,g=0.8,b=0.3,a=0.9},
    value = GROUND.FUNGUSGREEN,

    contents =  {
        distributepercent = .25,
        distributeprefabs=
        {
            mushtree_small = 2.0,
            green_mushroom = 2.0,
            flower_cave = 0.5,
            flower_cave_double = 0.2,
            flower_cave_triple = 0.2,

            cave_fern = 3.5,

            slurper = 0.001,
            rabbithouse = 0.005,
        },
    }
})

local bggreenmush = {
    colour={r=0.1,g=0.8,b=0.1,a=0.9},
    value = GROUND.FUNGUSGREEN,

    contents =  {
        distributepercent = .25,
        distributeprefabs=
        {
            mushtree_small = 6.0,
            green_mushroom = 0.5,
            flower_cave = 0.1,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            rabbithouse = 0.02,

            cave_fern = 2.5,

            slurper = 0.001,
        },
    }
}
AddRoom("DST_BGGreenMush", bggreenmush)
AddRoom("DST_BGGreenMushRoom", Roomify(bggreenmush))

-- ======================== 蓝色蘑菇区 BLUE MUSH ========================
AddRoom("DST_BlueMushForest", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = GROUND.FUNGUS,

    contents =  {
        distributepercent = .6,
        distributeprefabs=
        {
            mushtree_tall = 6.0,
            blue_mushroom = 0.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            batcave = 0.005,
            dropperweb = 0.015,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_BlueMushMeadow", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = GROUND.FUNGUS,

    contents =  {
        distributepercent = .3,
        distributeprefabs=
        {
            mushtree_tall = 1.0,
            blue_mushroom = 2.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            batcave = 0.005,
            dropperweb = 0.015,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_BlueSpiderForest", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = GROUND.FUNGUS,

    contents =  {
        distributepercent = .4,
        distributeprefabs=
        {
            mushtree_tall = 3.0,
            blue_mushroom = 2.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            dropperweb = 0.1,
            boneshard = 0.2,
            houndbone = 0.2,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_BlueDropperDesolation", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = GROUND.FUNGUS,

    contents =  {
        distributepercent = .2,
        distributeprefabs=
        {
            mushtree_tall = 2.0,
            blue_mushroom = 1.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            dropperweb = 1.5,
            boneshard = 0.4,
            houndbone = 1.6,

            slurper = 0.001,
        },
    }
})

local bgbluemush = {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = GROUND.FUNGUS,

    contents =  {
        distributepercent = .6,
        distributeprefabs=
        {
            mushtree_tall = 6.0,
            blue_mushroom = 0.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            batcave = 0.005,
            dropperweb = 0.015,

            slurper = 0.001,
        },
    }
}

AddRoom("DST_BGBlueMush", bgbluemush)
AddRoom("DST_BGBlueMushRoom", Roomify(bgbluemush))

-- ======================== 月蘑菇区 MOON MUSH ========================
AddRoom("DST_MoonMushForest", {
    colour={r=0.3,g=0.3,b=0.3,a=0.9},
    value = GROUND.FUNGUSMOON,

    random_node_entrance_weight = 0,
    contents =  {
        countstaticlayouts =
        {
            ["GrottoPoolBig"] = 1,
            ["GrottoPoolSmall"] = 4,
        },
        countprefabs =
        {
            mushgnome_spawner = 1,
        },
        distributepercent = 0.35,
        distributeprefabs =
        {
            mushtree_moon = 0.075,

            lightflier_flower = 0.02,

            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
        },
    }
})

AddRoom("DST_MoonMushForest_entrance", {
    colour={r=0.3,g=0.3,b=0.3,a=0.9},
    value = GROUND.FUNGUSMOON_NOISE,

    random_node_exit_weight = 0,
    contents =  {
		distributepercent = 0.20,
        distributeprefabs =
        {
			-- mushroom only
			mushtree_tall =	0.30,
            flower_cave = 0.10,

			-- moon only
            mushtree_moon = 0.40,
            lightflier_flower = 0.01,

			-- anywhere
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,
        },
    }
})

-- ======================== 石笋区 SPILLAGMITE ========================
AddRoom("DST_SpillagmiteForest", {
    colour={r=0.4,g=0.4,b=0.4,a=0.9},
    value = GROUND.UNDERROCK,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .35,
        distributeprefabs=
        {
            stalagmite = 0.35,
            stalagmite_med = 0.1,
            stalagmite_low = 0.05,
            pillar_cave = 0.1,
            pillar_stalactite = 0.1,
            spiderhole = 0.05,

            fissure = 0.01,
        },
    }
})

AddRoom("DST_DropperCanyon", {
    colour={r=0.4,g=0.4,b=0.4,a=0.9},
    value = GROUND.UNDERROCK,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .35,
        distributeprefabs=
        {
            stalagmite = 0.35,
            stalagmite_med = 0.1,
            stalagmite_low = 0.05,
            pillar_cave = 0.2,
            pillar_stalactite = 0.2,
            dropperweb = 0.15,

            boneshard = 0.2,
            houndbone = 0.2,

            fissure = 0.01,
        },
    }
})

AddRoom("DST_StalagmitesAndLights", {
    colour={r=0.4,g=0.4,b=0.4,a=0.9},
    value = GROUND.UNDERROCK,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            stalagmite = 0.35,
            stalagmite_med = 0.1,
            stalagmite_low = 0.05,
            pillar_cave = 0.1,
            pillar_stalactite = 0.1,
            spiderhole = 0.01,

            flower_cave = 0.1,

            fissure = 0.1,
            slurper = 0.001,
        },
    }
})

AddRoom("DST_SpidersAndBats", {
    colour={r=0.4,g=0.4,b=0.4,a=0.9},
    value = GROUND.UNDERROCK,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            stalagmite = 0.35,
            stalagmite_med = 0.1,
            stalagmite_low = 0.05,
            pillar_cave = 0.1,
            pillar_stalactite = 0.1,
            spiderhole = 0.05,
            batcave = 0.05,

            fissure = 0.01,
        },
    }
})

AddRoom("DST_ThuleciteDebris", {
    colour={r=0.4,g=0.4,b=0.4,a=0.9},
    value = GROUND.UNDERROCK,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            stalagmite = 0.35,
            stalagmite_med = 0.1,
            stalagmite_low = 0.05,
            pillar_cave = 0.1,
            pillar_stalactite = 0.1,
            spiderhole = 0.01,
            batcave = 0.01,

            fissure = 0.1,
            thulecite = 0.01,
            thulecite_pieces = 0.05,
        },
    }
})

local bgspillagmite = {
    colour={r=0.4,g=0.4,b=0.4,a=0.9},
    value = GROUND.UNDERROCK,

    contents =  {
        distributepercent = .35,
        distributeprefabs=
        {
            stalagmite = 0.35,
            stalagmite_med = 0.1,
            stalagmite_low = 0.05,
            pillar_cave = 0.1,
            pillar_stalactite = 0.1,
            spiderhole = 0.05,

            fissure = 0.01,
        },
    }
}
AddRoom("DST_BGSpillagmite", bgspillagmite)
AddRoom("DST_BGSpillagmiteRoom", Roomify(bgspillagmite))

-- ======================== 沼泽区 SWAMP ========================
AddRoom("DST_SinkholeSwamp", {
    colour={r=0.4,g=0.1,b=0.6,a=0.9},
    value = GROUND.MARSH,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .35,
        distributeprefabs=
        {
            tentacle = 1,
            reeds = 0.5,
            marsh_bush = 1.5,
            marsh_tree = 0.2,
            spiderden = 0.2,

            cavelight = 0.5,
            cavelight_small = 0.5,
            cavelight_tiny = 0.5,
        },
    }
})

AddRoom("DST_DarkSwamp", {
    colour={r=0.4,g=0.1,b=0.6,a=0.9},
    value = GROUND.MARSH,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .25,
        distributeprefabs=
        {
            tentacle = 0.5,
            reeds = 0.1,
            marsh_bush = 1.5,
            spiderden = 0.02,

            cavelight_tiny = 0.5,
        },
    }
})

AddRoom("DST_TentacleMud", {
    colour={r=0.4,g=0.1,b=0.6,a=0.9},
    value = GROUND.MARSH,

    type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts={
            ["Mudlights"]=6,
        },
        distributepercent = .25,
        distributeprefabs=
        {
            tentacle = 1,
            marsh_bush = 1.5,
            reeds = 0.1,
            spiderden = 0.05,

            cavelight = 0.5,
            cavelight_small = 0.5,
            cavelight_tiny = 0.5,
        },
    }
})

AddRoom("DST_TentaclesAndTrees", {
    colour={r=0.4,g=0.1,b=0.6,a=0.9},
    value = GROUND.MARSH,

    type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts={
            ["EvergreenSinkhole"]=3,
        },
        distributepercent = .25,
        distributeprefabs=
        {
            tentacle = 1,
            marsh_bush = 1.5,
            marsh_tree = 1.2,
            spiderden = 0.2,

            cavelight = 0.5,
            cavelight_small = 0.5,
            cavelight_tiny = 0.5,
        },
    }
})

local bgsinkholeswamp = {
    colour={r=0.4,g=0.1,b=0.6,a=0.9},
    value = GROUND.MARSH,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .35,
        distributeprefabs=
        {
            tentacle = 1,
            reeds = 0.5,
            marsh_bush = 1.5,
            marsh_tree = 0.2,
            spiderden = 0.2,

            cavelight = 0.5,
            cavelight_small = 0.5,
            cavelight_tiny = 0.5,
        },
    }
}
AddRoom("DST_BGSinkholeSwamp", bgsinkholeswamp)
AddRoom("DST_BGSinkholeSwampRoom", Roomify(bgsinkholeswamp))

-- ======================== 天井区 SINKHOLE ========================
AddRoom("DST_SinkholeForest", {
    colour={r=0.2,g=1,b=0.5,a=0.9},
    value = GROUND.SINKHOLE,

    contents =  {
        distributepercent = .55,
        distributeprefabs=
        {
            grass = 1,
            sapling = .8,
            twiggytree = .32,
            evergreen = 6.3,
            fireflies = .1,
            cavelight = 0.5,
            cavelight_small = 0.5,
            cavelight_tiny = 0.5,
            spiderden = 0.3,
        },
    }
})

AddRoom("DST_SinkholeCopses", {
    colour={r=0.2,g=1,b=0.5,a=0.9},
    value = GROUND.SINKHOLE,

    contents =  {
        countstaticlayouts={
            ["EvergreenSinkhole"]=3,
        },
        distributepercent = .15,
        distributeprefabs=
        {
            grass = 1,
            sapling = .8,
            twiggytree = .32,
            evergreen = .3,
            cave_fern = .75,
            berrybush = .2,
            berrybush_juicy = 0.1,
            fireflies = .1,
            cavelight = 0.01,
            cavelight_small = 0.01,
            cavelight_tiny = 0.01,
            spiderden = 0.03,
        },
    }
})

AddRoom("DST_SparseSinkholes", {
    colour={r=0.2,g=1,b=0.5,a=0.9},
    value = GROUND.SINKHOLE,

    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            grass = 1,
            sapling = .8,
            twiggytree = .32,
            evergreen = .3,
            cave_fern = .75,
            fireflies = .1,
            cavelight = 0.06,
            cavelight_small = 0.06,
            cavelight_tiny = 0.06,
            spiderden = 0.03,
        },
    }
})

AddRoom("DST_SinkholeOasis", {
    colour={r=0.2,g=1,b=0.5,a=0.9},
    value = GROUND.SINKHOLE,

    contents =  {
        countstaticlayouts={
            ["PondSinkhole"]=1,
        },
        distributepercent = .15,
        distributeprefabs=
        {
            grass = 1,
            sapling = .8,
            twiggytree = .32,
            pond = .05,
            stalagmite = 0.02,
            stalagmite_med = 0.007,
            stalagmite_low = 0.003,
            cave_fern = .75,
            berrybush = .2,
            berrybush_juicy = 0.1,
            fireflies = .1,
            cavelight = 0.01,
            cavelight_small = 0.01,
            cavelight_tiny = 0.01,
            spiderden = 0.03,
        },
    }
})

AddRoom("DST_GrasslandSinkhole", {
    colour={r=0.2,g=1,b=0.5,a=0.9},
    value = GROUND.SINKHOLE,

    contents =  {
        countstaticlayouts={
            ["GrassySinkhole"]=1,
        },
        distributepercent = .05,
        distributeprefabs=
        {
            grass = 2,
            cavelight = 0.6,
            cavelight_small = 0.6,
            cavelight_tiny = 0.6,
        },
    }
})

AddRoom("DST_SpiderSinkholeMarsh", {
    colour={r=0.2,g=0.5,b=0.2,a=0.9},
    value = GROUND.SINKHOLE,

    contents =  {
        distributepercent = .1,
        distributeprefabs=
        {
            evergreen = 1.0,
            tentacle = 2,
            pond_mos = 0.1,
            blue_mushroom = 0.1,
            reeds =  4,
            spiderden=3.15,

            cavelight = 0.5,
            cavelight_small = 0.5,
            cavelight_tiny = 0.5,
        },
    }
})

local bgsinkhole = {
    colour={r=0.2,g=1,b=0.5,a=0.9},
    value = GROUND.SINKHOLE,

    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
            grass = 1,
            sapling = .8,
            twiggytree = .32,
            evergreen = .3,
            cave_fern = .75,
            fireflies = .1,
            cavelight = 0.06,
            cavelight_small = 0.06,
            cavelight_tiny = 0.06,
            spiderden = 0.03,
        },
    }
}
AddRoom("DST_BGSinkhole", bgsinkhole)
AddRoom("DST_BGSinkholeRoom", Roomify(bgsinkhole))

-- ======================== 真菌噪声区 FUNGUS NOISE ========================
AddRoom("DST_FungusNoiseForest", {
    colour={r=1.0,g=0.5,b=1.0,a=0.9},
    value = GROUND.FUNGUS_NOISE,

    contents =  {
        distributepercent = .4,
        distributeprefabs=
        {
            mushtree_medium = 6.0,
            mushtree_tall = 6.0,
            mushtree_small = 6.0,
            red_mushroom = 0.5,
            green_mushroom = 0.5,
            blue_mushroom = 0.5,

            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            slurper = 0.001,
        },
    }
})

AddRoom("DST_FungusNoiseMeadow", {
    colour={r=1.0,g=1.0,b=1.0,a=0.9},
    value = GROUND.FUNGUS_NOISE,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .25,
        distributeprefabs=
        {
            mushtree_medium = 1.0,
            mushtree_tall = 1.0,
            mushtree_small = 1.0,
            red_mushroom = 2.5,
            green_mushroom = 2.5,
            blue_mushroom = 2.5,

            flower_cave = 1.5,
            flower_cave_double = 1.0,
            flower_cave_triple = 1.0,

            slurper = 0.001,
        },
    }
})

-- ======================== 排气口区 VENTS ========================
AddRoom("DST_BGVentsRoom", {
    colour={r=0.8,g=0.8,b=0.8,a=0.9},
    value = GROUND.VENT,
    type = NODE_TYPE.Background,
    random_node_exit_weight = 1,
    tags = {"fumarolearea"},
    contents =  {
        countprefabs =
        {
            cave_vent_mite_spawner = 1,
        },
        distributepercent = .24,
        distributeprefabs =
        {
            cave_vent_rock  = 0.1,
            tree_rock1      = 0.045,
            tree_rock2      = 0.045,

            cave_fern_withered = 0.2,
            flower_cave_withered = 0.03,
            flower_cave_double_withered = 0.015,
            flower_cave_triple_withered = 0.015,
        },
    },
})
AddRoom("DST_VentsRoom", {
    colour={r=.8,g=1,b=.8,a=.50},
    value = GROUND.VENT,
    random_node_exit_weight = 1,
    tags = {"fumarolearea"},
    contents =  {
        countprefabs =
        {
            cave_vent_mite_spawner = 1,
        },
        distributepercent = .22,
        distributeprefabs=
        {
            cave_vent_rock  = 0.5,
            tree_rock1      = 0.15,
            tree_rock2      = 0.15,

            cave_fern_withered = 1.0,
        },
    },
})
AddRoom("DST_CentipedeNest", {
    colour={r=.8,g=1,b=.8,a=.50},
    value = GROUND.VENT,
    random_node_entrance_weight = 0,
    type = NODE_TYPE.Room,
    tags = {"fumarolearea"},
    contents =  {
        distributepercent = .42,
        distributeprefabs =
        {
            cave_vent_rock  = 0.4,
            tree_rock1      = 0.02,
            tree_rock2      = 0.02,
            cave_fern_withered       = 0.8,

            flower_cave_withered = 0.05,
            flower_cave_double_withered = 0.025,
            flower_cave_triple_withered = 0.025,
        },
    },
})
AddRoom("DST_RockTreeRoom", {
    colour={r=.8,g=1,b=.8,a=.50},
    value = GROUND.VENT,
    random_node_exit_weight = 0,
    type = NODE_TYPE.Room,
    tags = {"fumarolearea"},
    contents =  {
        countprefabs = {
            tree_rock1      = function() return math.random(3) end,
            tree_rock2      = function() return math.random(3) end,
        },
        distributepercent = .12,
        distributeprefabs=
        {
            cave_vent_rock  = 0.1,
            tree_rock1      = 0.5,
            tree_rock2      = 0.5,
            cave_fern_withered       = 0.3,

            flower_cave_withered = 0.04,
            flower_cave_double_withered = 0.02,
            flower_cave_triple_withered = 0.02,
        },
    },
})
AddRoom("DST_VentsRoom_exit", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = GROUND.VENT_NOISE,
	random_node_entrance_weight = 0,
    tags = {"ExitPiece", "fumarolearea"},
    contents =  {
        countprefabs =
        {
            cave_vent_mite_spawner = 1,
        },
		distributepercent = 0.23,
        distributeprefabs =
        {
            cave_vent_rock = 0.1,
            tree_rock1 = 0.01,
            tree_rock2 = 0.01,
            cave_fern_withered = 0.2,

            flower_cave_withered = 0.04,
            flower_cave_double_withered = 0.02,
            flower_cave_triple_withered = 0.02,
        },
    },
})
AddRoom("DST_RuinsIsland", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = GROUND.TILES,
    SafeFromDisconnect = true,
    tags = {"ForceDisconnected", "RoadPoison", "not_mainland"},
    random_node_entrance_weight = 0,
    contents =  {
        countprefabs =
        {
            mushgnome_spawner = 1,
        },
        distributepercent = 0.35,
        distributeprefabs =
        {
            mushtree_moon = 0.075,

            lightflier_flower = 0.02,

            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
        },
    }
})
AddRoom("DST_RuinsIsland_entrance", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = GROUND.VENT_NOISE,
    SafeFromDisconnect = true,
    tags = {"ForceDisconnected", "RoadPoison", "not_mainland"},
	random_node_exit_weight = 0,
    contents =  {
		distributepercent = 0.20,
        distributeprefabs =
        {
			-- mushroom only
			mushtree_tall =	0.30,
            flower_cave = 0.10,

			-- moon only
            mushtree_moon = 0.40,
            lightflier_flower = 0.01,

			-- anywhere
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,
        },
    },
})

-- ======================== 兔子区 RABBIT ========================
AddRoom("DST_RabbitArea", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.SINKHOLE,
    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .2,
        distributeprefabs=
        {
            cavelight = 0.05,
            cavelight_small = 0.05,
            cavelight_tiny = 0.05,
            flower_cave = 0.5,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.05,
            carrot_planted = 1,
            rabbithouse = 0.21,
            cave_fern=0.5,
            fireflies = 0.01,

            red_mushroom = 0.1,
            green_mushroom = 0.1,
            blue_mushroom = 0.1,
        }
    }
})

AddRoom("DST_RabbitTown", {
    colour={r=0.3,g=0.2,b=0.3,a=0.9},
    value = GROUND.SINKHOLE,
    contents =  {
        countstaticlayouts={
            ["RabbitTown"]=1,
        },
        distributepercent = .2,
        distributeprefabs=
        {
            cavelight = 0.1,
            cavelight_small = 0.1,
            cavelight_tiny = 0.1,
            flower_cave=0.75,
            carrot_planted = 1,
            cave_fern=0.75,
            rabbithouse = 0.51,
            fireflies = 0.01,
        }
    }
})

AddRoom("DST_RabbitCity", {
    colour={r=0.3,g=0.2,b=0.5,a=0.9},
    value = GROUND.SINKHOLE,
    contents =  {
        countstaticlayouts={
            ["RabbitCity"]=1,
        },
        distributepercent = .15,
        distributeprefabs=
        {
            cavelight = 0.1,
            cavelight_small = 0.1,
            cavelight_tiny = 0.1,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.05,
            flower_cave=0.75,
            carrot_planted = 1,
            cave_fern=0.75,
            rabbithouse = 0.51,
            fireflies = 0.01,
        }
    }
})

AddRoom("DST_RabbitSinkhole", {
    colour={r=.15,g=.18,b=.15,a=.50},
    value = GROUND.SINKHOLE,
    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .175,
        distributeprefabs =
        {
            cavelight = 25,
            cavelight_small = 25,
            cavelight_tiny = 25,

            spiderden = .1,
            rabbithouse = 1,

            fireflies = 1,
            sapling = 15,
            twiggytree = 6,
            evergreen = .25,
            berrybush = .5,
            berrybush_juicy = 0.25,
            blue_mushroom = .5,
            green_mushroom = .3,
            red_mushroom = .4,
            grass = .25,
            cave_fern = 20,
        },
    }
})

AddRoom("DST_SpiderIncursion", {
    colour={r=.10,g=.08,b=.05,a=.50},
    value = GROUND.SINKHOLE,
    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .175,
        distributeprefabs =
        {
            cavelight = 25,
            cavelight_small = 25,
            cavelight_tiny = 25,

            spiderden = .1,
            rabbithouse = 1,

            fireflies = 1,
            sapling = 15,
            twiggytree = 6,
            evergreen = .25,
            berrybush = .5,
            berrybush_juicy = 0.25,
            blue_mushroom = .5,
            green_mushroom = .3,
            red_mushroom = .4,
            grass = .25,
            cave_fern = 20,
        },
    }
})

local bgrabbit = {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.SINKHOLE,
    contents =  {
        distributepercent = .2,
        distributeprefabs=
        {
            cavelight = 0.05,
            cavelight_small = 0.05,
            cavelight_tiny = 0.05,
            flower_cave = 0.5,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.05,
            carrot_planted = 1,
            cave_fern=0.5,
            fireflies = 0.01,

            red_mushroom = 0.1,
            green_mushroom = 0.1,
            blue_mushroom = 0.1,
        }
    }
}
AddRoom("DST_BGRabbitTown", bgrabbit)
AddRoom("DST_BGRabbitTownRoom", Roomify(bgrabbit))

-- ======================== 蜘蛛区 SPIDER ========================
AddRoom("DST_SpiderRoom", {
    colour={r=0.2,g=0.0,b=0.0,a=0.9},
    value = GROUND.SINKHOLE,

    contents = {},
})

-- ======================== 蛤蟆区 TOADSTOOL ========================
-- (已通过下方 toadstoolarena 定义 ToadstoolArenaBGMud/Mud/BGCave/Cave)
-- 此处保留区域入口占位
AddRoom("DST_ToadstoolRoom", {
    colour={r=1.0,g=0.0,b=0.0,a=0.9},
    value = GROUND.MUD,

    contents = {},
})

-- ======================== 通用空房间 ========================
AddRoom("DST_PitRoom", {
    colour={r=.25,g=.28,b=.25,a=.50},
    value = GROUND.IMPASSABLE,

    contents = {},
})
AddRoom("DST_Blank", {
    colour={r=0.5,g=0.5,b=0.5,a=0.3},
    value = GROUND.CAVE,
    contents = {},
})

----------------<DummyExitRoom：为 Teleportato 部件提供 ExitPiece 放置点>----------------
-- 此房间用于 NoneTasks/MonkeyNoneTasks，让分配到最深层的 Teleportato 部件能正常放置。
-- 注意：不能使用 type = "blank"（空白房间在 WorldSim 中尺寸为 0，放不下任何 layout）。
-- 使用普通房间 + GROUND.GRASS（兼容 PLACE_MASK.NORMAL）+ 空内容。
AddRoom("DummyExitRoom", {
    colour={r=.45,g=.75,b=.45,a=.50},
    tags = {"ExitPiece"},
    value = GROUND.GRASS,
    contents = {},
})


-- ======================== 遗迹：荒地 WILDS ========================
AddRoom("DST_WetWilds", {
    colour={r=0.5,g=0.3,b=0.1,a=0.9},
    value = GROUND.MUD,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = 0.25,
        distributeprefabs=
        {
            lichen = .25,
            cave_fern = 0.1,
            pillar_algae = .01,
            pond_cave = 0.1,
            slurper_spawner = .05,
            fissure_lower = 0.05,
        },
    }
})

AddRoom("DST_LichenMeadow", {
    colour={r=0.5,g=0.3,b=0.1,a=0.9},
    value = GROUND.BRICK,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = 0.15,
        distributeprefabs=
        {
            lichen = 1.0,
            cave_fern = 1.0,
            pillar_algae = 0.1,
            slurper_spawner = 0.35,
            fissure_lower = 0.05,

            flower_cave = .05,
            flower_cave_double = .03,
            flower_cave_triple = .01,

            worm_spawner = 0.07,
            wormlight_plant = 0.15,
        },
    }
})

AddRoom("DST_LichenLand", {
    colour={r=0.5,g=0.3,b=0.1,a=0.9},
    value = GROUND.BRICK,

    contents =  {
        distributepercent = 0.35,
        distributeprefabs=
        {
            lichen = 2.0,
            cave_fern = 0.5,
            pillar_algae = 0.5,
            slurper_spawner = 0.05,
            fissure_lower = 0.05,
        },
    }
})

AddRoom("DST_CaveJungle", {
    colour={r=0.5,g=0.3,b=0.1,a=0.9},
    value = GROUND.MUD,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = 0.35,
        distributeprefabs=
        {
            lichen = 0.3,
            cave_fern = 1,
            pillar_algae = 0.05,

            cave_banana_tree = 0.5,
            monkeybarrel_spawner = 0.1,

            slurper_spawner = 0.06,
            pond_cave = 0.07,
            fissure_lower = 0.04,
            worm_spawner = 0.04,
            wormlight_plant = 0.08,
        },
    }
})

AddRoom("DST_MonkeyMeadow", {
    colour={r=0.5,g=0.3,b=0.1,a=0.9},
    value = GROUND.MUD,

    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = 0.1,
        distributeprefabs=
        {
            lichen = 0.3,
            cave_fern = 1,
            pillar_algae = 0.05,

            cave_banana_tree = 0.1,
            monkeybarrel_spawner = 0.06,

            slurper_spawner = 0.06,
            pond_cave = 0.07,
            fissure_lower = 0.04,
            worm_spawner = 0.04,
            wormlight_plant = 0.08,
        },
    }
})

local bgwilds = {
    colour={r=0.5,g=0.3,b=0.1,a=0.9},
    value = GROUND.BRICK,

    contents =  {
        countprefabs=
        {
            cave_hole = function() return math.random(2) - 1 end,
        },
        distributepercent = 0.15,
        distributeprefabs=
        {
            lichen = 0.1,
            cave_fern = 1,
            pillar_algae = 0.01,

            cave_banana_tree = 0.01,
            monkeybarrel_spawner = 0.01,

            flower_cave = 0.05,
            flower_cave_double = 0.03,
            flower_cave_triple = 0.01,

            worm_spawner = 0.07,
            wormlight_plant = 0.15,

            fissure_lower = 0.04,
        },
    }
}
AddRoom("DST_BGWilds", bgwilds)
AddRoom("DST_BGWildsRoom", Roomify(bgwilds))

-- ======================== 遗迹：住宅区 RESIDENTIAL ========================
AddRoom("DST_Vacant", {
    colour={r=0.5,g=0.3,b=0.2,a=0.9},
    value = GROUND.TILES,

    contents =  {
        countstaticlayouts =
        {
            ["CornerWall"] = function() return math.random(2,3) end,
            ["StraightWall"] = function() return math.random(2,3) end,
            ["CornerWall2"] = function() return math.random(2,3) end,
            ["StraightWall2"] = function() return math.random(2,3) end,
        },
        distributepercent = 0.5,
        distributeprefabs=
        {
            lichen = .4,
            cave_fern = .6,
            pillar_algae = .01,
            slurper_spawner = .15,
            cave_banana_tree = .1,
            monkeybarrel_spawner = .2,
            dropperweb = .1,
            ruins_rubble_table = 0.1,
            ruins_rubble_chair = 0.1,
            ruins_rubble_vase = 0.1,
        },
    }
})

AddRoom("DST_RuinedCity", {
    colour={r=0.5,g=0.3,b=0.2,a=0.9},
    value = GROUND.TILES,

    contents =  {
        countprefabs=
        {
            cave_hole = function() return math.random() < 0.25 and 1 or 0 end,
        },
        distributepercent = 0.09,
        distributeprefabs=
        {
            lichen = .3,
            cave_fern = 1,
            pillar_algae = .05,

            cave_banana_tree = 0.1,
            monkeybarrel_spawner = 0.06,
            slurper_spawner = 0.06,
            pond_cave = 0.07,
            fissure_lower = 0.04,
            worm_spawner = 0.04,
        },
    }
})

AddRoom("DST_RuinedCityEntrance", {
    colour={r=0.5,g=0.3,b=0.2,a=0.9},
    value = GROUND.TILES,

    contents =  {
        distributepercent = .07,
        distributeprefabs=
        {
            blue_mushroom = 1,
            cave_fern = 1,
            lichen = .5,
        },
    }
})

-- ======================== 遗迹：军事区 MILITARY ========================
AddRoom("DST_MilitaryEntrance", {
    colour={r=0.6,g=0.2,b=0.2,a=0.9},
    value = GROUND.TILES,

    type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts =
        {
            ["MilitaryEntrance"] = 1,
        },
    }
})

AddRoom("DST_MilitaryMaze", {
    colour={r=0.6,g=0.2,b=0.2,a=0.9},
    value = GROUND.TILES,

    type = NODE_TYPE.Room,
    contents = {},
})

AddRoom("DST_Barracks", {
    colour={r=0.6,g=0.2,b=0.2,a=0.9},
    value = GROUND.TILES,

    type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts =
        {
            ["Barracks"] = 1,
        },
        distributepercent = 0.03,
        distributeprefabs=
        {
            chessjunk_spawner = .3,

            nightmarelight = 1,

            rook_nightmare_spawner = .07,
            bishop_nightmare_spawner = .07,
            knight_nightmare_spawner = .07,
        },
    }
})

-- ======================== 遗迹：祭坛区 SACRED ========================
AddRoom("DST_SacredBarracks", {
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
    value = GROUND.TILES,

    type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts =
        {
            ["SacredBarracks"] = 1,
        },
    }
})

AddRoom("DST_Bishops", {
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
    value = GROUND.TILES,

    type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts =
        {
            ["Barracks2"] = 1,
        },
    }
})

AddRoom("DST_Spiral", {
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
    value = GROUND.TILES,

    type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts =
        {
            ["Spiral"] = 1,
        },
    }
})

AddRoom("DST_BrokenAltar", {
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
    value = GROUND.BRICK_GLOW,

    type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts =
        {
            ["BrokenAltar"] = 1,
        },
    }
})

AddRoom("DST_Altar", {
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
    value = GROUND.BRICK_GLOW,

    type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts =
        {
            ["AltarRoom"] = 1,
        },
    }
})

AddRoom("DST_BridgeEntrance", {
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
    value = GROUND.TILES,

    type = NODE_TYPE.Room,
    contents = {},
})

local bgsacred = {
    colour={r=0.7,g=0.5,b=0.1,a=0.9},
    value = GROUND.BRICK,

    contents =  {
        countprefabs=
        {
            cave_hole = 1,
        },

        distributepercent = 0.03,
        distributeprefabs=
        {
            chessjunk_spawner = .3,

            nightmarelight = 1,

            pillar_ruins = 0.5,

            ruins_statue_head_spawner = .1,
            ruins_statue_head_nogem_spawner = .2,

            ruins_statue_mage_spawner =.1,
            ruins_statue_mage_nogem_spawner = .2,

            rook_nightmare_spawner = .07,
            bishop_nightmare_spawner = .07,
            knight_nightmare_spawner = .07,
        },
    }
}
AddRoom("DST_BGSacred", bgsacred)
AddRoom("DST_BGSacredRoom", Roomify(bgsacred))

-- ======================== 遗迹：迷宫 LABYRINTH ========================
AddRoom("DST_LabyrinthEntrance", {
    colour={r=0.3,g=0.2,b=0.1,a=0.9},
    value = GROUND.MUD,
    tags = {"ForceConnected", "LabyrinthEntrance"},
    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .2,
        distributeprefabs=
        {
            lichen = .8,
            cave_fern = 1,
            pillar_algae = .05,

            flower_cave = .2,
            flower_cave_double = .1,
            flower_cave_triple = .05,
        },
    }
})

AddRoom("DST_Labyrinth", {
    colour={r=0.3,g=0.2,b=0.1,a=0.9},
    value = GROUND.MUD,
    tags = {"Labyrinth"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = 0.1,
        distributeprefabs = {
            dropperweb = 0.5,

            ruins_rubble_vase = 0.1,
            ruins_rubble_chair = 0.1,
            ruins_rubble_table = 0.1,

            chessjunk_spawner = 0.03,

            rook_nightmare_spawner = 0.01,
            bishop_nightmare_spawner = 0.01,
            knight_nightmare_spawner = 0.01,

            thulecite_pieces = 0.05,
        },
    }
})

AddRoom("DST_RuinedGuarden", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    tags = {"LabyrinthEntrance"},
    required_prefabs = {"minotaur_spawner"},
    type = NODE_TYPE.Room,
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents =  {
        countstaticlayouts = {
            ["WalledGarden"] = 1,
        },
        countprefabs= {

            flower_cave = function () return 5 + math.random(3) end,
            gravestone = function () return 4 + math.random(4) end,
            mound = function () return 4 + math.random(4) end
        },
    }
})

-- ======================== 中庭 ATRIUM ========================
AddRoom("DST_AtriumMazeEntrance", {
    colour={r=0.2,g=0.1,b=0.2,a=0.9},
    value = GROUND.FAKE_GROUND,
    tags = {"ForceConnected", "MazeEntrance", "RoadPoison"},
    type = NODE_TYPE.Room,
    contents = {},
})
AddRoom("DST_AtriumMazeRooms", {
    colour={r=0.2,g=0.1,b=0.2,a=0.9},
    value = GROUND.FAKE_GROUND,
    tags = {"Maze", "ForceDisconnected", "RoadPoison"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    type = NODE_TYPE.Room,
    contents = {},
})
AddRoom("DST_AtriumRoom", {
    colour={r=0.2,g=0.1,b=0.2,a=0.9},
    value = GROUND.FAKE_GROUND,

    contents = {},
})

AddRoom("DST_AtriumEnd", {
    colour={r=0.2,g=0.1,b=0.2,a=0.9},
    value = GROUND.FAKE_GROUND,
    tags = {"ForceConnected", "RoadPoison"},
    type = NODE_TYPE.Room,
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    contents = {
        countstaticlayouts = {
            ["AtriumEnd"] = 1,
        },
    },
})

-- ======================== 档案馆 ARCHIVE ========================
AddRoom("DST_ArchiveMazeEntrance", {
    colour={r=0.4,g=0.4,b=0.5,a=0.9},
    value = GROUND.FUNGUSMOON,
    tags = {"ForceConnected", "MazeEntrance", "RoadPoison"},
    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = 0.5,
        distributeprefabs =
        {
            mushtree_moon = 0.05,

            lightflier_flower = 0.005,

            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
        },
    }
})
AddRoom("DST_ArchiveMazeRooms",  { -- layout contents determined by maze
    colour={r=0.4,g=0.4,b=0.5,a=0.9},
    value = GROUND.ARCHIVE,
    tags = {"ForceDisconnected", "Maze", "RoadPoison"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    type = NODE_TYPE.Room,
    contents = {},
})

-- DS 不支持 maze_tiles.special / maze_tiles.archive，所以把 archive_start/end/keyroom/supplyroom
-- 转成普通 room_choices，用 countstaticlayouts 注入原始静态布局。
AddRoom("DST_ArchiveStart", {
    colour={r=0.4,g=0.4,b=0.5,a=0.9},
    value = GROUND.ARCHIVE,
    tags = {"RoadPoison"},
    contents = {
        countstaticlayouts = {
            ["ArchiveStart"] = 1,
        },
        countprefabs = {
            archive_centipede = 1,
        },

        distributepercent = 0.01,
        distributeprefabs = {
            wall_ruins_2 = 0.03,
            ruins_plate = 0.03,
            ruins_bowl = 0.03,
            ruins_chair = 0.03,
            ruins_chipbowl = 0.03,
            ruins_vase = 0.03,
            ruins_table = 0.03,
            ruins_rubble_table = 0.03,
        },
    },
})

AddRoom("DST_ArchiveEnd", {
    colour={r=0.4,g=0.4,b=0.5,a=0.9},
    value = GROUND.ARCHIVE,
    tags = {"RoadPoison"},
    contents = {
        countstaticlayouts = {
            ["ArchiveEnd"] = 1,
        },
        countprefabs = {
            archive_centipede = 1,
        },

        distributepercent = 0.01,
        distributeprefabs = {
            wall_ruins_2 = 0.03,
            ruins_plate = 0.03,
            ruins_bowl = 0.03,
            ruins_chair = 0.03,
            ruins_chipbowl = 0.03,
            ruins_vase = 0.03,
            ruins_table = 0.03,
            ruins_rubble_table = 0.03,
        },
    },
})

AddRoom("DST_ArchiveKeyroom", {
    colour={r=0.4,g=0.4,b=0.5,a=0.9},
    value = GROUND.ARCHIVE,
    tags = {"RoadPoison"},
    contents = {
        countstaticlayouts = {
            ["ArchiveKeyroom"] = 1,
        },
        countprefabs = {
            archive_centipede = 1,
        },

        distributepercent = 0.01,
        distributeprefabs = {
            wall_ruins_2 = 0.03,
            ruins_plate = 0.03,
            ruins_bowl = 0.03,
            ruins_chair = 0.03,
            ruins_chipbowl = 0.03,
            ruins_vase = 0.03,
            ruins_table = 0.03,
            ruins_rubble_table = 0.03,
        },
    },
})

AddRoom("DST_ArchiveSupplyRoom", {
    colour={r=0.4,g=0.4,b=0.5,a=0.9},
    value = GROUND.ARCHIVE,
    tags = {"RoadPoison"},
    contents = {
        countstaticlayouts = {
            ["ArchiveSupplyRoom"] = 1,
        },

        distributepercent = 0.01,
        distributeprefabs = {
            wall_ruins_2 = 0.03,
            ruins_plate = 0.03,
            ruins_bowl = 0.03,
            ruins_chair = 0.03,
            ruins_chipbowl = 0.03,
            ruins_vase = 0.03,
            ruins_table = 0.03,
            ruins_rubble_table = 0.03,
        },
    },
})

-- ======================== 档案馆蒸馏室（3色）=====================
AddRoom("DST_ArchiveDistillery", {
    colour={r=0.4,g=0.4,b=0.5,a=0.9},
    value = GROUND.ARCHIVE,
    tags = {"RoadPoison"},
    contents = {
        countprefabs = {
            archive_lockbox_dispencer = 1,
            archive_centipede = 1,
            archive_security_desk = 1,
            archive_rune_statue = 1,
            archive_chandelier = 1,
            archive_moon_statue = 1,
        },
        distributepercent = 0.05,
        distributeprefabs = {
            wall_ruins_2 = 0.03,
            ruins_plate = 0.03,
            ruins_bowl = 0.03,
            ruins_chair = 0.03,
            ruins_chipbowl = 0.03,
            ruins_vase = 0.03,
            ruins_table = 0.03,
            ruins_rubble_table = 0.03,
        },
    },
})

AddRoom("DST_ArchiveDistillery2", {
    colour={r=0.4,g=0.4,b=0.5,a=0.9},
    value = GROUND.ARCHIVE,
    tags = {"RoadPoison"},
    contents = {
        countprefabs = {
            archive_lockbox_dispencer = 1,
            archive_centipede = 1,
            archive_security_desk = 1,
            archive_rune_statue = 1,
            archive_chandelier = 1,
            archive_moon_statue = 1,
        },
        distributepercent = 0.05,
        distributeprefabs = {
            wall_ruins_2 = 0.03,
            ruins_plate = 0.03,
            ruins_bowl = 0.03,
            ruins_chair = 0.03,
            ruins_chipbowl = 0.03,
            ruins_vase = 0.03,
            ruins_table = 0.03,
            ruins_rubble_table = 0.03,
        },
    },
})

AddRoom("DST_ArchiveDistillery3", {
    colour={r=0.4,g=0.4,b=0.5,a=0.9},
    value = GROUND.ARCHIVE,
    tags = {"RoadPoison"},
    contents = {
        countprefabs = {
            archive_lockbox_dispencer = 1,
            archive_centipede = 1,
            archive_security_desk = 1,
            archive_rune_statue = 1,
            archive_chandelier = 1,
            archive_moon_statue = 1,
        },
        distributepercent = 0.05,
        distributeprefabs = {
            wall_ruins_2 = 0.03,
            ruins_plate = 0.03,
            ruins_bowl = 0.03,
            ruins_chair = 0.03,
            ruins_chipbowl = 0.03,
            ruins_vase = 0.03,
            ruins_table = 0.03,
            ruins_rubble_table = 0.03,
        },
    },
})
-- ============================================================
-- 毒菌蛤蟆竞技场房间（原 rooms/cave/toadstoolarena.lua）
-- ============================================================
require "map/room_functions"

AddRoom("ToadstoolArenaBGMud", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.MUD,
    --tags = {},
    contents =  {
        distributepercent = .12,
        distributeprefabs=
        {
            pond_cave = 0.2,

            flower_cave = 0.1,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            stalagmite_tall=.01,
            stalagmite_tall_med=0.1,
            stalagmite_tall_low=0.1,
            pillar_cave_rock = 0.01,

            cave_fern = 1.0,

            slurtlehole = 0.001,
        }
    }
})


AddRoom("ToadstoolArenaMud", {
    colour={r=1.0,g=0.0,b=0.0,a=0.9},
    value = GROUND.MUD,
    --tags = {},
    contents = {
        countstaticlayouts = {
            ["ToadstoolArena"] = 1,
        },
        distributepercent = .1,
        distributeprefabs=
        {
            flower_cave = 1.0,
            flower_cave_double = 0.5,
            flower_cave_triple = 0.5,

            stalagmite_tall=0.05,
            stalagmite_tall_med=0.05,
            stalagmite_tall_low=0.1,
            pillar_cave_rock = 0.01,

            cave_fern = 0.1,
            wormlight_plant = 0.02,
        },
    }
})

AddRoom("ToadstoolArenaBGCave", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = GROUND.CAVE,
    --tags = {},
    contents =  {
        distributepercent = .12,
        distributeprefabs=
        {
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,
            stalagmite_tall=0.4,
            stalagmite_tall_med=0.4,
            stalagmite_tall_low=0.4,
            pillar_cave_rock = 0.01,
            fissure = 0.05,
            pond_cave = 0.15,
            batcave = 0.01,
        }
    }
})

AddRoom("ToadstoolArenaCave", {
    colour={r=1.0,g=0.0,b=0.0,a=0.9},
    value = GROUND.CAVE,
    --tags = {},
    contents = {
        countstaticlayouts = {
            ["ToadstoolArena"] = 1,
        },
        distributepercent = 0,
        distributeprefabs =
        {

        },
    }
})
