--------------------------------------------------------------------------
-- DS 移植版 dst_nightmareclock.lua
-- 从 DST 源码 scripts/components/nightmareclock.lua 移植
-- 改名原因：DS 原版已有自己的 nightmareclock 组件（gamelogic.lua:542），
--    API 不同（phasechange 事件、GetPhase/IsCalm 等方法），
--    如果用相同文件名会遮蔽原版，导致 DS 洞穴原版预制体崩溃
-- 改动：
--   移除网络层（net_smallbyte/tinybyte/float → 纯 Lua 变量）
--   移除 areaaware 区域感知（DS 纯单机，无需分服同步）
--   移除 _ismastersim 判断（DS 永远是 master）
--   保留：4 阶段轮转、事件推送、锁定机制、Save/Load、音效
--------------------------------------------------------------------------

local function GetTheWorld()
    return rawget(_G, "TheWorld")
end

return Class(function(self, inst)

-- table.invert 兼容：DS 基础版没有此函数
if not table.invert then
    table.invert = function(t)
        local inverted = {}
        for k, v in pairs(t) do
            inverted[v] = k
        end
        return inverted
    end
end

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local PHASE_NAMES =
{
    "calm",
    "warn",
    "wild",
    "dawn",
}
local PHASES = table.invert(PHASE_NAMES)

local SOUNDS =
{
    calm = {
        sound = nil,
        param = 0,
    },
    warn = {
        sound = "dontstarve/cave/nightmare_warning",
        param = 1,
    },
    wild = {
        sound = "dontstarve/cave/nightmare_full",
        param = 2,
    },
    dawn = {
        sound = "dontstarve/cave/nightmare_end",
        param = 1,
    },
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = GetTheWorld()
local _phasedirty = true
local _oldphase = 1  -- 用于 DS 兼容的 phasechange 事件

--Phase state（纯 Lua 变量，替代 DST 的 net_*）
local _segs = {}
for i, v in ipairs(PHASE_NAMES) do
    _segs[i] = TUNING.NIGHTMARE_SEGS[string.upper(v)] or 0
end
local _phase = PHASES.calm
local _totaltimeinphase = _segs[_phase] * TUNING.SEG_TIME
local _remainingtimeinphase = _totaltimeinphase
local _lockedphase = nil

--------------------------------------------------------------------------
--[[ Sound helpers ]]
--------------------------------------------------------------------------

local function OnPhaseChanged()
    -- 播放阶段切换音效
    local sound = SOUNDS[PHASE_NAMES[_phase]].sound
    if sound ~= nil then
        _world.SoundEmitter:PlaySound(sound)
    end

    -- 更新环境循环音效
    local param = SOUNDS[PHASE_NAMES[_phase]].param
    if param > 0 then
        if not _world.SoundEmitter:PlayingSound("nightmare_loop") then
            _world.SoundEmitter:PlaySound("dontstarve/cave/nightmare", "nightmare_loop")
        end
        _world.SoundEmitter:SetParameter("nightmare_loop", "nightmare", param)
    else
        if _world.SoundEmitter:PlayingSound("nightmare_loop") then
            _world.SoundEmitter:KillSound("nightmare_loop")
        end
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Event listeners ]]
--------------------------------------------------------------------------

inst:ListenForEvent("ms_setnightmaresegs", function(src, lengths)
    local normremaining = _totaltimeinphase > 0 and (_remainingtimeinphase / _totaltimeinphase) or 1

    if lengths then
        for i, v in ipairs(PHASE_NAMES) do
            _segs[i] = lengths[v] or 0
        end
    else
        for i, v in ipairs(PHASE_NAMES) do
            _segs[i] = TUNING.NIGHTMARE_SEGS[string.upper(v)] or 0
        end
    end

    local resulttime = _segs[_phase] * TUNING.SEG_TIME + math.random() * TUNING.NIGHTMARE_SEG_VARIATION * TUNING.SEG_TIME
    _totaltimeinphase = resulttime
    _remainingtimeinphase = normremaining * _totaltimeinphase
end, _world)

inst:ListenForEvent("ms_setnightmarephase", function(src, phase)
    if _lockedphase ~= nil then return end
    phase = PHASES[phase]
    if phase ~= nil then
        _phase = phase
        local resulttime = _segs[_phase] * TUNING.SEG_TIME + math.random() * TUNING.NIGHTMARE_SEG_VARIATION * TUNING.SEG_TIME
        _totaltimeinphase = resulttime
        _remainingtimeinphase = _totaltimeinphase
    end
    self:LongUpdate(0)
end, _world)

inst:ListenForEvent("ms_nextnightmarephase", function()
    if _lockedphase ~= nil then return end
    _remainingtimeinphase = 0
    self:LongUpdate(0)
end, _world)

inst:ListenForEvent("ms_nextnightmarecycle", function()
    if _lockedphase ~= nil then return end
    _phase = #PHASE_NAMES
    _remainingtimeinphase = 0
    self:LongUpdate(0)
end, _world)

