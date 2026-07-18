-- ==================== DST Fire Spreading System ====================
-- DST 式蓄火→点燃火焰蔓延机制
-- 移植自 mod "DST Fire Spreading" (Leonidas IV, Viktor)
-- 适用于 dst_boss 模组的 DS 环境
-- ================================================================

local easing = require("easing")

-- SMOTHER 动作优先级：保证火焰蔓延时优先扑灭
GLOBAL.ACTIONS.SMOTHER.priority = 7

-- PlayerController：正在蓄火的物体优先显示扑灭动作
AddComponentPostInit("playercontroller", function(self)
    local _GetActionButtonAction = self.GetActionButtonAction
    function self:GetActionButtonAction(...)
        local action = _GetActionButtonAction(self, ...)
        local tool = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if action then
            if action.target.components.burnable and action.target.components.burnable:IsSmoldering() then
                return BufferedAction(self.inst, action.target, ACTIONS.SMOTHER, tool)
            end
        end
        return action
    end
end)

-- DST 风格点火函数：蓄火 → 点燃
GLOBAL.DefaultIgniteFn = function(inst)
    if inst.components.burnable then
        inst.components.burnable:StartWildfire()
    end
end

-- ==================== 燃耗时覆盖 ====================
local _MakeSmallBurnable = MakeSmallBurnable
GLOBAL.MakeSmallBurnable = function(inst, time, offset, structure)
    _MakeSmallBurnable(inst, time, offset, structure)
    inst.components.burnable:SetBurnTime(time or 10)
end

local _MakeMediumBurnable = MakeMediumBurnable
GLOBAL.MakeMediumBurnable = function(inst, time, offset, structure)
    _MakeMediumBurnable(inst, time, offset, structure)
    inst.components.burnable:SetBurnTime(time or 20)
end

local _MakeLargeBurnable = MakeLargeBurnable
GLOBAL.MakeLargeBurnable = function(inst, time, offset, structure)
    _MakeLargeBurnable(inst, time, offset, structure)
    inst.components.burnable:SetBurnTime(time or 30)
end

-- ==================== 传播参数覆盖 ====================
local _MakeSmallPropagator = MakeSmallPropagator
GLOBAL.MakeSmallPropagator = function(inst)
    _MakeSmallPropagator(inst)
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.propagaterange = 3 + math.random() * 2
    inst.components.propagator.heatoutput = 3 + math.random() * 2
end

-- 注：MakeMediumPropagator 由 dst_global.lua 定义，
-- 这里用 hook 叠加 DST 风格的 decayrate/随机范围
local _MakeMediumPropagator = MakeMediumPropagator
GLOBAL.MakeMediumPropagator = function(inst)
    _MakeMediumPropagator(inst)
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.propagaterange = 5 + math.random() * 2
    inst.components.propagator.heatoutput = 5 + math.random() * 3.5
end

local _MakeLargePropagator = MakeLargePropagator
GLOBAL.MakeLargePropagator = function(inst)
    _MakeLargePropagator(inst)
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.propagaterange = 6 + math.random() * 2
    inst.components.propagator.heatoutput = 6 + math.random() * 3.5
end

-- ==================== Propagator 组件修复 ====================
AddComponentPostInit("propagator", function(self)
    self.pauseheating = nil

    local _StopSpreading = self.StopSpreading
    function self:StopSpreading(reset, heatpct)
        local _acceptsheat = self.acceptsheat
        self.pauseheating = nil
        _StopSpreading(self, reset, heatpct)
        self.acceptsheat = _acceptsheat

        if reset then
            self.currentheat = heatpct ~= nil
                and (heatpct * easing.outCubic(math.random(), 0, 1, 1)) * self.flashpoint
                or 0
        end
    end

    local _AddHeat = self.AddHeat
    function self:AddHeat(amount)
        if not self.pauseheating then
            -- 防火地皮（GROUND.SCALE）上的实体不收热量
            local _ground = GLOBAL.GetWorld()
            if _ground and _ground.Map then
                local x, y, z = self.inst.Transform:GetWorldPosition()
                if x and _ground.Map:GetTileAtPoint(x, 0, z) == GLOBAL.GROUND.SCALE then
                    return
                end
            end

            if self.currentheat > self.flashpoint then
                self.pauseheating = true
            end

            local _acceptsheat = self.acceptsheat
            _AddHeat(self, amount)
            self.acceptsheat = _acceptsheat
        end
    end
end)

