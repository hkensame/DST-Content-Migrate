
--local RuinsRespawner = require "prefabs/ruinsrespawner" -- DS: not needed for step 1

local assets =
{
    Asset("ANIM", "anim/cave/archive_moon_statue.zip"),
    Asset("ANIM", "anim/cave/archive_runes.zip"),
    Asset("MINIMAP_IMAGE", "archive_runes"),
    Asset("MINIMAP_IMAGE", "archive_moon_statue1"),
    Asset("MINIMAP_IMAGE", "archive_moon_statue2"),
    Asset("MINIMAP_IMAGE", "archive_moon_statue3"),
    Asset("MINIMAP_IMAGE", "archive_moon_statue4"),
}

local assets_desk =
{
    Asset("ANIM", "anim/cave/archive_security_desk.zip"),
}

local prefabs_desk =
{
    "archive_security_pulse",
    "archive_security_waypoint",
}

local assets_security =
{
    Asset("ANIM", "anim/cave/archive_security_pulse.zip"),
}

local prefabs_security =
{
    "archive_security_pulse_sfx",
}

local assets_switch =
{
    Asset("ANIM", "anim/cave/archive_switch.zip"),
    Asset("MINIMAP_IMAGE", "archive_power_switch"),
}

local prefabs_switch =
{
    "archive_switch_base",
    "archive_switch_pad",
    "grotto_war_sfx",
}

local assets_switch_base =
{
    Asset("ANIM", "anim/cave/archive_switch_ground.zip"),
}

local assets_switch_pad =
{
    Asset("ANIM", "anim/cave/archive_switch_ground_small.zip"),
}

SetSharedLootTable('archive_statues',
{
    {'thulecite',     1.00},
    {'moonrocknugget',1.00},
    {'moonrocknugget',0.05},
})

local assets_seal =
{
    Asset("ANIM", "anim/moonbase/moonbase_fx.zip"),
}

local assets_portal =
{
    Asset("ANIM", "anim/cave/archive_portal.zip"),
    Asset("ANIM", "anim/cave/archive_portal_base.zip"),
    Asset("MINIMAP_IMAGE", "archive_portal"),
}

local function ShowWorkState(inst, worker, workleft)
    inst.AnimState:PlayAnimation(
        (   (workleft < TUNING.MARBLEPILLAR_MINE / 3 and "idle_low_") or
            (workleft < TUNING.MARBLEPILLAR_MINE * 2 / 3 and "idle_med_") or
            "idle_full_"
        )..(inst.anim or ""),
        true
    )
end

local function OnWorkFinished(inst)
    inst.components.lootdropper:DropLoot(inst:GetPosition())

    local fx = SpawnAt("collapse_small", inst)
    -- DS: no SetMaterial
    --fx:SetMaterial("rock")

    inst:Remove()
end

local function setminimapiconstatue(inst)
    inst.MiniMapEntity:SetIcon("archive_moon_statue"..inst.anim..".tex")
end

local function onsave(inst, data)
    data.anim = inst.anim
end

local function onloadpostpass(inst, newents, data)
    if data ~= nil and data.anim ~= nil then
        inst.anim = data.anim
    end
    setminimapiconstatue(inst)
    ShowWorkState(inst, nil, inst.components.workable.workleft)
end

local function statuefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    MakeObstaclePhysics(inst, 0.66)

    inst.AnimState:SetBank("archive_moon_statue")
    inst.AnimState:SetBuild("archive_moon_statue")
	inst.AnimState:PlayAnimation("idle_full_1")
    inst.scrapbook_anim = "idle_full_1"

    inst:AddTag("structure")
    inst:AddTag("statue")
    inst:AddTag("dustable")

    inst:SetPrefabNameOverride("archive_moon_statue")

	inst.anim = math.random(4)
	if inst.anim ~= 1 then
		inst.AnimState:PlayAnimation("idle_full_"..tostring(inst.anim))
	end

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.MARBLEPILLAR_MINE)
    inst.components.workable:SetOnWorkCallback(ShowWorkState)
    inst.components.workable:SetOnFinishCallback(OnWorkFinished)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("archive_statues")

    --MakeHauntableWork(inst) -- DS: removed

    setminimapiconstatue(inst)

    inst.OnLoadPostPass = onloadpostpass
    inst.OnSave = onsave

    return inst
