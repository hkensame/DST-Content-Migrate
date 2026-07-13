return {
  version = "1.1",
  luaversion = "5.1",
  orientation = "orthogonal",
  width = 24,
  height = 24,
  tilewidth = 16,
  tileheight = 16,
  properties = {},
  tilesets = {
    {
      name = "tiles",
      firstgid = 1,
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      image = "../../../../tools/tiled/dont_starve/tiles.png",
      imagewidth = 512,
      imageheight = 512,
      properties = {},
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "BG_TILES",
      x = 0,
      y = 0,
      width = 24,
      height = 24,
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "lua",
      data = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,1,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        1,0,0,0,42,0,0,0,42,0,0,0,42,0,0,0,42,0,0,0,42,0,0,1,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        1,0,0,0,42,0,0,0,42,0,0,0,42,0,0,0,42,0,0,0,42,0,0,1,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        1,0,0,0,42,0,0,0,42,0,0,0,42,0,0,0,42,0,0,0,42,0,0,1,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        1,0,0,0,42,0,0,0,42,0,0,0,42,0,0,0,42,0,0,0,42,0,0,1,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,1,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      }
    },
    {
      type = "objectgroup",
      name = "FG_OBJECTS",
      visible = true,
      opacity = 1,
      properties = {},
      objects = {
        -- 3 个 archive_lockbox_dispencer 呈等边三角形分布
        -- 顶点 1（顶部）：(192, 112)
        -- 顶点 2（右下）：(264, 232)
        -- 顶点 3（左下）：(120, 232)
        {
          name = "",
          type = "archive_lockbox_dispencer",
          shape = "rectangle",
          x = 192,
          y = 112,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "archive_lockbox_dispencer",
          shape = "rectangle",
          x = 264,
          y = 232,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "archive_lockbox_dispencer",
          shape = "rectangle",
          x = 120,
          y = 232,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        -- 4 根中庭柱子（四角装饰）
        {
          name = "",
          type = "archive_pillar",
          shape = "rectangle",
          x = 48,
          y = 48,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "archive_pillar",
          shape = "rectangle",
          x = 320,
          y = 48,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "archive_pillar",
          shape = "rectangle",
          x = 48,
          y = 304,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "archive_pillar",
          shape = "rectangle",
          x = 320,
          y = 304,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        -- 吊灯（中心偏上）
        {
          name = "",
          type = "archive_chandelier",
          shape = "rectangle",
          x = 192,
          y = 168,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        -- 保卫台（三角形下方中间）
        {
          name = "",
          type = "archive_security_desk",
          shape = "rectangle",
          x = 192,
          y = 280,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        -- 符文雕像和月亮雕像（三角形两侧）
        {
          name = "",
          type = "archive_rune_statue",
          shape = "rectangle",
          x = 104,
          y = 160,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "archive_moon_statue",
          shape = "rectangle",
          x = 280,
          y = 160,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
      }
    }
  }
}
