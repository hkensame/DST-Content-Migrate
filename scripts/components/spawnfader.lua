local function OnFadeDirty(inst)
    local self = inst.components.spawnfader
    if not self.updating then
        self.fadeval = self._fade / 7
        self.updating = true
        self.inst:StartUpdatingComponent(self)
        self:OnUpdate(FRAMES)
    end
end

local function OnDeath(inst)
    inst.components.spawnfader:Cancel()
end

local SpawnFader = Class(function(self, inst)
    self.inst = inst

    self._fade = 0
    self.fadeval = 0
    self.updating = false

        inst:ListenForEvent("fadedirty", OnFadeDirty)
        inst:ListenForEvent("death", OnDeath)
    
end)

function SpawnFader:OnRemoveFromEntity()
        self.inst:RemoveEventCallback("fadedirty", OnFadeDirty)
        self.inst:RemoveEventCallback("death", OnDeath)
end

function SpawnFader:FadeIn()
    self.fadeval = 1
    if not self.updating then
        self.updating = true
        self.inst:StartUpdatingComponent(self)
        self.inst:AddTag("NOCLICK")
        self:OnUpdate(FRAMES)
    end
end

function SpawnFader:Cancel()
    if self.updating then
        self.fadeval = 0
        self:OnUpdate(FRAMES)
    end
end

function SpawnFader:OnUpdate(dt)
    self.fadeval = math.max(0, self.fadeval - dt)
    local k = 1 - self.fadeval * self.fadeval
    self.inst.AnimState:SetMultColour(k, k, k, k)
    if self.fadeval <= 0 then
        self.updating = false
        self.inst:StopUpdatingComponent(self)
    end

        self._fade = math.floor(7 * self.fadeval + .5)
        if not self.updating then
            self.inst:RemoveTag("NOCLICK")
        end
end

return SpawnFader
