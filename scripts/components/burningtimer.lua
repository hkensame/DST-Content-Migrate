local FollowText = require "widgets/followtext"

local SEARCHDISTANCE = 1.25 -- sqrt(2) = 1.4142135623730950488016887242097

local function OnRemove(inst)
	if inst.burningTimerWidget then
		inst.burningTimerWidget:Kill()
	end
	local timer = inst.components.burningtimer
	if timer and inst:HasTag("bt_visible") then
		timer:PassTimer()
	end
--	inst:RemoveTag("bt_visible")
	inst:RemoveTag("bt_waiting")
	if timer and timer.target then
		timer.target:RemoveTag("bt_invalid")
	end
end

--[[
3 different tags:
 "bt_visible" = For fires, to mark that they have a timer rn
 "bt_waiting" = For fires, to mark that they have an invisible timer
 "bt_invalid" = For targets, to mark that they're currently or in general invalid targets
]]

local BurningTimer = Class(function(self, inst)
	-- Step 1: Make out which object is currently burning.
	local target
	local burntime, burntime_rng
	local pos = inst:GetPosition()
	if not inst.parent then -- That would be too easy
		local entities = TheSim:FindEntities(pos.x,pos.y,pos.z,0.001,{"fire"},{"INLIMBO","bt_invalid"}) -- Note: pos.y needs to be included since Red Hounds do not always spawn their fires at y = 0
		for k,v in pairs(entities) do
			v:AddTag("bt_invalid")
			burntime, burntime_rng = mod_burningTimer.getBurntime(v.prefab)
			if burntime and burntime ~= 0.0 then
				target = v
				break
			end
		end
	else
		target = inst.parent
		burntime, burntime_rng = mod_burningTimer.getBurntime(target.prefab)
	end
	if not target then
		inst:RemoveComponent("burningtimer")
		return
	end
	inst:ListenForEvent("onremove", OnRemove)

	-- Step 1.5: Mark the burningtimer in the components
	-- This is actually required to ensure that there's only one counter if two objects start burning exactly at the same moment
	-- How to reproduce: Drop a stack of Rope, Logs, Cut Grass below a Star
	inst.components.burningtimer = self

	-- Step 2: Get all the required data
	self.inst = inst
	self.target = target
	self.prefab = target.prefab
	self.spawntime = inst.spawntime or GetTime() or 0.0
	self.explosive = target:HasTag("explosive")
	self.duration = burntime
	self.rng = burntime_rng
	self.x = pos.x
	self.z = pos.z
	self.incorrect = (target:GetTimeAlive() or 1.0) <= 0.1

	-- Step 3: Are we allowed to show our timer?
	self.inst:AddTag("bt_waiting")
	self:AskForTimer()

	self.inst:StartUpdatingComponent(self)
end)

function BurningTimer:AskForTimer(ignorePass)
--	if self.inst:HasTag("bt_visible") then return true end
	local pos = self.inst:GetPosition()
	local entities = TheSim:FindEntities(pos.x,0,pos.z,SEARCHDISTANCE,{"bt_visible"},{"INLIMBO"})
	for k,v in pairs(entities) do
		local timer = v.components.burningtimer
		if timer and timer:TimeLeft() <= self:TimeLeft() then
			return false
		end
	end
	self:ShowTimer()
	for k,v in pairs(entities) do
		local timer = v.components.burningtimer
		if timer then
			if ignorePass then
				timer:HideTimer()
			else
				timer:PassTimer()
			end
		end
	end
	return true
end

local function sortTimers(a,b)
	return a.components.burningtimer:TimeLeft() < b.components.burningtimer:TimeLeft()
end

function BurningTimer:TimeLeft() return self.duration + self.spawntime - GetTime() end

function BurningTimer:ShowTimer()
	if not self.widget then self:MakeTimer() end
--	if self.widget then self.widget:Show() end
	self.inst:RemoveTag("bt_waiting")
	self.inst:AddTag("bt_visible")
