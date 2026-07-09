local easing = require("easing")
require("sourcemodifierlist")

local SOURCE_MODIFIER_LIST_KEY = "groggyresistance"
--走得慢组建
local Grogginess_dst = Class(function(self, inst)
    self.inst = inst

    self.resistance = 1
    self.grog_amount = 0
    self.knockouttime = 0
    self.knockoutduration = 0
    self.wearofftime = 0
    self.wearoffduration = TUNING.GROGGINESS_WEAR_OFF_DURATION
    self.decayrate = TUNING.GROGGINESS_DECAY_RATE
    self.speedmod = nil
    self.enablespeedmod = true
    self.isgroggy = false

    self._resistance_sources = SourceModifierList(inst, 0, SourceModifierList.additive)

    --self._disable_task = nil
    --self._disable_finish = nil

    self:SetDefaultTests()
end)

function Grogginess_dst:OnRemoveFromEntity()
    if self.isgroggy then
        self.isgroggy = false
        self.inst:RemoveTag("groggy_dst")
        if self.onwearofffn ~= nil then
            self.onwearofffn(self.inst)
        end
    end
end

function DefaultKnockoutTest(inst)
    local self = inst.components.grogginess_dst
    return self.grog_amount >= self:GetResistance()
        and not (inst.components.health ~= nil and inst.components.health.takingfiredamage)
        and not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning())
end

function DefaultComeToTest(inst)
    local self = inst.components.grogginess_dst
    return self.knockouttime > self.knockoutduration and self.grog_amount < self:GetResistance()
end

function DefaultWhileGroggy(inst)
    --assume grog_amount > 0
    local self = inst.components.grogginess_dst
    local pct = self.grog_amount < self:GetResistance() and self.grog_amount / self:GetResistance() or 1
    self.speedmod = Remap(pct, 1, 0, TUNING.MIN_GROGGY_SPEED_MOD, TUNING.MAX_GROGGY_SPEED_MOD)
    if self.enablespeedmod then
        --inst.components.locomotor:SetExternalSpeedMultiplier(inst, "grogginess", self.speedmod)
        inst.components.locomotor:AddSpeedModifier_Mult("grogginess", -self.speedmod)
    end
end

function DefaultWhileWearingOff(inst)
    --assume wearofftime > 0
    local self = inst.components.grogginess_dst
    local pct = self.wearofftime < self.wearoffduration and easing.inQuad(self.wearofftime / self.wearoffduration, 0, 1, 1) or 1
    self.speedmod = Remap(pct, 0, 1, TUNING.MAX_GROGGY_SPEED_MOD, 1)
    if self.enablespeedmod then
        --inst.components.locomotor:SetExternalSpeedMultiplier(inst, "grogginess", self.speedmod)
        inst.components.locomotor:AddSpeedModifier_Mult("grogginess", -self.speedmod)
    end
end

function DefaultOnWearOff(inst)
    --check required in case we're coming from OnRemoveFromEntity
    if inst.components.grogginess_dst ~= nil then
        inst.components.grogginess_dst.speedmod = nil
    end
    --inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "grogginess")
    inst.components.locomotor:RemoveSpeedModifier_Mult("grogginess")
    if GetPlayer().sg:HasStateTag("running") then
      GetPlayer().sg:GoToState("run_dst")
    end
end

function Grogginess_dst:SetDefaultTests()
    self.knockouttestfn = DefaultKnockoutTest
    self.cometotestfn = DefaultComeToTest
    self.whilegroggyfn = DefaultWhileGroggy
    self.whilewearingofffn = DefaultWhileWearingOff
    self.onwearofffn = DefaultOnWearOff
end

-----------------------------------------------------------------------------------------------------

function Grogginess_dst:SetComeToTest(fn)
    self.cometotestfn = fn
end

function Grogginess_dst:SetKnockOutTest(fn)
    self.knockouttestfn = fn
end

function Grogginess_dst:SetResistance(resist)
    self.resistance = resist
end

function Grogginess_dst:GetResistance()
    return self.resistance + self._resistance_sources:CalculateModifierFromKey(SOURCE_MODIFIER_LIST_KEY)
end

function Grogginess_dst:SetDecayRate(rate)
    self.decayrate = rate
end

function Grogginess_dst:SetWearOffDuration(duration)
    self.wearoffduration = duration
end

function Grogginess_dst:SetEnableSpeedMod(enable)
    if enable then
        if not self.enablespeedmod then
            self.enablespeedmod = true
            if self.speedmod ~= nil then
                --self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "grogginess", self.speedmod)
                self.inst.components.locomotor:AddSpeedModifier_Mult("grogginess", -self.speedmod)
            end
            if self.isgroggy then
                self.inst:AddTag("groggy_dst")
            end
        end
    elseif self.enablespeedmod then
        self.enablespeedmod = false
        --self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "grogginess")
        self.inst.components.locomotor:RemoveSpeedModifier_Mult("grogginess")
        self.inst:RemoveTag("groggy_dst")
    end
