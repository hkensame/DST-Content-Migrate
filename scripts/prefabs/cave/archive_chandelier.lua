local assets =
{
    Asset("ANIM", "anim/cave/chandelier_archives.zip"),
    Asset("ANIM", "anim/cave/chandelier_fire.zip"),
}

local assets_vault =
{
	Asset("ANIM", "anim/cave/chandelier_vault.zip"),
}

local assets_crawler =
{
	Asset("ANIM", "anim/cave/chandelier_vault2.zip"),
}

local prefabs_crawler =
{
	"vault_crawler",
}

local OFF = 0
local ON = 1
local DROP = 2

local LIGHT_PARAMS =
{
	[ON] =
    {
		id = ON,
        radius = 5,
        intensity = .6,
        falloff = .6,
        colour = { 131/255, 194/255, 255/255 },
        time = 3,
    },

	[OFF] =
    {
		id = OFF,
        radius = 0,
        intensity = 0,
        falloff = 1,
        colour = { 0, 0, 0 },
        time = 3,
    },
}

local LIGHT_PARAMS_VAULT =
{
	[ON] =
	{
		id = ON,
		radius = 4.5,
		intensity = 0.7,
		falloff = 0.65,
		colour = { 180/255, 240/255, 255/255 },
		time = 3,
	},

	[OFF] =
	{
		id = OFF,
		radius = 0,
		intensity = 0,
		falloff = 1,
		colour = { 0, 0, 0 },
		time = 3,
	},

	[DROP] =
	{
		id = DROP,
		radius = 4.5,
		intensity = 0.7,
		falloff = 0.8,
		colour = { 180/255, 240/255, 255/255 },
		time = 9 * FRAMES,
	},
}

local FLAMEDATA = {
    flame1 = "flame1",
    flame2 = "flame2",
    flame3 = "flame3",
    flame4 = "flame4",
}


local function CreateFireFx()
	local inst = CreateEntity()

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetBank("chandelier_fire")
	inst.AnimState:SetBuild("chandelier_fire")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

	return inst
end


local function sfx_StartSound(inst, level)
	if not inst.SoundEmitter:PlayingSound("firesfx") then
		inst.SoundEmitter:PlaySound("grotto/common/chandelier_LP", "firesfx")
	end
	inst.SoundEmitter:SetParameter("firesfx", "intensity", level)
end

local function sfx_SetSoundLevel(inst, level)
	if inst.level ~= level then
		inst.level = level
		if not inst:IsAsleep() then
			if level > 0 then
				sfx_StartSound(inst, level)
			else
				inst.SoundEmitter:KillSound("firesfx")
			end
		end
	end
end

local function sfx_OnEntitySleep(inst)
	if inst.level > 0 then
		inst.SoundEmitter:KillSound("firesfx")
	end
end

local function sfx_OnEntityWake(inst)
	if inst.level > 0 then
		sfx_StartSound(inst, inst.level)
	end
end

local function CreateSfxProp()
	local inst = CreateEntity()

	inst:AddTag("FX")
	inst.OnEntitySleep = sfx_OnEntitySleep
	inst.OnEntityWake = sfx_OnEntityWake
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddSoundEmitter()

	inst.level = 0
	inst.SetSoundLevel = sfx_SetSoundLevel

	return inst
end


local function pushparams(inst, params)
    inst.Light:SetRadius(params.radius * inst.widthscale)
    inst.Light:SetIntensity(params.intensity)
    inst.Light:SetFalloff(params.falloff)
    inst.Light:SetColour(unpack(params.colour))

    if params.intensity > 0 and not inst.detached then
        inst.Light:Enable(true)
    else
        inst.Light:Enable(false)
    end

	if inst.sfxprop then
		inst.sfxprop:SetSoundLevel(params.intensity)
	end
end