end

function BurningTimer:HideTimer()
	if self.widget then self.widget:Hide() end
	self.inst:RemoveTag("bt_visible")
	self.inst:AddTag("bt_waiting")
end

function BurningTimer:PassTimer()
	self.inst:RemoveTag("bt_waiting")
	self.inst:RemoveTag("bt_visible") -- I can't give/take requests right now
	local pos = self.target and self.target:GetPosition() or Vector3(self.x,0,self.z)
	local entities = TheSim:FindEntities(pos.x,0,pos.z,SEARCHDISTANCE,{"bt_waiting"},{"INLIMBO"})
	table.sort(entities, sortTimers) -- Shortest timers first
	local num = 1
	for k,v in pairs(entities) do
		local timer = v.components.burningtimer
		if timer then
			timer:AskForTimer(false)
--			timer:AskForTimer(true) -- There's no need for this anymore.
		end
		if num >= 10 then break end -- Stop looking for others after taking 10 requests to prevent lag from a stack of burning items
		-- It's quite unlikely that there's a valid target left after 10 requests
		num = num+1
	end
	self:HideTimer()
end

function BurningTimer:MakeTimer()
	local player = GetPlayer()
	if not player or not player.HUD or not player.HUD.overlayroot then return false end
	self.widget = player.HUD.overlayroot:AddChild(FollowText(BODYTEXTFONT,mod_burningTimer.burntimeTextSize))
	self.widget:SetOffset(Vector3(0,-100,0))
	self.widget:SetTarget(self.inst)
	self.inst.burningTimerWidget = self.widget
--[[
	if self.explosive then
		self.widget.text:SetColour(1,0.6,0.5,1)
	end
]]
	return true
end

function BurningTimer:AdjustColour()
	local remaining = self:TimeLeft()
	if remaining > 12.0 then
		self.widget.text:SetColour(1,1,1,1)
	elseif remaining > 0.0 then
		local num = 1.0-remaining/12.0
		self.widget.text:SetColour(
			5/3-num,
			1.5-num*2,
			1.0-num*3/2,
		1)
	elseif self.rng then
		local num = -remaining/self.rng
		self.widget.text:SetColour(
			2/3+num*1/3,
			num*2/3,
			num*2/3,
		1)
	else
		self.widget.text:SetColour(
			2/3,
			0,
			0,
		1)
	end
end

function BurningTimer:UpdateTimer(dt)
	if not self.inst:HasTag("bt_visible") then -- Made for Red Hounds
		if self.inst.GetCurrentPlatform and self.inst:GetCurrentPlatform() then -- but ignore if on boats (DST-only)
			return
		end
		local pos = self.inst:GetPosition()
		if self.x ~= pos.x or self.z ~= pos.z then
			self.x = pos.x
			self.z = pos.z
			if not self:AskForTimer() then
				return
			end
		else
			return
		end
	end
	if not self.widget then
		self:MakeTimer()
		if not self.widget then return end
	end
	if not mod_burningTimer.enabled then
		if self.widget and self.widget:IsVisible() then
			self.widget:Hide()
		end
		return
	end
	if not self.widget:IsVisible() then self.widget:Show() end
	local time_passed = GetTime() - self.spawntime
	local text = string.format("%0.2fs",math.max(self.duration - time_passed,0.0))
	if self.incorrect then
		text = string.format("(%s)",text)
	end
	if self.explosive then
		text = string.format("!!%s!!",text)
	end
	if self.rng then
		text = string.format("%s\n(%0.2fs)",text,math.max(self.rng - math.max(time_passed - self.duration,0.0),0))
	end
	self.widget.text:SetString(text)
	self:AdjustColour()
end

-- dt - How much time passed since last update
function BurningTimer:OnUpdate(dt)
	self:UpdateTimer(dt)
end

function BurningTimer:OnRemoveFromEntity()
	OnRemove(self.inst)
end

return BurningTimer
