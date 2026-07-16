-- ==================== DST 组件 API 扩展 ====================
-- 所有 AddComponentPostInit / AddClassPostConstruct 汇总
-- 通过 modimport("scripts/dst_component_api.lua") 从 modmain.lua 加载

--防止掉落物到海上
local function invitemfn(self)
  if self.inst and self.inst.Physics then
   self.inst.Physics:CollidesWith(SJ and COLLISION.WORLD or 192)
  end
end
AddComponentPostInit("inventoryitem", invitemfn)

AddComponentPostInit("locomotor", function(self)
  function self:IsAquatic()
    return self.pathcaps ~= nil and self.pathcaps.allowocean == true and self.pathcaps.ignoreLand == true
  end
end)

--启迪之冠攻击特效
AddComponentPostInit("follower", function(self)
  self.keepleaderonattacked = nil
  function self:KeepLeaderOnAttacked()
    self.keepleaderonattacked = true
    self.inst:RemoveEventCallback("attacked", onattacked)
  end
end)

--蚁狮
AddComponentPostInit("inventoryitem", function(self)
  function self:SetSinks(should_sink)
    self.sinks = should_sink
    if self.is_landed then
        self:TryToSink()
    end
  end
end)

--蜂后，联机龙蝇里有这api
AddComponentPostInit("combat", function(self)
  self.lastwasattackedtime = 0
  function self:HasTarget()
    return self.target ~= nil
  end
  function self:GetLastAttackedTime()
    return self.lastwasattackedtime
  end
  function self:CancelAttack()
    self.laststartattacktime = 0
  end
  local _GetAttacked = self.GetAttacked
  function self:GetAttacked(attacker, damage, weapon, stimuli)
  self.lastwasattackedtime = GetTime()
    return _GetAttacked(self, attacker, damage, weapon, stimuli)
  end
  --蜂后
  function self:SetPlayerStunlock(stunlock)
    self.playerstunlock = stunlock
  end
  --天体英雄
  function self:RestartCooldown()
    self.laststartattacktime = GetTime()
  end
end)

--邪天翁
AddComponentPostInit("health", function(self)
  function self:GetMaxWithPenalty()
    return self.maxhealth - self.maxhealth * self.penalty
  end
  function self:SetCurrentHealth(amount)
    self.currenthealth = amount
  end
  function self:DoDelta(amount, overtime, cause, ignore_invincible, skipredirect)
    if self.redirect and not skipredirect then
      self.redirect(self.inst, amount, overtime, cause, ignore_invincible)
      return
    end
    if not ignore_invincible and (self.invincible or self.inst.is_teleporting == true) then
      return
    end
    if amount < 0 then
      amount = amount - (amount * self.absorb)
    end
    local old_percent = self:GetPercent()
    self:SetVal(self.currenthealth + amount, cause)
    local new_percent = self:GetPercent()
    self.inst:PushEvent("healthdelta", {oldpercent = old_percent, newpercent = self:GetPercent(), overtime=overtime, cause=cause, amount = amount })
    if METRICS_ENABLED and self.inst == GetPlayer() and cause and cause ~= "debug_key" then
      if amount > 0 then
        ProfileStatsAdd("healby_" .. cause, math.floor(amount))
        FightStat_Heal(math.floor(amount))
      end
    end
    if self.ondelta then
      self.ondelta(self.inst, old_percent, self:GetPercent())
    end
  end
end)

AddComponentPostInit("pickable", function(self)
  function self:ChangeProduct(newProduct)
    self.product = newProduct
  end

  -- DST 兼容: remove_when_picked 支持（DS 原生 Pick 方法没有此检查）
  local _Pick = self.Pick
  function self:Pick(picker)
    local result = _Pick(self, picker)
    if self.remove_when_picked and self.inst and self.inst:IsValid() then
      self.inst:Remove()
    end
    return result
  end
end)

