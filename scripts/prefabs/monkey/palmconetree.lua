-- 棕榈锥树 (palmconetree)
-- 移植自 DST，适配 DS 单机模式
-- 移除：AddNetwork, SetPristine, ismastersim 网络门控
-- 移除：plantregrowth/simplemagicgrower/MakeWaxablePlant/MakeHauntableWorkAndIgnite/scrapbook
-- 适配：SetPrefabName→displaynamefn, 树冠颜色随机化

local assets = {
    Asset("ANIM", "anim/monkey/dst_palmcone_short.zip"),
    Asset("ANIM", "anim/monkey/dst_palmcone_nomal.zip"),
    Asset("ANIM", "anim/monkey/dst_palmcone_tall.zip"),
    Asset("ANIM", "anim/monkey/palmcone_seed.zip"),
}

local prefabs = {
    "charcoal",
    "log",
    "palmcone_scale",
    "palmcone_seed",
    "collapse_small",
}

local function makeanims(stage)
    return {
        idle = "idle_"..stage,
        sway1 = "sway1_loop_"..stage,
        sway2 = "sway2_loop_"..stage,
        chop = "chop_"..stage,
        fallleft = "fallleft_"..stage,
        fallright = "fallright_"..stage,
        stump = "stump_"..stage,
        burning = "burning_loop_"..stage,
        burnt = "burnt_"..stage,
        chop_burnt = "chop_burnt_"..stage,
        idle_chop_burnt = "idle_chop_burnt_"..stage,
    }
end

local SHORT = "short"
local NORMAL = "normal"
local TALL = "tall"

local anims = {
    [SHORT] = makeanims(SHORT),
    [TALL] = makeanims(TALL),
    [NORMAL] = makeanims(NORMAL),
}

local loot_small = { "log", "log" }
local loot_normal = { "log", "log", "log" }
local loot_tall = { "log", "log", "log", "palmcone_scale", "palmcone_scale", "palmcone_seed" }
local loot_burnt = { "charcoal" }

-- 砍烧焦的树
local function chop_down_burnt(inst, chopper)
    inst:RemoveComponent("workable")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    inst.AnimState:PlayAnimation(anims[inst.size].chop_burnt)
    RemovePhysicsColliders(inst)
    inst:ListenForEvent("animover", inst.Remove)
    inst.components.lootdropper:DropLoot()
end

local function burnt_changes(inst)
    if inst.components.burnable ~= nil then
        inst.components.burnable:Extinguish()
    end
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("growable")
    inst:RemoveTag("shelter")
    inst.components.lootdropper:SetLoot(loot_burnt)
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnWorkCallback(nil)
        inst.components.workable:SetOnFinishCallback(chop_down_burnt)
    end
end

local function tree_burnt_immediate_helper(inst, immediate)
    if immediate then
        burnt_changes(inst)
    else
        inst:DoTaskInTime(.5, burnt_changes)
    end
    inst.AnimState:PlayAnimation(anims[inst.size].burnt, true)
    inst.MiniMapEntity:SetIcon("palmcone_tree_burnt.tex")
    inst.AnimState:SetRayTestOnBB(true)
    inst:AddTag("burnt")
end

local function on_tree_burnt(inst)
    tree_burnt_immediate_helper(inst, false)
end

