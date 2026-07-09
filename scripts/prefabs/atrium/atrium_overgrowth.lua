local assets =
{
    Asset("ANIM", "anim/atrium/atrium_overgrowth.zip"),
}

local nightmare_assets =
{
    Asset("ANIM", "anim/atrium/atrium_overgrowth.zip"),
}

local function fn(bank)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    inst.AnimState:SetBuild(bank)
    inst.AnimState:SetBank(bank)
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon(bank..".tex")

    MakeObstaclePhysics(inst, 1.5)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SUPERHUGE

    inst:AddComponent("inspectable")

    return inst
end

local function idolfn()
    local inst = fn("atrium_overgrowth")

    inst:SetPrefabName("atrium_overgrowth")

    return inst
end

return Prefab("atrium_overgrowth", function() return fn("atrium_overgrowth") end, assets),
    Prefab("atrium_idol", idolfn, assets) -- deprecated