AddComponentPostInit("workable", function(self)
  function self:Destroy(destroyer)
    if self:CanBeWorked() then
      self:WorkedBy(destroyer, self.workleft)
    end
  end
  function self:CanBeWorked()
    return self.workable and self.workleft > 0
  end
  function self:WorkedBy(worker, numworks)
    local tool = worker.components.inventory ~= nil and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    local recoil
    recoil, numworks = self:ShouldRecoil(worker, tool, numworks)
    self:WorkedBy_Internal(worker, numworks)
  end
  function self:WorkedBy_Internal(worker, numworks)
    numworks = numworks or 1
    if self.workmultiplierfn ~= nil then
      numworks = numworks * (self.workmultiplierfn(self.inst, worker, numworks) or 1)
    end
    if numworks > 0 then
      if self.workleft <= 1 then
        self.workleft = 0
      else
        self.workleft = self.workleft - numworks
        if self.workleft < 0.01 then
          self.workleft = 0
        end
      end
    end
    self.lastworktime = GetTime()
    worker:PushEvent("working", { target = self.inst })
    self.inst:PushEvent("worked", { worker = worker, workleft = self.workleft })
    if self.onwork ~= nil then
      self.onwork(self.inst, worker, self.workleft, numworks)
    end
    if self.workleft <= 0 then
      local isplant = self.inst:HasTag("plant") and not self.inst:HasTag("burnt") and not (self.inst.components.diseaseable ~= nil and self.inst.components.diseaseable:IsDiseased())
      local pos = isplant and self.inst:GetPosition() or nil
      if self.onfinish ~= nil then
        local ok, err = pcall(self.onfinish, self.inst, worker)
        if not ok then
          print("[WORKABLE] WARNING: onfinish failed - " .. tostring(err))
        end
      end
      self.inst:PushEvent("workfinished", { worker = worker })
      worker:PushEvent("finishedwork", { target = self.inst, action = self.action })
      if isplant then
        GetWorld():PushEvent("plantkilled", { doer = worker, pos = pos, workaction = self.action })
      end
    end
  end
  function self:SetShouldRecoilFn(fn)
    self.shouldrecoilfn = fn
  end
  function self:ShouldRecoil(worker, tool, numworks)
    if self.shouldrecoilfn ~= nil then
      local recoil, remainingworks = self.shouldrecoilfn(self.inst, worker, tool, numworks)
      if recoil ~= nil then
        if recoil then return true, remainingworks or 0 end
        return false, remainingworks or numworks
      end
    end
    if self.tough and not (worker ~= nil and worker:HasTag("toughworker")) and not (tool ~= nil and tool.components.tool ~= nil and tool.components.tool:CanDoToughWork()) then
      return true, 0
    end
    return false, numworks
  end
end)

AddComponentPostInit("trader", function(self)
  self.abletoaccepttest = nil
  function self:SetAbleToAcceptTest(fn)
    self.abletoaccepttest = fn
  end
  function self:AbleToAccept(item, giver)
    if not self.enabled or item == nil then
      return false
    elseif self.abletoaccepttest ~= nil then
      return self.abletoaccepttest(self.inst, item, giver)
    elseif self.inst.components.health ~= nil and self.inst.components.health:IsDead() then
      return false, "DEAD"
    elseif self.inst.components.sleeper ~= nil and self.inst.components.sleeper:IsAsleep() then
      return false, "SLEEPING"
    elseif self.inst.sg ~= nil and self.inst.sg:HasStateTag("busy") then
      return false, "BUSY"
    end
    return true
  end
end)

AddComponentPostInit("heater", function(self)
  self.exothermic = true
  self.endothermic = false
  function self:SetThermics(exo, endo)
    self.exothermic = exo
    self.endothermic = endo
  end
end)

