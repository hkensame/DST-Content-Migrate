-- ==================== 科技树 + 蓝图统一管理系统 ====================
-- 从 GLOBAL.__tech_blueprints 和 GLOBAL.__custom_techs 读取配置
-- 由 modmain.lua 在 modimport 前设置这两个全局变量

-- DS 兼容性：table.count 是 DST 专有扩展
if not table.count then
    table.count = function(t)
        local n = 0
        for _ in pairs(t) do n = n + 1 end
        return n
    end
end

local BLUEPRINT_ASSETS = {
    Asset("ANIM", "anim/blueprint.zip"),
}

local function MakeBlueprint(recipe_name)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        -- DS 没有 Network 组件，跳过 AddNetwork
        -- inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("blueprint")
        inst.AnimState:SetBuild("blueprint")
        inst.AnimState:PlayAnimation("idle")
        inst:AddTag("_named")

        -- DS 没有 TheWorld.ismastersim，默认视为主机
        -- if not TheWorld.ismastersim then
        --     return inst
        -- end

        inst:RemoveTag("_named")

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:ChangeImageName("blueprint")

        inst:AddComponent("named")
        inst:AddComponent("teacher")
        inst.components.teacher.onteach = function(blueprint, learner)
            if learner.components.builder then
                learner.components.builder:AddRecipe(recipe_name)
            end
        end
        inst.components.teacher:SetRecipe(recipe_name)

        local recipe = GetValidRecipe(recipe_name)
        local item_name = recipe and (STRINGS.NAMES[string.upper(recipe_name)] or STRINGS.NAMES.UNKNOWN) or STRINGS.NAMES.UNKNOWN
        inst.components.named:SetName(item_name .. "蓝图")

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        return inst
    end
end

local function SafeWrapBlueprints()
    local count = 0
    for name, prefab in pairs(GLOBAL.Prefabs or {}) do
        if name:match("_blueprint$") or name == "blueprint" then
            local orig_fn = prefab.fn
            prefab.fn = function(...)
                local ok, result = pcall(orig_fn, ...)
                if ok and result then
                    return result
                end
                if not ok then
                    print("[TechManager] SafeBlueprint: " .. name .. " 构造出错 " .. tostring(result))
                end
                return nil
            end
            count = count + 1
        end
    end
    if count > 0 then
        print("[TechManager] SafeBlueprint: 已安全包装 " .. count .. " 个蓝图预制体")
    end
end

-- ==================== 读取配置 ====================
local blueprints = GLOBAL.__tech_blueprints or {}
local custom_techs = GLOBAL.__custom_techs or {}
GLOBAL.__tech_blueprints = nil
GLOBAL.__custom_techs = nil

-- ==================== 注册蓝图 prefab ====================
for prefab_name, recipe_name in pairs(blueprints) do
    GLOBAL.Prefabs[prefab_name] = GLOBAL.Prefab(prefab_name, MakeBlueprint(recipe_name), BLUEPRINT_ASSETS)
end
if next(blueprints) then
    print("[TechManager] 已注册 " .. table.count(blueprints) .. " 个蓝图预制体")
end

SafeWrapBlueprints()

-- ==================== 注入 Builder 组件 ====================
AddComponentPostInit("builder", function(self)
    local TechTree = package.loaded["techtree"]

    -- 1. 将所有自定义科技注入 TechTree
    if TechTree and TechTree.AVAILABLE_TECH and custom_techs then
        for tech_name, _ in pairs(custom_techs) do
            local already = false
            for _, v in ipairs(TechTree.AVAILABLE_TECH) do
                if v == tech_name then already = true break end
            end
            if not already then
                table.insert(TechTree.AVAILABLE_TECH, tech_name)
                local bonus_key = string.lower(tech_name) .. "_bonus"
                local tempbonus_key = string.lower(tech_name) .. "_tempbonus"
                if TechTree.AVAILABLE_TECH_BONUS then
                    TechTree.AVAILABLE_TECH_BONUS[tech_name] = bonus_key
                end
                if TechTree.AVAILABLE_TECH_TEMPBONUS then
                    TechTree.AVAILABLE_TECH_TEMPBONUS[tech_name] = tempbonus_key
                end
                if TechTree.AVAILABLE_TECH_BONUS_CLASSIFIED then
                    TechTree.AVAILABLE_TECH_BONUS_CLASSIFIED[tech_name] = string.lower(tech_name) .. "bonus"
                end
                if TechTree.AVAILABLE_TECH_TEMPBONUS_CLASSIFIED then
                    TechTree.AVAILABLE_TECH_TEMPBONUS_CLASSIFIED[tech_name] = string.lower(tech_name) .. "tempbonus"
                end
                if TechTree.AVAILABLE_TECH_LEVEL_CLASSIFIED then
                    TechTree.AVAILABLE_TECH_LEVEL_CLASSIFIED[tech_name] = string.lower(tech_name) .. "level"
                end
                print("[TechManager] 已注入科技树 " .. tech_name)
            end
        end
    end

    -- 2. 为每个自定义科技创建 bonus 字段
    if custom_techs then
        for tech_name, _ in pairs(custom_techs) do
            self[string.lower(tech_name) .. "_bonus"] = 0
        end
    end

    -- 3. KnowsRecipe hook — 通用化
    local old_KnowsRecipe = self.KnowsRecipe
    self.KnowsRecipe = function(_, recname)
        local recipe = GetRecipe(recname)
        if not recipe then
            return old_KnowsRecipe(_, recname)
        end

        -- 检查自定义科技树（有 level 定义且 > 0 的）
        if custom_techs and recipe.level then
            for tech_name, _ in pairs(custom_techs) do
                local recipe_level = recipe.level[tech_name]
                if recipe_level and recipe_level > 0 then
                    local bonus = _[string.lower(tech_name) .. "_bonus"] or 0
                    return recipe_level <= bonus
                        or _.freebuildmode
                        or table.contains(_.recipes, recname)
                end
            end
        end

        -- nounlock=true 的配方（蓝图门控）：仅限天体栏配方
        if recipe.nounlock and recipe.tab == RECIPETABS.DST_CELESTIAL then
            return _.freebuildmode or table.contains(_.recipes, recname)
        end

        return old_KnowsRecipe(_, recname)
    end

    -- 4. UnlockRecipe 覆写 — 天体配方不永久解锁（从旧版 modmain.lua 恢复）
    local old_UnlockRecipe = self.UnlockRecipe
    function self:UnlockRecipe(recname, ...)
        for _, recipe in ipairs(Recipes) do
            if recipe.name == recname and recipe.tab == RECIPETABS.DST_CELESTIAL then
                print("[TechManager][UnlockRecipe] BLOCKED: " .. recname .. " (CELESTIAL tab)")
                return
            end
        end
        return old_UnlockRecipe(self, recname, ...)
    end

    -- 5. 初始补齐
    if custom_techs then
        for tech_name, _ in pairs(custom_techs) do
            local bonus_field = string.lower(tech_name) .. "_bonus"
            if self.accessible_tech_trees[tech_name] == nil then
                self.accessible_tech_trees[tech_name] = self[bonus_field] or 0
            end
        end
    end
end)
