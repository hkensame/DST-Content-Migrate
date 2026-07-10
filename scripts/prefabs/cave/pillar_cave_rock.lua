-- DS 移植版：删除 AddNetwork/SetPristine/ismastersim
-- 洞穴岩石柱（装饰性障碍物）

local assets =
{
    Asset("ANIM", "anim/pillar_cave_rock.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeObstaclePhysics(inst, 2.35)

    inst.AnimState:SetBank("pillar_cave_rock")
    inst.AnimState:SetBuild("pillar_cave_rock")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("pillar")
    inst:AddTag("structure")

    inst:AddComponent("inspectable")

    return inst
end

return Prefab("pillar_cave_rock", fn, assets)
