-- ==================== 蓝图统一管理系统 ====================
-- 功能：
--   1. 从蓝图配置表读取配置，运行时注册蓝图 prefab
--   2. 注入 Builder 组件使蓝图配方受学习门控
--
-- 设计要点：
--   - UnlockRecipe 不作阻挡（蓝图学习正常生效）
--   - KnowsRecipe 拦截：nounlock 自定义科技配方需要蓝图学习
--   - 非 nounlock 的近程门控由 tech_tabs.lua 的 CanBuild 负责

print("[BLUEPRINT] blueprint_system.lua 开始加载")

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

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("blueprint")
        inst.AnimState:SetBuild("blueprint")
        inst.AnimState:PlayAnimation("idle")
        inst:AddTag("_named")

        inst:RemoveTag("_named")

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:ChangeImageName("blueprint")

        inst:AddComponent("named")
        inst:AddComponent("teacher")
        inst.components.teacher.onteach = function(blueprint, learner)
            if learner.components.builder then
                learner.components.builder:AddRecipe(recipe_name)
                learner.components.builder.inst:PushEvent("unlockrecipe", {recipe = recipe_name})
            end
        end
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

-- ==================== 蓝图配置 ====================
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
print(string.format("[BLUEPRINT] 蓝图配置: %d 项", table.count(blueprints)))

-- ==================== 注册蓝图 prefab ====================
for prefab_name, recipe_name in pairs(blueprints) do
    local prefab_obj = GLOBAL.Prefab(prefab_name, MakeBlueprint(recipe_name), BLUEPRINT_ASSETS)
    prefab_obj.modfns = {}
    GLOBAL.Prefabs[prefab_name] = prefab_obj
    print(string.format("[BLUEPRINT] 注册蓝图 prefab: %s → 配方 %s", prefab_name, recipe_name))
end
if next(blueprints) then
    print("[BLUEPRINT] 已注册 " .. table.count(blueprints) .. " 个蓝图预制体")
end

print("[BLUEPRINT] blueprint_system.lua 加载完成")
