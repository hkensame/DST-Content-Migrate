local assets=
{
	Asset("ANIM", "anim/moonisland/sapling_moon.zip"),
	Asset("MINIMAP_IMAGE", "sapling_moon"),
	Asset("SOUND", "sound/common.fsb"),
}


local prefabs =
{
    "twigs",
    "dug_sapling_moon",
}    

local function ontransplantfn(inst)
	inst.components.pickable:MakeEmpty()
end


local function dig_up(inst, chopper)
	if inst.components.pickable ~= nil and inst.components.lootdropper ~= nil then
		if inst.components.pickable:CanBePicked() then
			inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product)
		end
		local withered = inst.components.pickable:IsWithered()
		inst.components.lootdropper:SpawnLootPrefab(
			(withered and "twigs")
			or "dug_sapling_moon"
		)
	end
	inst:Remove()
end

local function onpickedfn(inst, picker)
	inst.AnimState:PlayAnimation("picked", false)
end

local function onregenfn(inst)
	inst.AnimState:PlayAnimation("grow") 
	inst.AnimState:PushAnimation("sway", true)
end

local function makeemptyfn(inst)
	if not POPULATING and inst.components.pickable:IsWithered() then
		inst.AnimState:PlayAnimation("dead_to_empty")
		inst.AnimState:PushAnimation("empty", false)
	else
		inst.AnimState:PlayAnimation("empty")
		inst.AnimState:PushAnimation("empty", false)
	end
end

local function makebarrenfn(inst, wasempty)
	if not POPULATING and inst.components.pickable:IsWithered() then
		inst.AnimState:PlayAnimation(wasempty and "empty_to_dead" or "full_to_dead")
		inst.AnimState:PushAnimation("idle_dead", false)
	else
		inst.AnimState:PlayAnimation("idle_dead")
	end
end

--[[local function onguststart(inst, windspeed)
	if inst.components.pickable and inst.components.pickable:CanBePicked() then
		inst.AnimState:PlayAnimation("blown_pre", false)
		inst.AnimState:PushAnimation("blown_loop", true)
	end
end

local function ongustend(inst, windspeed)
	if inst.components.pickable and inst.components.pickable:CanBePicked() then
		inst.AnimState:PushAnimation("blown_pst", false)
		inst.AnimState:PushAnimation("sway", true)
	end
end

local function ongustpickfn(inst)
    if inst.components.pickable and inst.components.pickable:CanBePicked() then
        inst.components.pickable:MakeEmpty()
        inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product)
    end
end]]

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local minimap = inst.entity:AddMiniMapEntity()
    inst.AnimState:SetRayTestOnBB(true);
    
    anim:SetBank("sapling_moon")
    anim:SetBuild("sapling_moon")
    anim:PlayAnimation("sway",true)
    anim:SetTime(math.random()*2)

	minimap:SetIcon( "sapling_moon.tex" ) 

    inst:AddTag("plant")
    inst:AddTag("renewable")
    inst:AddTag("gustable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
    
    inst.components.pickable:SetUp("twigs", TUNING.SAPLING_REGROW_TIME)
	inst.components.pickable.onregenfn = onregenfn
	inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
	inst.components.pickable.ontransplantfn = ontransplantfn
	inst.components.pickable.makebarrenfn = makebarrenfn
	local variance = math.random() * 4 - 2
	inst.makewitherabletask = inst:DoTaskInTime(TUNING.WITHER_BUFFER_TIME + variance, function(inst) inst.components.pickable:MakeWitherable() end)

    inst:AddComponent("inspectable")
    
	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up)
    inst.components.workable:SetWorkLeft(1)

    MakePickableBlowInWindGust(inst, TUNING.SAPLING_WINDBLOWN_SPEED, TUNING.SAPLING_WINDBLOWN_FALL_CHANCE)
    --[[inst:AddComponent("blowinwindgust")
    inst.components.blowinwindgust:SetWindSpeedThreshold(TUNING.SAPLING_WINDBLOWN_SPEED)
    inst.components.blowinwindgust:SetDestroyChance(TUNING.SAPLING_WINDBLOWN_FALL_CHANCE)
    inst.components.blowinwindgust:SetGustStartFn(onguststart)
    inst.components.blowinwindgust:SetGustEndFn(ongustend)
    inst.components.blowinwindgust:SetDestroyFn(ongustpickfn)
    inst.components.blowinwindgust:Start()]]

    
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:MakeDragonflyBait(1)

	MakeNoGrowInWinter(inst)    
    ---------------------   
    
    return inst
end

----------------<可挖掘物品：dug_sapling_moon>----------------
local function dug_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("sapling_moon")
    inst.AnimState:SetBuild("sapling_moon")
    inst.AnimState:PlayAnimation("dropped")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "dug_sapling"
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "dug_sapling_moon"
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = function(pt, deployer)
        local tree = SpawnPrefab("sapling_moon")
        if tree then
            tree.Transform:SetPosition(pt.x, pt.y, pt.z)
            inst.components.stackable:Get():Remove()
            tree.components.pickable:OnTransplant()
        end
    end
    inst.components.deployable.min_spacing = 1

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "WOOD"
    inst.components.edible.woodiness = 10

    return inst
end

return Prefab("sapling_moon", fn, assets, prefabs),
    Prefab("dug_sapling_moon", dug_fn, assets),
    MakePlacer("common/dug_sapling_moon_placer", "sapling_moon", "sapling_moon", "idle")