local function inspect_tree(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or (inst:HasTag("stump") and "CHOPPED")
        or nil
end

local function on_chop_tree(inst, chopper, chops_remaining, num_chops)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    local anim_set = anims[inst.size]
    inst.AnimState:PlayAnimation(anim_set.chop)
    inst.AnimState:PushAnimation(anim_set.sway1, true)
end

local function dig_up_stump(inst, digger)
    inst.components.lootdropper:SpawnLootPrefab("log")
    inst.components.lootdropper:SpawnLootPrefab("log")
    inst:Remove()
end

local function make_stump_burnable(inst)
    if inst.size == SHORT then
        MakeSmallBurnable(inst)
    elseif inst.size == NORMAL then
        MakeMediumBurnable(inst)
    else
        MakeLargeBurnable(inst)
        inst.components.burnable:SetFXLevel(5)
    end
end

local function make_stump(inst)
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("workable")
    inst:RemoveTag("shelter")

    make_stump_burnable(inst)
    MakeMediumPropagator(inst)

    RemovePhysicsColliders(inst)

    inst:AddTag("stump")
    inst.MiniMapEntity:SetIcon("palmcone_tree_stump.tex")
    if inst.components.growable ~= nil then
        inst.components.growable:StopGrowing()
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(1)
end

local function on_chop_tree_down(inst, chopper)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")

    local anim_set = anims[inst.size]
    inst.AnimState:PlayAnimation(anim_set.fallleft)
    inst.components.lootdropper:DropLoot(inst:GetPosition())

    inst:DoTaskInTime(0.4, function(inst)
        GetPlayer().components.playercontroller:ShakeCamera(inst, "FULL", .25, .03, (inst.size == TALL and .5) or .25, 6)
    end)

    make_stump(inst)
    inst.AnimState:PushAnimation(anim_set.stump)
end

local function sway(inst)
    local anim_to_play = (math.random() > .5 and anims[inst.size].sway1) or anims[inst.size].sway2
    -- sway diagnostic removed
    inst.AnimState:PlayAnimation(anim_to_play, true)
end

local function push_sway(inst)
    local anim_to_play = (math.random() > .5 and anims[inst.size].sway1) or anims[inst.size].sway2
    inst.AnimState:PushAnimation(anim_to_play, true)
end

--------------------------------------------------------------------------------

local function set_short_burnable(inst)
    if inst.components.burnable == nil then
        inst:AddComponent("burnable")
        inst.components.burnable:AddBurnFX("fire", Vector3(0, 0, 0))
    end
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:SetBurnTime(TUNING.TREE_BURN_TIME / 2)
    inst.components.burnable:SetOnIgniteFn(DefaultBurnFn)
    inst.components.burnable:SetOnExtinguishFn(DefaultExtinguishFn)
    inst.components.burnable:SetOnBurntFn(on_tree_burnt)

    if inst.components.propagator == nil then
        inst:AddComponent("propagator")
    end
    inst.components.propagator.acceptsheat = true
    inst.components.propagator:SetOnFlashPoint(DefaultIgniteFn)
    inst.components.propagator.flashpoint = 5 + math.random()*5
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.propagaterange = 5
    inst.components.propagator.heatoutput = 5
    inst.components.propagator.damagerange = 2
    inst.components.propagator.damages = true
end

local function set_short(inst)
    if inst.size == SHORT then
        return
    end
    -- set_short diagnostic removed
    inst.size = SHORT
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.PALMCONETREE_CHOPS_SMALL or 5)
    end
    inst.AnimState:SetBank("dst_palmcone_short")
    inst.AnimState:SetBuild("dst_palmcone_short")
    set_short_burnable(inst)
    inst.components.lootdropper:SetLoot(loot_small)
    inst:AddTag("shelter")
    sway(inst)
end

local function grow_short(inst)
    -- grow_short diagnostic removed
    inst.AnimState:SetBank("dst_palmcone_short")
    inst.AnimState:SetBuild("dst_palmcone_short")
    inst.AnimState:PlayAnimation("grow_tall_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrowFromWilt")
    set_short_burnable(inst)
    push_sway(inst)
end

--------------------------------------------------------------------------------

local function set_normal_burnable(inst)
    if inst.components.burnable == nil then
        inst:AddComponent("burnable")
        inst.components.burnable:AddBurnFX("fire", Vector3(0, 0, 0))
    end
    inst.components.burnable:SetBurnTime(TUNING.TREE_BURN_TIME)
    inst.components.burnable:SetFXLevel(3)
    inst.components.burnable:SetOnIgniteFn(DefaultBurnFn)
    inst.components.burnable:SetOnExtinguishFn(DefaultExtinguishFn)
    inst.components.burnable:SetOnBurntFn(on_tree_burnt)

    if inst.components.propagator == nil then
        inst:AddComponent("propagator")
    end
    inst.components.propagator.acceptsheat = true
    inst.components.propagator:SetOnFlashPoint(DefaultIgniteFn)
    inst.components.propagator.flashpoint = 5 + math.random()*5
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.propagaterange = 5
    inst.components.propagator.heatoutput = 5
    inst.components.propagator.damagerange = 2
    inst.components.propagator.damages = true
end

local function set_normal(inst)
    if inst.size == NORMAL then
        return
    end
    -- set_normal diagnostic removed
    inst.size = NORMAL
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.PALMCONETREE_CHOPS_NORMAL or 10)
    end
    inst.AnimState:SetBank("dst_palmcone_nomal")
    inst.AnimState:SetBuild("dst_palmcone_nomal")
    set_normal_burnable(inst)
    inst.components.lootdropper:SetLoot(loot_normal)
    inst:AddTag("shelter")
    sway(inst)
end

local function grow_normal(inst)
    -- grow_normal diagnostic removed
    inst.AnimState:SetBank("dst_palmcone_nomal")
    inst.AnimState:SetBuild("dst_palmcone_nomal")
    inst.AnimState:PlayAnimation("grow_short_to_normal")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    set_normal_burnable(inst)
    push_sway(inst)
end

--------------------------------------------------------------------------------

