require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/wander"
require "behaviours/chaseandattack"

local MAX_CHASE_TIME = 60
local MAX_CHASE_DIST = 40

local BatBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local function GoHomeAction(inst)
    if inst.components.homeseeker and 
       inst.components.homeseeker.home and 
       inst.components.homeseeker.home:IsValid() and 
       inst.components.homeseeker.home.components.childspawner and not 
       inst.components.teamattacker.inteam then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

local function EatFoodAction(inst)
    local target = nil
    if inst.sg:HasStateTag("busy") then
        return
    end
    if inst.components.inventory and inst.components.eater then
        target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
        if target then return BufferedAction(inst,target,ACTIONS.EAT) end
    end
    if not target then
        target = FindEntity(inst, 30, function(item)
            if item:GetTimeAlive() < 8 then return false end
            if not item:IsOnValidGround() then
                return false
            end
            return inst.components.eater:CanEat(item)
        end)
    end
    if target then
        return BufferedAction(inst,target,ACTIONS.PICKUP)
    end
end

function BatBrain:OnStart()
    local leave_team = function()
        if self.inst.components.teamattacker then
            self.inst.components.teamattacker:LeaveTeam()
        end
    end
    local root = PriorityNode(
    {
        -- 兼容 DST batcave 的 panic 事件（DS 原生 batbrain 没有处理）
        EventNode(self.inst, "panic",
            ParallelNode{
                Panic(self.inst),
                ActionNode(leave_team),
                WaitNode(6),
            }),
        WhileNode(function() return self.inst.components.health.takingfiredamage and not self.inst.components.teamattacker.inteam end, "OnFire", Panic(self.inst)),
        AttackWall(self.inst),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
        -- 洞穴环境下改用 iscaveday 判断，避免表面白天导致蝙蝠立即回家
        WhileNode(function() return TheWorld.state.iscaveday end, "IsCaveDay",
            DoAction(self.inst, GoHomeAction)), 
        WhileNode(function() return self.inst.components.teamattacker.teamleader == nil end, "No Leader Eat Action",
            DoAction(self.inst, EatFoodAction)),
        WhileNode(function() return self.inst.components.teamattacker.teamleader == nil end, "No Leader Wander Action", 
            Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, 40)),
    }, .25)
    
    self.bt = BT(self.inst, root)
end

return BatBrain
