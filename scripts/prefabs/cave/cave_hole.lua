local assets =
{
    Asset("ANIM", "anim/cave/cave_hole.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    inst:AddTag("groundhole")
    inst:AddTag("blocker")

    inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetCapsule(2.75, 1)

    inst.AnimState:SetBank("cave_hole")
    inst.AnimState:SetBuild("cave_hole")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst.MiniMapEntity:SetIcon("cave_hole.tex")
    inst.Transform:SetEightFaced()

    return inst
end

return Prefab("cave_hole", fn, assets)
