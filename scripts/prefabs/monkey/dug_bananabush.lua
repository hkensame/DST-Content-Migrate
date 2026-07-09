-- 挖起的香蕉丛 (dug_bananabush)
-- 可重新种植

local assets =
{
    Asset("ANIM", "anim/monkey/bananabush.zip"),
    Asset("INV_IMAGE", "dug_bananabush")
}

local function ondeploy(inst, pt, deployer)
    local plant = SpawnPrefab("bananabush")
    if plant then
        if deployer ~= nil and deployer.SoundEmitter ~= nil then
            deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
        end
        plant.Transform:SetPosition(pt.x, pt.y, pt.z)
        plant.components.pickable:OnTransplant()
        inst.components.stackable:Get():Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bananabush")
    inst.AnimState:SetBuild("bananabush")
    inst.AnimState:PlayAnimation("dead")

    inst:AddTag("plant")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "dug_bananabush"
    inst.components.inventoryitem.atlasname = "images/dug_bananabush.xml"

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable.min_spacing = 1

    MakeSmallBurnable(inst, TUNING.SMALL_FUEL)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("dug_bananabush", fn, assets)