-- Not using deepcopy because we want to copy in place
local function copyparams(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = dest[k] or {}
            copyparams(dest[k], v)
        else
            dest[k] = v
        end
    end
end

local function lerpparams(pout, pstart, pend, lerpk)
    for k, v in pairs(pend) do
        if type(v) == "table" then
            lerpparams(pout[k], pstart[k], v, lerpk)
        else
            pout[k] = pstart[k] * (1 - lerpk) + v * lerpk
        end
    end
end

local function UpdateFlames(inst)
	if inst.flamedata then
		for k, v in pairs(inst.flamedata) do
			local val = Remap(inst._currentlight.intensity, inst.light_params[OFF].intensity, inst.light_params[ON].intensity, 0, 1)
			local fx = inst[v]
			if val > 0 then
				if fx == nil then
					fx = CreateFireFx()
					fx.entity:SetParent(inst.entity)
					fx.Follower:FollowSymbol(inst.GUID, inst.AnimState.GetSymbolID and inst.AnimState:GetSymbolID(v) or v, 0, 0, 0)
					inst[v] = fx
				end
				fx.AnimState:SetLightOverride(val)
				fx.AnimState:SetScale(val, val, val)
			elseif fx then
				fx:Remove()
				inst[v] = nil
			end
		end
	end
end

local function OnUpdateLight(inst, dt)
    inst._currentlight.time = inst._currentlight.time + dt
    if inst._currentlight.time >= inst._endlight.time then
        inst._currentlight.time = inst._endlight.time
        inst._lighttask:Cancel()
        inst._lighttask = nil
    end

    lerpparams(inst._currentlight, inst._startlight, inst._endlight, inst._endlight.time > 0 and inst._currentlight.time / inst._endlight.time or 1)
    pushparams(inst, inst._currentlight)

	inst.AnimState:SetLightOverride(Remap(inst._currentlight.intensity, inst.light_params[OFF].intensity, inst.light_params[ON].intensity, 0,1))

	UpdateFlames(inst)
end

local function SetLightPhase(inst, newphase)
	local params = inst.light_params[newphase]
	if params and params ~= inst._endlight then
		copyparams(inst._startlight, inst._currentlight)
		inst._currentlight.time = 0
		inst._startlight.time = 0
		inst._endlight = params
		if inst._lighttask == nil then
			inst._lighttask = inst:DoPeriodicTask(FRAMES, OnUpdateLight, nil, FRAMES)
		end
	end
end

local function _updatelight(inst)
	local theWorld = inst:GetTheWorld()
	if theWorld == nil then return end
	local powered
	if inst.vaultpowered then
		local vaultroommanager = theWorld.components.vaultroommanager
		powered = vaultroommanager ~= nil and vaultroommanager:NumPlayersInVault() > 0
	else
		local archivemanager = theWorld.components.archivemanager
		local playerprox = inst.components.playerprox
		powered = (playerprox == nil or playerprox:IsPlayerClose()) and (archivemanager == nil or archivemanager:GetPowerSetting())
	end
	if powered then
        if inst._lightphase ~= ON then
            inst._lightphase = ON
            SetLightPhase(inst, ON)
        end
    else
        if inst._lightphase ~= OFF then
            inst._lightphase = OFF
            SetLightPhase(inst, OFF)
        end
    end
end

local function OnInit(inst)
	--Skip lerping the lights
	local params = inst.light_params[inst._lightphase]
	if params and params ~= inst._endlight then
		copyparams(inst._currentlight, params)
		inst._endlight = params
		if inst._lighttask then
			inst._lighttask:Cancel()
			inst._lighttask = nil
		end
		pushparams(inst, inst._currentlight)
		UpdateFlames(inst)
	end
end

local function MakeChandelier(name, build, light_params, flamedata, sfxheight, common_postinit, master_postinit, assets, prefabs)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddLight()

		inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		inst.AnimState:SetBank(build)
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation("idle", true)

		inst:AddTag("NOCLICK")
		inst:AddTag("FX")
		inst:AddTag("archive_chandelier")

		inst.light_params = light_params
		inst.flamedata = flamedata
		inst.widthscale = 1
		inst._endlight = light_params[OFF]
		inst._startlight = {}
		inst._currentlight = {}
		copyparams(inst._startlight, inst._endlight)
		copyparams(inst._currentlight, inst._endlight)
		pushparams(inst, inst._currentlight)

		inst._lightphase = inst._currentlight.id
		inst._lighttask = nil

		inst.sfxprop = CreateSfxProp()
		inst.sfxprop.entity:SetParent(inst.entity)
		inst.sfxprop.Transform:SetPosition(0, sfxheight, 0)

		inst:DoTaskInTime(0, OnInit)

		if common_postinit then
			common_postinit(inst)
		end

		inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

		inst.updatelight = _updatelight

		if master_postinit then
			master_postinit(inst)
		end

		return inst
	end
	return Prefab(name, fn, assets, prefabs)
end


local function archive_OnSave(inst, data)
    data.lightphase = inst._lightphase
end

local function archive_OnLoad(inst, data)
    if data and data.lightphase then
        inst._lightphase = data.lightphase
    end
end

local function archive_master_postinit(inst)
	inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(20, 23)
	inst.components.playerprox:SetOnPlayerNear(inst.updatelight)
	inst.components.playerprox:SetOnPlayerFar(inst.updatelight)
    inst.OnSave = archive_OnSave
    inst.OnLoad = archive_OnLoad
end


local function vault_SetVariation(inst, variation)
	inst.variation = variation
	local anim = variation == 1 and "idle" or "idle_2"
	if not inst.AnimState:IsCurrentAnimation(anim) then
		local t = inst.AnimState:GetCurrentAnimationTime()
		inst.AnimState:PlayAnimation(anim, true)
		inst.AnimState:SetTime(t)
	end
	return inst
end

local function vault_OnSave(inst, data)
	data.variation = inst.variation ~= 1 and inst.variation or nil
end

local function vault_OnLoad(inst, data)
	if data and data.variation then
		inst:SetVariation(data.variation)
	end
end

local function vault_master_postinit(inst)
	inst.vaultpowered = true
	inst.variation = 1
	inst.SetVariation = vault_SetVariation
	inst.OnSave = vault_OnSave
	inst.OnLoad = vault_OnLoad

	inst:updatelight()
end


local function crawler_UpdateLight(inst)
	if not inst.dropped then
		_updatelight(inst)
	elseif inst._lightphase ~= DROP then
		inst._lightphase = DROP
		SetLightPhase(inst, DROP)
	end
end

local function crawler_OnAnimOver(inst)
	if inst.AnimState:IsCurrentAnimation("fall") then
		inst.persists = false
		inst.detached = true
		inst.Light:Enable(false)
		inst.AnimState:ClearBloomEffectHandle()
		inst.AnimState:SetFinalOffset(2)

		local x, _, z = inst.Transform:GetWorldPosition()
		local crawler = SpawnPrefab("vault_crawler")
		crawler.Transform:SetPosition(x, 0, z)
		crawler.sg:GoToState("spawn")

		inst:PushEvent("ms_vaultcrawler_dropped", crawler)

		if inst:IsAsleep() then
			inst:Remove()
		else
			inst.OnEntitySleep = inst.Remove
			inst.AnimState:PlayAnimation("fall_pst")
		end
	elseif inst.AnimState:IsCurrentAnimation("fall_pst") then
		inst.AnimState:PlayAnimation("withdraw")
	elseif inst.AnimState:IsCurrentAnimation("withdraw") then
		inst:Remove()
	end
end

local function crawler_DropCrawler(inst)
	if inst.dropped then
		return
	end
	inst.dropped = true
	inst:ListenForEvent("animover", crawler_OnAnimOver)
	inst.AnimState:PlayAnimation("fall")
	inst:updatelight()
end

local function crawler_OnSave(inst, data)
    data.lightphase = inst._lightphase
    data.dropped = inst.dropped or nil
    data.detached = inst.detached or nil
end

local function crawler_OnLoad(inst, data)
    if data then
        inst.dropped = data.dropped or nil
        inst.detached = data.detached or nil
        if inst.dropped then
            inst.persists = false
            inst.Light:Enable(false)
            inst.AnimState:ClearBloomEffectHandle()
        end
        if data.lightphase then
            inst._lightphase = data.lightphase
        end
    end
end

local function crawler_master_postinit(inst)
	inst.vaultpowered = true
	inst.updatelight = crawler_UpdateLight
	inst.DropCrawler = crawler_DropCrawler
    inst.OnSave = crawler_OnSave
    inst.OnLoad = crawler_OnLoad

	inst:updatelight()
end


return MakeChandelier("archive_chandelier", "chandelier_archives", LIGHT_PARAMS, FLAMEDATA, 8, nil, archive_master_postinit, assets),
	MakeChandelier("vault_chandelier", "chandelier_vault", LIGHT_PARAMS_VAULT, nil, 6, nil, vault_master_postinit, assets_vault),
	MakeChandelier("vault_crawler_chandelier", "chandelier_vault2", LIGHT_PARAMS_VAULT, nil, 6, nil, crawler_master_postinit, assets_crawler, prefabs_crawler)
