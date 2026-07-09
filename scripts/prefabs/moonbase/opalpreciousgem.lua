local assets =
{
    Asset("ANIM", "anim/moonbase/dst_gems.zip"),
}

local function Sparkle(inst)
    if not inst.AnimState:IsCurrentAnimation("opalgem_sparkle") then
        inst.AnimState:PlayAnimation("opalgem_sparkle")
        inst.AnimState:PushAnimation("opalgem_idle", true)
    end
    inst:DoTaskInTime(4 + math.random(), Sparkle)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst, "opalgem_idle", "opalgem_idle")
    end

    inst.AnimState:SetBank("dst_gems")
    inst.AnimState:SetBuild("dst_gems")
    inst.AnimState:PlayAnimation("opalgem_idle", true)

    inst:AddTag("molebait")
    inst:AddTag("quakedebris")
    inst:AddTag("gem")

    inst.pickupsound = "gem"

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "ELEMENTAL"
    inst.components.edible.hungervalue = 5
    inst.components.edible.healthvalue = 10

    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "opalgem"
    inst.components.inventoryitem.atlasname = "images/opalgem.xml"

    inst:DoTaskInTime(1, Sparkle)

    return inst
end

return Prefab("opalpreciousgem", fn, assets)
