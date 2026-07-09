
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require "util"
require("map/tasks")
require("constants")
require("map/terrain")
require("map/level")
require("map/lockandkey")
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")
-- 蛤蟆竞技场静态布局（房间定义已合并到 rooms/room_defs.lua，由 map_dstcave.lua 加载）（供已迁移到 map_dstcave.lua 的 ToadStoolTask 引用）
Layouts["ToadstoolArena"] = StaticLayout.Get("map/static_layouts/toadstool_arena", {
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
    disable_transform = true,
})
