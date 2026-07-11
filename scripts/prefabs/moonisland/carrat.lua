-- 胡萝卜鼠 (carrat)
-- 移植自 DST，适配 DS 单人生存模式
-- 移除：YOTC赛跑系统、颜色变换、牛毛鼠、MakeFeedableSmallLivestock、drownable

local brain = require("brains/carratbrain")

local assets =
{
    Asset("ANIM", "anim/moonisland/carrat_basic.zip"),
    Asset("ANIM", "anim/moonisland/carrat_build.zip"),
    Asset("ATLAS", "images/carrat_altas.xml"),
}

local prefabs =
{
    "carrat_planted",
    "carrot_seeds",
    "plantmeat",
    "plantmeat_cooked",
}

local planted_prefabs =
{
    "carrat",
}

SetSharedLootTable("carrat",
{
    {"plantmeat", 1.00},
    {"carrot_seeds",    0.33},
})

-- 音效表
local carratsounds =
{
    idle = "turnoftides/creatures/together/carrat/idle",
    hit = "turnoftides/creatures/together/carrat/hit",
    sleep = "turnoftides/creatures/together/carrat/sleep",
    death = "turnoftides/creatures/together/carrat/death",
    emerge = "turnoftides/creatures/together/carrat/emerge",
    submerge = "turnoftides/creatures/together/carrat/submerge",
    eat = "turnoftides/creatures/together/carrat/eat",
    stunned = "turnoftides/creatures/together/carrat/stunned",
    reaction = "turnoftides/creatures/together/carrat/reaction",
    step = "dontstarve/creatures/mandrake/footstep",
}

-- Common functions

local function common_onsave(inst, data)
    data.is_burrowed = inst._is_burrowed
end

local function common_onload(inst, data)
    if data ~= nil and data.is_burrowed then
        inst.sg:GoToState("submerged")
    end
end

-- Submerged state (burrowed = looks like planted carrot)

local function on_submerged_ignite(inst)
    inst:GoToEmerged()
    inst.sg:GoToState("emerge_fast")
end

local function on_submerged_picked(inst)
    inst:GoToEmerged()
    inst.sg:GoToState("emerge_fast")
end

local function on_submerged_dug_up(inst, digger)
    inst:GoToEmerged()
    inst.sg:GoToState("dug_up")
end

local function play_special_submerged_idle(inst)
    inst.AnimState:PlayAnimation("planted_ruffle")
    inst.AnimState:PushAnimation("planted")
end

local function go_to_submerged(inst)
    -- Remove creature tags
    inst:RemoveTag("animal")
    inst:RemoveTag("canbetrapped")
    inst:RemoveTag("catfood")
    inst:RemoveTag("cattoy")
    inst:RemoveTag("prey")
    inst:RemoveTag("smallcreature")
    inst:RemoveTag("stunnedbybomb")

    -- Remove creature components
    inst:RemoveComponent("locomotor")
    inst:RemoveComponent("lootdropper")
    inst:RemoveComponent("combat")
    inst:RemoveComponent("cookable")
    inst:RemoveComponent("sleeper")
    inst:RemoveComponent("freezable")

    inst.components.inventoryitem.canbepickedup = false

    -- Update burnable
    inst.components.burnable.canlight = true
    inst.components.burnable:SetOnIgniteFn(on_submerged_ignite)

    -- Add burrowed components
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable.onpickedfn = on_submerged_picked
    inst.components.pickable.canbepicked = true

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(on_submerged_dug_up)
    inst.components.workable:SetWorkLeft(1)

    -- Visual
    inst:SetPrefabNameOverride("CARROT_PLANTED")
    inst.AnimState:SetRayTestOnBB(true)

    -- Periodic ruffle animation
    inst._planted_ruffle_task = inst:DoPeriodicTask(
        TUNING.TOTAL_DAY_TIME / 4 or 120,
        play_special_submerged_idle,
        math.random(TUNING.TOTAL_DAY_TIME / 4 or 60)
    )

    -- 种植态暂停新鲜度衰减
    if inst.components.perishable then
        inst.components.perishable:StopPerishing()
    end

    inst:SetBrain(nil)
    inst._is_burrowed = true
end

-- Emerge state (active creature)

local function on_cooked_fn(inst, cooker, chef)
    inst.SoundEmitter:PlaySound(inst.sounds.hit)
end

local function go_to_emerged(inst)
    -- Add creature tags
    inst:AddTag("animal")
    inst:AddTag("canbetrapped")
    inst:AddTag("catfood")
    inst:AddTag("cattoy")
    inst:AddTag("prey")
    inst:AddTag("smallcreature")
    inst:AddTag("stunnedbybomb")

    -- Remove burrowed components
    inst:RemoveComponent("pickable")
    inst:RemoveComponent("workable")

    -- Update burnable
    inst.components.burnable.canlight = false
    inst.components.burnable:SetOnIgniteFn(nil)

    -- Make hauntable panic
    --MakeHauntablePanic(inst) -- DS 无此函数

    -- Add locomotor
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.CARRAT_WALK_SPEED or 4
    inst.components.locomotor.runspeed = TUNING.CARRAT_RUN_SPEED or 7

    -- Add lootdropper
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("carrat")

    -- Add combat
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "carrat_body"

    -- Add sleeper
    inst:AddComponent("sleeper")

    -- Add freezable
    MakeTinyFreezableCharacter(inst, "carrat_body")

    -- Add cookable
    inst:AddComponent("cookable")
    inst.components.cookable.product = "plantmeat_cooked"
    inst.components.cookable:SetOnCookedFn(on_cooked_fn)

    -- Visual
    inst.AnimState:SetRayTestOnBB(false)
    inst:SetPrefabNameOverride(nil)

    if inst._planted_ruffle_task ~= nil then
        inst._planted_ruffle_task:Cancel()
        inst._planted_ruffle_task = nil
    end

    -- 生物态恢复新鲜度衰减
    if inst.components.perishable then
        inst.components.perishable:StartPerishing()
    end

    inst:SetBrain(brain)
    inst._is_burrowed = false