--联机龙蝇
AddClassPostConstruct("components/freezable", function(self, inst)
  local function OnAttacked(inst, data)
    local freezable = inst.components.freezable
    if freezable and freezable:IsFrozen() then
      freezable.damagetotal = freezable.damagetotal + math.abs(data.damage)
      if freezable.damagetotal >= freezable.damagetobreak then
        freezable:Unfreeze()
      end
    end
  end
  self.damagetotal = 0
  self.damagetobreak = 0
  self.inst:ListenForEvent("attacked", OnAttacked)
end)

AddComponentPostInit("freezable", function(self)
  local states = { FROZEN = "FROZEN", THAWING = "THAWING", NORMAL = "NORMAL" }
  local function WearOff(inst)
    local freezable = inst.components.freezable
    if freezable then
      if freezable.state == states.FROZEN then freezable:Thaw()
      elseif freezable.state == states.THAWING then freezable:Unfreeze()
      elseif freezable.coldness > 0 then
        freezable.coldness = math.max(0, freezable.coldness - 1)
        if freezable.coldness > 0 then freezable:StartWearingOff() end
      end
      freezable:UpdateTint()
    end
  end
  function self:StartWearingOff(wearofftime)
    if self.wearofftask ~= nil then self.wearofftask:Cancel() end
    self.wearofftask = self.inst:DoTaskInTime(self:ResolveWearOffTime(wearofftime or self.wearofftime), WearOff, self)
  end
  function self:UpdateTint()
    if self.inst.AnimState then
      local defaultColor = Vector3(0,0,0)
      local frozenColor = Vector3(82/255,115/255,124/255)
      local r,g,b = defaultColor.x,defaultColor.y,defaultColor.z
      if self:IsFrozen() then r,g,b = frozenColor.x,frozenColor.y,frozenColor.z
      else
        local resistance = self:ResolveResistance()
        if self.coldness >= resistance then r,g,b = frozenColor.x,frozenColor.y,frozenColor.z
        elseif self.coldness <= 0 then r,g,b = defaultColor.x,defaultColor.y,defaultColor.z
        else
          local percent = self.coldness / self.resistance
          r = defaultColor.x+percent*frozenColor.x; g = defaultColor.y+percent*frozenColor.y; b = defaultColor.z+percent*frozenColor.z
        end
      end
      if not self.inst.components.highlight then self.inst:AddComponent("highlight") end
      self.inst.components.highlight:SetAddColour(Vector3(r,g,b))
    end
  end
  local function DecayExtraResist(inst, self)
    local new_resist = math.max(0, self.extraresist - .1)
    local current_resist = self.coldness - self.resistance
    if new_resist >= current_resist then self:SetExtraResist(new_resist)
    elseif current_resist < self.extraresist then self:SetExtraResist(current_resist) end
  end
  function self:SetExtraResist(resist)
    self.extraresist = math.clamp(resist, 0, self.resistance * 2.5)
    if self.extraresist > 0 then
      if self.diminishingtask == nil then self.diminishingtask = self.inst:DoPeriodicTask(30, DecayExtraResist, nil, self) end
    elseif self.diminishingtask ~= nil then self.diminishingtask:Cancel(); self.diminishingtask = nil end
  end
  function self:ResolveResistance()
    return self.extraresist ~= nil and math.min(self.resistance * 2.5, self.resistance + self.extraresist) or self.resistance
  end
  function self:ResolveWearOffTime(t)
    return self.extraresist ~= nil and t * math.clamp(1 - self.extraresist / (self.resistance * 2.5), .1, 1) or t
  end
  function self:IsThawing() return self.state == states.THAWING end
  function self:Freeze(freezetime)
    if self.inst.entity:IsVisible() and not (self.inst.components.health and self.inst.components.health:IsDead()) then
      if self.diminishingtask ~= nil then self.diminishingtask:Cancel(); self.diminishingtask = self.inst:DoPeriodicTask(30, DecayExtraResist, nil, self) end
      local prevState = self.state
      self.state = states.FROZEN
      self:StartWearingOff(freezetime)
      self:UpdateTint()
      if self.inst.brain then self.inst.brain:Stop() end
      if self.inst.components.combat then self.inst.components.combat:SetTarget(nil) end
      if self.inst.components.locomotor then self.inst.components.locomotor:Stop() end
      if self.state ~= prevState then
        self.inst:PushEvent("freeze")
        if self.diminishingreturns then self:SetExtraResist((self.extraresist or 0) + self.resistance * .25) end
      end
    end
  end
  function self:Unfreeze()
    if self:IsFrozen() then
      self.state = states.NORMAL; self.coldness = 0; self.damagetotal = 0
      self:SpawnShatterFX(); self:UpdateTint()
      if not self.inst.components.health or not self.inst.components.health:IsDead() then
        if self.inst.brain then self.inst.brain:Start() end
        self.inst:PushEvent("unfreeze")
      end
    end
  end
  function self:Reset() self.state = states.NORMAL; self.coldness = 0; self:UpdateTint() end
  function self:OnSave()
    return self.extraresist ~= nil and self.extraresist > 0 and { extraresist = math.floor(self.extraresist * 10) * .1 } or nil
  end
  function self:OnLoad(data)
    if data.extraresist ~= nil then self:SetExtraResist(data.extraresist) end
  end
end)