end

local _storyprogress = 0
local NUM_STORY_LINES = 5

local function rune_AdvanceStory(inst)
	if inst.storyprogress == nil then
		_storyprogress = (_storyprogress % NUM_STORY_LINES) + 1
		inst.storyprogress = _storyprogress
	end
end

local function getstatus(inst)
	rune_AdvanceStory(inst)
    return "LINE_"..tostring(inst.storyprogress)
end

local function rune_getdescription(inst, viewer)
	if viewer.components.inventory and viewer.components.inventory:EquipHasTag("ancient_reader") then
		rune_AdvanceStory(inst)
		return STRINGS.ARCHIVE_RUNE_STATUE["LINE_"..tostring(inst.storyprogress)]
	end
end

local function onsaveRune(inst, data)
    data.storyprogress = inst.storyprogress
    data.anim = inst.anim
end

local function onloadRune(inst, data)
	if data then
		if data.storyprogress then
			inst.storyprogress = data.storyprogress
			_storyprogress = math.max(_storyprogress, inst.storyprogress)
		end

		if data.anim then
			inst.anim = data.anim
			local anim = inst.anim == 1 and "idle" or ("idle"..tostring(inst.anim))
			if not inst.AnimState:IsCurrentAnimation(anim) then
				inst.AnimState:PlayAnimation(anim)
			end
		end
	end
end

local function runefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    MakeObstaclePhysics(inst, 0.66)

    inst.AnimState:SetBank("archive_rune")
    inst.AnimState:SetBuild("archive_runes")
	inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("archive_runes.tex")

    inst:AddTag("structure")
    inst:AddTag("statue")
    inst:AddTag("dustable")
	inst:AddTag("ancient_text")

    inst:SetPrefabNameOverride("archive_rune_statue")

	inst.scrapbook_anim = "idle"
    inst.scrapbook_specialinfo = "ARCHIVERUNESTATUE"

	inst.scrapbook_speechstatus = "LINE_1"

	inst.anim = math.random(3)
	if inst.anim ~= 1 then
		inst.AnimState:PlayAnimation("idle"..tostring(inst.anim))
	end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus
	inst.components.inspectable.descriptionfn = rune_getdescription

    inst.OnLoad = onloadRune
    inst.OnSave = onsaveRune

    return inst
end

local function canspawn(inst)
    local theWorld = inst:GetTheWorld()
    local archive = theWorld ~= nil and theWorld.components.archivemanager
    if not archive or archive:GetPowerSetting() and inst.AnimState:IsCurrentAnimation("idle") then
        return inst.canspawn == true
    end
end

local function OnUpdateDesk(inst)
    local theWorld = inst:GetTheWorld()
    local archive = theWorld ~= nil and theWorld.components.archivemanager

    if archive and not archive:GetPowerSetting() then
        if not inst.AnimState:IsCurrentAnimation("idle_leave") and
           not inst.AnimState:IsCurrentAnimation("leave") then
            inst.AnimState:PlayAnimation("leave",false)
            inst.AnimState:PushAnimation("idle_leave",false)
            inst.Light:Enable(false)
            inst.SoundEmitter:KillSound("loop")
        end
    else
        if inst.components.childspawner.childreninside > 0 then
            if  not inst.AnimState:IsCurrentAnimation("appear") and
                not inst.AnimState:IsCurrentAnimation("idle") then
                    inst.AnimState:PlayAnimation("appear",false)
                    inst.AnimState:PushAnimation("idle",true)

                    inst.SoundEmitter:PlaySound("grotto/common/archive_security_desk/appear")
            end
            -- Guard: DLC0003 childspawner calls GetWorld():getworldgenoptions() which can return nil at runtime
            pcall(function() inst.components.childspawner:SpawnChild() end)
            inst.Light:Enable(true)
            if not inst.SoundEmitter:PlayingSound("loop") then
                inst.SoundEmitter:PlaySound("grotto/common/archive_security_desk/contained_LP","loop")
            end
        else
            if  not inst.AnimState:IsCurrentAnimation("idle_leave") and
                not inst.AnimState:IsCurrentAnimation("leave") then
                    inst.AnimState:PlayAnimation("leave",false)
                    inst.AnimState:PushAnimation("idle_leave",false)
            end
            inst.Light:Enable(false)
            inst.SoundEmitter:KillSound("loop")
        end
    end
