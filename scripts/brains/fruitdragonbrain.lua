-- fruitdragonbrain.lua - 火龙果蜥蜴 AI（全功能版）
-- 找热源、挑战其他火龙果、恐慌逃跑

require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/runaway"
require "behaviours/leash"

local MAX_HOME_WANDER_DIST = 12
local MAX_CHASE_DIST = 12
local TARGET_FOLLOW_DIST = 4
local MAX_FOLLOW_DIST = 4.5
local CHALLENGE_LOST_RUN = 10
local CHALLENGE_LOST_STOP = 15
local NIGHT_LEASH_DIST = 6

local function GetHome(inst)
    return inst.components.entitytracker and inst.components.entitytracker:GetEntity("home") or nil
end

local function IsHomeMoveable(inst)
    local home = GetHome(inst)
    home = (home ~= nil and home.components.inventoryitem ~= nil) and home.components.inventoryitem:GetGrandOwner() or home
    return home ~= nil and home.components.locomotor ~= nil
end

local function GetHomePos(inst)
    local home = GetHome(inst)
    return home and home:GetPosition() or nil
end

local function IsPanicing(inst)
    if not inst or not inst.components or not inst.components.timer then return false end
    return inst.components.timer:TimerExists("panicing")
end

local wander_timing = {minwalktime = 4, randwalktime = 4, randwaittime = 1}

local FruitDragonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function FruitDragonBrain:OnStart()
    local root = PriorityNode({
        -- 着火恐慌
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),

        -- 挑战失败逃跑
        WhileNode(IsPanicing, "Panicing",
            RunAway(self.inst, "fruitdragon", CHALLENGE_LOST_RUN, CHALLENGE_LOST_STOP, function()
                self.inst.components.combat:SetTarget(nil)
                return true
            end)
        ),

        -- 正常战斗
        ChaseAndAttack(self.inst, nil, MAX_CHASE_DIST),

        -- 有家时：夜间在家附近游荡，白天跟随热源
        WhileNode(function() return GetHome(self.inst) ~= nil end, "HasHome",
            PriorityNode({
                IfNode(function() return IsHomeMoveable(self.inst) end, "MoveableHome",
                    PriorityNode({
                        Follow(self.inst, function() return GetHome(self.inst) end, 0, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
                        FaceEntity(self.inst, GetHome),
                    })
                ),
                -- 夜间在家附近游荡
                IfNode(function() return GetClock() ~= nil and GetClock():IsNight() end, "NightWander",
                    Leash(self.inst, GetHomePos, NIGHT_LEASH_DIST, NIGHT_LEASH_DIST)
                ),
                -- 在家附近闲逛
                Wander(self.inst, GetHomePos, MAX_HOME_WANDER_DIST, wander_timing),
            })
        ),

        -- 无家时闲逛
        Wander(self.inst, nil, nil, wander_timing),
    }, .25)
    self.bt = BT(self.inst, root)
end

return FruitDragonBrain