--联机龙蝇
AddComponentPostInit("moisture", function(self)
  local _CheckForShelter = self.CheckForShelter
  function self:CheckForShelter()
    self.shelter_waterproofness = TUNING.WATERPROOFNESS_SMALLMED
    local x,y,z = self.inst.Transform:GetWorldPosition()
    local fog = GetSeasonManager().IsFoggy and GetSeasonManager():IsFoggy()
    local ents = {}
    if not fog then ents = TheSim:FindEntities(x,y,z, 3, {"shelter"}, {"FX", "NOCLICK", "DECOR", "INLIMBO", "stump", "burnt"}) end
    if #ents > 0 then
      for _, v in ipairs(ents) do
        if v:HasTag("dryshelter") then self.shelter_waterproofness = TUNING.WATERPROOFNESS_ABSOLUTE; break end
      end
      if self.new_sheltered and self.prev_sheltered then
        self.sheltered = true; self.targetshade = SHELTERED_SHADE; self.inst:PushEvent("sheltered")
        if (not self.lastannouncetime or (GetTime() - self.lastannouncetime > TUNING.TOTAL_DAY_TIME)) and GetSeasonManager() and (GetSeasonManager():IsRaining() or GetSeasonManager():GetCurrentTemperature() >= TUNING.OVERHEAT_TEMP - 5) then
          if self.inst.components.talker then self.inst.components.talker:Say(GetString(self.inst.prefab, "ANNOUNCE_SHELTER")) end
          self.lastannouncetime = GetTime()
        end
      end
      if self.new_sheltered then self.prev_sheltered = true end
      self.new_sheltered = true
    elseif (self.inst:HasTag("under_leaf_canopy") or self.inst:HasTag("under_shadowcaster")) and not fog then
      local ents = TheSim:FindEntities(x,y,z, 3, {"exposure"})
      if #ents <= 0 then self.sheltered = true; self.targetshade = SHELTERED_SHADE; self.inst:PushEvent("sheltered") end
    elseif TheCamera.interior then
      self.sheltered = true; self.targetshade = SHELTERED_SHADE; self.inst:PushEvent("sheltered")
    else
      self.sheltered = false; self.targetshade = EXPOSED_SHADE; self.prev_sheltered = false; self.new_sheltered = false; self.inst:PushEvent("unsheltered")
    end
    return _CheckForShelter(self)
  end
  function self:GetDebugString()
    local easing = require("easing")
    local temp = self.inst.components.temperature
    local sm = GetWorld().components.seasonmanager
    local rate = self.baseDryingRate
    return string.format("\n\t\tMoisture Rate: %2.2f -- %2.2f\n\t\tDrying Rate: %2.2f\n\t\tMoisture: %2.2f\n\t\tCombinedRate: %2.2f\n\t\t %2.2f, %2.2f, %2.2f \n\t\tSheltered: %s shade: %f", self:GetMoistureRate(), GetWorld().components.seasonmanager.precip_rate, self:GetDryingRate(), self:GetMoisture(), self:GetMoistureRate()-self:GetDryingRate(), easing.linear(sm:GetCurrentTemperature(), self.minDryingRate, self.maxDryingRate, self.optimalDryingTemp), easing.inExpo(temp~=nil and temp:GetCurrent() or 0, self.minPlayerTempDrying, self.maxPlayerTempDrying, self.optimalDryingTemp), easing.inExpo(self:GetMoisture(), 0, 1, self.moistureclamp.max), tostring(self.sheltered), self.shade)
  end
  function self:AnnounceMoisture(oldSegs, newSegs)
    if self.inst.components.talker then
      if oldSegs < 1 and newSegs >= 1 then self.inst.components.talker:Say(GetString(self.inst.prefab, "ANNOUNCE_DAMP"))
      elseif oldSegs < 2 and newSegs >= 2 then self.inst.components.talker:Say(GetString(self.inst.prefab, "ANNOUNCE_WET"))
      elseif oldSegs < 3 and newSegs >= 3 then self.inst.components.talker:Say(GetString(self.inst.prefab, "ANNOUNCE_WETTER"))
      elseif oldSegs < 4 and newSegs >= 4 then self.inst.components.talker:Say(GetString(self.inst.prefab, "ANNOUNCE_SOAKED")) end
    end
  end
end)

