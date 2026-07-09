
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")


Layouts["Sculptures_1"] = StaticLayout.Get("map/static_layouts/sculptures_1") --暗影三基佬
	
AddLevelPreInit("SURVIVAL_DEFAULT", function(level)
    level.set_pieces["Sculptures_1"] = { count = 1, tasks = {"Dig that rock"} } --暗影三基佬
end)
