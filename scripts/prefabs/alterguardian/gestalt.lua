require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/alterguardian/brightmare_gestalt.zip"),
}

local prefabs =
{
	"gestalt_head",
	"gestalt_trail",
}

local assets_trail =
{
    Asset("ANIM", "anim/alterguardian/brightmare_gestalt_trail.zip"),
}

local brain = require "brains/brightmare_gestaltbrain"

local function SetHeadAlpha(inst, a)
	if inst.blobhead then
		inst.blobhead.AnimState:SetMultColour(a, a, a, a) 
	end
end

local function Client_CalcSanityForTransparency(inst, observer)
	if inst.components.inspectable ~= nil then
		return TUNING.GESTALT_COMBAT_TRANSPERENCY
	end

	-- DS 适配：无 replica，直接用 player sanity component
	local player = observer or GetPlayer()
	local sanity = player and player.components.sanity
	local pct = sanity and sanity:GetPercent() or 0.5
	local x = (pct - TUNING.GESTALT_MIN_SANITY_TO_SPAWN) / (1 - TUNING.GESTALT_MIN_SANITY_TO_SPAWN)
	return math.min(0.5, 0.4*x*x*x + 0.3)
end

-- DS 适配：无 brightmarespawner 时，在玩家附近找重定位点
local function FindRelocatePoint(inst)
	local player = inst.enlightenment_owner or GetPlayer()
	if not player then return nil end
	local x, y, z = player.Transform:GetWorldPosition()
	local angle = math.random() * 2 * PI
	local dist = (TUNING.GESTALT_SPAWN_DIST or 14) + math.random() * (TUNING.GESTALT_SPAWN_DIST_VAR or 3)
	return Vector3(x + math.cos(angle) * dist, 0, z - math.sin(angle) * dist)
end

local function SetTrackingTarget(inst, target, behaviour_level)
	local prev_target = inst.tracking_target
	inst.tracking_target = target
	inst.behaviour_level = behaviour_level
	if prev_target ~= inst.tracking_target then
		if inst.OnTrackingTargetRemoved ~= nil then
			inst:RemoveEventCallback("onremove", inst.OnTrackingTargetRemoved, prev_target)
			inst:RemoveEventCallback("death", inst.OnTrackingTargetRemoved, prev_target)
			inst.OnTrackingTargetRemoved = nil
		end
		if inst.tracking_target ~= nil then
			inst.OnTrackingTargetRemoved = function(target) inst.tracking_target = nil end
			inst:ListenForEvent("onremove", inst.OnTrackingTargetRemoved, inst.tracking_target)
			inst:ListenForEvent("death", inst.OnTrackingTargetRemoved, inst.tracking_target)
		end
	end
end

-- DS 适配：无 brightmarespawner，直接以玩家为跟踪目标
local function UpdateBestTrackingTarget(inst)
	local player = inst.enlightenment_owner or GetPlayer()
	if player and player:IsValid() then
		-- 根据启蒙等级决定 behaviour_level
		local enlight = player.components.enlightenment
		local level = enlight and enlight.behaviour_level or 1
		SetTrackingTarget(inst, player, level)
	end
end

local function Retarget(inst)
    -- If we don't have a tracking target, or are in combat cooldown, no target.
    if inst.tracking_target == nil 
            or inst.components.combat:InCooldown() then
        return nil
    end

    -- Level 1-2: 只在 GESTALT_AGGRESSIVE_RANGE 内攻击
    -- Level 3: 无视距离主动追击玩家
    if inst.behaviour_level < 3 
            and not inst:IsNear(inst.tracking_target, TUNING.GESTALT_AGGRESSIVE_RANGE) then
        return nil
    end

    -- If our potential target is sleeping, don't target them.
    local sleeping = inst.tracking_target.sg:HasStateTag("knockout")
        or inst.tracking_target.sg:HasStateTag("sleeping")
        or inst.tracking_target.sg:HasStateTag("bedroll")
        or inst.tracking_target.sg:HasStateTag("tent")
        or inst.tracking_target.sg:HasStateTag("waking")
    if sleeping then
        return nil
    end

    -- If our potential target has a gestalt item, don't target them.
    local target_inventory = inst.tracking_target.components.inventory
    if target_inventory ~= nil and target_inventory:EquipHasTag("gestaltprotection") then
        return nil
    end

    return inst.tracking_target
