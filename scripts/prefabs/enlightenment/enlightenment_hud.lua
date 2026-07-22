-- enlightenment_hud.lua - Enlightenment HUD display
-- Single entry: Hook sanitybadge directly
--
-- DS Badge structure (badge.lua):
--   self.anim   = UIAnim, bank/build = "sanity", anim = "anim"
--   self.pulse  = UIAnim, bank/build = "hunger_health_pulse"
--   self.warning = UIAnim, bank/build = "hunger_health_pulse", hidden by default
--
-- DS statusdisplays sanity delta triggers:
--   IsCrazy() -> StartWarning (red pulse loop)
--   sanity decreased -> PulseRed (red flash)
--
-- Strategy:
--   - Override StartWarning/PulseRed on sanitybadge to use white during enlightenment
--   - OnUpdate handles event-driven icon switch (not polling)
--   - 6 FRAMES delay + transition animation for smooth icon change
--   - Single source of truth for enlightenment state

local UIAnim = require "widgets/uianim"

local function SpawnTransitionFX(badge, anim)
    local parent = badge.parent
    if parent == nil then return end
    local fx = parent:AddChild(UIAnim())
    fx:SetPosition(badge:GetPosition())
    fx:SetClickable(false)
    fx.inst:ListenForEvent("animover", function(inst) inst.widget:Kill() end)
    fx:GetAnimState():SetBank("status_sanity")
    fx:GetAnimState():SetBuild("status_sanity")
    fx:GetAnimState():Hide("frame")
    fx:GetAnimState():PlayAnimation(anim)
end

AddClassPostConstruct("widgets/sanitybadge", function(self)
    local is_enlightened = false  -- single source of truth
    local transition_task = nil

    -- [1] Override StartWarning: during enlightenment, force white color
    local _StartWarning = self.StartWarning
    function self:StartWarning()
        _StartWarning(self)
        if is_enlightened then
            self.warning:GetAnimState():SetMultColour(1, 1, 1, 1)
        end
    end

    -- [2] Override PulseRed: during enlightenment, swap green/red meaning
    local _PulseRed = self.PulseRed
    local _PulseGreen = self.PulseGreen
    function self:PulseRed()
        if is_enlightened then
            -- Swapped: red becomes green during lunacy (like DST)
            _PulseGreen(self)
        else
            _PulseRed(self)
        end
    end
    function self:PulseGreen()
        if is_enlightened then
            -- Swapped: green becomes red during lunacy
            _PulseRed(self)
        else
            _PulseGreen(self)
        end
    end

    -- [3] Icon switching functions
    -- DS 的 sanity build 是预着色单张贴图，没有 "brain" 等可覆写符号
    -- 用 SetMultColour 叠蓝色透明层来模拟颜色变化
    local function SetLunacyIcon()
        if self.anim then
            self.anim:GetAnimState():SetMultColour(0.75, 0.91, 0.94, 1)
        end
        if self.circleframe then
            self.circleframe:GetAnimState():OverrideSymbol("icon", "status_sanity", "lunacy_icon")
        end
        if self.backing then
            self.backing:GetAnimState():OverrideSymbol("bg", "status_sanity", "lunacy_bg")
        end
    end

    local function RestoreSanityIcon()
        if self.anim then
            self.anim:GetAnimState():SetMultColour(1, 1, 1, 1)
        end
        if self.circleframe then
            -- 必须用 OverrideSymbol 重新指定 sanity 图标，而非 ClearOverrideSymbol（否则回退到 status_meter 默认图标）
            self.circleframe:GetAnimState():OverrideSymbol("icon", "status_sanity", "icon")
        end
        if self.backing then
            self.backing:GetAnimState():ClearOverrideSymbol("bg")
        end
    end

    -- [4] OnUpdate: handle icon switch with transition
    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt)
        if _OnUpdate then
            _OnUpdate(self, dt)
        end

        local enlight = self.owner and self.owner.components.enlightenment
        local new_state = enlight and enlight:IsEnabled()
        if new_state == is_enlightened then return end

        -- Cancel any pending transition
        if transition_task then
            transition_task:Cancel()
            transition_task = nil
        end

        if new_state then
            -- Entering enlightenment
            SpawnTransitionFX(self, "transition_lunacy")
            transition_task = self.owner:DoTaskInTime(6 * FRAMES, function()
                SetLunacyIcon()
                transition_task = nil
            end)
            -- Show white warning immediately (StartWarning override handles subsequent updates)
            if not self.warning.shown then
                self.warning:Show()
            end
            self.warning:GetAnimState():SetMultColour(1, 1, 1, 1)
            if not self.warning:GetAnimState():IsCurrentAnimation("pulse") then
                self.warning:GetAnimState():PlayAnimation("pulse", true)
            end
        else
            -- Exiting enlightenment
            SpawnTransitionFX(self, "transition_sanity")
            transition_task = self.owner:DoTaskInTime(6 * FRAMES, function()
                RestoreSanityIcon()
                transition_task = nil
            end)
            -- 退出启蒙时强制隐藏 warning，让原版 sanity 系统重新接管
            -- 重置颜色后隐藏，避免下次 StartWarning 时残留白色
            self.warning:GetAnimState():SetMultColour(1, 0, 0, 1)
            self.warning:Hide()
        end

        is_enlightened = new_state
    end
end)
