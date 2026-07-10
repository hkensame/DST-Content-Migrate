local assets =
{
    Asset("ANIM", "anim/support_pillar_dreadstone.zip"),
}

local prefabs =
{
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("support_pillar_dreadstone.png")

    MakeObstaclePhysics(inst, 1.6, 6)

    inst.Transform:SetEightFaced()

    inst.AnimState:SetBank("support_pillar_dreadstone")
    inst.AnimState:SetBuild("support_pillar_dreadstone")
    inst.AnimState:PlayAnimation("idle", true)
    if inst.AnimState.SetSymbolLightOverride then
        inst.AnimState:SetSymbolLightOverride("pillar_pieces_red", 1)
        inst.AnimState:SetSymbolLightOverride("pillar_pieces_red_90", 1)
    end

    inst:AddTag("structure")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("quake_blocker")

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst.components.lootdropper.y_speed = 4

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(5)
    inst.components.workable:SetOnFinishCallback(function(inst, worker)
        inst.components.lootdropper:DropLoot(inst:GetPosition())
        inst:Remove()
    end)

    -- 地震响应动画
    inst:ListenForEvent("startquake", function()
        inst.AnimState:PlayAnimation("shake")
        inst.AnimState:PushAnimation("idle", true)
    end, TheWorld)

    return inst
end

return Prefab("support_pillar_dreadstone_scaffold", fn, assets, prefabs)
