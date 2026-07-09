-- 光飞虫 AI
-- 移植自 DST，适配 DS 单人生存模式
-- 移除：BrainCommon、formationfollower、homeseeker、childspawner

require "behaviours/panic"
require "behaviours/runaway"
require "behaviours/wander"

local SEE_THREAT_DIST = 3.5
local SEE_THREAT_DIST_ALERT = 8
local STOP_RUN_DIST = 5
local STOP_RUN_DIST_ALERT = 10
local MAX_WANDER_DIST = 10

local LightFlierBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function LightFlierBrain:OnStart()
    local root = PriorityNode({
        -- 着火时恐慌
        WhileNode(function()
            return (self.inst.components.health and self.inst.components.health.takingfiredamage)
                or (self.inst.components.burnable and self.inst.components.burnable:IsBurning())
        end, "OnFire", Panic(self.inst)),

        -- 被吓唬时恐慌
        WhileNode(function()
            return self.inst.components.hauntable and self.inst.components.hauntable.panic
        end, "PanicHaunted", Panic(self.inst)),

        -- 远离可怕生物（警戒距离更大）
        RunAway(self.inst, "scarytoprey", SEE_THREAT_DIST_ALERT, STOP_RUN_DIST_ALERT),

        -- 闲逛
        Wander(self.inst, nil, MAX_WANDER_DIST),
    }, .25)

    self.bt = BT(self.inst, root)
end

return LightFlierBrain
