-- 挖起的猴尾草 (dug_monkeytail)
-- 可重新种植

local assets =
{
    Asset("ANIM", "anim/monkey/reeds_monkeytails.zip"),
    Asset("INV_IMAGE", "dug_monkeytails")
}

local function ondeploy(inst, pt, deployer)
    local plant = SpawnPrefab("monkeytail")
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

    inst.AnimState:SetBank("grass")
    inst.AnimState:SetBuild("reeds_monkeytails")
    inst.AnimState:PlayAnimation("dropped")

    inst:AddTag("plant")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "dug_monkeytails"
    inst.components.inventoryitem.atlasname = "images/dug_monkeytails.xml"

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable.min_spacing = 1

    MakeSmallBurnable(inst, TUNING.SMALL_FUEL)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("dug_monkeytail", fn, assets)
