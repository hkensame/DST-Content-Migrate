-- 光飞虫 AI
-- 移植自 DST，适配 DS 单人生存模式
-- 移除：BrainCommon、formationfollower
-- 保留：homeseeker、GoHome 行为、以家为中心的 Wander

require "behaviours/panic"
require "behaviours/runaway"
require "behaviours/wander"

local SEE_THREAT_DIST = 3.5
local SEE_THREAT_DIST_ALERT = 8
local STOP_RUN_DIST = 5
local STOP_RUN_DIST_ALERT = 10
local MAX_WANDER_DIST = 10

local huntertags = { "scarytoprey" }
local NEW_HOME_TAGS = { "lightflier_home" }
local NEW_HOME_NOTAGS = { "burnt", "fire" }

---------------------------------------------------------------------------
-- 回家逻辑
---------------------------------------------------------------------------

local function GoHomeAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    local homeseeker = inst.components.homeseeker
    if homeseeker ~= nil
        and homeseeker.home ~= nil
        and homeseeker.home:IsValid()
        and homeseeker.home.components.childspawner ~= nil
        and not homeseeker.home.components.burnable:IsBurning()
        and not homeseeker.home.components.pickable:CanBePicked() then

        return BufferedAction(inst, homeseeker.home, ACTIONS.GOHOME)
    end
end

local function FindHome(inst)
    if inst.components.homeseeker == nil then
        inst:AddComponent("homeseeker")
    end

    if inst.components.homeseeker.home == nil then
        local new_home = FindEntity(inst, MAX_WANDER_DIST, nil, NEW_HOME_TAGS, NEW_HOME_NOTAGS)
        if new_home ~= nil and new_home.components.childspawner ~= nil then
            new_home.components.childspawner:TakeOwnership(inst)
        end
    end
end

local function ShouldGoHome(inst)
    FindHome(inst)

    local home = inst.components.homeseeker.home
    if home ~= nil and home:IsValid() then
        -- 花正在召回这只虫
        if home._lightflier_returning_home == inst then
            return true
        end
        -- 虫在外太久（>60秒）且花的虫数量超标
        if inst:GetTimeAlive() > 60
            and home.components.childspawner.numchildrenoutside > TUNING.LIGHTFLIER_FLOWER_TARGET_NUM_CHILDREN_OUTSIDE then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- 获取家的位置（用于 Wander 中心点）
---------------------------------------------------------------------------

local function GetHomePos(inst)
    local homepos = inst.components.homeseeker ~= nil and inst.components.homeseeker:GetHomePos() or nil
    homepos = homepos or (inst.components.knownlocations ~= nil and inst.components.knownlocations:GetLocation("home")) or nil
    return homepos
end

---------------------------------------------------------------------------
-- Brain
---------------------------------------------------------------------------

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

        -- 回家（花召回或虫数量超标）
        WhileNode(function() return ShouldGoHome(self.inst) end, "ShouldGoHome",
            DoAction(self.inst, GoHomeAction, "GoHome")),

        -- 以家为中心闲逛
        Wander(self.inst, function() return GetHomePos(self.inst) end, MAX_WANDER_DIST),
    }, .25)

    self.bt = BT(self.inst, root)
end

return LightFlierBrain
