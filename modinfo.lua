name = "dst_boss"
version = "1.50"
author = "青青草原扛把子"

description = [[
从联机版移植部分BOSS、食物、植物
此模组仍有未知bug，希望以体验为主
遇见崩溃则在模组配置里关闭相应内容
]]
forumthread = ""

api_version = 6
dont_starve_compatible = true
reign_of_giants_compatible = true
shipwrecked_compatible = true
hamlet_compatible = true

priority = -10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

configuration_options =
{
  {
  name = "language",
  label = "语言",
  options =
 {
  {description = "中文", data = false},
 },
  default = false,
  },
  {
  name = "beta",
  label = "测试功能",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = false,
  },
------------BOSS生成选择------------
 {
  name = "B",
  label = "========",
  options =
  {
   {description = "BOSS生成", data = false},
 },
  default = false,
 },
  {
  name = "winters_feast",
  label = "冬季盛宴",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = false,
  },
  {
  name = "moonisland",
  label = "月岛生成",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = false,
  },
  {
  name = "antlion",
  label = "蚁狮生成",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "moonbase",
  label = "月台生成",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "dragonfly",
  label = "龙蝇生成",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "malbatross",
  label = "邪天翁生成",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "atrium",
  label = "织影者生成",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "klaus",
  label = "克劳斯包生成",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },--[[
  {
  name = "moon_device",
  label = "天体英雄生成",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },--]]
  {
  name = "sculptures",
  label = "暗影雕像生成",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "monkeyisland",
  label = "猴岛生成",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },
 {
  name = "dstcave",
  label = "实验性地穴",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },
------------火焰蔓延系统------------
 {
  name = "Fire",
  label = "========",
  options =
  {
   {description = "火焰蔓延系统", data = false},
 },
  default = false,
 },
  {
  name = "enabledByDefault",
  label = "计时器默认启用",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "showBurningTimer",
  label = "燃烧计时器",
  options =
 {
  {description = "关闭", data = false},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "showCampfireTimer",
  label = "营火计时器",
  options =
 {
  {description = "关闭", data = false},
  {description = "隐藏", data = "hidden"},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "showLanternTimer",
  label = "提灯计时器",
  options =
 {
  {description = "关闭", data = false},
  {description = "隐藏", data = "hidden"},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "showStarTimer",
  label = "星杖计时器",
  options =
 {
  {description = "关闭", data = false},
  {description = "隐藏", data = "hidden"},
  {description = "开启", data = true},
 },
  default = true,
  },
  {
  name = "showHiddenDuration",
  label = "悬停显示时长",
  options =
 {
  {description = "1s", data = 1.0},
  {description = "2s", data = 2.0},
  {description = "3s", data = 3.0},
  {description = "5s", data = 5.0},
  {description = "10s", data = 10.0},
 },
  default = 5.0,
  },
}