end

local function getStatusPower(inst)
    local theWorld = inst:GetTheWorld()
    local archive = theWorld ~= nil and theWorld.components.archivemanager
    return archive and not archive:GetPowerSetting() and "POWEROFF"
end

local SECURITY_SCRAPBOOK_HIDE_LAYER = { "moss" }

local function securityfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(false)

    MakeObstaclePhysics(inst, 0.66)

    inst.AnimState:SetBuild("archive_security_desk")
    inst.AnimState:SetBank("archive_security_desk")
	inst.AnimState:PlayAnimation("idle_leave")
	--inst.AnimState:SetSymbolLightOverride("fx_beam", 1)         -- DS: no SetSymbolLightOverride
	--inst.AnimState:SetSymbolLightOverride("fx_archive_circles", 1)
	--inst.AnimState:SetSymbolLightOverride("fx_archive_point_loop", 1)
	inst.AnimState:Hide("moss")

    inst:AddTag("structure")
    inst:AddTag("statue")
    inst:AddTag("dustable")
	inst:AddTag("security_desk")

    inst.scrapbook_specialinfo = "ARCHIVESECURITYDESK"

    inst.scrapbook_anim = "idle"
	inst.scrapbook_hide = SECURITY_SCRAPBOOK_HIDE_LAYER

    inst.canspawn = false

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getStatusPower

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "archive_security_pulse"
    inst.components.childspawner:SetRegenPeriod(TUNING.ARCHIVE_SECURITY.REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.ARCHIVE_SECURITY.RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(1)
    -- 不调用 StartSpawning()：DLC0003 childspawner 内部 OnUpdate → SpawnChild → GetWorld():getworldgenoptions() 在运行时返回 nil
    -- 由 1 秒间隔的 OnUpdateDesk 手动控制 SpawnChild（已用 pcall 保护）
    --inst.components.childspawner:StartSpawning()
    inst.components.childspawner:SetSpawnedFn(function()
        inst.SoundEmitter:PlaySound("grotto/common/archive_security_desk/leave")
    end)
    inst.components.childspawner.canspawnfn = canspawn

    inst.components.childspawner.overridespawnlocation = function(inst)
        return Vector3(0,0,0)
    end

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(6,7)

    inst.components.playerprox:SetOnPlayerNear(function()
        inst.canspawn = true
    end)
    inst.components.playerprox:SetOnPlayerFar(function()
        inst.canspawn = false
    end)

    inst:DoPeriodicTask(1, OnUpdateDesk)

    return inst
end

local function securitywaypointfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("NOBLOCK")
    inst:AddTag("archive_waypoint")

    return inst
end

----------------------------------------------------------------------------------------------------

local brain = require("brains/archive_securitypulsebrain")

local SFXRANGE = 4

local POWERPOINT_POSSESSION_RANGE = 0.2

local POWERPOINT_MUST_TAGS = { "security_powerpoint" }
local POWERPOINT_CAN_TAGS =  { "INLIMBO", "FX" }

local function FindFollowTargetTest(inst, target)
    local item = target.components.inventory ~= nil and target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    if item == nil or item.prefab ~= "vault_compass" then
        return false
    end

    if target.components.leader ~= nil then
        local c = 0
        local sparks = target.components.leader:GetFollowersByTag("power_point")
        for i, v in ipairs(sparks) do
            c = c + 1
            if v == inst then
                return true
            end
        end

        return c < TUNING.MAX_SECURITY_PULSE_FOLLOWING
    end
end

local function RecaculateFormationOffset(leader)
    if not leader.components.leader then
        return
    end
    local sparks = leader.components.leader:GetFollowersByTag("power_point")
    local maxsparks = #sparks
    local radius = 2 + math.random()
    local angleoffset = math.random() * TWOPI
    local x, y, z = leader.Transform:GetWorldPosition()
	for i = 1, #sparks do
        local angle = angleoffset + PI2 * (i - 1) / maxsparks
        local offset = Vector3(radius * math.cos(angle), 0, radius * math.sin(angle))
		local x1 = x + offset.x
		local z1 = z + offset.z
		local mindistsq = math.huge
		local minj
		for j, pet in ipairs(sparks) do
			local dsq = pet:GetDistanceSqToPoint(x1, 0, z1)
			if dsq < mindistsq then
				mindistsq = dsq
				minj = j
			end
		end
		table.remove(sparks, minj).components.knownlocations:RememberLocation("formationoffset", offset, false)
    end
end

local function SetSecurityPulseLeader(inst, leader)
    if leader ~= nil then
        leader:PushEvent("ms_securitysparkfollowing")
        inst.patrol = false
        inst.persists = false
        inst.components.follower:SetLeader(leader)
        RecaculateFormationOffset(leader)

        local owner = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
        if owner ~= nil and owner.components.childspawner ~= nil then
            owner.components.childspawner:OnChildKilled(inst)
        end
    else
        local oldleader = inst.components.follower.leader
        inst.components.follower:SetLeader(nil)
        inst.components.knownlocations:ForgetLocation("formationoffset")
        if oldleader then
            RecaculateFormationOffset(oldleader)
        end
    end
end

local function FindSecurityPulseTarget(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, inst.possession_range, POWERPOINT_MUST_TAGS, POWERPOINT_CAN_TAGS)

    for i=#ents, 1, -1 do
        local ent = ents[i]

        if ent.components.health ~= nil and ent.components.health:GetPercent() < (ent.MED_THRESHOLD_DOWN or 1) then
            table.remove(ents, i)
        end
    end

    if ents[1] ~= nil then
        ents[1]:PushEvent("possess", { possesser = inst })
        return
    end

    if not inst:IsAsleep() then
        local leader = inst.components.follower.leader
        if leader ~= nil then
            if FindFollowTargetTest(inst, leader) then
                return true
            else
                SetSecurityPulseLeader(inst, nil)
            end
        end

        local px, py, pz = 0, 0, 0
        local player = GetPlayer()
        if player then
            px, py, pz = player.Transform:GetWorldPosition()
            local dsq = inst:GetDistanceSqToPoint(px, py, pz)
            if dsq <= 9*9 and FindFollowTargetTest(inst, player) then
                SetSecurityPulseLeader(inst, player)
            end
        end
    end
end

local function OnLocomote(inst)
    if inst.components.locomotor:WantsToMoveForward() then
        inst.components.locomotor:WalkForward()
    else
        inst.components.locomotor:StopMoving()
    end
end

local function SetSfxPosition(inst)
    if inst.sfx_prefab ~= nil then
        inst.sfx_prefab.Transform:SetPosition(SFXRANGE, 0, 0)
    end
end

local function Despawn(inst, opt_target)
	if inst:IsAsleep() then
		inst:Remove()
		return
	end
	inst:StopBrain("despawn")
    inst.components.locomotor:StopMoving()
    inst.components.locomotor.walkspeed = 0
    inst.persists = false
    inst.SoundEmitter:PlaySound("grotto/creatures/centipede/electricity/small_explode")
    inst.AnimState:PlayAnimation("despawn")
	if opt_target then
		inst.Physics:Teleport(opt_target.Transform:GetWorldPosition())
		inst.AnimState:SetFinalOffset(4)
	end
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)
end

