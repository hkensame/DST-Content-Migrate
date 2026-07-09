-- 胡萝卜鼠 AI
-- 移植自 DST，适配 DS 单人生存模式
-- 移除：BrainCommon、YOTC赛跑、牛毛鼠、平台判定

require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/runaway"
require "behaviours/wander"

local AVOID_PLAYER_DIST = 3
local AVOID_PLAYER_STOP = 5
local SEE_BAIT_DIST = 20
local MAX_WANDER_DIST = 20

local function edible(inst, item)
    return inst.components.eater ~= nil
        and inst.components.eater:CanEat(item)
        and item.components.bait
        and not item:HasTag("planted")
        and not (item.components.inventoryitem and item.components.inventoryitem:IsHeld())
end

local NO_TAGS = { "INLIMBO", "outofreach" }

local function eat_food_action(inst)
    if inst == nil or not inst:IsValid() then return nil end

    local px, py, pz = inst.Transform:GetWorldPosition()
    local ents_nearby = TheSim:FindEntities(px, py, pz, SEE_BAIT_DIST + AVOID_PLAYER_DIST, nil, NO_TAGS)

    local foods = {}
    local scaries = {}
    for _, ent in ipairs(ents_nearby) do
        if ent ~= inst and ent.entity:IsVisible() then
            if ent:HasTag("scarytoprey") then
                table.insert(scaries, ent)
            elseif edible(inst, ent) then
                table.insert(foods, ent)
            end
        end
    end

    if #foods == 0 then return nil end

    local target = nil
    if #scaries == 0 then
        target = foods[1]
    else
        for fi = 1, #foods do
            local food = foods[fi]
            local scary_nearby = false
            for si = 1, #scaries do
                local scary = scaries[si]
                if scary ~= nil and scary.Transform ~= nil then
                    local sq = food:GetDistanceSqToPoint(scary.Transform:GetWorldPosition())
                    if sq < AVOID_PLAYER_DIST * AVOID_PLAYER_DIST then
                        scary_nearby = true
                        break
                    end
                end
            end
            if not scary_nearby then
                target = food
                break
            end
        end
    end

    if target then
        local act = BufferedAction(inst, target, ACTIONS.EAT)
        act.validfn = function() return not (target.components.inventoryitem and target.components.inventoryitem:IsHeld()) end
        return act
    end
end

local CarratBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function CarratBrain:OnStart()
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

        -- 远离可怕生物
        RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),

        -- 吃诱饵
        DoAction(self.inst, eat_food_action, "eat food"),

        -- 闲逛
        Wander(self.inst, nil, MAX_WANDER_DIST),
    }, .25)

    self.bt = BT(self.inst, root)
end

return CarratBrain
