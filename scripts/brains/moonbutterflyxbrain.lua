--月娥
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/panic"

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 10
local MAX_WANDER_DIST = 20

local function GetHomePos(inst)
    return inst.components.knownlocations:GetLocation("home")
end

local MoonButterflyxBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function MoonButterflyxBrain:OnStart()
    local root =
        PriorityNode(
        {
            WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
            RunAway(self.inst, "monster", RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
            Wander(self.inst, GetHomePos, MAX_WANDER_DIST)
        },1)

    self.bt = BT(self.inst, root)
end

function MoonButterflyxBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
end

return MoonButterflyxBrain