local function OnPulseStartAction(inst, data)
    if data ~= nil and data.action ~= nil and data.action.action == ACTIONS.GOHOME then
        local home = data.action.target
        if home ~= nil and home.components.childspawner ~= nil and home.components.childspawner.childreninside == 0 then
            home.components.childspawner:TakeOwnership(inst)
            inst:PerformBufferedAction()
        else
            inst:ClearBufferedAction()
        end
    end
end

local function securitypulsefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)

    inst.entity:AddPhysics()
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCapsule(.5, 1)

    inst.AnimState:SetBank("archive_security_pulse")
    inst.AnimState:SetBuild("archive_security_pulse")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetLightOverride(1)

    inst:AddTag("power_point")
	inst:AddTag("flying")

    inst.patrol = true
    inst.possession_range = POWERPOINT_POSSESSION_RANGE

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.ARCHIVE_SECURITY.WALK_SPEED

    inst:AddComponent("follower")
    inst:AddComponent("knownlocations")

    inst.OnLocomote = OnLocomote
    inst.FindSecurityPulseTarget = FindSecurityPulseTarget
    inst.Despawn = Despawn

    inst.sfx_prefab = inst:SpawnChild("archive_security_pulse_sfx")

    inst:ListenForEvent("locomote", inst.OnLocomote)
    inst:ListenForEvent("startaction", OnPulseStartAction)

    inst:DoPeriodicTask(.25, inst.FindSecurityPulseTarget, 0)
    inst:DoTaskInTime(0, SetSfxPosition)

    inst:SetStateGraph("SGarchive_security_pulse")

    inst:SetBrain(brain)

    return inst
