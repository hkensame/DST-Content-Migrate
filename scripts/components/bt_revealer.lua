local BT_Revealer = Class(function(self, inst)
	self.inst = inst
	self.inst:StartUpdatingComponent(self)
end)

function BT_Revealer:OnUpdate(dt)
	if not TheInput or not mod_burningTimer.enabled then return end
	local obj = TheInput:GetWorldEntityUnderMouse()
	if obj and obj.bt_Reveal then
		obj.bt_Reveal = GetTime() + mod_burningTimer.revealDuration
	end

	return
end

return BT_Revealer
