local BathBomb = Class(function(self, inst)
    self.inst = inst

    self.inst:AddTag("bathbomb")
end)

function BathBomb:OnRemoveFromEntity()
    self.inst:RemoveTag("bathbomb")
end

function BathBomb:CollectUseActions(doer, target, actions)
    --if inst:HasTag("bathbomb") and target:HasTag("bathbombable") then
    if target.components.bathbombable then
		table.insert(actions, ACTIONS.BATHBOMB)
	end
end

return BathBomb