end

local function OnUpdatePulseSFX(inst, dt)
    dt = dt or GetTickTime()
    if inst.parent == nil then
        inst:Remove()
    else
        local pt = inst:GetPosition()
        local CIRCLE_TIME = 2
        local rate = TWOPI/ CIRCLE_TIME
        local theta = (inst.parent:GetAngleToPoint(pt)* DEGREES) + (rate * dt)
        local offset = Vector3(SFXRANGE * math.cos( theta ), 0, -SFXRANGE * math.sin( theta ))
        inst.Transform:SetPosition(offset.x,offset.y,offset.z)
    end
end

local function securitypulse_sfxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst.persists = false

    inst:DoPeriodicTask(0, OnUpdatePulseSFX)

    inst.SoundEmitter:PlaySound("grotto/common/archive_security_desk/leave_LP", "loop")

    return inst
end

local function ItemTradeTestSwitch(inst, item)
    if item == nil then
        return false
    elseif item.prefab ~= "opalpreciousgem" then
        return false, string.sub(item.prefab, -3) == "gem" and "WRONGGEM" or "NOTGEM"
    end
    return true
end

local function startshadowwar(inst)
    local theWorld = inst:GetTheWorld()
    local warstarted = theWorld ~= nil and theWorld.components.grottowarmanager and theWorld.components.grottowarmanager:IsWarStarted()
    if not warstarted and not inst.shadowwartask then
        inst.shadowwartask = inst:DoTaskInTime(7 ,function()
            if theWorld ~= nil then
                theWorld:PushEvent("ms_archivesbreached")
            end
        end)
    end
end

local WAYPOINT_MUST_TAGS = {"archive_waypoint"}
local function findwaypoints(inst, dist)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, dist, WAYPOINT_MUST_TAGS)
    for i,ent in ipairs(ents)do
        if ent == inst then
            table.remove(ents,i)
            break
        end
    end
    return ents
end

local function spawnsounderobj(pos, sound)
    local soundobj = CreateEntity()
    soundobj.entity:AddTransform()
    soundobj.entity:AddSoundEmitter()
    soundobj.Transform:SetPosition(pos.x,pos.y,pos.z)
    soundobj:DoTaskInTime(10,function() soundobj:Remove() end)
    soundobj.SoundEmitter:PlaySound(sound)
end

