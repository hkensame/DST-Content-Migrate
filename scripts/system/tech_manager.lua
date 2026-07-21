-- ==================== 科技树 + 蓝图统一管理系统 ====================
-- 功能：
--   1. 从 GLOBAL.__tech_blueprints 读取蓝图配置，运行时注册蓝图 prefab
--   2. 从 GLOBAL.__custom_techs 读取自定义科技配置（如 CELESTIAL）
--   3. 注入 Builder 组件使自定义科技配方受蓝图门控
--   4. 扩展 Prototyper GetTechTrees 防止 nil + 0 崩溃
--
-- 设计要点：
--   - 不含 EvaluateTechTrees 防抖 hook（原版 per-frame 扫描的根源已移除）
--   - KnowsRecipe 只检查 self.recipes + freebuildmode，不查 accessible_tech_trees
--   - UnlockRecipe 不作阻挡（蓝图学习正常生效）
--   - 自定义科技的 proximity 解锁由 prototyper.trees 和 CanPrototypeRecipe 处理

print("[TECHMANAGER] tech_manager.lua 开始加载")

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

local function GetBlueprintItemName(recipe_name)
    -- DS 没有 GetValidRecipe，改用 GetRecipe（双端通用）
    local recipe = GetRecipe(recipe_name)
    return recipe and (STRINGS.NAMES[string.upper(recipe_name)] or STRINGS.NAMES.UNKNOWN) or STRINGS.NAMES.UNKNOWN
end

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
                -- 直接调用 AddRecipe，不走 UnlockRecipe（避免 nounlock 阻挡和理智奖励等副作用）
                learner.components.builder:AddRecipe(recipe_name)
                learner.components.builder.inst:PushEvent("unlockrecipe", {recipe = recipe_name})
            end
        end
        -- DS 兼容：SetRecipe 可能 DST-only
        if inst.components.teacher.SetRecipe then
            inst.components.teacher:SetRecipe(recipe_name)
        end

        local item_name = GetBlueprintItemName(recipe_name)
        inst.components.named:SetName(item_name .. "蓝图")

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        return inst
    end
end

-- ==================== 蓝图 + 科技树配置 ====================
-- 蓝图注册表：{ prefab名 = 配方名 }
-- 有新蓝图掉落时在这里加一行
local blueprints = {
    armordreadstone_blueprint      = "armordreadstone",
    dreadstonehat_blueprint        = "dreadstonehat",
    wall_dreadstone_item_blueprint = "wall_dreadstone_item",
    -- 档案馆锁盒奖励（archive_lockbox）
    turfcraftingstation_blueprint       = "turfcraftingstation",
    archive_resonator_item_blueprint    = "archive_resonator_item",
    refined_dust_blueprint              = "refined_dust",
    turf_archive_blueprint              = "turf_archive",
    thulecitebugnet_blueprint           = "thulecitebugnet",
}
print(string.format("[TECHMANAGER] 蓝图配置: %d 项", table.count(blueprints)))

-- 自定义科技树：{ 科技名 = { levels = { 等级名=值, ... } } }
-- 未来扩展在此添加（如 SHADOW_FORGE、LUNAR_FORGE）
local custom_techs = {
    CELESTIAL = { levels = { ONE = 1, THREE = 3 } },
}
print(string.format("[TECHMANAGER] 自定义科技: %d 项", table.count(custom_techs)))


-- ==================== 注册蓝图 prefab ====================
for prefab_name, recipe_name in pairs(blueprints) do
    -- DS 的 SpawnPrefabFromSim 需要 prefab.modfns（为空表也可）
    local prefab_obj = GLOBAL.Prefab(prefab_name, MakeBlueprint(recipe_name), BLUEPRINT_ASSETS)
    prefab_obj.modfns = {}
    GLOBAL.Prefabs[prefab_name] = prefab_obj
    print(string.format("[TECHMANAGER] 注册蓝图 prefab: %s → 配方 %s", prefab_name, recipe_name))
end
if next(blueprints) then
    print("[TechManager] 已注册 " .. table.count(blueprints) .. " 个蓝图预制体")
end