inst:ListenForEvent("ms_locknightmarephase", function(src, phase)
    _lockedphase = PHASES[phase]
    if _lockedphase ~= nil then
        _phase = _lockedphase
        local resulttime = _segs[_phase] * TUNING.SEG_TIME + math.random() * TUNING.NIGHTMARE_SEG_VARIATION * TUNING.SEG_TIME
        _totaltimeinphase = resulttime
        _remainingtimeinphase = 0
    end
    self:LongUpdate(0)
end, _world)

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    local remainingtimeinphase = _remainingtimeinphase - dt

    if remainingtimeinphase > 0 then
        -- 在当前阶段推进时间
        _remainingtimeinphase = remainingtimeinphase
    else
        -- 进入下一阶段
        _remainingtimeinphase = 0

        if _lockedphase == nil then
            while _remainingtimeinphase <= 0 do
                _phase = (_phase % #PHASE_NAMES) + 1
                _phasedirty = true
                local resulttime = _segs[_phase] * TUNING.SEG_TIME + math.random() * TUNING.NIGHTMARE_SEG_VARIATION * TUNING.SEG_TIME
                _totaltimeinphase = resulttime
                _remainingtimeinphase = _totaltimeinphase
            end

            if remainingtimeinphase < 0 then
                self:OnUpdate(-remainingtimeinphase)
                return
            end
        end
    end

    -- 相位变更时推送事件 + 更新音效
    if _phasedirty then
        _world:PushEvent("nightmarephasechanged", PHASE_NAMES[_phase])
        -- DS 兼容：同时推送 phasechange 事件
        -- DS 用 "nightmare" 对应模组的 "wild"，需要映射
        local ds_newphase = PHASE_NAMES[_phase] == "wild" and "nightmare" or PHASE_NAMES[_phase]
        local ds_oldphase = PHASE_NAMES[_oldphase] == "wild" and "nightmare" or PHASE_NAMES[_oldphase]
        _world:PushEvent("phasechange", { oldphase = ds_oldphase, newphase = ds_newphase })
        OnPhaseChanged()
        _phasedirty = false
        _oldphase = _phase
    end

    -- 每帧推送进度事件供其他组件监听
    local elapsedtime = 0
    local normtimeinphase = 0
    for i, v in ipairs(_segs) do
        if _phase == i then
            normtimeinphase = 1 - (_totaltimeinphase > 0 and _remainingtimeinphase / _totaltimeinphase or 0)
            elapsedtime = elapsedtime + v * normtimeinphase * TUNING.SEG_TIME
            break
        end
        elapsedtime = elapsedtime + v * TUNING.SEG_TIME
    end
    _world:PushEvent("nightmareclocktick", { phase = PHASE_NAMES[_phase], timeinphase = normtimeinphase, time = elapsedtime })
end

self.LongUpdate = self.OnUpdate

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data =
    {
        lengths = {},
        phase = PHASE_NAMES[_phase],
        totaltimeinphase = _totaltimeinphase,
        remainingtimeinphase = _remainingtimeinphase,
        lockedphase = _lockedphase ~= nil and PHASE_NAMES[_lockedphase] or nil,
    }

    for i, v in ipairs(_segs) do
        data.lengths[PHASE_NAMES[i]] = v
    end

    return data
end

function self:OnLoad(data)
    for i, v in ipairs(PHASE_NAMES) do
        _segs[i] = data.lengths and data.lengths[v] or 0
    end

    if PHASES[data.phase] then
        _phase = PHASES[data.phase]
    else
        for i, v in ipairs(_segs) do
            if v > 0 then
                _phase = i
                break
            end
        end
    end

    _totaltimeinphase = data.totaltimeinphase or _segs[_phase] * TUNING.SEG_TIME
    _remainingtimeinphase = math.min(data.remainingtimeinphase or _totaltimeinphase, _totaltimeinphase)
    _lockedphase = data.lockedphase ~= nil and PHASES[data.lockedphase] or nil
end

--------------------------------------------------------------------------
--[[ DS 兼容公开方法 ]]
-- DS nightmare_timepiece、nightmarelight、fissure 等 prefab
-- 通过 GetNightmareClock() 获取组件后调用这些方法
--------------------------------------------------------------------------

function self:GetPhase()
    -- DS 兼容：将 "wild" 映射为 "nightmare"（DS 原版阶段名）
    local phase = PHASE_NAMES[_phase]
    return phase == "wild" and "nightmare" or phase
end

function self:IsCalm()
    return _phase == PHASES.calm
end

function self:IsWarn()
    return _phase == PHASES.warn
end

function self:IsNightmare()
    -- DS 原版暴动阶段名是 "nightmare"，模组是 "wild"
    return _phase == PHASES.wild
end

function self:IsDawn()
    return _phase == PHASES.dawn
end

function self:GetNormEraTime()
    return _totaltimeinphase > 0 and (1 - _remainingtimeinphase / _totaltimeinphase) or 1
end

function self:GetTimeLeftInEra()
    return _remainingtimeinphase
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    return string.format("%s: %2.2f ", PHASE_NAMES[_phase], _remainingtimeinphase)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