--联机龙蝇
AddClassPostConstruct("components/sleeper", function(self, inst)
  local function onattacked(inst, data)
    if inst.components.sleeper ~= nil then inst.components.sleeper:WakeUp() end
  end
  local function onnewcombattarget(inst, data)
    if data.target ~= nil and inst.components.sleeper ~= nil then inst.components.sleeper:StartTesting() end
  end
  self.inst:ListenForEvent("onignite", onattacked)
  self.inst:ListenForEvent("attacked", onattacked)
  self.inst:ListenForEvent("newcombattarget", onnewcombattarget)
  self.inst:ListenForEvent("bigfootstep", onattacked, GetWorld())
end)

AddComponentPostInit("sleeper", function(self)
  local function OnGoToSleep(inst, sleeptime)
    if inst.components.sleeper ~= nil then inst.components.sleeper:GoToSleep(sleeptime) end
  end
  function self:AddSleepiness(sleepiness, sleeptime, source)
    self.sleepiness = self.sleepiness + sleepiness
    if self.sleepiness > self.resistance or self.isasleep then self:GoToSleep(sleeptime)
    elseif self.sleepiness == self.resistance then self.inst:DoTaskInTime(self.resistance, OnGoToSleep, sleeptime)
    else if not self.wearofftask then self.wearofftask = self.inst:DoPeriodicTask(self.wearofftime, WearOff) end end
  end
  local function DecayExtraResist(inst, self) self:SetExtraResist(self.extraresist - .1) end
  function self:SetExtraResist(resist)
    self.extraresist = math.clamp(resist, 0, self.wearofftime)
    if self.extraresist > 0 then
      if self.diminishingtask == nil then self.diminishingtask = self.inst:DoPeriodicTask(30, DecayExtraResist, nil, self) end
    elseif self.diminishingtask ~= nil then self.diminishingtask:Cancel(); self.diminishingtask = nil end
  end
  function self:GetSleepTimeMultiplier() return self.extraresist ~= nil and math.max(.2, 1 - self.extraresist * .1) or 1 end
  function self:GoToSleep(sleeptime)
    if self.inst.entity:IsVisible() and not (self.inst.components.health and self.inst.components.health:IsDead()) then
      local wasasleep = self.isasleep
      self.lasttransitiontime = GetTime(); self.isasleep = true
      if self.wearofftask then self.wearofftask:Cancel(); self.wearofftask = nil end
      if self.inst.brain then self.inst.brain:Stop() end
      if self.inst.components.combat then self.inst.components.combat:SetTarget(nil) end
      if self.inst.components.locomotor then self.inst.components.locomotor:Stop() end
      if not wasasleep then
        self.inst:PushEvent("gotosleep")
        if self.diminishingreturns then self:SetExtraResist((self.extraresist or 0) + 1) end
      end
      self:SetWakeTest(self.waketestfn, sleeptime ~= nil and sleeptime * self:GetSleepTimeMultiplier() or sleeptime)
    end
  end
  function self:OnSave() return self.extraresist ~= nil and self.extraresist > 0 and { extraresist = math.floor(self.extraresist * 10) * .1 } or nil end
  function self:OnLoad(data) if data.extraresist ~= nil then self:SetExtraResist(data.extraresist) end end
end)

