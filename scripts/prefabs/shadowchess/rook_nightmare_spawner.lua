local assets =
{
    Asset("ANIM", "anim/rook_nightmare.zip"),
}

local prefabs =
{
    "nightmarefuel",
    "thulecite_pieces",
}

SetSharedLootTable("rook_nightmare_spawner",
{
    {"nightmarefuel",    1.00},
    {"thulecite_pieces", 0.50},
})

local function OnWorkFinished(inst)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("rook")
    inst.AnimState:SetBuild("rook_nightmare")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("atrium_statue.tex")

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.MARBLEPILLAR_MINE)
    inst.components.workable:SetOnFinishCallback(OnWorkFinished)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("rook_nightmare_spawner")

    return inst
end

return Prefab("rook_nightmare_spawner", fn, assets, prefabs)
