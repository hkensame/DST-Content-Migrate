--[[
feather_canary.lua
金丝雀羽毛（Saffron Feather）
移植自 A New Reign DLC
]]--

local assets =
{
    Asset("ANIM", "anim/toadstool/feather_canary.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("feather_canary")
    inst.AnimState:SetBuild("feather_canary")
    inst.AnimState:PlayAnimation("idle")

    inst.pickupsound = "cloth"

    inst:AddTag("cattoy")
    inst:AddTag("birdfeather")
    if IsDLCEnabled(CAPY_DLC) or IsDLCEnabled(PORKLAND_DLC) then
        MakeInventoryFloatable(inst, "idle", "idle")
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.TINY_FUEL

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.imagename = "feather_canary"
    inst.components.inventoryitem.atlasname = "images/feather_canary.xml"

    inst:AddComponent("tradable")

    return inst
end

return Prefab("feather_canary", fn, assets)
