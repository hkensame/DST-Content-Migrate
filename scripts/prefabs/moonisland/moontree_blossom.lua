local assets =
{
    Asset("ANIM", "anim/moonisland/moon_tree_petal.zip"),
}

local prefabs =
{
	"moon_tree_blossom_worldgen",
	"moonbutterfly",
}

local function OnPickup(inst, pickupguy, src_pos)
    inst.components.perishable:StartPerishing()
end

local function OnDrop(inst)
    inst.components.perishable:StopPerishing() -- 地面暂停新鲜度衰减
end

-- 月岛花白天有概率生成月蛾
local function TrySpawnMoonbutterfly(inst)
    if not inst:IsInLimbo()
        and GetClock() ~= nil
        and GetClock():IsDay()
        and math.random() < 0.1 then
        local moth = SpawnPrefab("moonbutterfly")
        if moth then
            local x, y, z = inst.Transform:GetWorldPosition()
            moth.Physics:Teleport(x, y, z)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst) -- so it can be dropped as loot

    inst.AnimState:SetBank("moon_tree_petal")
    inst.AnimState:SetBuild("moon_tree_petal")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)

    inst.pickupsound = "vegetation_grassy"

    inst:AddTag("cattoy")
    inst:AddTag("vasedecoration")

    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst)
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnPickupFn(OnPickup)
    inst.components.inventoryitem:SetOnDroppedFn(OnDrop)
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

    inst:AddComponent("tradable")
    --inst:AddComponent("vasedecoration")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = 0
    inst.components.edible.foodtype = "VEGGIE"

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

local function ground_fn()
	local inst = fn()

    inst:SetPrefabName("moon_tree_blossom")

	inst.components.perishable:StopPerishing()

    -- 地面月岛花白天有概率生成月蛾
    inst:DoPeriodicTask(TUNING.TOTAL_DAY_TIME / 6 or 40, TrySpawnMoonbutterfly, math.random(20))

	return inst
end

return Prefab("moon_tree_blossom", fn, assets, prefabs),
	Prefab("moon_tree_blossom_worldgen", ground_fn, assets)
