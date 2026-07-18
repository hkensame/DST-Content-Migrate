local FollowText = require "widgets/followtext"

local function OnRemove(inst)
	if inst.campfireTimerWidget then
		inst.campfireTimerWidget:Kill()
	end
end

local CampfireTimer = Class(function(self, inst)
	local pos = inst:GetPosition()
	local maxFuel, fuelRate, rainRate, fireLevels
	local target, lightsource
	for num,obj in pairs(TheSim:FindEntities(pos.x,0,pos.z,2.0,{"fire"},{"INLIMBO","_equippable"},mod_burningTimer.validFueltypes)) do
		local targetPos = obj:GetPosition()
		lightsource = TheSim:FindEntities(targetPos.x,targetPos.y,targetPos.z,0.001,{"lightsource"},{"INLIMBO"})[1]
		if lightsource and (obj:HasTag("campfire") or obj:HasTag("shadow_fire") or obj:HasTag("PIGTORCH_fueled")) then
			maxFuel, fuelRate, rainRate, fireLevels = mod_burningTimer.getCampfireStats(obj.prefab)
			if maxFuel then
				target = obj
				break
			end
		end
	end
	if not target then
		inst:RemoveComponent("campfiretimer")
		return
	end

	inst:ListenForEvent("onremove", OnRemove)

	self.inst = inst
	self.campfire = target
	target.bt_Reveal = mod_burningTimer.campfireReveal
	self.prefab = target.prefab
	self.light = lightsource
	self.minLightValue = 0

	self.maxFuel = maxFuel
	self.fuelRate = fuelRate
	self.rainRate = rainRate
	self.fireLevels = fireLevels

	self.inst:StartUpdatingComponent(self)
end)

function CampfireTimer:MakeTimer()
	local player = GetPlayer()
	if not player or not player.HUD or not player.HUD.overlayroot then return false end
	self.widget = player.HUD.overlayroot:AddChild(FollowText(BODYTEXTFONT,mod_burningTimer.campfireTextSize))
	self.widget:SetOffset(Vector3(9,self.inst.prefab == "coldfirefire" and -155 or -90,0))
	self.widget:SetTarget(self.inst)
	self.inst.campfireTimerWidget = self.widget
	return true
end

function CampfireTimer:newLightValue()
	if not self.light or not self.light.Light then return false end
	local lightValue = self.light.Light:GetRadius()
	if lightValue - 0.075 > self.minLightValue then
		self.minLightValue = lightValue
	elseif lightValue >= self.minLightValue then
		return false
	else
		self.minLightValue = lightValue
	end
	return self.minLightValue
end

function CampfireTimer:UpdateTimer(dt)
	if not self.campfire then
		self.inst:RemoveComponent("lanterntimer")
		return
	end
	if not mod_burningTimer.enabled or self.campfire.bt_Reveal and self.campfire.bt_Reveal < GetTime() then
		if self.widget and self.widget:IsVisible() then
			if self.campfire.bt_Reveal then
				self.campfire.bt_Reveal = 0.0
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
	local lightValue = self:newLightValue()
	if not lightValue then return end

	local AnimState = self.inst.AnimState
	local level, highRadius, lowRadius
	for num,tabl in pairs(self.fireLevels) do
		if AnimState:IsCurrentAnimation(tabl.anim) then
			level = num
			highRadius = tabl.radius
			lowRadius = num == 1 and 0 or self.fireLevels[num-1].radius
		end
	end

	if level then
		local percent = (level - 1 + (lightValue - lowRadius) / (highRadius - lowRadius)) / (#self.fireLevels)
		local seconds = self.maxFuel*math.min(percent,1.0)/(self.fuelRate + (TheWorld.state.israining and TheWorld.state.precipitationrate * self.rainRate or 0.0))+0.5
		--self.widget.text:SetString(string.format("%d%%\n%d:%02d",math.min(percent*100.0+0.5,100.0),seconds/60,seconds%60))
		-- math.ceil instead of rounding to make it more on par with Klei's fuel system
		self.widget.text:SetString(string.format("%d%%\n%d:%02d",math.ceil(math.min(percent,1.0)*100.0),seconds/60,seconds%60))
	end

	return true
end

-- dt - How much time passed since last update
function CampfireTimer:OnUpdate(dt)
	self:UpdateTimer(dt)
end

function CampfireTimer:OnRemoveFromEntity()
	OnRemove(self.inst)
end

return CampfireTimer
