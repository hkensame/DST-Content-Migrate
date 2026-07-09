require "prefabutil"

assets = 
{
    Asset("ANIM", "anim/moonisland/crater_pool.zip"),
}

local prefabs =
{
    "slow_steam_fx1",
    "slow_steam_fx2",
    "slow_steam_fx3",
    "slow_steam_fx4",
    "slow_steam_fx5",
    "moonglass",
    "bluegem",
    "redgem",
}
--温泉
local MINED_GLASS_LOOT_TABLE = {"moonglass", "moonglass", "moonglass", "moonglass", "moonglass"}

local function OnTimerDone(inst, data)
    if data.name == "Cooldown" then
        inst.cooldown = nil
    end
end

local function choose_anim_by_level(remaining, low, med, full)
    return (remaining < (TUNING.HOTSPRING_WORK / 3) and low) or (remaining < (TUNING.HOTSPRING_WORK * 2 / 3) and med) or full
end

local function push_special_idle(inst)
  if inst._glassed then
    inst._glass_sparkle_tick = (inst._glass_sparkle_tick or 0) - 1
    
    if inst._glass_sparkle_tick < 0 then
      local work_remaining = (inst.components.workable ~= nil and inst.components.workable.workleft) or TUNING.HOTSPRING_WORK
      local sparkle_anim = choose_anim_by_level(work_remaining, "glass_low_sparkle1", "glass_med_sparkle"..math.random(2), "glass_full_sparkle"..math.random(3))
      inst.AnimState:PushAnimation(sparkle_anim, false)

      local idle_anim = choose_anim_by_level(work_remaining, "glass_low", "glass_med", "glass_full")
      inst.AnimState:PushAnimation(idle_anim)

      inst._glass_sparkle_tick = math.random(1, 3)
     end
  else
        local steam_anim_index = math.random(5)
        local x, y, z = inst.Transform:GetWorldPosition()
        SpawnPrefab("slow_steam_fx"..steam_anim_index).Transform:SetPosition(x, y, z)
  end
end

local function StartFx(inst, delay)
	if inst._fx_task ~= nil then
		inst._fx_task:Cancel()
	end
    inst._fx_task = inst:DoPeriodicTask(TUNING.HOTSPRING_IDLE.BASE, push_special_idle, delay or (math.random() * TUNING.HOTSPRING_IDLE.DELAY))
end

local function StopFx(inst)
    if inst._fx_task ~= nil then
        inst._fx_task:Cancel()
        inst._fx_task = nil
    end
end

local function Refill(inst, snap) --重新积水
    inst._glassed = false
    inst.empty = false
    inst.Light:Enable(false)

    inst:RemoveTag("moonglass")

	if not snap then
		inst.AnimState:PlayAnimation("refill", false)
		inst.AnimState:PushAnimation("idle", true)
		StartFx(inst, 30*FRAMES)
	else
		inst.AnimState:PlayAnimation("idle", true)
		StartFx(inst)
	end
end

local function RemoveGlass(inst) --移除玻璃
    inst._glassed = false
    inst.empty = true
    inst.Light:Enable(false)

    inst:RemoveTag("moonglass")
    inst.AnimState:PlayAnimation("empty")
    StopFx(inst)
end

local function TurnToGlassed(inst, is_loading) --生成玻璃
    inst._glassed = true
    inst.empty = false

    inst:AddTag("moonglass")
    inst.Light:Enable(true)

    if is_loading then
        local work_remaining = (inst.components.workable ~= nil and inst.components.workable.workleft) or TUNING.HOTSPRING_WORK
        local glass_idle = choose_anim_by_level(work_remaining, "glass_low", "glass_med", "glass_full")
        inst.AnimState:PlayAnimation(glass_idle)
    else
        inst.AnimState:PlayAnimation("glassify")
        inst.AnimState:PushAnimation("glass_full", false)

        inst.components.workable:SetWorkLeft(TUNING.HOTSPRING_WORK)
    end

    inst.components.workable:SetWorkable(true)
end

local function OnGlassedSpringMineFinished(inst, miner)
    inst.components.lootdropper:DropLoot()
    if math.random() < TUNING.HOTSPRING_GEM_DROP_CHANCE then
        inst.components.lootdropper:SpawnLootPrefab((math.random(2) == 1 and "bluegem") or "redgem")
    end
    RemoveGlass(inst)

    inst.components.timer:StartTimer("Cooldown", TUNING.TOTAL_DAY_TIME * 3)
    inst.cooldown = true
end

local function OnGlassSpringMined(inst, miner, mines_remaining, num_mines)
    local glass_idle = choose_anim_by_level(mines_remaining, "glass_low", "glass_med", "glass_full")
    inst.AnimState:PlayAnimation(glass_idle)
end

local function OnSleep(inst)
	StopFx(inst)
end

local function OnWake(inst)
    if inst._fx_task == nil then
        StartFx(inst)
    end
end

local function GetStatus(inst)
	return inst._glassed and "GLASS"
			or inst._bathbombed and "BOMBED"
			or inst.empty and "EMPTY"
			or nil
end

local function OnSave(inst, data)
   data.cooldown = inst.cooldown
   if inst._glassed then
     data.glassed = true
   elseif inst.empty then
     data.empty = true
   end
end

local function OnLoad(inst, data)
  if data then
    inst.cooldown = data.cooldown
  end
  inst:DoTaskInTime(0, function(inst)
    if (GetClock():IsNight() and GetClock():GetMoonPhase() == "full") then
      if data.glassed then
        TurnToGlassed(inst, true)
      elseif data.empty then
        RemoveGlass(inst)
      end
    else
      Refill(inst, true)
    end
  end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("hotspring.tex")

    MakeObstaclePhysics(inst, 1)
    --MakeSmallObstaclePhysics(inst, 1)

    inst.AnimState:SetBuild("crater_pool")
    inst.AnimState:SetBank("crater_pool")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Light:Enable(false)
    inst.Light:SetRadius(TUNING.HOTSPRING_GLOW.RADIUS)
    inst.Light:SetIntensity(TUNING.HOTSPRING_GLOW.INTENSITY)
    inst.Light:SetFalloff(TUNING.HOTSPRING_GLOW.FALLOFF)
    inst.Light:SetColour(0.1, 1.6, 2)

    inst.no_wet_prefix = true
    inst._glassed = false
    inst.empty = false

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(MINED_GLASS_LOOT_TABLE)
    
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetOnFinishCallback(OnGlassedSpringMineFinished)
    inst.components.workable:SetOnWorkCallback(OnGlassSpringMined)
    inst.components.workable:SetWorkLeft(TUNING.HOTSPRING_WORK)
    inst.components.workable:SetWorkable(false)
    inst.components.workable.savestate = true

    inst:AddComponent("timer")	

    inst:AddComponent("heater") --加热
    inst.components.heater.heat = 65

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    inst.OnEntitySleep = OnSleep
    inst.OnEntityWake = OnWake

	inst:ListenForEvent("timerdone", OnTimerDone)
	inst:ListenForEvent("fullmoon", function() TurnToGlassed(inst) end, GetWorld())
	inst:ListenForEvent("daytime", function() Refill(inst) end, GetWorld())

	return inst
end

return Prefab("hotspring", fn, assets, prefabs)
-- MakePlacer 已移至单独的 placer 文件