local function testbetweenpoints(pt1,pt2)
    local x1,y1,z1 = pt1.Transform:GetWorldPosition()
    local x2,y2,z2 = pt2.Transform:GetWorldPosition()

    local xdiff = (x2 - x1)/2
    local zdiff = (z2 - z1)/2

    local x = x1 + xdiff
    local z = z1 + zdiff

    local theWorld = pt1:GetTheWorld()
    if theWorld ~= nil and theWorld.Map ~= nil and theWorld.Map.IsVisualGroundAtPoint ~= nil then
        return theWorld.Map:IsVisualGroundAtPoint(x,0,z)
    end
    return true -- DS 没有 IsVisualGroundAtPoint，默认通过
end

local WAYPOINT_RANGE = 34
local function startpowersound(inst)
    local wp = findwaypoints(inst, 5)

    if #wp > 0 then
        wp = wp[1]
        local wps = findwaypoints(wp, WAYPOINT_RANGE)

        local pos = Vector3(wp.Transform:GetWorldPosition())
        spawnsounderobj(pos, "grotto/common/archive_switch/start")

        for i=#wps,1,-1 do
            if not testbetweenpoints(wp,wps[i]) then
                table.remove(wps,i)
            end
        end

        for i,ent in ipairs(wps)do
            local pos = Vector3(wp.Transform:GetWorldPosition())
            local x,y,z = ent.Transform:GetWorldPosition()
            local theta = wp:GetAngleToPoint(x,y,z)*DEGREES
            local radius = 6
            local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
            local time = 0

            time = time + 1
            wp:DoTaskInTime(time,function()
                local pos1 = pos + offset
                spawnsounderobj(pos1, "grotto/common/archive_switch/1")
            end)

            time = time + 1
            wp:DoTaskInTime(time,function()
                local pos1 = pos + (offset *2)
                spawnsounderobj(pos1, "grotto/common/archive_switch/2")
            end)

            time = time + 1
            wp:DoTaskInTime(time,function()
                local pos1 = pos + (offset *3)
                spawnsounderobj(pos1, "grotto/common/archive_switch/3")
            end)

            time = time + 1
            wp:DoTaskInTime(time,function()
                local pos1 = pos + (offset *4)
                spawnsounderobj(pos1, "grotto/common/archive_switch/4")
            end)
        end
    end
end

local GEM_SOCKET_MUST_TAGS = {"gemsocket","archive_switch"}
local CHANDELIER_MUST_TAGS = {"archive_chandelier"}
local function checkforgems(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 6, GEM_SOCKET_MUST_TAGS )
    -- checkforgems diagnostics removed

    for i=#ents,1,-1 do
        local ent = ents[i]
        if not ent.gem then
            -- removing switch (no gem)
            table.remove(ents,i)
        else
            -- keeping switch (has gem)
        end
    end

    -- 注意：不能使用 GetWorld()，DS 中它会缓存第一次找到的 ground 实体（森林），
    -- 进入洞穴后仍然返回森林，导致 archivemanager 始终为 nil。
    -- 此处 inst 为 archive_switch，已通过 archive_hooks.lua 注入了 GetTheWorld
    local theWorld = inst:GetTheWorld()
    local archive = theWorld ~= nil and theWorld.components.archivemanager
    -- checkforgems status diagnostics removed
    if archive and #ents >= 3 then
        -- ACTIVATING POWER!
        local success, err = pcall(archive.SwitchPowerOn, archive, true)
        if not success then
            -- ARCHIVE CRASHED! SwitchPowerOn error
        else
            -- SwitchPowerOn returned OK
        end
        startpowersound(inst)
        startshadowwar(inst)
        local ents = TheSim:FindEntities(x, y, z, 10, CHANDELIER_MUST_TAGS )
        for i,ent in ipairs(ents)do
            if ent.updatelight then
                ent.updatelight(ent)
            end
        end
    else
        -- power NOT activated (need more gems)
    end
end

