local assets =
{
    Asset("ANIM", "anim/moonisland/meteor_dst.zip"),
    Asset("ANIM", "anim/moonisland/meteor_shadow_dst.zip"),
  Asset("ANIM", "anim/burntground.zip"),
}

local prefabs =
{
}
----------<流星>----------
local SMASHABLE_WORK_ACTIONS =
{
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}

local function onexplode(inst)
    local scale = inst.size * 1.3
    local x, y, z = inst.Transform:GetWorldPosition()
    local scorch = SpawnPrefab("burntground")
    if scorch ~= nil then
      scorch.Transform:SetPosition(x, y, z)
      scorch.Transform:SetScale(scale, scale, scale)
    end
    
	   inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/volcano/volcano_erupt")
    local ix, _, iz = inst.Transform:GetWorldPosition()
    --local boss = SpawnPrefab("alterguardian_phase1")
    --boss.Transform:SetPosition(ix, 0, iz)
    --boss.sg:GoToState("prespawn_idle")
    
    local ents = TheSim:FindEntities(x, y, z, inst.size * 3.5, nil, { "INLIMBO", "playerghost" })
    for i, v in ipairs(ents) do
      if v:IsValid() and not v:IsInLimbo() then
        if v.components.workable ~= nil then
          if v.sg == nil or not v.sg:HasStateTag("busy") then
            local work_action = v.components.workable:GetWorkAction()
            if work_action ~= nil and
                SMASHABLE_WORK_ACTIONS[work_action.id] and
                (work_action ~= ACTIONS.DIG
                or (v.components.spawner == nil and
                   v.components.childspawner == nil)) then
                     v.components.workable:WorkedBy(inst, inst.workdone or 20)
            end
          end
        elseif v.components.combat ~= nil then
          v.components.combat:GetAttacked(inst, inst.size * 50, nil)
        elseif v.components.inventoryitem ~= nil then
          if v.components.container ~= nil then
            v.components.container:DropEverything()
          end
        end
      end
    end
end

local function fn() 
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    
    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank("meteor")
    inst.AnimState:SetBuild("meteor_dst")
    inst.AnimState:PlayAnimation("crash")

    inst:AddTag("NOCLICK")
    
    inst.size = 1.3
    inst:DoTaskInTime(0.33, onexplode)
    inst.Transform:SetRotation(math.random(360))

    inst.persists = false

    return inst
end

----------<地面痕迹>----------
local FADE_INTERVAL = (TUNING.TOTAL_DAY_TIME or 480) * 5 / 64 --64 ticks for smallbyte

local function OnFadeDirty(inst)
	local alpha = (64 - inst.fade) / 65
	inst.AnimState:SetMultColour(alpha, alpha, alpha, alpha)
end

local function UpdateFade(inst)
	if inst.fade < 63 then
		inst.fade = inst.fade + 1
		OnFadeDirty(inst)
	else
		inst:Remove()
	end
end

local function OnSave(inst, data)
	data.fade = inst.fade > 0 and inst.fade or nil
	data.rotation = inst.Transform:GetRotation()
	data.scale = { inst.Transform:GetScale() }
end

local function OnLoad(inst, data)
	if data ~= nil then
		if data.rotation ~= nil then
			inst.Transform:SetRotation(data.rotation)
		end
		if data.scale ~= nil then
			inst.Transform:SetScale(data.scale[1] or 1, data.scale[2] or 2, data.scale[3] or 3)
		end
		if data.fade ~= nil and data.fade > 0 then
			inst.fade = math.min(data.fade, 63)
			OnFadeDirty(inst)
		end
	end
end

local function fn2()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst.AnimState:SetBuild("burntground")
	inst.AnimState:SetBank("burntground")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")

	inst.fade = 0
	OnFadeDirty(inst)

	--inst:DoPeriodicTask(FADE_INTERVAL, UpdateFade, math.max(0, FADE_INTERVAL - math.random()))
	inst:DoTaskInTime(10, inst.Remove)

	inst.Transform:SetRotation(math.random() * 360)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

----------<阴影警告>----------
local function AlphaToFade(alpha)
	return math.floor(alpha * 63 + .5)
end

local function FadeToAlpha(fade)
	return fade / 63
end

local function CalculatePeriod(time, starttint, endtint)
	return time / math.max(1, AlphaToFade(endtint) - AlphaToFade(starttint))
end

local DEFAULT_START = .33
local DEFAULT_END = 1
local DEFAULT_DURATION = 1
local DEFAULT_PERIOD = CalculatePeriod(DEFAULT_DURATION, DEFAULT_START, DEFAULT_END)

local function PushAlpha(inst)
	local alpha = FadeToAlpha(inst.fade)
	inst.AnimState:SetMultColour(alpha, alpha, alpha, alpha)
end

local function UpdateFade(inst)
	if inst.fade < inst.fadeend then
		inst.fade = inst.fade + 1
		PushAlpha(inst)
	end
	if inst.fade >= inst.fadeend and inst.task ~= nil then
		inst.task:Cancel()
		inst.task = nil
	end
end

local function OnFadeDirty(inst)
	PushAlpha(inst)
	if inst.task ~= nil then
		inst.task:Cancel()
	end
	inst.task = inst:DoPeriodicTask(inst.period, UpdateFade)
end

local function startshadow(inst, time, starttint, endtint)
	if time ~= DEFAULT_DURATION or starttint ~= DEFAULT_START or endtint ~= DEFAULT_END then
		inst.fade = AlphaToFade(starttint)
		inst.fadeend = AlphaToFade(endtint)
		inst.period = CalculatePeriod(time, starttint, endtint)
		OnFadeDirty(inst)
	end
end

local function fn3()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

	inst.AnimState:SetBank("warning_shadow")
	inst.AnimState:SetBuild("meteor_shadow_dst")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetFinalOffset(-1)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.fade = AlphaToFade(DEFAULT_START)
	inst.fadeend = AlphaToFade(DEFAULT_END)
	inst.period = DEFAULT_PERIOD
	inst.task = nil
	OnFadeDirty(inst)

	inst.SoundEmitter:PlaySound("dontstarve/common/meteor_spawn")

	inst.startfn = startshadow

	inst.persists = false

	return inst
end

return Prefab("common/shadowmeteor", fn, assets, prefabs),
       Prefab("common/objects/burntground", fn2, assets),
       Prefab("common/fx/meteorwarning", fn3, assets)