-- ==================== Prototyper GetTechTrees 扩展 ====================
-- 确保所有 prototyper 返回的科技树包含标准字段(SCIENCE/MAGIC/ANCIENT)和自定义科技字段。
-- 目的：
--   1. 防止 EvaluateTechTrees 中 nil + 0 崩溃（部分 prototyper 的 trees 缺少标准字段）
--   2. 消除 accessible_tech_trees 与 prototyper deepcopy 间的字段差异，
--      避免每帧 techtreechange 事件触发全配方扫描。
local STANDARD_TECHS = { "SCIENCE", "MAGIC", "ANCIENT" }
if custom_techs and next(custom_techs) then
    AddComponentPostInit("prototyper", function(self)
        local _GetTechTrees = self.GetTechTrees
        if not _GetTechTrees then
            -- prototyper PostInit but no GetTechTrees
            return
        end
        local _gt_call_count = 0
        self.GetTechTrees = function(pself, ...)
            _gt_call_count = _gt_call_count + 1
            local trees = _GetTechTrees(pself, ...)
            if trees then
                -- 返回副本，避免污染 prototyper 内部 trees 表
                local copy = {}
                for k, v in pairs(trees) do
                    copy[k] = v
                end
                -- 补全标准科技字段（防止 nil + 0）
                for _, tech_name in ipairs(STANDARD_TECHS) do
                    if copy[tech_name] == nil then
                        copy[tech_name] = 0
                    end
                end
                -- 补全自定义科技字段（消除 deepcopy 差异）
                for tech_name in pairs(custom_techs) do
                    if copy[tech_name] == nil then
                        copy[tech_name] = 0
                    end
                end

                return copy
            end
            return trees
        end
    end)
    print("[TECHMANAGER] Prototyper GetTechTrees 已扩展：补全标准字段 + 自定义科技字段")
end

