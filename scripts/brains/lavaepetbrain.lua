require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/panic"
require "behaviours/faceentity"
require "behaviours/follow"

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 8
local TARGET_FOLLOW_DIST = 5

local MAX_WANDER_DIST = 3

local FIND_FOOD_ACTION_DIST = 12

local function GetOwner(inst)
    return inst.components.follower.leader
end

local GetFaceTargetFn = GetOwner

local function KeepFaceTargetFn(inst, target)
    return target == GetOwner(inst)
end

local function EatFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return nil
    end

    if inst.components.inventory ~= nil and inst.components.eater ~= nil then
        local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
        return target ~= nil
            and BufferedAction(inst, target, ACTIONS.EAT)
            or nil
    end
end

local FUELTYPE =
{
    BURNABLE = "BURNABLE",
    USAGE = "USAGE",
    MAGIC = "MAGIC",
    CAVE = "CAVE",
    NIGHTMARE = "NIGHTMARE",
    ONEMANBAND = "ONEMANBAND",
    PIGTORCH = "PIGTORCH",
    CHEMICAL = "CHEMICAL",
    WORMLIGHT = "WORMLIGHT",
}

local MAKE_FOOD_TAGS = { "canlight", "fire", "smolder" }
local NO_MAKE_FOOD_TAGS = { "INLIMBO", "_equippable", "outofreach" }
for k, v in pairs(FUELTYPE) do
    if v ~= "USAGE" then --Not a real fuel
        table.insert(NO_MAKE_FOOD_TAGS, v.."_fueled")
    end
end

local function MakeFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    local target = FindEntity(inst, FIND_FOOD_ACTION_DIST, nil, nil, NO_MAKE_FOOD_TAGS, MAKE_FOOD_TAGS)
    return target ~= nil and BufferedAction(inst, target, ACTIONS.NUZZLE) or nil
end

local function CanPickup(item)
    return item.components.inventoryitem.canbepickedup and item:IsOnValidGround()
end

local function FindFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    local target = FindEntity(inst, FIND_FOOD_ACTION_DIST, CanPickup, { "edible_BURNT", "_inventoryitem" }, { "INLIMBO", "fire", "catchable", "outofreach" })
    return target ~= nil and BufferedAction(inst, target, ACTIONS.PICKUP) or nil
end

local function OwnerIsClose(inst)
    local owner = GetOwner(inst)
    return owner ~= nil and owner:IsNear(inst, 2.5)
end

local function LoveOwner(inst)
    if inst.sg:HasStateTag("busy") then
        return nil
    end

    local owner = GetOwner(inst)
    return owner ~= nil
        and owner:HasTag("player")
        and inst.components.hunger:GetPercent() > 0.5
        and math.random() < 0.5        
        or nil
end

local LavaePetBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetWanderDistFn(inst)
    return GetClock():IsDay() and WANDER_DIST_DAY or WANDER_DIST_NIGHT
end

function LavaePetBrain:OnStart()
    local root =
    PriorityNode({

        
        --当饱食度过低时制造寻找食物
        WhileNode(function() return self.inst.components.hunger:GetPercent() < 0.05 end, "STARVING BABY ALERT!",
            PriorityNode{
                --Eat the foods
                DoAction(self.inst, EatFoodAction),
                --Find the foods
                DoAction(self.inst, FindFoodAction),
                --Make the foods!
                SequenceNode{
                    DoAction(self.inst, MakeFoodAction),
                    WaitNode(10),
                },
            }),
		--跟随行为
        Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
		
		--吃东西
        DoAction(self.inst, EatFoodAction),
        
        FailIfRunningDecorator(FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),
		
		--Wander(self.inst, GetHomePos, GetWanderDistFn),
		FaceEntity(self.inst, GetOwner, GetOwner),
		
		--拥有者关闭
        WhileNode(function() return OwnerIsClose(self.inst) end, "Owner Is Close",
            SequenceNode{
                WaitNode(4),
                DoAction(self.inst, LoveOwner),
            }),

    }, 1)
    self.bt = BT(self.inst, root)
end

return LavaePetBrain
