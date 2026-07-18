local FollowText = require "widgets/followtext"

local function OnRemove(inst)
	if inst.lt_Widget then
		inst.lt_Widget:Kill()
	end
	if inst.lt_Lantern then
		inst.lt_Lantern:RemoveTag("lt_visible")
	end
end

local LanternTimer = Class(function(self, inst)
	local lantern
	-- Actually, for this one we don't need to find the proper lantern to make it functionable
	-- But if we don't find the proper lantern then the text will be shown even if the lantern is in someone's inventory
	-- Also without lantern text will not be right above the lantern but rather on the ground
	lantern = self:FindLantern(inst)
	if not lantern then
		inst:RemoveComponent("lanterntimer")
		return
	end

	inst:ListenForEvent("onremove", OnRemove)

	self.inst = inst
	self.inst:StartUpdatingComponent(self)
end)

function LanternTimer:FindLantern(inst)
	local pos = inst:GetPosition()
	local lightTime, intensityMin, intensityDiff
	for num,obj in pairs(TheSim:FindEntities(pos.x,pos.y,pos.z,0.001,{"turnedon"},{"INLIMBO","lt_visible"})) do
		if obj.prefab == "lantern" then -- There's no other prefab this mod supports yet, so I'll keep it with lantern only
			lightTime, intensityMin, intensityDiff = mod_burningTimer.getLanternStats(obj.prefab)
			if lightTime then
				obj:AddTag("lt_visible")
				self.lantern = obj
				self.lightTime = lightTime
				self.intensityMin = intensityMin
				self.intensityDiff = intensityDiff
				obj.bt_Reveal = mod_burningTimer.lanternReveal
				inst.lt_Lantern = obj
				return obj
			end
		end
	end
	return nil
end

function LanternTimer:MakeTimer()
	local player = GetPlayer()
	if not player or not player.HUD or not player.HUD.overlayroot then return false end
	self.widget = player.HUD.overlayroot:AddChild(FollowText(BODYTEXTFONT,mod_burningTimer.lanternTextSize))
	self.widget:SetOffset(Vector3(9,-110,0))
	self.widget:SetTarget(self.lantern)
	self.inst.lt_Widget = self.widget
	return true
end

function LanternTimer:UpdateTimer(dt)
	if self.lantern and (not self.lantern:HasTag("turnedon") or self.lantern:HasTag("INLIMBO")) then
		-- If two lanterns are stacked above each other and you exit and enter the area then it might happen that two lanterns get mixed with each other (e.g. one widget showing the timer of the other lantern instead of its own)
		-- This code is supposed to fix bugs like these
		self.lantern:RemoveTag("lt_visible")
		self.lantern = nil
	end
	if not self.lantern then
		-- Lantern seems to be gone, look for another lantern close by
		local lantern = self:FindLantern(self.inst)
		if lantern then
			self.lantern = lantern
			if self.widget then
				self.widget:SetTarget(self.lantern)
			end
		else
			self.inst:RemoveComponent("lanterntimer")
			return
		end
	end
	if not mod_burningTimer.enabled or self.lantern.bt_Reveal and self.lantern.bt_Reveal < GetTime() then
		if self.widget and self.widget:IsVisible() then
			if self.lantern.bt_Reveal then
				self.lantern.bt_Reveal = 0.0
			end
			self.widget:Hide()
		end
		return
	end

	if not self.widget then
		self:MakeTimer()
		if not self.widget then return end
	end
	if not self.widget:IsVisible() then self.widget:Show() end
	local lightValue = self.inst.Light and self.inst.Light:GetRadius()
	if not lightValue then return end

	local percent = (lightValue - self.intensityMin)/self.intensityDiff
	local seconds = self.lightTime*percent+0.5
	self.widget.text:SetString(string.format("%d%%\n%d:%02d",math.ceil(percent*100.0),seconds/60,seconds%60))

	return true
end

function LanternTimer:OnUpdate(dt)
	self:UpdateTimer(dt)
end

function LanternTimer:OnRemoveFromEntity()
	OnRemove(self.inst)
end

return LanternTimer
