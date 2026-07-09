-- 猴子桶 (monkeybarrel)
-- 移植自 DST，适配 DS 单机模式
-- 移除：AddNetwork, SetPristine, ismastersim, worldsettingsutil, ruinsrespawner
-- 适配：isacidraining 逻辑移除(DS无酸雨), TheWorld.net 事件移除, hauntable 注释
-- 注意：RuinsRespawner 依赖 objectspawner 组件(DS不存在)，仅返回主 prefab

local assets =
{
    Asset("ANIM", "anim/monkey/monkey_barrel.zip"),
    Asset("SOUND", "sound/monkey.fsb"),
}

local prefabs =
{
    "monkey",
    "poop",
    "cave_banana",
    "collapse_small",
}

SetSharedLootTable('monkey_barrel',
{
    {'poop',        1.0},
    {'poop',        1.0},
    {'cave_banana', 1.0},
    {'cave_banana', 1.0},
    {'trinket_4',   .01},
    {'trinket_13',   .01},
})

local function shake(inst)
    inst.AnimState:PlayAnimation(math.random() > .5 and "move1" or "move2")
    inst.AnimState:PushAnimation("idle")
    inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey/barrel_rattle")
end

local function enqueueShake(inst)
    if inst.shake ~= nil then
        inst.shake:Cancel()
    end
    inst.shake = inst:DoPeriodicTask(GetRandomWithVariance(10, 3), shake)
end

local function onhammered(inst)
    if inst.shake ~= nil then
        inst.shake:Cancel()
        inst.shake = nil
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    -- DS: no SetMaterial
    --fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren(worker)
    end
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", false)

    enqueueShake(inst)
end

local function pushsafetospawn(inst)
    inst.task = nil
    inst:PushEvent("safetospawn")
end

local function ReturnChildren(inst)
    for _, child in pairs(inst.components.childspawner.childrenoutside) do
        if child.components.homeseeker ~= nil then
            child.components.homeseeker:GoHome()
        end
        child:PushEvent("gohome")
    end

    if not inst.task then
        inst.task = inst:DoTaskInTime(math.random(60, 120), pushsafetospawn)
    end
end

local function OnIgniteFn(inst)
    inst.AnimState:PlayAnimation("shake", true)

    if inst.shake ~= nil then
        inst.shake:Cancel()
        inst.shake = nil
    end

    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren()
    end
end

local function ongohome(inst, child)
    if child.components.inventory ~= nil then
        child.components.inventory:DropEverything(false, false)
    end
end

local function onsafetospawn(inst)
    -- DS 无酸雨系统，直接开始生成
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:StartSpawning()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("monkeybarrel.tex")

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("barrel")
    inst.AnimState:SetBuild("monkey_barrel")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("cavedweller")

    ----------------------------------------------------------
    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(TUNING.MONKEYBARREL_REGEN_PERIOD)
    inst.components.childspawner:SetSpawnPeriod(TUNING.MONKEYBARREL_SPAWN_PERIOD)
    if TUNING.MONKEYBARREL_CHILDREN.max == 0 then
        inst.components.childspawner:SetMaxChildren(0)
    else
        inst.components.childspawner:SetMaxChildren(math.random(TUNING.MONKEYBARREL_CHILDREN.min, TUNING.MONKEYBARREL_CHILDREN.max))
    end

    inst.components.childspawner:StartRegen()
    inst.components.childspawner.childname = "monkey"
    inst.components.childspawner:StartSpawning()
    inst.components.childspawner.ongohome = ongohome
    inst.components.childspawner:SetSpawnedFn(shake)

    ----------------------------------------------------------
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('monkey_barrel')

    ----------------------------------------------------------
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    ----------------------------------------------------------
    local function ondanger()
        if inst.components.childspawner ~= nil then
            inst.components.childspawner:StopSpawning()
            ReturnChildren(inst)
        end
    end

    -- 猴子在危险时返回
    inst:ListenForEvent("monkeydanger", ondanger)

    inst:ListenForEvent("safetospawn", onsafetospawn)

    ----------------------------------------------------------
    inst:AddComponent("inspectable")

    ----------------------------------------------------------
    MakeLargeBurnable(inst)
    MakeLargePropagator(inst)
    inst:ListenForEvent("onignite", OnIgniteFn)

    ----------------------------------------------------------
    -- hauntable 组件注释掉 (DS 无幽灵系统)
    --inst:AddComponent("hauntable")
    --inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    --inst.components.hauntable:SetOnHauntFn(OnHaunt)

    enqueueShake(inst)

    return inst
end

return Prefab("monkeybarrel", fn, assets, prefabs)
