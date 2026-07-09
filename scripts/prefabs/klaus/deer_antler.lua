local function MakeAntler(antlertype, trueklaussackkey)
    local assets = antlertype ~= nil and {
        Asset("ANIM", "anim/klaus/deer_antler.zip"),
    } or nil

    local prefabs = antlertype == nil and {
        "deer_antler1",
        "deer_antler2",
        "deer_antler3",
    } or nil
--鹿角
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("deer_antler")
        inst.AnimState:SetBuild("deer_antler")
        inst.AnimState:PlayAnimation("idle"..tostring(antlertype or 1))

        inst:AddTag("deerantler")

        --klaussackkey (from klaussackkey component) added to pristine state for optimization
        inst:AddTag("klaussackkey")

        if trueklaussackkey then
            inst:AddTag("irreplaceable")
        else
            inst:AddTag("deer_antler") --单独加个标签
            if antlertype == nil then
                inst:SetPrefabName("deer_antler1")
            end
            inst:SetPrefabNameOverride("deer_antler")
        end

        MakeInventoryFloatable(inst, "idle"..tostring(antlertype or 1), "idle"..tostring(antlertype or 1))

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

        inst:AddComponent("tradable")

        return inst
    end

    return Prefab(trueklaussackkey and "klaussackkey" or "deer_antler"..tostring(antlertype or ""), fn, assets, prefabs)
end

return MakeAntler(),
        MakeAntler(1),
        MakeAntler(2),
        MakeAntler(3),
        MakeAntler(4, true)
