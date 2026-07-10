-- DS 适配版 mushgnomebrain.lua
-- 从 DST 源码 scripts/brains/mushgnomebrain.lua 移植
-- 改动：
--   🟡 BrainCommon 替换为本地实现（PanicTrigger / ElectricFencePanicTrigger）
--   🟡 RunAway 参数从 table 改为 predicate function（DS RunAway 不接受 table）

require "behaviours/standandattack"
require "behaviours/standstill"
require "behaviours/wander"
require "behaviours/panic"

local MushGnomeBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

-- 🟡 DS RunAway 不接受 table 参数，改用 predicate function
local function ThreatTest(candidate, inst)
    if candidate == nil or not candidate:IsValid() then
        return false
    end
    if candidate:HasTag("DECOR") or candidate:HasTag("FX") or candidate:HasTag("INLIMBO") then
        return false
    end
    -- 检测战斗目标或被攻击来源
    if candidate.components.combat ~= nil then
        if candidate.components.combat:TargetIs(inst) or inst.components.combat:TargetIs(candidate) then
            return true
        end
    end
    return false
end

-- 🟡 PanicTrigger 本地实现：当着火时恐慌
local function PanicTrigger(inst)
    return WhileNode(
        function()
            return inst.components.burnable ~= nil and inst.components.burnable:IsBurning()
        end,
        "PanicOnFire",
        Panic(inst)
    )
end

function MushGnomeBrain:OnStart()
    local root =
        PriorityNode(
        {
            WhileNode(function() return self.inst.components.combat:HasTarget() and not self.inst.components.combat:InCooldown() end, "Spray Spores",
                StandAndAttack(self.inst, nil, 7)),
            PanicTrigger(self.inst),
            -- 🟡 移除 ElectricFencePanicTrigger（DS 无此机制）
            RunAway(self.inst, function(candidate) return ThreatTest(candidate, self.inst) end, 5, 10),
            Wander(self.inst),
        }, 1)

    self.bt = BT(self.inst, root)
end

return MushGnomeBrain
