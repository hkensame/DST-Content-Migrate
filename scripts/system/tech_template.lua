-- ==================== 自定义科技栏系统框架 ====================
-- 提供注册 API 和全局钩子，供 tech_tabs.lua 调用。
--
-- 用法（在 tech_tabs.lua 中）：
--   modimport("scripts/system/tech_template.lua")
--   RegisterTech("CELESTIAL", { ONE = 1, THREE = 3 })
--   RegisterTechTab("DST_CELESTIAL", { ... }, "天体")
--   RegisterTechBuilding("moon_altar", "CELESTIAL", 1)

print("[TEMPLATE] tech_template.lua 开始加载")

-- ==================== 注册表（供 blueprint_system 引用） ====================
custom_techs = custom_techs or {}

-- 启用近程门控的科技列表（调用了 RegisterTechBuilding 的科技自动加入）
_proximity_techs = _proximity_techs or {}

-- ==================== 注册 API ====================

-- 注册自定义科技：创建 TECH 常量，记录到注册表
function RegisterTech(tech_name, level_def)
    if custom_techs[tech_name] then
        print(string.format("[TEMPLATE] 科技 %s 已注册，跳过", tech_name))
        return
    end
    custom_techs[tech_name] = { levels = level_def }

    GLOBAL.TECH = GLOBAL.TECH or {}
    for lv_name, lv_val in pairs(level_def) do
        GLOBAL.TECH[tech_name .. "_" .. lv_name] = { [tech_name] = lv_val }
    end
    print(string.format("[TEMPLATE] 注册科技: %s", tech_name))
end

-- 注册制作栏标签：创建 RECIPETABS 和 STRINGS.TABS
function RegisterTechTab(tab_name, tab_def, tab_string)
    RECIPETABS[tab_name] = tab_def
    if tab_string then
        STRINGS.TABS = STRINGS.TABS or {}
        STRINGS.TABS[tab_name] = tab_string
    end
    print(string.format("[TEMPLATE] 注册制作栏: %s", tab_name))
end

-- 启用近程门控：指定科技不再全局可用，需要附近有 prototyper 建筑提供等级
-- 底层标记控制 CanBuild/KnowsRecipe 拦截。
function EnableProximityGate(tech_name)
    _proximity_techs[tech_name] = true
    print(string.format("[TEMPLATE] 近程门控已开启: %s", tech_name))
end

-- ==================== Prototyper GetTechTrees 扩展 ====================
local STANDARD_TECHS = { "SCIENCE", "MAGIC", "ANCIENT" }
AddComponentPostInit("prototyper", function(self)
    local _GetTechTrees = self.GetTechTrees
    if not _GetTechTrees then return end

    self.GetTechTrees = function(pself, ...)
        local trees = _GetTechTrees(pself, ...)
        if trees then
            local copy = {}
            for k, v in pairs(trees) do copy[k] = v end
            for _, tech_name in ipairs(STANDARD_TECHS) do
                if copy[tech_name] == nil then copy[tech_name] = 0 end
            end
            for tech_name in pairs(custom_techs) do
                if copy[tech_name] == nil then copy[tech_name] = 0 end
            end
            return copy
        end
        return trees
    end
end)
print("[TEMPLATE] Prototyper GetTechTrees 已扩展")