-- ==================== Burnable 组件：蓄火→点燃机制 ====================
local SMOLDER_TICK_TIME = 2

local function SmolderUpdate(inst, self)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 12)
    local nearbyheat = 0

    for _, v in ipairs(ents) do
        if v.components.propagator ~= nil then
            nearbyheat = nearbyheat + v.components.propagator.currentheat
        end
    end

    -- 下雨时蓄火进度回退
    if GetSeasonManager() and GetSeasonManager():IsRaining() then
        if nearbyheat > 0 then
            local rainmod = 1.8 * GetSeasonManager().precip_rate
            self.smoldertimeremaining = self.smoldertimeremaining + SMOLDER_TICK_TIME * rainmod
        else
            self.smoldertimeremaining = self.smoldertimeremaining + SMOLDER_TICK_TIME * 3.0
        end
    end

    local heatmod = math.clamp(Remap(nearbyheat, 20, 40, 1, 2.2), 1, 2.2)
    self.smoldertimeremaining = self.smoldertimeremaining - SMOLDER_TICK_TIME * heatmod

    if self.smoldertimeremaining <= 0 then
        self:StopSmoldering()
        self:Ignite()

    elseif
        self.inst.components.propagator
        and self.inst.components.propagator.flashpoint
        and self.smoldertimeremaining > self.inst.components.propagator.flashpoint * 1.1
    then
        -- 被雨水浇灭
        self:StopSmoldering()
    end
end

AddComponentPostInit("burnable", function(self)
    self.task = nil
    self.smolder_task = nil

    local _StopSmoldering = self.StopSmoldering
    function self:StopSmoldering(heatpct)
        _StopSmoldering(self)
        if self.inst.components.propagator ~= nil then
            self.inst.components.propagator:StopSpreading(true, heatpct)
        end
        if self.onstopsmoldering ~= nil then
            self.onstopsmoldering(self.inst)
        end
    end

    local _SmotherSmolder = self.SmotherSmolder
    function self:SmotherSmolder(...)
        _SmotherSmolder(self, ...)
        self:StopSmoldering(-1)
    end

    local _Extinguish = self.Extinguish
    function self:Extinguish(...)
        self:StopSmoldering(-1)
        _Extinguish(self, ...)
    end

    -- DST 式蓄火：物体开始冒烟→最终点燃
    function self:StartWildfire()
        if not (self.burning or self.smoldering or self.inst:HasTag("fireimmune")) then
            local _ground = GLOBAL.GetWorld()
            if _ground and _ground.Map then
                local x, y, z = self.inst.Transform:GetWorldPosition()
                if x and _ground.Map:GetTileAtPoint(x, 0, z) == GLOBAL.GROUND.SCALE then
                    return
                end
            end

            self.smoldering = true
            self.inst:AddTag("smolder")

            if self.onsmoldering then
                self.onsmoldering(self.inst)
            end

            self.smoke = SpawnPrefab("smoke_plant")
            if self.smoke ~= nil then
                if #self.fxdata == 1 and self.fxdata[1].follow then
                    if self.fxdata[1].followaschild then
                        self.inst:AddChild(self.smoke)
                    end
                    local follower = self.smoke.entity:AddFollower()
                    local xoffs, yoffs, zoffs = self.fxdata[1].x, self.fxdata[1].y, self.fxdata[1].z

                    if self.fxoffset ~= nil then
                        xoffs = xoffs + self.fxoffset.x
                        yoffs = yoffs + self.fxoffset.y
                        zoffs = zoffs + self.fxoffset.z
                    end

                    follower:FollowSymbol(self.inst.GUID, self.fxdata[1].follow, xoffs, yoffs, zoffs)
                else
                    self.inst:AddChild(self.smoke)
                end

                self.smoke.Transform:SetPosition(0, 0, 0)
            end

            self.smoldertimeremaining = (
                self.inst.components.propagator ~= nil and self.inst.components.propagator.flashpoint
                or
                math.random(TUNING.MIN_SMOLDER_TIME, TUNING.MAX_SMOLDER_TIME)
            )

            if self.smolder_task ~= nil then
                self.smolder_task:Cancel()
            end

            self.smolder_task = self.inst:DoPeriodicTask(
                SMOLDER_TICK_TIME,
                SmolderUpdate,
                math.random() * SMOLDER_TICK_TIME,
                self
            )
        end
    end
end)