local function OnGemGiven(inst, giver, item)
    -- OnGemGiven: switch diagnostics removed
    inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")

    inst.components.trader:Disable()
    inst.components.pickable:SetUp("opalpreciousgem", 1000000)
    inst.components.pickable.caninteractwith = true
    inst.gem = true
    -- OnGemGiven: gem=true set
    checkforgems(inst)  -- 始终检查，无论动画状态

    if not inst.AnimState:IsCurrentAnimation("idle_full") and not inst.AnimState:IsCurrentAnimation("activate") then
        inst.AnimState:PlayAnimation("activate",false)
        inst.SoundEmitter:PlaySound("grotto/common/archive_switch/on")
    end
end

local function OnGemTaken(inst, picker, loot)
    if loot == nil and picker ~= nil and picker.components.inventory then
        -- Pickable:Pick 未能生成宝石，手动补偿
        loot = SpawnPrefab("opalpreciousgem")
        if loot then
            picker.components.inventory:GiveItem(loot)
        end
    end
    inst.components.trader:Enable()
    inst.components.pickable.caninteractwith = false
    inst.gem = false

    local theWorld = inst:GetTheWorld()
    local archive = theWorld ~= nil and theWorld.components.archivemanager
    if archive then
        archive:SwitchPowerOn(false)
    end
    if not inst.AnimState:IsCurrentAnimation("idle_empty") then
        if not inst.AnimState:IsCurrentAnimation("deactivate") then
            local pos = Vector3(inst.Transform:GetWorldPosition())
            if rawget(_G, 'ShakeAllCameras') then
                ShakeAllCameras(CAMERASHAKE.SIDE, 20/30, .02, .05, pos, 50)
            end

            inst.AnimState:PlayAnimation("deactivate",false)
            inst.SoundEmitter:PlaySound("grotto/common/archive_switch/off")
        end
    end
end

local function ShatterGem(inst)
    inst.SoundEmitter:KillSound("hover_loop")
    inst.AnimState:ClearBloomEffectHandle()
    inst.AnimState:PlayAnimation("shatter")
    inst.AnimState:PushAnimation("idle_empty")
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
end

local function DestroyGem(inst)
    inst.components.trader:Enable()
    inst.components.pickable.caninteractwith = false
    inst:DoTaskInTime(math.random() * 0.5, ShatterGem)
end

local function OnSaveSwitch(inst, data)
    if inst.shadowwartask then
        data.startwar = true
    end
    if inst.gem then
        data.gem = true
    end
end

local function OnLoadPostPassSwitch(inst, newents, data)
    -- OnLoadPostPassSwitch diagnostics removed
    -- DS 中静态布局的 spawnopal 属性不会传递给实体，由 archive_hooks.lua 的 auto-insert 替代
    -- DS 静态布局 properties 在 worldgen 时不会注入到 data 中，此判断无效
    -- 保留日志观察，但不再处理 spawnopal

    -- 从存档数据恢复宝石状态，因为 pickable.caninteractwith 不会自动存档
    if data and data.gem then
        inst.gem = true
        inst.components.pickable.caninteractwith = true
        inst.components.trader:Disable()
        inst.AnimState:PlayAnimation("idle_full", false)
        checkforgems(inst)
    end

    if data and data.startwar then
        startshadowwar(inst)
    end
end

local function getstatusSwitch(inst)
    return inst.components.pickable.caninteractwith and "VALID" or "GEMS"
end

local function switchfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("archive_power_switch.tex")

    inst.AnimState:SetBank("archive_switch")
    inst.AnimState:SetBuild("archive_switch")
    inst.AnimState:PlayAnimation("idle_empty")

    inst:AddTag("gemsocket")
    inst:AddTag("outofreach")
    inst:AddTag("archive_switch")

    inst:AddTag("trader")

    inst.scrapbook_proxy = "archive_switch_base"

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatusSwitch

    inst:AddComponent("pickable")
    inst.components.pickable.caninteractwith = false
    inst.components.pickable.onpickedfn = OnGemTaken

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTestSwitch)
    inst.components.trader.onaccept = OnGemGiven

    inst.DestroyGemFn = DestroyGem

    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("activate") then
            inst.AnimState:PlayAnimation("idle_full")
            -- activate complete, calling checkforgems
            checkforgems(inst)
        end
        if inst.AnimState:IsCurrentAnimation("deactivate") then
            inst.AnimState:PlayAnimation("idle_empty")
        end
    end)

    inst:DoTaskInTime(0,function()
        local x,y,z = inst.Transform:GetWorldPosition()
        local pad = SpawnPrefab("archive_switch_pad")
        pad.Transform:SetPosition(x,y,z)
    end)

    inst.OnSave = OnSaveSwitch
    inst.OnLoadPostPass = OnLoadPostPassSwitch

    return inst