local function set_tall_burnable(inst)
    if inst.components.burnable == nil then
        inst:AddComponent("burnable")
        inst.components.burnable:AddBurnFX("fire", Vector3(0, 0, 0))
    end
    inst.components.burnable:SetFXLevel(5)
    inst.components.burnable:SetBurnTime(TUNING.TREE_BURN_TIME * 1.5)
    inst.components.burnable:SetOnIgniteFn(DefaultBurnFn)
    inst.components.burnable:SetOnExtinguishFn(DefaultExtinguishFn)
    inst.components.burnable:SetOnBurntFn(on_tree_burnt)

    if inst.components.propagator == nil then
        inst:AddComponent("propagator")
    end
    inst.components.propagator.acceptsheat = true
    inst.components.propagator:SetOnFlashPoint(DefaultIgniteFn)
    inst.components.propagator.flashpoint = 15+math.random()*10
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.propagaterange = 7
    inst.components.propagator.heatoutput = 8.5
    inst.components.propagator.damagerange = 3
    inst.components.propagator.damages = true
end

local function set_tall(inst)
    if inst.size == TALL then
        return
    end
    -- set_tall diagnostic removed
    inst.size = TALL
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.PALMCONETREE_CHOPS_TALL or 15)
    end
    inst.AnimState:SetBank("dst_palmcone_tall")
    inst.AnimState:SetBuild("dst_palmcone_tall")
    set_tall_burnable(inst)
    inst.components.lootdropper:SetLoot(loot_tall)
    inst:AddTag("shelter")
    sway(inst)
end

local function grow_tall(inst)
    -- grow_tall diagnostic removed
    inst.AnimState:SetBank("dst_palmcone_tall")
    inst.AnimState:SetBuild("dst_palmcone_tall")
    inst.AnimState:PlayAnimation("grow_normal_to_tall")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    set_tall_burnable(inst)
    push_sway(inst)
end

--------------------------------------------------------------------------------

local growth_stages = {
    {
        name = SHORT,
        time = function(inst)
            return GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base * 3, TUNING.PINECONE_GROWTIME.random * 3)
        end,
        fn = set_short,
        growfn = grow_short,
    },
    {
        name = NORMAL,
        time = function(inst)
            return GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base * 10, TUNING.PINECONE_GROWTIME.random * 8)
        end,
        fn = set_normal,
        growfn = grow_normal,
    },
    {
        name = TALL,
        time = function(inst)
            return GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base * 10, TUNING.PINECONE_GROWTIME.random * 8)
        end,
        fn = set_tall,
        growfn = grow_tall,
    },
}