AddComponentPostInit("timer", function(self)
  function self:ResumeTimer(name)
    if not self:TimerExists(name) then return end
    if not self:IsPaused(name) then return end
    if self:IsPaused(name) then
      self.timers[name].paused = false
      self.timers[name].timer = self.inst:DoTaskInTime(self.timers[name].timeleft, self.timers[name].timerfn)
      self.timers[name].end_time = GetTime() + self.timers[name].timeleft
    end
  end
  function self:StopTimer(name)
    if not self:TimerExists(name) then return end
    if self.timers[name].timer ~= nil then self.timers[name].timer:Cancel(); self.timers[name].timer = nil end
    self.timers[name] = nil
  end
end)

--克劳斯
AddComponentPostInit("burnable", function(self)
  function self:ExtendBurning()
    if self.task ~= nil then self.task:Cancel() end
    self.task = self.burntime ~= nil and self.inst:DoTaskInTime(self.burntime, DoneBurning, self) or nil
  end
  function self:SetFXOffset(x, y, z)
    self.fxoffset = x ~= nil and (y ~= nil and z ~= nil and Vector3(x, y, z) or Vector3(x:Get())) or nil
  end
end)

--克劳斯，天体英雄
AddComponentPostInit("lootdropper", function(self)
  function self:FlingItem(loot, pt)
    if loot ~= nil then
      if pt == nil then pt = self.inst:GetPosition() end
      loot.Transform:SetPosition(pt:Get())
      local min_speed = self.min_speed or 0; local max_speed = self.max_speed or 2
      local y_speed = self.y_speed or 8; local y_speed_variance = self.y_speed_variance or 4
      if loot.Physics ~= nil then
        local angle = self.flingtargetpos ~= nil and GetRandomWithVariance(self.inst:GetAngleToPoint(self.flingtargetpos), self.flingtargetvariance or 0) * DEGREES or math.random() * 2 * PI
        local speed = min_speed + math.random() * (max_speed - min_speed)
        if loot:IsAsleep() then
          local radius = .5 * speed + (self.inst.Physics ~= nil and loot:GetPhysicsRadius(1) + self.inst:GetPhysicsRadius(1) or 0)
          loot.Transform:SetPosition(pt.x + math.cos(angle) * radius, 0, pt.z - math.sin(angle) * radius)
        else
          local sinangle = math.sin(angle); local cosangle = math.cos(angle)
          loot.Physics:SetVel(speed * cosangle, GetRandomWithVariance(y_speed, y_speed_variance), speed * -sinangle)
          if self.inst ~= nil and self.inst.Physics ~= nil then
            local radius = loot:GetPhysicsRadius(1) + self.inst:GetPhysicsRadius(1)
            if not self.spawn_loot_inside_prefab then loot.Transform:SetPosition(pt.x + cosangle * radius, pt.y, pt.z - sinangle * radius)
            else radius = radius * math.random(); loot.Transform:SetPosition(pt.x + cosangle * radius, pt.y + 0.5, pt.z - sinangle * radius) end
          end
        end
      end
    end
  end
  function self:SpawnLootPrefab(lootprefab, pt)
    if lootprefab ~= nil then
      local loot = SpawnPrefab(lootprefab)
      if not SaveGameIndex:IsModeShipwrecked() then
        if loot ~= nil then
          self:FlingItem(loot, pt)
          loot:PushEvent("on_loot_dropped", {dropper = self.inst})
          self.inst:PushEvent("loot_prefab_spawned", {loot = loot})
          return loot
        end
      else return self:DropLootPrefab(loot, pt) end
    end
  end
  function self:SetLootSetupFn(fn) self.lootsetupfn = fn end
  local old_GenerateLoot = self.GenerateLoot
  function self:GenerateLoot()
    local loots = {}
    if self.lootsetupfn then self.lootsetupfn(self) end
    return old_GenerateLoot(self)
  end
end)

