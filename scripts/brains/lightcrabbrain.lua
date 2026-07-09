-- 光蟹 AI (小型发光生物，会逃跑)
-- 移植自 DST，适配 DS

require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"

local AVOID_PLAYER_DIST = 5
local AVOID_PLAYER_STOP = 9

local SEE_BAIT_DIST = 5
local FINDFOOD_CANT_TAGS = { "INLIMBO" }

local WANDER_TIMING = {minwaittime = 10, randwaittime = 10}

local LightCrabBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_BAIT_DIST,
        function(item)
            return item.components.bait ~= nil
                and item:HasTag("deployable") == false
                and item:IsOnPassablePoint()
        end,
        nil,
        FINDFOOD_CANT_TAGS)

    if target then
        local act = BufferedAction(inst, target, ACTIONS.EAT)
        return act
    end
end

function LightCrabBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),
        DoAction(self.inst, EatFoodAction),
        Wander(self.inst, nil, nil, WANDER_TIMING),
    }, .25)
    self.bt = BT(self.inst, root)
end

return LightCrabBrain
