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
	if inst.components.pickable and inst.components.pickable:CanBePicked() then
		inst.components.lootdropper:SpawnLootPrefab("twigs")
	end
	if inst.components.pickable and not inst.components.pickable.withered then
		local bush = inst.components.lootdropper:SpawnLootPrefab("dug_sapling_moon")
	else
		inst.components.lootdropper:SpawnLootPrefab("twigs")
	end
	inst:Remove()
end

local function onpickedfn(inst)
	-- 播放采集动画提供视觉反馈
	inst.AnimState:PlayAnimation("picked", false)
end

local function onregenfn(inst)
	inst.AnimState:PlayAnimation("grow") 
	inst.AnimState:PushAnimation("sway", true)
end

local function makeemptyfn(inst)
	if inst.components.pickable and inst.components.pickable:IsWithered() then
		inst.AnimState:PlayAnimation("dead_to_empty")
		inst.AnimState:PushAnimation("empty", false)
	else
		inst.AnimState:PlayAnimation("empty")
		inst.AnimState:PushAnimation("empty", false)
	end
end

local function makebarrenfn(inst)
	if inst.components.pickable and inst.components.pickable.withered then
		if not inst.components.pickable.hasbeenpicked then
			inst.AnimState:PlayAnimation("full_to_dead")
		else
			inst.AnimState:PlayAnimation("empty_to_dead")
		end
		inst.AnimState:PushAnimation("idle_dead")
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

return Prefab( "forest/objects/sapling_moon", fn, assets, prefabs) 