-- ==================== 注入 Builder 组件 ====================
print("[TECHMANAGER] 即将执行 AddComponentPostInit(\"builder\", ...)")
AddComponentPostInit("builder", function(self)
    local TechTree = package.loaded["techtree"]
    print(string.format("[TECHMANAGER] Builder 开始注入: builder_inst=%s, TechTree=%s", tostring(self.inst), tostring(TechTree)))

    -- 1. 将所有自定义科技注入 TechTree（如果存在）
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
                print("[TECHMANAGER] 已注入科技树 " .. tech_name)
            else
                print("[TECHMANAGER] 科技树 " .. tech_name .. " 已存在，跳过注入")
            end
        end
    end

    -- 2. 为每个自定义科技创建 bonus 字段（角色固有加成，参考 vanilla lost_bonus）
    if custom_techs then
        for tech_name, _ in pairs(custom_techs) do
            local fname = string.lower(tech_name) .. "_bonus"
            self[fname] = 0
            print(string.format("[TECHMANAGER] 初始化 bonus 字段 %s = 0", fname))
        end
    end

    -- 3. KnowsRecipe hook
    --    只拦截含有自定义科技字段的配方（如 CELESTIAL）。
    local _KnowsRecipe = self.KnowsRecipe
    if not _diag_kr_counter then _diag_kr_counter = 0 end
    if not _diag_kr_recipe_counts then _diag_kr_recipe_counts = {} end
    if not _diag_kr_fallback then _diag_kr_fallback = 0 end  -- 落入原版 KnowsRecipe 的次数
    self.KnowsRecipe = function(kself, recname)
        if not recname then
            return _KnowsRecipe(kself, recname)
        end
        _diag_kr_counter = _diag_kr_counter + 1
        _diag_kr_recipe_counts[recname] = (_diag_kr_recipe_counts[recname] or 0) + 1
        local recipe = GetRecipe(recname)
        if recipe and recipe.level then
            for tech_name in pairs(custom_techs) do
                if recipe.level[tech_name] and recipe.level[tech_name] > 0 then
                    -- nounlock CELESTIAL：需要蓝图
                    if recipe.nounlock then
                        return kself.freebuildmode or table.contains(kself.recipes, recname)
                    end
                    -- 非 nounlock CELESTIAL：近程门控（不查 self.recipes 防永久解锁）
                    local current = (kself.accessible_tech_trees and kself.accessible_tech_trees[tech_name]) or 0
                    if current >= recipe.level[tech_name] then
                        _diag_kr_fallback = 0
                        return true
                    end
                    return false
                end
            end
        end
        -- 非 CELESTIAL 的 nounlock：原版逻辑
        if recipe and recipe.nounlock then
            return kself.freebuildmode or table.contains(kself.recipes, recname)
        end
        return _KnowsRecipe(kself, recname)
    end
    -- 重置计数器
    self.inst:ListenForEvent("techtreechange", function()
        _diag_kr_counter = 0
        _diag_kr_recipe_counts = {}
        _diag_kr_fallback = 0
    end, self.inst)

    -- 4a. CanBuild override — 对自定义科技（CELESTIAL）加近程门控
    --     DS 原版 CanBuild 只检查材料（不查近程），需要拦截以确保没祭坛不能做
    local _CanBuild = self.CanBuild
    self.CanBuild = function(cself, recname)
        if cself.freebuildmode then
            return true
        end
        local recipe = GetRecipe(recname)
        if recipe and recipe.level then
            for tech_name in pairs(custom_techs) do
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

    -- 5. EvaluateTechTrees — 轻量 hook，仅同步自定义科技字段
    local _old_ett = self.EvaluateTechTrees
    self.EvaluateTechTrees = function(bself)
        -- 保存旧状态用于变化检测（完整快照，不依赖 deepcopy）
        local old_trees = {}
        if bself.accessible_tech_trees then
            for k, v in pairs(bself.accessible_tech_trees) do
                old_trees[k] = v
            end
        end
        local old_prototyper = bself.current_prototyper

        -- ========== 1. 寻找 prototyper（同原版逻辑） ==========
        local pos = bself.inst:GetPosition()
        local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, TUNING.RESEARCH_MACHINE_DIST, {"prototyper"})

        bself.current_prototyper = nil
        local prototyper_active = false
        for k, v in pairs(ents) do
            if v.components.prototyper then
                if not prototyper_active then
                    v.components.prototyper:TurnOn()
                    local trees = v.components.prototyper:GetTechTrees()
                    -- 强制隔离：prototyper:GetTechTrees 返回的数据切到 builder 私有表
                    local copy = {}
                    if trees then
                        for tk, tv in pairs(trees) do
                            copy[tk] = tv
                        end
                    end
                    bself.accessible_tech_trees = copy
                    prototyper_active = true
                    bself.current_prototyper = v
                else
                    v.components.prototyper:TurnOff()
                end
            end
        end

        -- ========== 2. 应用角色固有加成（同原版逻辑） ==========
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

        -- ========== 3. 确保永远是 builder 私有表（隔离共享 TECH.NONE） ==========
        local private_trees = {}
        if bself.accessible_tech_trees then
            for k, v in pairs(bself.accessible_tech_trees) do
                private_trees[k] = v
            end
        end
        bself.accessible_tech_trees = private_trees

        -- ========== 4. 同步自定义科技字段（CELESTIAL） ==========
        if custom_techs then
            for tech_name in pairs(custom_techs) do
                local bonus = bself[string.lower(tech_name) .. "_bonus"] or 0
                local proto_val = 0
                if prototyper_active then
                    local trees = bself.current_prototyper.components.prototyper:GetTechTrees()
                    proto_val = trees and trees[tech_name] or 0
                end
                bself.accessible_tech_trees[tech_name] = proto_val + bonus
            end
        end

        -- ========== 5. 关闭旧的 prototyper（同原版逻辑） ==========
        if old_prototyper and old_prototyper.components.prototyper and old_prototyper:IsValid() and old_prototyper ~= bself.current_prototyper then
            old_prototyper.components.prototyper:TurnOff()
        end

        -- ========== 6. 自行比较变化（无 deepcopy 问题） ==========
        local trees_changed = false
        for k, v in pairs(old_trees) do
            if v ~= bself.accessible_tech_trees[k] then
                trees_changed = true
                break
            end
        end
        if not trees_changed then
            for k, v in pairs(bself.accessible_tech_trees) do
                if v ~= old_trees[k] then
                    trees_changed = true
                    break
                end
            end
        end

        if trees_changed then
            bself.inst:PushEvent("techtreechange", {level = bself.accessible_tech_trees})
        end
    end   -- end EvaluateTechTrees

    -- 5. 初始补齐：确保 accessible_tech_trees 包含自定义科技字段
    --    原版初始化为 TECH.NONE，不包含 CELESTIAL，需要手动添加。
    if custom_techs then
        for tech_name, _ in pairs(custom_techs) do
            if self.accessible_tech_trees[tech_name] == nil then
                self.accessible_tech_trees[tech_name] = self[string.lower(tech_name) .. "_bonus"] or 0
            end
        end
    end

    print(string.format("[TECHMANAGER] Builder 注入完成: custom_techs=%d", table.count(custom_techs)))
end)

print("[TECHMANAGER] tech_manager.lua 加载完成")