--蜂王帽回san效果
AddComponentPostInit("sanity", function(self)
  self.neg_aura_absorb = 0
  function self:Recalc(dt)
    local total_dapperness = self.dapperness or 0
    local empty_slots = 3
    for k,v in pairs(self.inst.components.inventory.equipslots) do
      if v.components.equippable then
        empty_slots = empty_slots - 1
        total_dapperness = total_dapperness + v.components.equippable:GetDapperness(self.inst)
      end
    end
    total_dapperness = total_dapperness * self.dapperness_mult
    local moisture_delta = self:GetMoistureDelta()
    local dapper_delta = total_dapperness * TUNING.SANITY_DAPPERNESS
    local light_delta = 0
    local lightval = self.inst.LightWatcher:GetLightValue()
    local day = GetClock():IsDay() and not GetWorld():IsCave()
    if day then light_delta = TUNING.SANITY_DAY_GAIN
    else
      local highval = TUNING.SANITY_HIGH_LIGHT; local lowval = TUNING.SANITY_LOW_LIGHT
      if lightval > highval then light_delta = TUNING.SANITY_NIGHT_LIGHT
      elseif lightval < lowval then light_delta = TUNING.SANITY_NIGHT_DARK
      else light_delta = TUNING.SANITY_NIGHT_MID end
      light_delta = light_delta * self.night_drain_mult
    end
    local aura_delta = 0
    local x,y,z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, TUNING.SANITY_EFFECT_RANGE, nil, {"FX", "NOCLICK", "DECOR","INLIMBO"})
    for k,v in pairs(ents) do
      if v.components.sanityaura and v ~= self.inst then
        local distsq = self.inst:GetDistanceSqToInst(v)
        local aura_val = v.components.sanityaura:GetAura(self.inst) / math.max(1, distsq)
        aura_val = (aura_val < 0 and (self.neg_aura_absorb > 0 and self.neg_aura_absorb * -aura_val or aura_val) * self.neg_aura_mult or aura_val)
        aura_delta = aura_delta + aura_val
      end
    end
    local drivabledelta = 0
    if self.inst.components.driver then
      local vehicle = self.inst.components.driver.vehicle
      if vehicle then
        if vehicle.components.drivable then drivabledelta = vehicle.components.drivable:GetSanityDrain()
        elseif vehicle.components.searchable then drivabledelta = vehicle.components.searchable:GetSanityDrain() end
      end
    end
    local poisondelta = 0
    if self.inst.components.poisonable and self.inst.components.poisonable:IsPoisoned() then
      poisondelta = -self.inst.components.poisonable.damage_per_interval * TUNING.POISON_SANITY_SCALE
    end
    local mount = self.inst.components.rider and self.inst.components.rider:IsRiding() and self.inst.components.rider:GetMount() or nil
    if mount and mount.components.sanityaura then
      local aura_val = mount.components.sanityaura:GetAura(self.inst)
      aura_delta = aura_delta + aura_val
    end
    self.rate = (dapper_delta + moisture_delta + light_delta + aura_delta + drivabledelta + poisondelta)
    if self.custom_rate_fn then self.rate = self.rate + self.custom_rate_fn(self.inst) end
    self.rate = self.rate * self:GetRateModifier()
    self:DoDelta(self.rate * dt, true)
  end
