local assets =
{
    Asset("ANIM", "anim/toadstool/shroom_skin.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("shroom_skin")
    inst.AnimState:SetBuild("shroom_skin")
    inst.AnimState:PlayAnimation("idle")

    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst, "idle", "idle")
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/shroom_skin.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    return inst
end

return Prefab("shroom_skin", fn, assets)