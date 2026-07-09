-- DS 移植版：移除 AddNetwork/SetPristine/ismastersim/scrapbook
-- cave_fern_withered.lua — 枯萎蕨类

local assets =
{
    Asset("ANIM", "anim/cave_ferns_withered_build.zip"),
}

local prefabs =
{
    "spoiled_food",
}

local names = {"f1","f2","f3","f4","f5","f6","f7","f8","f9","f10"}

local function onsave(inst, data)
    data.anim = inst.animname
end

local function onload(inst, data)
    if data and data.anim then
        inst.animname = data.anim
        inst.AnimState:PlayAnimation(inst.animname)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("ferns")
    inst.AnimState:SetBuild("cave_ferns_withered_build")
    inst.AnimState:SetRayTestOnBB(true)

    -- === Master Simulation ===
    inst.animname = names[math.random(#names)]
    inst.AnimState:PlayAnimation(inst.animname)

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("cutgrass", 10)
    inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("cave_fern_withered", fn, assets, prefabs)