end)

AddComponentPostInit("armor", function(self)
  function self:Repair(amount)
    self:SetCondition(self.condition + amount)
    if self.onrepair ~= nil then self.onrepair(self.inst, amount) end
  end
end)

AddComponentPostInit("repairable", function(self)
  self.noannounce = nil; self.checkmaterialfn = nil
  function self:CollectSceneActions(doer, actions, right)
    if right then
      local equipedbody = doer.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
      if equipedbody and equipedbody:HasTag("heavy") then table.insert(actions, ACTIONS.REPAIR2) end
    end
  end
  local old_Repair = self.Repair
  function self:Repair(doer, repair_item)
    if self.checkmaterialfn ~= nil then
      local success, reason = self.checkmaterialfn(self.inst, repair_item)
      if not success then return false, reason end
    end
    return old_Repair(self, doer, repair_item)
  end
  local old_StartNight = self.StartNight
  function self:StartNight(instant, fromnightvision)
    if self:GetMoonPhase() == "new" and not GetWorld():IsCave() then self.inst:PushEvent("newmoon") end
    return old_StartNight(self, instant, fromnightvision)
  end
end)

--食物buff，收获三个糖果
AddComponentPostInit("stewer", function(self)
  function self:Harvest(harvester)
    if self.done then
      if self.onharvest then self.onharvest(self.inst) end
      self.done = nil
      if self.product then
        if harvester and harvester.components.inventory then
          local loot = nil
          if self.product ~= "spoiledfood" then
            loot = SpawnPrefab(self.product)
            if loot and loot.components.perishable then
              loot.components.perishable:SetPercent(self.product_spoilage)
              loot.components.perishable:LongUpdate(GetTime() - self.targettime)
              loot.components.perishable:StartPerishing()
            end
          else loot = SpawnPrefab("spoiled_food") end
          if loot then
            loot.targetMoisture = 0
            loot:DoTaskInTime(2*FRAMES, function()
              if loot.components.moisturelistener then
                loot.components.moisturelistener.moisture = loot.targetMoisture; loot.targetMoisture = nil
                loot.components.moisturelistener:DoUpdate()
              end
            end)
            if self.product == "jellybean" then
              for i = 1,3 do local addt_prod = SpawnPrefab("jellybean"); harvester.components.inventory:GiveItem(addt_prod, nil, TheInput:GetScreenPosition()) end
            else harvester.components.inventory:GiveItem(loot, nil, Vector3(TheSim:GetScreenPos(self.inst.Transform:GetWorldPosition()))) end
          end
        end
        self.product = nil; self.spoiltargettime = nil
        if self.spoiltask then self.spoiltask:Cancel(); self.spoiltask = nil end
      end
      if self.inst.components.container and not self.inst:HasTag("flooded") then self.inst.components.container.canbeopened = true end
      return true
    end
  end
end)

--铲地皮得地皮
AddComponentPostInit("terraformer", function(self)
  local function SpawnTurf(turf, pt)
    if turf then
      local loot = GLOBAL.SpawnPrefab(turf)
      loot.Transform:SetPosition(pt.x, pt.y, pt.z)
      if loot.Physics then
        local angle = math.random()*2*GLOBAL.PI
        loot.Physics:SetVel(2*math.cos(angle), 10, 2*math.sin(angle))
      end
    end
  end
  local _Terraform = self.Terraform
  self.Terraform = function(self, pt)
    if self:CanTerraformPoint(pt) == false then return false end
    local ground = GLOBAL.GetWorld()
    local original_tile_type = ground.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
    local ret = _Terraform(self, pt)
    if ret == true then
      local turf_prefab = GLOBAL.DST_TURFS[original_tile_type]
      if turf_prefab ~= nil then SpawnTurf(turf_prefab, pt) end
      return true
    end
    return false
  end
end)