end

function Grogginess_dst:IsKnockedOut()
    return self.inst.sg ~= nil and self.inst.sg:HasStateTag("knockout")
end

function Grogginess_dst:IsGroggy()
    return self.grog_amount > 0 and self.enablespeedmod and not self:IsKnockedOut()
end

function Grogginess_dst:HasGrogginess()
    return self.grog_amount > 0 and self.enablespeedmod
end

function Grogginess_dst:GetDebugString()
    return string.format("%s, KO time=%2.2f Groggy: %d/%d%s (%.2f)",
            self:IsKnockedOut() and "KNOCKED OUT" or "AWAKE",
            self.knockouttime,
            self.grog_amount,
            self:GetResistance(),
            self.enablespeedmod and "" or " (disable speed mod)",
			self.grog_amount)
end

function Grogginess_dst:AddGrogginess(grogginess, knockoutduration)
    if grogginess <= 0 then
        return
    end

    self.grog_amount = self.grog_amount + grogginess
    self.wearofftime = 0

    if not self.isgroggy then
        self.isgroggy = true
        if self.enablespeedmod then
            self.inst:AddTag("groggy_dst")
        end
        self.inst:StartUpdatingComponent(self)
        self.knockouttime = 0
    end

    if self.knockouttestfn ~= nil and self.knockouttestfn(self.inst) then
        if not self:IsKnockedOut() then
            self.knockouttime = 0
        end
        self.knockoutduration = math.max(self.knockoutduration, knockoutduration or TUNING.MIN_KNOCKOUT_TIME)
        self:KnockOut()
    end
end

function Grogginess_dst:MaximizeGrogginess()
    local delta = self:GetResistance() - self.grog_amount
    if delta > .1 then
        self:AddGrogginess(delta - .1)
    end
end

function Grogginess_dst:SubtractGrogginess(grogginess)
    if grogginess <= 0 then
        return
    end

    self.grog_amount = math.max(0, self.grog_amount - grogginess)

    if self.isgroggy then
        -- Make sure we're updating so we hit the end-of-grogginess behaviour.
        self.inst:StartUpdatingComponent(self)
    end
end

function Grogginess_dst:ResetGrogginess()
    if self.grog_amount > 0 then
        self:SubtractGrogginess(self.grog_amount)
    end
end

function Grogginess_dst:ExtendKnockout(knockoutduration)
    if self:IsKnockedOut() then
        self.knockoutduration = knockoutduration
        self.knockouttime = 0
        self.grog_amount = math.max(self.grog_amount, self:GetResistance())
    end
end

function Grogginess_dst:KnockOut()
    if self.inst.entity:IsVisible() and not (self.inst.components.health ~= nil and self.inst.components.health:IsDead()) then
        self.inst:PushEvent("knockedout")
    end
end

function Grogginess_dst:ComeTo()
    if self:IsKnockedOut() and not (self.inst.components.health ~= nil and self.inst.components.health:IsDead()) then
        self.grog_amount = self.resistance
        self.inst:PushEvent("cometo")
    end
end

function Grogginess_dst:AddResistanceSource(source, resistance)
    self._resistance_sources:SetModifier(source, resistance, SOURCE_MODIFIER_LIST_KEY)
end

function Grogginess_dst:RemoveResistanceSource(source)
    self._resistance_sources:RemoveModifier(source, SOURCE_MODIFIER_LIST_KEY)
end

function Grogginess_dst:OnUpdate(dt)
    self.grog_amount = math.max(0, self.grog_amount - self.decayrate)

    if self:IsKnockedOut() then
        self.knockouttime = self.knockouttime + dt
        if self.cometotestfn ~= nil and self.cometotestfn(self.inst) then
            self:ComeTo()
        end
    elseif self.grog_amount <= 0 then
        self.isgroggy = false
        self.inst:RemoveTag("groggy_dst")
        self.wearofftime = math.min(self.wearoffduration, self.wearofftime + dt)
        if self.wearofftime >= self.wearoffduration then
            self.inst:StopUpdatingComponent(self)
            self.knockouttime = 0
            self.knockoutduration = 0
            self.wearofftime = 0
            if self.onwearofffn ~= nil then
                self.onwearofffn(self.inst)
            end
        elseif self.whilewearingofffn ~= nil then
            self.whilewearingofffn(self.inst)
        end
    elseif self.whilegroggyfn ~= nil then
        self.whilegroggyfn(self.inst)
    end
end

return Grogginess_dst