end

-- carrat (creature)

-- DS 无 FOODTYPE/FOODGROUP，直接用字符串；eater 无 SetDiet，用 SetOmnivore

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()

    MakeCharacterPhysics(inst, 1, 0.5)

    inst.DynamicShadow:SetSize(1, .75)
    inst.DynamicShadow:Enable(false)
    inst.Transform:SetSixFaced()

    inst.AnimState:SetBank("carrat")
    inst.AnimState:SetBuild("carrat_build")
    inst.AnimState:PlayAnimation("planted")

    inst.sounds = carratsounds

    inst:AddTag("animal")
    inst:AddTag("canbetrapped")
    inst:AddTag("catfood")
    inst:AddTag("cattoy")
    inst:AddTag("prey")
    inst:AddTag("smallcreature")
    inst:AddTag("stunnedbybomb")
    inst:AddTag("lunar_aligned")
    inst:AddTag("show_spoilage")
    inst:AddTag("small_livestock")

    -- inventoryitem
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "carrat_altas"
    inst.components.inventoryitem.atlasname = "images/carrat_altas.xml"
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true

    -- perishable (forces emerge after time)
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.CARRAT_PERISH_TIME or TUNING.TOTAL_DAY_TIME * 2 or 120)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "carrat_planted"
    inst.components.perishable:SetOnPerishFn(function(inst)
        -- 在背包中时 onperishreplacement 自动生效；在地面时需手动替换
        if not inst:IsInLimbo() then
            local carrat_planted = SpawnPrefab("carrat_planted")
            if carrat_planted then
                carrat_planted.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
        end
        inst:Remove()
    end)

    -- eater
    inst:AddComponent("eater")
    inst.components.eater:SetOmnivore()
    inst.components.eater.strongstomach = true

    -- health
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.CARRAT_HEALTH or 25)

    -- burnable
    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable.canlight = false
    inst.components.burnable:SetBurnTime(6 * (TUNING.PLANTMOB_BURNTIME_MULT or 0.25))
    inst.components.health.fire_damage_scale = TUNING.PLANTMOB_FIRE_DAMAGE_SCALE or 1.5

    MakeSmallPropagator(inst)
    inst.components.propagator.acceptsheat = false

    -- freezable
    MakeTinyFreezableCharacter(inst, "carrat_body")

    -- locomotor (must be before SG)
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.CARRAT_WALK_SPEED or 4
    inst.components.locomotor.runspeed = TUNING.CARRAT_RUN_SPEED or 7

    -- lootdropper
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("carrat")

    -- combat
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "carrat_body"

    -- sleeper
    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true

    -- inspectable
    inst:AddComponent("inspectable")

    -- tradable
    inst:AddComponent("tradable")

    -- hauntable
    --MakeHauntablePanic(inst) -- DS 无此函数

    -- StateGraph + Brain
    inst:SetStateGraph("SGcarrat")
    inst:SetBrain(brain)

    inst.GoToSubmerged = go_to_submerged
    inst.GoToEmerged = go_to_emerged

    inst.OnSave = common_onsave
    inst.OnLoad = common_onload

    return inst
end

-- carrat_planted (worldgen prefab, looks like a carrot)

local function spawn_carrat_from_planted()
    local carrat = SpawnPrefab("carrat")
    return carrat
end

local function on_planted_prefab_picked(inst)
    local carrat = spawn_carrat_from_planted()
    carrat.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function on_planted_prefab_ignite(inst, source, doer)
    local carrat = spawn_carrat_from_planted()
    carrat.Transform:SetPosition(inst.Transform:GetWorldPosition())
    carrat.components.burnable:Ignite(nil, source, doer)
    inst:DoTaskInTime(0, function(ignited_inst) ignited_inst:Remove() end)
end

local function on_planted_prefab_dug_up(inst, digger)
    local carrat = spawn_carrat_from_planted()
    carrat.Transform:SetPosition(inst.Transform:GetWorldPosition())
    carrat.sg:GoToState("dug_up")
    inst:Remove()
end

local function planted_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("carrat")
    inst.AnimState:SetBuild("carrat_build")
    inst.AnimState:PlayAnimation("planted")
    inst.AnimState:SetRayTestOnBB(true)

    -- inspectable
    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "CARROT_PLANTED"

    -- pickable
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable.onpickedfn = on_planted_prefab_picked
    inst.components.pickable.remove_when_picked = true
    inst.components.pickable.canbepicked = true

    -- burnable
    MakeSmallBurnable(inst)
    inst.components.burnable:SetOnIgniteFn(on_planted_prefab_ignite)

    -- propagator
    MakeSmallPropagator(inst)

    -- hauntable
    --inst:AddComponent("hauntable") -- DS 无 hauntable 组件
    --inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY or 0.01)

    -- workable (dig up)
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(on_planted_prefab_dug_up)
    inst.components.workable:SetWorkLeft(1)

    -- periodic ruffle animation
    inst:DoPeriodicTask(
        TUNING.TOTAL_DAY_TIME / 4 or 120,
        play_special_submerged_idle,
        math.random(TUNING.TOTAL_DAY_TIME / 4 or 60)
    )

    inst.OnSave = common_onsave
    inst.OnLoad = common_onload

    return inst
end

local p1 = Prefab("carrat", fn, assets, prefabs)
local p2 = Prefab("carrat_planted", planted_fn, assets, planted_prefabs)

return p1, p2
