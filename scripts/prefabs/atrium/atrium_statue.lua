local assets =
{
    Asset("ANIM", "anim/atrium/atrium_statue.zip"),
    Asset("MINIMAP_IMAGE", "atrium_statue"),
}

local prefabs =
{
    "thulecite",
    "thulecite_pieces",
}

SetSharedLootTable("atrium_statue_loot",
{
    {"thulecite",        1.00},
    {"thulecite",        0.25},
    {"thulecite_pieces", 1.00},
    {"thulecite_pieces", 1.00},
    {"thulecite_pieces", 0.50},
    {"thulecite_pieces", 0.50},
})

local function OnWorked(inst, worker, workleft)
    inst.AnimState:PlayAnimation(
        (   (workleft < TUNING.MARBLEPILLAR_MINE / 3 and ("idle_low"..inst._suffix)) or
            (workleft < TUNING.MARBLEPILLAR_MINE * 2 / 3 and ("idle_med"..inst._suffix)) or
            ("idle_full"..inst._suffix)
        ),
        true)
end

local function OnWorkFinished(inst)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function MakeStatue(name, rotate)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()

        MakeObstaclePhysics(inst, .45)

        inst.AnimState:SetBank("atrium_statue")
        inst.AnimState:SetBuild("atrium_statue")
        inst.AnimState:PlayAnimation("idle_full")

        inst.MiniMapEntity:SetIcon("atrium_statue.tex")

        if rotate then
            inst.Transform:SetTwoFaced()
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetWorkLeft(TUNING.MARBLEPILLAR_MINE)
        inst.components.workable:SetOnWorkCallback(OnWorked)
        inst.components.workable:SetOnFinishCallback(OnWorkFinished)

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable("atrium_statue_loot")

        if rotate then
            inst:AddComponent("savedrotation")
        end

        inst._suffix = ""

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeStatue("atrium_statue", false),
    MakeStatue("atrium_statue_facing", true)

