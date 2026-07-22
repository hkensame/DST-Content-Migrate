-- DS 兼容：DST 的玩家排序搜索函数
local FindPlayersInRangeSortedByDistance = rawget(_G, "FindPlayersInRangeSortedByDistance")
	or function() return {} end

local assets =
{
	Asset("ANIM", "anim/shadow_leech.zip"),
}

local prefabs =
{
	"nightmarefuel",
}

local brain = require("brains/shadow_leechbrain")

local LOOT = { "nightmarefuel" }

local function CalcSanityAura(inst, observer)
	return observer.components.sanity:IsCrazy()
		and -TUNING.SANITYAURA_MED
		or 0
end

local function ToggleBrain(inst, enable)
	inst:SetBrain(enable and brain or nil)
end

local function StartTrackingDaywalker(inst, daywalker)
	inst.components.entitytracker:TrackEntity("daywalker", daywalker)
	if daywalker.StartTrackingLeech ~= nil then
		daywalker:StartTrackingLeech(inst)
	end
end

local function OnSpawnFor(inst, daywalker, delay)
	StartTrackingDaywalker(inst, daywalker)
	inst:ForceFacePoint(daywalker.Transform:GetWorldPosition())
	inst.sg:GoToState("spawn_delay", delay)
end

local function OnFlungFrom(inst, daywalker, speedmult, randomdir)
	if inst._followtask ~= nil then
		inst._followtask:Cancel()
		inst._followtask = nil
	end
	inst._attachpos = nil

	local x, y, z = daywalker.Transform:GetWorldPosition()
	local rot = randomdir and math.random() * 360 or daywalker.Transform:GetRotation() + math.random() * 10 - 5
	inst.Transform:SetRotation(rot + 180) --flung backwards
	rot = rot * DEGREES
	speedmult = speedmult or 1
	inst.Physics:Teleport(x + math.cos(rot) * speedmult, y, z - math.sin(rot) * speedmult)
	inst.sg:GoToState("flung", speedmult)
end

local function OnLoadPostPass(inst)--, ents, data)
	local daywalker = inst.components.entitytracker:GetEntity("daywalker")
	if daywalker ~= nil and daywalker.StartTrackingLeech ~= nil then
		daywalker:StartTrackingLeech(inst)
	end
end

local function CanBeAttacked(inst)
	local player = inst.components.combat.target
	if player ~= nil and player.components.sanity then
		return player.components.sanity:IsCrazy()
	end
	-- 无目标或目标无 sanity 时，检查附近的玩家
	local players = FindPlayersInRangeSortedByDistance(inst.Transform:GetWorldPosition(), 20, false)
	for i, v in ipairs(players) do
		if v.components.sanity and v.components.sanity:IsCrazy() then
			return true
		end
	end
	return false
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddFollower()

	MakeCharacterPhysics(inst, 10, 0.9)

	inst.Transform:SetSixFaced()

	inst:AddTag("shadowcreature")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("shadow")
	inst:AddTag("notraptrigger")
	inst:AddTag("shadow_aligned")
    inst:AddTag("NOBLOCK")

	inst.AnimState:SetBank("shadow_leech")
	inst.AnimState:SetBuild("shadow_leech")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetMultColour(1, 1, 1, .5)

	inst:AddComponent("entitytracker")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = CalcSanityAura

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.SHADOW_LEECH_HEALTH)
	inst.components.health.nofadeout = true

	inst:AddComponent("combat")
	inst.components.combat.canbeattackedfn = CanBeAttacked

	-- DS 兼容：根据理智透明度（移除了 DST 的 TheNet:IsDedicated 守卫）
	if rawget(_G, "transparentonsanity") ~= nil then
		inst:AddComponent("transparentonsanity")
		inst.components.transparentonsanity.most_alpha = .8
		inst.components.transparentonsanity.osc_amp = .1
		inst.components.transparentonsanity:ForceUpdate()
	end

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot(LOOT)

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = TUNING.SHADOW_LEECH_RUNSPEED
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }

	inst:SetStateGraph("SGshadow_leech")
	inst:SetBrain(brain)

	inst.ToggleBrain = ToggleBrain
	inst.OnSpawnFor = OnSpawnFor
	inst.OnFlungFrom = OnFlungFrom
	inst.OnLoadPostPass = OnLoadPostPass

	return inst
end

return Prefab("shadow_leech", fn, assets, prefabs)