local function growfromseed_handler(inst)
    inst.components.growable:SetStage(1)
    inst.AnimState:PlayAnimation("grow_seed_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    push_sway(inst)
end

local function on_save(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
    if inst:HasTag("stump") then
        data.stump = true
    end
    data.size = inst.size
end

local function on_load(inst, data)
    if data == nil then
        return
    end
    inst.size = data.size ~= nil and data.size or NORMAL
    if inst.size == SHORT then
        set_short(inst)
    elseif inst.size == NORMAL then
        set_normal(inst)
    else
        set_tall(inst)
    end

    local is_burnt = data.burnt or inst:HasTag("burnt")
    if data.stump and is_burnt then
        make_stump(inst)
        inst.AnimState:PlayAnimation(anims[inst.size].stump)
        DefaultBurntFn(inst)
    elseif data.stump then
        make_stump(inst)
        inst.AnimState:PlayAnimation(anims[inst.size].stump)
    elseif is_burnt then
        tree_burnt_immediate_helper(inst, true)
    end
end

local function on_sleep(inst)
    local do_burnt = inst.components.burnable ~= nil and inst.components.burnable:IsBurning()
    if do_burnt and inst:HasTag("stump") then
        DefaultBurntFn(inst)
    else
        inst:RemoveComponent("burnable")
        inst:RemoveComponent("propagator")
        inst:RemoveComponent("inspectable")
        if do_burnt then
            inst:RemoveComponent("growable")
            inst:AddTag("burnt")
        end
    end
end

local function on_wake(inst)
    if inst:HasTag("burnt") then
        on_tree_burnt(inst)
    else
        if not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
            local is_stump = inst:HasTag("stump")
            if is_stump then
                if inst.components.burnable == nil then
                    make_stump_burnable(inst)
                end
                if inst.components.propagator == nil then
                    MakeMediumPropagator(inst)
                end
            else
                if inst.size == SHORT then
                    set_short_burnable(inst)
                elseif inst.size == NORMAL then
                    set_normal_burnable(inst)
                else
                    set_tall_burnable(inst)
                end
            end
        end
    end
    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree
    end
end

local function displaynamefn(inst)
    return STRINGS.NAMES.PALMCONETREE
end

-----------------------------------------------------------------
-- 四个独立 prefab，每个简单直接（像 DS 树苗的写法）
-- fn() 中不设 SetBank/SetBuild，由 set_* 在 SetStage 时自动切换
-----------------------------------------------------------------

local function make_short()
    local function fn()
        -- Creating palmconetree_short
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()

        MakeObstaclePhysics(inst, .5)

        inst.MiniMapEntity:SetIcon("palmcone_tree.tex")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("shelter")
        inst:AddTag("palmconetree")
        inst.displaynamefn = displaynamefn

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(on_chop_tree)
        inst.components.workable:SetOnFinishCallback(on_chop_tree_down)

        inst:AddComponent("lootdropper")

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(1)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable.magicgrowable = true
        inst.components.growable:StartGrowing()

        inst.color = 0.75 + math.random() * 0.25
        inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
        inst.growfromseed = growfromseed_handler

        inst.OnSave = on_save
        inst.OnLoad = on_load

        inst.AnimState:SetTime(math.random() * .2)
        inst:DoTaskInTime(1, function(inst)
            if inst and inst:IsValid() then
                -- 1s check diagnostic removed
            end
        end)

        inst.OnEntitySleep = on_sleep
        inst.OnEntityWake = on_wake
        return inst
    end
    return Prefab("palmconetree_short", fn, assets, prefabs)
end

local function make_normal()
    local function fn()
        -- Creating palmconetree_normal
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()

        MakeObstaclePhysics(inst, .5)

        inst.MiniMapEntity:SetIcon("palmcone_tree.tex")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("shelter")
        inst:AddTag("palmconetree")
        inst.displaynamefn = displaynamefn

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(on_chop_tree)
        inst.components.workable:SetOnFinishCallback(on_chop_tree_down)

        inst:AddComponent("lootdropper")

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(2)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable.magicgrowable = true
        inst.components.growable:StartGrowing()

        inst.color = 0.75 + math.random() * 0.25
        inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
        inst.growfromseed = growfromseed_handler

        inst.OnSave = on_save
        inst.OnLoad = on_load

        inst.AnimState:SetTime(math.random() * .2)
        inst:DoTaskInTime(1, function(inst)
            if inst and inst:IsValid() then
                -- 1s check diagnostic removed
            end
        end)

        inst.OnEntitySleep = on_sleep
        inst.OnEntityWake = on_wake
        return inst
    end
    return Prefab("palmconetree_normal", fn, assets, prefabs)
end

local function make_tall()
    local function fn()
        -- Creating palmconetree_tall
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()

        MakeObstaclePhysics(inst, .5)

        inst.MiniMapEntity:SetIcon("palmcone_tree.tex")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("shelter")
        inst:AddTag("palmconetree")
        inst.displaynamefn = displaynamefn

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(on_chop_tree)
        inst.components.workable:SetOnFinishCallback(on_chop_tree_down)

        inst:AddComponent("lootdropper")

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(3)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable.magicgrowable = true
        inst.components.growable:StartGrowing()

        inst.color = 0.75 + math.random() * 0.25
        inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
        inst.growfromseed = growfromseed_handler

        inst.OnSave = on_save
        inst.OnLoad = on_load

        inst.AnimState:SetTime(math.random() * .2)
        inst:DoTaskInTime(1, function(inst)
            if inst and inst:IsValid() then
                -- 1s check diagnostic removed
            end
        end)

        inst.OnEntitySleep = on_sleep
        inst.OnEntityWake = on_wake
        return inst
    end
    return Prefab("palmconetree_tall", fn, assets, prefabs)
end

local function make_generic()
    local function fn()
        -- Creating palmconetree (random)
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()

        MakeObstaclePhysics(inst, .5)

        inst.MiniMapEntity:SetIcon("palmcone_tree.tex")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("plant")
        inst:AddTag("tree")
        inst:AddTag("shelter")
        inst:AddTag("palmconetree")
        inst.displaynamefn = displaynamefn

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(on_chop_tree)
        inst.components.workable:SetOnFinishCallback(on_chop_tree_down)

        inst:AddComponent("lootdropper")

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(math.random(1, 3))
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable.magicgrowable = true
        inst.components.growable:StartGrowing()

        inst.color = 0.75 + math.random() * 0.25
        inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
        inst.growfromseed = growfromseed_handler

        inst.OnSave = on_save
        inst.OnLoad = on_load

        inst.AnimState:SetTime(math.random() * .2)
        inst:DoTaskInTime(1, function(inst)
            if inst and inst:IsValid() then
                -- 1s check diagnostic removed
            end
        end)

        inst.OnEntitySleep = on_sleep
        inst.OnEntityWake = on_wake
        return inst
    end
    return Prefab("palmconetree", fn, assets, prefabs)
end

return  make_generic(),
        make_short(),
        make_normal(),
        make_tall()
