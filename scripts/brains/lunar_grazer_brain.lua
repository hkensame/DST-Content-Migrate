-- 月辔 AI
-- 移植自 DST，适配 DS 单人生存模式
-- 移除：planar系统、gestalt、碎片系统、portal追踪

require("behaviours/chaseandattack")
require("behaviours/leash")
require("behaviours/wander")

local STRAFE_INNER_DIST = TUNING.LUNAR_GRAZER_ATTACK_RANGE or 3
local STRAFE_OUTER_DIST = STRAFE_INNER_DIST + 2
local WANDER_DIST = 4

-- DiffAngle: 计算两个角度之间的差值（DS 无此函数，本地实现）
local function DiffAngle(a, b)
    local diff = (a - b) % 360
    if diff > 180 then diff = diff - 360 end
    if diff < -180 then diff = diff + 360 end
    return diff
end

local LunarGrazerBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function IsSleeper(target)
    return target.components.sleeper ~= nil
end

local function SleepCheck(target)
    if target.components.sleeper ~= nil then
        return target.components.sleeper:IsAsleep()
    end
    return false
end

local function DoStalking(inst)
    local target = inst.components.combat.target
    if target ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local dx = x1 - x
        local dz = z1 - z
        local dist = math.sqrt(dx * dx + dz * dz)
        local strafe_angle = Remap(math.clamp(dist, STRAFE_INNER_DIST, STRAFE_OUTER_DIST), STRAFE_INNER_DIST, STRAFE_OUTER_DIST, 90, 0)
        local rot = inst.Transform:GetRotation()
        local rot1 = math.atan2(-dz, dx) * RADIANS
        local rota = rot1 - strafe_angle
        local rotb = rot1 + strafe_angle
        if DiffAngle(rot, rota) < 30 then
            rot1 = rota
        elseif DiffAngle(rot, rotb) < 30 then
            rot1 = rotb
        else
            rot1 = math.random() < 0.5 and rota or rotb
        end
        rot1 = rot1 * DEGREES
        return Vector3(x + math.cos(rot1) * 10, 0, z - math.sin(rot1) * 10)
    end
end

local function GetHome(inst)
    return inst.components.knownlocations and inst.components.knownlocations:GetLocation("spawnpoint") or nil
end

function LunarGrazerBrain:OnStart()
    local root = PriorityNode({
        -- 碎片状态（休眠中）：等待重生或消失
        WhileNode(function()
            return self.inst.sg:HasStateTag("debris")
                and self.inst.components.combat:HasTarget()
                and not self.inst.components.health:IsHurt()
        end, "Debris",
        NotDecorator(ActionNode(function()
            self.inst:PushEvent("lunar_grazer_respawn")
        end))),

        -- 活跃状态
        WhileNode(function()
            return not self.inst.sg:HasStateTag("debris")
        end, "Awake",
        PriorityNode({
            -- 攻击目标
            WhileNode(function()
                return not self.inst.components.combat:InCooldown()
                    and self.inst.components.combat:HasTarget()
            end, "EngageTarget",
            PriorityNode({
                -- 攻击清醒目标
                IfNode(function()
                    local target = self.inst.components.combat.target
                    return target ~= nil and not IsSleeper(target)
                end, "AttackNonSleeper",
                ChaseAndAttack(self.inst)),

                -- 攻击沉睡目标（先潜行再攻击）
                WhileNode(function()
                    local target = self.inst.components.combat.target
                    return target ~= nil and SleepCheck(target)
                end, "AttackSleeper",
                SequenceNode{
                    ParallelNodeAny{
                        WaitNode(2),
                        Leash(self.inst, DoStalking, 0, 0),
                    },
                    ChaseAndAttack(self.inst),
                }),
            }, 0.5)),

            -- 无目标时潜行
            Leash(self.inst, DoStalking, 0, 0),

            -- 闲逛
            Wander(self.inst, GetHome, WANDER_DIST),
        }, 0.5)),
    }, 0.5)

    self.bt = BT(self.inst, root)
end

return LunarGrazerBrain