end

local function switchpadfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("archive_switch_ground_small")
    inst.AnimState:SetBuild("archive_switch_ground_small")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst.persists = false

    return inst
end

local SWITCH_MUST_TAGS = {"archive_switch"}
local function switchbasefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("archive_switch_ground")
    inst.AnimState:SetBuild("archive_switch_ground")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)

    -- DS 没有 pointofinterest 组件
    --inst:AddComponent("pointofinterest")
    --inst.components.pointofinterest:SetHeight(220)

    inst.scrapbook_anim = "idle_empty"
    inst.scrapbook_bank = "archive_switch"
    inst.scrapbook_build = "archive_switch"
    inst.scrapbook_specialinfo = "ARCHIVESWITCH"
    inst.scrapbook_speechname = "archive_switch"
	inst.scrapbook_speechstatus = "GEMS"

    inst:DoTaskInTime(0,function()
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, 10, SWITCH_MUST_TAGS)
        if #ents > 0 then
            local target = ents[1]
            local pos = Vector3(target.Transform:GetWorldPosition())
            local angle = inst:GetAngleToPoint(pos.x, 0, pos.z)
            inst.Transform:SetRotation(angle-90)
        end
    end)

    return inst
end

local function CreateDropShadow(parent)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBuild("archive_portal_base")
    inst.AnimState:SetBank("archive_portal_base")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)

    inst.Transform:SetEightFaced()

    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")

    inst.persists = false
    inst.entity:SetParent(parent.entity)

    return inst
end

local function getstatusportal(inst)
    local theWorld = inst:GetTheWorld()
    local archive = theWorld ~= nil and theWorld.components.archivemanager
    return archive and not archive:GetPowerSetting() and "POWEROFF"
end

local function portalfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    inst.Transform:SetEightFaced()

    inst.AnimState:SetBank("archive_portal")
    inst.AnimState:SetBuild("archive_portal")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetFinalOffset(2)

    inst.MiniMapEntity:SetIcon("archive_portal.tex")
    inst:AddTag("groundhole")
    inst:AddTag("blocker")

    CreateDropShadow(inst)

    inst.scrapbook_anim = "scrapbook"
    inst.scrapbook_overridedata = { "archive_portal_base_01", "archive_portal_base", "archive_portal_base_01" }

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatusportal

    return inst
end

local function ambientfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")

    return inst
end

local function worldgenitemfn()
    -- this is just used during world gen and should not stick around.
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst.persists = false

    inst:DoTaskInTime(0,function() inst:Remove() end)
    return inst
end


return Prefab("archive_moon_statue",statuefn, assets),
       Prefab("archive_rune_statue", runefn, assets),
       Prefab("archive_security_desk", securityfn, assets_desk, prefabs_desk),
       Prefab("archive_security_pulse", securitypulsefn, assets_security, prefabs_security),
       Prefab("archive_security_pulse_sfx", securitypulse_sfxfn),
       Prefab("archive_security_waypoint", securitywaypointfn),
       Prefab("archive_switch", switchfn, assets_switch, prefabs_switch),
       Prefab("archive_switch_pad", switchpadfn, assets_switch_pad),
       Prefab("archive_switch_base", switchbasefn, assets_switch_base),
       Prefab("archive_portal", portalfn, assets_portal),
       Prefab("archive_ambient_sfx", ambientfn),
       Prefab("rubble1",worldgenitemfn),
       Prefab("rubble2",worldgenitemfn)