-- ==================== Builder 组件注入（近程门控 + 科技同步） ====================
AddComponentPostInit("builder", function(self)
    local TechTree = package.loaded["techtree"]

    -- 1. 将自定义科技注入 TechTree.AVAILABLE_TECH
    if TechTree and TechTree.AVAILABLE_TECH and next(custom_techs) then
        for tech_name in pairs(custom_techs) do
            local already = false
            for _, v in ipairs(TechTree.AVAILABLE_TECH) do
                if v == tech_name then already = true; break end
            end
            if not already then
                table.insert(TechTree.AVAILABLE_TECH, tech_name)
                local lname = string.lower(tech_name)
                if TechTree.AVAILABLE_TECH_BONUS then
                    TechTree.AVAILABLE_TECH_BONUS[tech_name] = lname .. "_bonus"
                end
                if TechTree.AVAILABLE_TECH_TEMPBONUS then
                    TechTree.AVAILABLE_TECH_TEMPBONUS[tech_name] = lname .. "_tempbonus"
                end
                if TechTree.AVAILABLE_TECH_BONUS_CLASSIFIED then
                    TechTree.AVAILABLE_TECH_BONUS_CLASSIFIED[tech_name] = lname .. "bonus"
                end
                if TechTree.AVAILABLE_TECH_TEMPBONUS_CLASSIFIED then
                    TechTree.AVAILABLE_TECH_TEMPBONUS_CLASSIFIED[tech_name] = lname .. "tempbonus"
                end
                if TechTree.AVAILABLE_TECH_LEVEL_CLASSIFIED then
                    TechTree.AVAILABLE_TECH_LEVEL_CLASSIFIED[tech_name] = lname .. "level"
                end
                print("[TEMPLATE] 科技树 " .. tech_name .. " 已注入")
            end
        end
    end

    -- 2. 初始化 bonus 字段
    for tech_name in pairs(custom_techs) do
        local fname = string.lower(tech_name) .. "_bonus"
        self[fname] = 0
    end

    -- 3. CanBuild 覆写：近程门控（仅对 _proximity_techs 生效）
    local _CanBuild = self.CanBuild
    self.CanBuild = function(cself, recname)
        if cself.freebuildmode then return true end
        local recipe = GetRecipe(recname)
        if recipe and recipe.level then
            for tech_name in pairs(_proximity_techs) do
                if recipe.level[tech_name] and recipe.level[tech_name] > 0 then
                    local current = (cself.accessible_tech_trees and cself.accessible_tech_trees[tech_name]) or 0
                    if current < recipe.level[tech_name] then
                        return false
                    end
                end
            end
        end
        return _CanBuild(cself, recname)
    end

    -- 3b. KnowsRecipe 覆写：蓝图门控 + 近程门控
    -- 蓝图门控（所有 nounlock 自定义科技）：需要已学习蓝图
    -- 近程门控（仅 _proximity_techs）：离开建筑范围配方不显示
    local _KnowsRecipe = self.KnowsRecipe
    self.KnowsRecipe = function(kself, recname)
        if not recname then
            return _KnowsRecipe(kself, recname)
        end
        local recipe = GetRecipe(recname)
        if recipe and recipe.level then
            for tech_name in pairs(custom_techs) do
                if recipe.level[tech_name] and recipe.level[tech_name] > 0 then
                    -- 近程门控：仅对启用该功能的科技生效
                    if _proximity_techs[tech_name] then
                        local current = (kself.accessible_tech_trees and kself.accessible_tech_trees[tech_name]) or 0
                        if current < recipe.level[tech_name] then
                            return false
                        end
                    end
                    -- 蓝图门控：nounlock 配方需要已学习蓝图（不限近程门控）
                    if recipe.nounlock then
                        return kself.freebuildmode or table.contains(kself.recipes, recname)
                    end
                    return true
                end
            end
        end
        return _KnowsRecipe(kself, recname)
    end

    -- 4. EvaluateTechTrees 覆写
    local _old_ett = self.EvaluateTechTrees
    self.EvaluateTechTrees = function(bself)
        local old_trees = {}
        if bself.accessible_tech_trees then
            for k, v in pairs(bself.accessible_tech_trees) do
                old_trees[k] = v
            end
        end
        local old_prototyper = bself.current_prototyper

        local pos = bself.inst:GetPosition()
        local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, TUNING.RESEARCH_MACHINE_DIST, {"prototyper"})
        bself.current_prototyper = nil
        local prototyper_active = false
        for _, v in pairs(ents) do
            if v.components.prototyper then
                if not prototyper_active then
                    v.components.prototyper:TurnOn()
                    local trees = v.components.prototyper:GetTechTrees()
                    local copy = {}
                    if trees then
                        for tk, tv in pairs(trees) do copy[tk] = tv end
                    end
                    bself.accessible_tech_trees = copy
                    prototyper_active = true
                    bself.current_prototyper = v
                else
                    v.components.prototyper:TurnOff()
                end
            end
        end

        if not prototyper_active then
            if bself.accessible_tech_trees then
                bself.accessible_tech_trees.SCIENCE = bself.science_bonus or 0
                bself.accessible_tech_trees.MAGIC = bself.magic_bonus or 0
                bself.accessible_tech_trees.ANCIENT = bself.ancient_bonus or 0
            else
                bself.accessible_tech_trees = {
                    SCIENCE = bself.science_bonus or 0,
                    MAGIC = bself.magic_bonus or 0,
                    ANCIENT = bself.ancient_bonus or 0,
                }
            end
        else
            local t = bself.accessible_tech_trees
            t.SCIENCE = (t.SCIENCE or 0) + (bself.science_bonus or 0)
            t.MAGIC = (t.MAGIC or 0) + (bself.magic_bonus or 0)
            t.ANCIENT = (t.ANCIENT or 0) + (bself.ancient_bonus or 0)
        end

        local private_trees = {}
        if bself.accessible_tech_trees then
            for k, v in pairs(bself.accessible_tech_trees) do
                private_trees[k] = v
            end
        end
        bself.accessible_tech_trees = private_trees

        for tech_name in pairs(custom_techs) do
            local bonus = bself[string.lower(tech_name) .. "_bonus"] or 0
            local proto_val = 0
            if prototyper_active then
                local trees = bself.current_prototyper.components.prototyper:GetTechTrees()
                proto_val = trees and trees[tech_name] or 0
            end
            bself.accessible_tech_trees[tech_name] = proto_val + bonus
        end

        if old_prototyper and old_prototyper.components.prototyper and old_prototyper:IsValid() and old_prototyper ~= bself.current_prototyper then
            old_prototyper.components.prototyper:TurnOff()
        end

        local trees_changed = false
        for k, v in pairs(old_trees) do
            if v ~= bself.accessible_tech_trees[k] then trees_changed = true; break end
        end
        if not trees_changed then
            for k, v in pairs(bself.accessible_tech_trees) do
                if v ~= old_trees[k] then trees_changed = true; break end
            end
        end
        if trees_changed then
            bself.inst:PushEvent("techtreechange", {level = bself.accessible_tech_trees})
        end
    end

    -- 5. 初始补齐
    if self.accessible_tech_trees then
        for tech_name in pairs(custom_techs) do
            if self.accessible_tech_trees[tech_name] == nil then
                self.accessible_tech_trees[tech_name] = self[string.lower(tech_name) .. "_bonus"] or 0
            end
        end
    end

    print(string.format("[TEMPLATE] Builder 近程门控注入完成: techs=%d", table.count(custom_techs)))
end)


-- ==================== 制作栏标签注入 ====================
AddClassPostConstruct("widgets/crafttabs", function(self)
    self.tabnames = self.tabnames or {}
    for tab_name, _ in pairs(RECIPETABS) do
        if type(tab_name) == "string" and tab_name:find("^DST_") then
            local found = false
            for _, v in ipairs(self.tabnames) do
                if v == RECIPETABS[tab_name] then found = true; break end
            end
            if not found then
                table.insert(self.tabnames, RECIPETABS[tab_name])
            end
        end
    end
end)

print("[TEMPLATE] tech_template.lua 加载完成")
