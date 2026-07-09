-- 火药猴 AI (powdermonkeybrain)
-- 移植自 DST，适配 DS 单机模式
-- 移除：BrainCommon (PanicTrigger/ElectricFencePanicTrigger)
-- 移除：boat/crew/ocean 相关行为 (rowboat, Dotinker, firecannon, gotocannon,
--       DoAbandon, ReturnToBoat, bananahandoff, shouldsteal 中的箱子逻辑)
-- 适配：TheWorld.state.isnight → GetClock():IsNight()

require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/chaseandattack"
require "behaviours/leash"

local MAX_WANDER_DIST = 20

local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30

local SEE_PLAYER_DIST = 5
local STOP_RUN_DIST = 10

local NO_LOOTING_TAGS = { "INLIMBO", "catchable", "fire", "irreplaceable", "heavy", "outofreach", "spider" }
local NO_PICKUP_TAGS = deepcopy(NO_LOOTING_TAGS)
table.insert(NO_PICKUP_TAGS, "_container")

local PowderMonkeyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local ITEM_MUST = {"_inventoryitem"}
local ITEM_MUSTNOT = { "INLIMBO", "NOCLICK", "knockbackdelayinteraction", "catchable", "fire", "minesprung", "mineactive", "spider", "nosteal", "irreplaceable" }

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "playerghost" }
local RETARGET_ONEOF_TAGS = { "character", "monster" }

local function shouldsteal(inst)
    if inst.sg:HasStateTag("busy") or inst.components.timer:TimerExists("hit") then
        return nil
    end

    inst.nothingtosteal = nil
    if inst.components.inventory:IsFull() then
        return nil
    end

    if inst.components.combat.target and not inst.components.combat:InCooldown() then
        return nil
    end

    local x,y,z = inst.Transform:GetWorldPosition()
    local range = 15

    local ents = TheSim:FindEntities(x, y, z, range, ITEM_MUST, ITEM_MUSTNOT)

    if #ents > 0 then
        for i=#ents,1,-1 do
            local ent = ents[i]
            if  not ent.components.inventoryitem or
                not ent.components.inventoryitem.canbepickedup or
                not ent.components.inventoryitem.cangoincontainer or
                ent.components.sentientaxe or
                ent.components.inventoryitem:IsHeld() then
                table.remove(ents,i)
            end
        end
    end

    if #ents > 0 then
        -- 优先偷洞穴香蕉
        for i,ent in ipairs(ents) do
            if ent.prefab == "cave_banana" or ent.prefab == "cave_banana_cooked" then
                inst.itemtosteal = ents[i]
                return BufferedAction(inst, inst.itemtosteal, ACTIONS.PICKUP)
            end
        end
        inst.itemtosteal = ents[1]
        return BufferedAction(inst, inst.itemtosteal, ACTIONS.PICKUP)
    else
        -- 看能否偷别人的东西
        if not inst.components.combat.target then
            local target = FindEntity(
                    inst,
                    10,
                    function(guy)
                        if guy:HasTag("monkey") then
                            return false
                        end

                        if not guy.components.inventory or guy.components.inventory:NumItems() == 0 then
                            return false
                        end

                        local count = 0
                        for k,v in pairs(guy.components.inventory.itemslots) do
                            local keep = true
                            if v:HasTag("nosteal") then
                                keep = false
                            end
                            if keep == true then
                                count = count +1
                            end
                        end

                        if count == 0 then
                            return false
                        end

                        return inst.components.combat:CanTarget(guy)
                    end,
                    RETARGET_MUST_TAGS,
                    RETARGET_CANT_TAGS,
                    RETARGET_ONEOF_TAGS
                )
            if target then
                return BufferedAction(inst, target, ACTIONS.STEAL)
            else
                inst.nothingtosteal = true
            end
        end
    end
end

local function shouldattack(inst)
    if (inst.bufferedaction ~= nil and inst.bufferedaction.id == ACTIONS.PICKUP.id)
            or inst.components.combat:InCooldown()
            or inst.sg:HasStateTag("busy") then
        return nil
    end

    return inst.components.combat.target ~= nil
end

local function shouldrun(inst)
    return inst.components.combat.target ~= nil and inst.components.timer:TimerExists("hit")
end

local function GetRunAwayTarget(inst)
    return inst.components.combat.target
end

local function GoToHut(inst)
    local home = (inst.components.homeseeker ~= nil and inst.components.homeseeker.home)
        or nil
    if home == nil
            or (home.components.burnable ~= nil and home.components.burnable:IsBurning())
            or home:HasTag("burnt") then
        return nil
    end

    if inst.components.combat.target == nil then
        return BufferedAction(inst, home, ACTIONS.GOHOME)
    end
end

local HARVEST_MUSTHAVE_TAGS = {"bananabush"}
local function HarvestBanana(inst)
    local x,y,z = inst.Transform:GetWorldPosition()

    local ents = TheSim:FindEntities(x, y, z, 15, HARVEST_MUSTHAVE_TAGS)
    if #ents > 0 then
        for i=#ents,1,-1 do
            local ent = ents[i]
            if ent.prefab == "bananabush" and ent.components.pickable and ent.components.pickable.canbepicked then
                return BufferedAction(inst, ents[1], ACTIONS.PICK)
            end
        end
    end
end

function PowderMonkeyBrain:OnStart()

    local root = PriorityNode(
    {
        -- BrainCommon 节点移除

        -- 家着火了就恐慌
        WhileNode(
            function()
                return self.inst.components.homeseeker ~= nil
                    and self.inst.components.homeseeker.home
                    and self.inst.components.homeseeker.home.components.burnable
                    and self.inst.components.homeseeker.home.components.burnable:IsBurning()
            end,
            "OnFire", Panic(self.inst)),

        -- 被打后逃跑
        WhileNode(function() return shouldrun(self.inst) end, "Should run",
            RunAway(self.inst, GetRunAwayTarget, SEE_PLAYER_DIST, STOP_RUN_DIST, nil, true)),

        -- 战斗
        WhileNode(function() return shouldattack(self.inst) end, "Should attack",
            ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

        -- 偷东西
        ChattyNode(self.inst, "MONKEY_TALK_STEAL",
            DoAction(self.inst, shouldsteal, "steal")),

        -- 夜晚回家
        ChattyNode(self.inst, "MONKEY_TALK_RETREAT",
            WhileNode(function() return GetClock():IsNight() end, "Is Night",
                DoAction(self.inst, GoToHut, "Go Home", true))),

        -- 收获香蕉
        DoAction(self.inst, HarvestBanana, "harvestbanana", true ),

        -- 漫游
        Wander(self.inst,
            function() return self.inst.components.knownlocations:GetLocation("home") end,
            MAX_WANDER_DIST,
            {minwalktime=0.2,randwalktime=.8,minwaittime=1,randwaittime=5}
        )

    }, .25)
    self.bt = BT(self.inst, root)
end

return PowderMonkeyBrain
