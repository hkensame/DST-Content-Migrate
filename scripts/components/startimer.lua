local FollowText = require "widgets/followtext"
local total_day_time = TUNING.TOTAL_DAY_TIME

local function OnRemove(inst)
	if inst.st_Widget then
		inst.st_Widget:Kill()
	end
end

local StarTimer = Class(function(self, inst)
	-- The Star also emits the light, no need for searching this time
	inst:ListenForEvent("onremove", OnRemove)

	self.inst = inst
	self.pulsetime = inst._pulsetime or 0.0
	self.correction = 0.0
	self.duration = inst.prefab == "stafflight" and (TUNING.YELLOWSTAFF_STAR_DURATION or TUNING.TOTAL_DAY_TIME) or (TUNING.OPALSTAFF_STAR_DURATION or TUNING.TOTAL_DAY_TIME * 2)
	self.inst.bt_Reveal = mod_burningTimer.starReveal
	self.inst:StartUpdatingComponent(self)
end)

function StarTimer:MakeTimer()
	local player = GetPlayer()
	if not player or not player.HUD or not player.HUD.overlayroot then return false end
	self.widget = player.HUD.overlayroot:AddChild(FollowText(BODYTEXTFONT,mod_burningTimer.starTextSize))
	self.widget:SetOffset(Vector3(9,-240,0))
	self.widget:SetTarget(self.inst)
	self.inst.st_Widget = self.widget
	return true
end

function StarTimer:UpdateTimer(dt)
	if not mod_burningTimer.enabled or self.inst.bt_Reveal and self.inst.bt_Reveal < GetTime() then
		if self.widget and self.widget:IsVisible() then
			if self.inst.bt_Reveal then
				self.inst.bt_Reveal = 0.0
			end
			self.widget:Hide()
		end
		return
	end

	if not self.widget then
		self:MakeTimer()
		if not self.widget then return end
	end

	local inst = self.inst
	local newPulseTime = inst._pulsetime or 0.0

	if newPulseTime ~= self.pulsetime then -- Adjust timers whenever the pulsetime changes
		self.pulsetime = newPulseTime
		self.correction = inst:GetTimeAlive()
	end

	local remainingTime = self.duration - newPulseTime - (inst:GetTimeAlive() - self.correction)
	local seconds = remainingTime+0.5
	if seconds < 0.0 then
		if self.widget:IsVisible() then
			self.widget:Hide()
		end
	else
		if not self.widget:IsVisible() then
			self.widget:Show()
		end
		self.widget.text:SetString(string.format("%.1f d\n%d:%02d",seconds/total_day_time,seconds/60,seconds%60))
	end

	return true
end

function StarTimer:OnUpdate(dt)
	self:UpdateTimer(dt)
end

function StarTimer:OnRemoveFromEntity()
	OnRemove(self.inst)
end

return StarTimer
