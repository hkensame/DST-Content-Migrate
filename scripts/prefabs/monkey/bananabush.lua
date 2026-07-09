-- 香蕉丛 (bananabush)
-- 移植自 DST，适配 DS 单机模式
-- 移除：AddNetwork, SetPristine, ismastersim 网络门控
-- 适配：POPULATING→rawget, 注释 MakeNoGrowInWinter/MakeHauntableIgnite/MakeWaxablePlant/simplemagicgrower
-- 适配：GetGameModeProperty→直接允许挖掘移植

local assets = 
{
    Asset("ANIM", "anim/monkey/bananabush.zip"),
    Asset("MINIMAP_IMAGE", "bananabush"),
}

local prefabs = 
{
    "cave_banana",
    "dug_bananabush"
}

local function set_empty(inst)
    inst.AnimState:PushAnimation("idle_empty")
end

local function grow_empty(inst)
    set_empty(inst)
end

local function set_small(inst)
    inst.AnimState:PlayAnimation("grow_none_to_small")
    inst.AnimState:PushAnimation("idle_small")
end

local function grow_small(inst)
    set_small(inst)
end

local function set_medium(inst)
    inst.AnimState:PlayAnimation("grow_small_to_medium")
    inst.AnimState:PushAnimation("idle_medium")
end

local function grow_medium(inst)
    set_medium(inst)
end

local function set_big(inst)
    if not inst.AnimState:IsCurrentAnimation("idle_big") then
        inst.AnimState:PlayAnimation("grow_medium_to_big")
        inst.AnimState:PushAnimation("idle_big")
        inst.components.pickable:Regen()
    end
end

local function grow_big(inst)
    set_big(inst)
end

local BANANABUSH_GROWTH_STAGES = {
    {
        name = "empty",
        time = function(inst) return TUNING.TOTAL_DAY_TIME end,
        fn = set_empty,
        growfn = grow_empty,
    },
    {
        name = "small",
        time = function(inst) return TUNING.TOTAL_DAY_TIME end,
        fn = set_small,
        growfn = grow_small,
    },
    {
        name = "normal",
        time = function(inst) return TUNING.TOTAL_DAY_TIME end,
        fn = set_medium,
        growfn = grow_medium,
    },
    {
        name = "tall",
        time = function(inst) return TUNING.TOTAL_DAY_TIME end,
        fn = set_big,
        growfn = grow_big,
    },
}

local function OnDig(inst, worker)
    if inst.components.pickable ~= nil and inst.components.lootdropper ~= nil then
        -- DS: 枯萎状态由 pickable 组件管理
        local withered = inst.components.pickable:IsWithered()

        if withered or inst.components.pickable:IsBarren() then
            inst.components.lootdropper:SpawnLootPrefab("twigs")
            inst.components.lootdropper:SpawnLootPrefab("twigs")
        else
            if inst.components.pickable:CanBePicked() then
                local pt = inst:GetPosition()
                pt.y = pt.y + (inst.components.pickable.dropheight or 0)
                inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product, pt)
            end

            inst.components.lootdropper:SpawnLootPrefab("dug_"..inst.prefab)
        end
    end

    inst:Remove()
end

local function OnPicked(inst, picker)
    if inst.components.pickable ~= nil then
        if inst.components.pickable:IsBarren() then
            inst.AnimState:PlayAnimation("idle_to_dead")
            inst.AnimState:PushAnimation("dead", false)
            inst.components.growable:StopGrowing()
        else
            inst.AnimState:PlayAnimation("picked")
            inst.AnimState:PushAnimation("idle_empty")

            inst.components.growable:SetStage(1)
            inst.components.growable:StartGrowing()
        end
    end
end

local function OnTransplant(inst)
    inst.components.pickable:MakeBarren()
end

local function MakeEmpty(inst)
    -- DS 无 POPULATING 全局变量，安全保护
    local populating = rawget(_G, "POPULATING")
    if not populating then
        inst.components.growable:SetStage(1)
        inst.components.growable:StartGrowing()
    end
end

local function MakeBarren(inst, wasempty)
    inst.components.growable:SetStage(1)
    inst.components.growable:StopGrowing()

    inst.AnimState:PlayAnimation("dead")
end

local function OnRegen(inst)
    inst.components.growable:Resume()
    if inst.components.growable.stage < 4 then
        inst.components.growable:SetStage(4)
    end
end

local function on_load(inst, data)
    -- DS: 枯萎由 pickable 组件管理，DST 的 witherable 组件不存在
    if data ~= nil and inst.components.pickable ~= nil and inst.components.pickable:IsWithered() then
        inst.components.pickable:MakeBarren()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()

    --inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT] / 2)
    --MakeSmallObstaclePhysics(inst, .1) -- DST-only, DS无此函数
    MakeObstaclePhysics(inst, .1)

    inst:AddTag("bananabush")
    inst:AddTag("plant")

    inst.MiniMapEntity:SetIcon("bananabush.tex")

    inst.AnimState:SetBank("bananabush")
    inst.AnimState:SetBuild("bananabush")
    inst.AnimState:PlayAnimation("idle_small", true)

    --------------------------------------------------------------------------
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"

    local variance_cycles = (TUNING.BANANABUSH_CYCLES_VAR <= 1 and TUNING.BANANABUSH_CYCLES_VAR)
        or math.random(TUNING.BANANABUSH_CYCLES_VAR)
    inst.components.pickable.max_cycles = TUNING.BANANABUSH_CYCLES + variance_cycles
    inst.components.pickable.cycles_left = inst.components.pickable.max_cycles

    inst.components.pickable.onpickedfn = OnPicked
    inst.components.pickable:SetUp("cave_banana")
    inst.components.pickable.ontransplantfn = OnTransplant
    inst.components.pickable:SetMakeEmptyFn(MakeEmpty)
    inst.components.pickable:SetMakeBarrenFn(MakeBarren)
    inst.components.pickable:SetOnRegenFn(OnRegen)
    inst.components.pickable.canbepicked = false

    --------------------------------------------------------------------------
    inst:AddComponent("growable")
    inst.components.growable.stages = BANANABUSH_GROWTH_STAGES
    inst.components.growable:SetStage(1)
    inst.components.growable.loopstages = false
    inst.components.growable.springgrowth = true
    inst.components.growable:StartGrowing()

    --inst:AddComponent("simplemagicgrower")
    --inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

    --------------------------------------------------------------------------
    -- DS 无 GetGameModeProperty，直接允许挖掘移植
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnDig)

    --------------------------------------------------------------------------
    inst:AddComponent("lootdropper")

    --------------------------------------------------------------------------
    inst:AddComponent("inspectable")

    --------------------------------------------------------------------------
    -- DS: 枯萎由 pickable 组件内置管理 (MakeWitherable)
    if inst.components.pickable then
        inst.components.pickable:MakeWitherable()
    end

    --------------------------------------------------------------------------
    --MakeNoGrowInWinter(inst) -- DS 无冬季生长抑制

    --------------------------------------------------------------------------
    MakeLargeBurnable(inst)
    MakeMediumPropagator(inst)

    --------------------------------------------------------------------------
    --MakeHauntableIgnite(inst) -- DS 无幽灵互动

    --MakeWaxablePlant(inst) -- DS 无蜡质植物

    --------------------------------------------------------------------------
    inst.OnLoad = on_load

    return inst
end

return Prefab("bananabush", fn, assets, prefabs)