end

local function OnNewCombatTarget(inst, data)
	if inst.components.inspectable == nil then
		inst:AddComponent("inspectable")
		inst:AddTag("scarytoprey")
	end
end

local function OnNoCombatTarget(inst)
	inst.components.combat:RestartCooldown()
	inst:RemoveComponent("inspectable")
	inst:RemoveTag("scarytoprey")
end

local function fn()
    local inst = CreateEntity()

    --Core components
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    --Initialize physics
    local phys = inst.entity:AddPhysics()
    phys:SetMass(1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.FLYERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.GROUND)
    phys:SetCapsule(0.5, 1)

	inst:AddTag("brightmare")
	inst:AddTag("brightmare_gestalt")
	inst:AddTag("NOBLOCK")

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBuild("brightmare_gestalt")
    inst.AnimState:SetBank("brightmare_gestalt")
    inst.AnimState:PlayAnimation("idle", true)

	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    -- DS 适配：无 net_tinybyte，直接用普通变量
    inst._level = 1

	-- DS 无 TheNet:IsDedicated，始终显示
	do
		inst.blobhead = SpawnPrefab("gestalt_head")
		if inst.blobhead then
			inst.blobhead.entity:SetParent(inst.entity)
			inst.blobhead.Follower:FollowSymbol(inst.GUID, "head_fx", 0, 0, 0)
			inst.blobhead.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		end

	    inst.highlightchildren = { inst.blobhead }

		-- this is purely view related
		inst:AddComponent("transparentonsanity_dst")
		inst.components.transparentonsanity_dst.most_alpha = .2
		inst.components.transparentonsanity_dst.osc_amp = .05
		inst.components.transparentonsanity_dst.osc_speed = 5.25 + math.random() * 0.5
		inst.components.transparentonsanity_dst.calc_percent_fn = Client_CalcSanityForTransparency
		inst.components.transparentonsanity_dst.onalphachangedfn = SetHeadAlpha
		inst.components.transparentonsanity_dst:OnUpdate(0)
	end

	inst.persists = false

	inst.tracking_target = nil
	inst.behaviour_level = 1
	inst.FindRelocatePoint = FindRelocatePoint
	inst.SetTrackingTarget = SetTrackingTarget
	inst:DoPeriodicTask(0.1, UpdateBestTrackingTarget, 0)

    inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = TUNING.SANITYAURA_MED

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = TUNING.GESTALT_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.GESTALT_WALK_SPEED
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(0)
	inst.components.combat:SetAttackPeriod(TUNING.GESTALT_ATTACK_COOLDOWN)
	inst.components.combat:SetRange(TUNING.GESTALT_ATTACK_RANGE)
    inst.components.combat:SetRetargetFunction(1, Retarget)
	inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
	inst:ListenForEvent("droppedtarget", OnNoCombatTarget)
	inst:ListenForEvent("losttarget", OnNoCombatTarget)
	
    inst:SetStateGraph("SGbrightmare_gestalt")
    inst:SetBrain(brain)

    return inst
end

local function gestalt_trail_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("FX")

    inst.AnimState:SetBank("brightmare_gestalt_trail")
    inst.AnimState:SetBuild("brightmare_gestalt_trail")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetSortOrder(2)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:PlayAnimation("trail1")

	inst.Transform:SetScale(1.2, 1.2, 1.2)

	--if not TheNet:IsDedicated() then
		-- this is purely view related
		inst:AddComponent("transparentonsanity_dst")
		inst.components.transparentonsanity_dst.most_alpha = .2
		inst.components.transparentonsanity_dst.osc_amp = .05
		inst.components.transparentonsanity_dst.osc_speed = 5.25 + math.random() * 0.5
		inst.components.transparentonsanity_dst.calc_percent_fn = Client_CalcSanityForTransparency
		inst.components.transparentonsanity_dst:OnUpdate(0)
	--end


	local anim = math.random(8)
	if anim > 1 then
	    inst.AnimState:PlayAnimation("trail"..anim)
	end

    inst.persists = false
    inst:DoTaskInTime(40 * FRAMES, inst.Remove)

    return inst
end

return Prefab("gestalt", fn, assets, prefabs),
	Prefab("gestalt_trail", gestalt_trail_fn, assets_trail)
