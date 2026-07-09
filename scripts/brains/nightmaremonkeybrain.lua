-- 噩梦猴子 AI (nightmaremonkeybrain)
-- 移植自 DST，适配 DS 单机模式
-- 移除：BrainCommon.PanicTrigger / ElectricFencePanicTrigger

require "behaviours/wander"
require "behaviours/chaseandattack"

local MAX_WANDER_DIST = 10

local MAX_CHASE_TIME = 60
local MAX_CHASE_DIST = 40


local NightmareMonkeyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function EquipWeapon(inst, weapon)
    if not weapon.components.equippable:IsEquipped() then
        inst.components.inventory:Equip(weapon)
    end
end

function NightmareMonkeyBrain:OnStart()

    local root = PriorityNode(
    {
        -- BrainCommon 节点移除 (mod braincommon 不含 PanicTrigger/ElectricFencePanicTrigger)
        SequenceNode({
            ActionNode(function() EquipWeapon(self.inst, self.inst.weaponitems.hitter) end, "Equip hitter"),
            ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
        }),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),
    }, .25)
    self.bt = BT(self.inst, root)
end

return NightmareMonkeyBrain
