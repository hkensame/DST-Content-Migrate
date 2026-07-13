-- DS 移植版：tree_rock 树苗（独立文件，不依赖 moonisland/planted_tree）

local assets =
{
    Asset("ANIM", "anim/tree_rock_seed.zip"),
}

local prefabs =
{
    "tree_rock1_short",
    "tree_rock2_short",
}

local SAPLING_GROW_TIME = 3600

local function growtree(inst)
    local grow_prefab = type(inst.growprefab) == "table" and GetRandomItem(inst.growprefab) or inst.growprefab
    local tree = SpawnPrefab(grow_prefab)
    if tree then
        tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tree:growfromseed()
        inst:Remove()
    end
end

local function stopgrowing(inst)
    inst.components.timer:StopTimer("grow")
end

local function startgrowing(inst)
    if not inst.components.timer:TimerExists("grow") then
        inst.components.timer:StartTimer("grow", SAPLING_GROW_TIME)
    end
end

local function ontimerdone(inst, data)
    if data.name == "grow" then
        growtree(inst)
    end
end

local function digup(inst, digger)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("tree_rock_seed")
    inst.AnimState:SetBuild("tree_rock_seed")
    inst.AnimState:PlayAnimation("idle_planted")

    inst:AddTag("treerock")

    inst.growprefab = {"tree_rock1_short", "tree_rock2_short"}
    inst.StartGrowing = startgrowing

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)
    startgrowing(inst)

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"twigs"})

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(digup)
    inst.components.workable:SetWorkLeft(1)

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    inst:ListenForEvent("onignite", stopgrowing)
    inst:ListenForEvent("onextinguish", startgrowing)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("tree_rock_sapling", fn, assets, prefabs)
