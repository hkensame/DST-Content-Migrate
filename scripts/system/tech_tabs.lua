-- ==================== 自定义科技栏注册 ====================
-- 加载框架后，注册项目中用到的自定义科技。
-- 新增科技时在此添加对应注册调用。

print("[TECHTABS] tech_tabs.lua 开始加载")

modimport("scripts/system/tech_template.lua")

-- ==================== 天体科技 ====================
RegisterTech("CELESTIAL", { ONE = 1, THREE = 3 })
RegisterTechTab("DST_CELESTIAL", {
    str = "DST_CELESTIAL",
    sort = 700,
    priority = 1,
    icon = "tab_celestial.tex",
    icon_atlas = "images/tab_celestial.xml",
}, "天体")

print("[TECHTABS] tech_tabs.lua 加载完成")
