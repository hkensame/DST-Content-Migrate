-- enlightenment.lua - 启蒙系统核心组件
-- 启蒙值 = 理智值本身（sanity:GetPercent()），不维护独立数值
-- 组件仅管理"是否处于启蒙状态"和月灵生成/行为
-- 正常状态：低 san 有危害（暗影生物）
-- 启蒙状态：高 san 有危害（月灵攻击）

local Enlightenment = Class(function(self, inst)
    self.inst = inst
    self.enabled = false       -- 是否处于启蒙状态
    self.sources = {}          -- 激活源表 { source_name = expiry_time or nil }
    self.linger_task = nil     -- 脱离延续计时器
    self.gestalts = {}         -- 当前跟随的月灵实体列表
    self.behaviour_level = 1   -- 当前月灵行为等级
    self.speed_penalty = 0     -- 当前移速惩罚
    self._virtual_pct = nil    -- 启蒙期间虚拟sanity百分比（nil=用真实值）
end)

-- 获取启蒙百分比（= 理智百分比）
-- 注意：必须直接读 sanity.current / sanity.max 原始值
-- 不能使用 sanity:GetPercent()，因为外部已经 hook 了 GetPercent 使其在启蒙期间返回 1.0
function Enlightenment:GetPercent()
    local sanity = self.inst.components.sanity
    if not sanity then return 0 end
    return sanity.current / sanity.max
end

function Enlightenment:IsEnabled()
    return self.enabled
end

-- 清空玩家附近的暗影生物（启蒙期间不应存在影怪）
-- 返回清除数量
local SHADOW_MONSTER_TAGS = {"shadow", "shadowcreature", "monster"}
local SHADOW_MONSTER_PREFABS = {
    "crawlingnightmare",
    "nightmarebeak",
    "terrorbeak",
    -- DS 洞穴噩梦版本
    "crawlingnightmare_cave",
    "nightmarebeak_cave",
    "terrorbeak_cave",
}

function Enlightenment:_DespawnShadowMonsters()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local killed = 0
    -- 搜索通用shadow标签的实体
    local ents = TheSim:FindEntities(x, y, z, 30, SHADOW_MONSTER_TAGS, {"brightmare_gestalt", "gestalt"})
    for _, ent in ipairs(ents) do
        if ent:IsValid() then
            killed = killed + 1
            if ent.components.health then
                ent.components.health:Kill()
            else
                ent:Remove()
            end
        end
    end
    -- 补充按prefab名搜索（通用tag未覆盖的情况）
    for _, prefab in ipairs(SHADOW_MONSTER_PREFABS) do
        local entities = TheSim:FindEntities(x, y, z, 30, nil, nil, {prefab})
        for _, ent in ipairs(entities) do
            if ent:IsValid() then
                killed = killed + 1
                if ent.components.health then
                    ent.components.health:Kill()
                else
                    ent:Remove()
                end
            end
        end
    end
    if killed > 0 then
        -- DespawnShadowMonsters diagnostics removed
    end
end

-- 核心：进入启蒙状态
function Enlightenment:Enable(source, duration)
    -- 振荡检测：如果同源刚被 Disable 不到 2 秒就又被 Enable，阻止重新激活
    if source and self._last_disable_time and GetTime() - self._last_disable_time < 2
       and source == self._last_disable_source then
        -- OSCILLATION GUARD: blocked Enable
        return
    end

    -- 快速路径：源已存在且状态无变化时直接返回（避免每秒 tick 刷屏）
    if source and self.sources[source] ~= nil and self.enabled then
        -- 刷新 timed 源的过期时间
        if duration and duration > 0 then
            self.sources[source] = GetTime() + duration
            -- refreshed timer (diagnostic removed)
        end
        return -- 无实际状态变化
    end

    -- 记录激活源
    if source then
        if duration and duration > 0 then
            self.sources[source] = GetTime() + duration
            -- source='..duration=.. (timed)
        else
            self.sources[source] = true -- true = 永久源（不会被 pairs 跳过）
            -- source='..duration=permanent
        end
    end

    -- 打印当前所有源（诊断已移除）
    local src_list = ""
    for k, v in pairs(self.sources) do
        if v == true then src_list = src_list .. k .. "(perm),"
        else src_list = src_list .. k .. "(exp=" .. string.format("%.1f", v) .. "),"
        end
    end
    -- Enable: sources diagnostic removed

    -- 取消脱离延续计时
    if self.linger_task then
        self.linger_task:Cancel()
        self.linger_task = nil
        -- Enable: cancelled linger_task
    end

    -- 恢复 behaviour_level（可能在 Disable 中被设为 0，即使没有 linger_task 也需要恢复）
    -- 限制在 source ~= nil 时，避免意外恢复
    if source and self.behaviour_level <= 0 then
        self.behaviour_level = 1
        -- Enable: restored behaviour_level
    end

    if self.enabled then
        -- Enable: already enabled, skip (just refreshed source)
        return
    end
    self.enabled = true

    local sanity = self.inst.components.sanity
    -- >>> ENABLED <<< diagnostics removed

    -- 清空已有暗影生物（启蒙状态下不应有影怪）
    self:_DespawnShadowMonsters()

    self.inst:PushEvent("enlightenment_enabled")
    -- Enable: pushed event (diagnostic removed)

    -- 文字提示
    if self.inst.components.talker then
        self.inst.components.talker:Say(ANNOUNCE_ENLIGHTENMENT_START or "月光的力量在体内涌动...")
    end
end

-- 核心：离开启蒙状态（带延续延迟）
function Enlightenment:Disable(source)
    -- 快速路径：源不存在时直接返回
    if source and self.sources[source] == nil then
        return
    end

    -- Disable: diagnostics removed
    self._last_disable_time = GetTime()  -- 振荡检测用
    self._last_disable_source = source  -- 记录源名称，用于振荡检测
    if source then
        self.sources[source] = nil
        -- Disable: removed source (diagnostic removed)
    end

    -- 已完全退出，忽略后续 Disable 调用（防止 _DoDisable 后循环创建 linger）
    if not self.enabled then
        -- Disable: already not enabled, skip
        return
    end

    -- 检查是否还有激活源
    local now = GetTime()
    local has_source = false
    local src_list = ""
    for k, expiry in pairs(self.sources) do
        if expiry == true then
            src_list = src_list .. k .. "(perm),"
        else
            src_list = src_list .. k .. "(rem=" .. string.format("%.1f", expiry - now) .. "s),"
        end
        if expiry == true or expiry > now then
            has_source = true
        end
    end
    -- Disable: remaining_sources diagnostic removed

    -- 清理过期源
    for k, expiry in pairs(self.sources) do
        if expiry ~= true and expiry ~= nil and expiry <= now then
            -- Disable: cleaning expired source (diagnostic removed)
            self.sources[k] = nil
        end
    end

    -- 无论是否还有其他源（如 lunar_combat），只要有一个源被移除就立即停止月灵生成
    -- 否则 gestalt 继续攻击 → 刷新 lunar_combat → 死循环永远不退出
    if #self.gestalts > 0 then
        -- Disable: immediately despawning gestalts
        self:_DespawnAllGestalts()
    end
    self.behaviour_level = 0

    if has_source then
        -- Disable: still has active source, not fully disabling
        return
    end

    -- 无激活源 → 启动延续计时（给玩家短暂缓冲重新进入启蒙区域）
    if not self.linger_task then
        local linger = TUNING.ENLIGHTENMENT_LINGER_TIME or 5
        local start_time = GetTime()
        self.linger_task = self.inst:DoTaskInTime(linger, function()
            local elapsed = GetTime() - start_time
            -- Linger expired diagnostics removed
            self:_DoDisable()
        end)
        -- Disable: no sources, started linger timer
    else
        -- Disable: linger_task already active, NOT creating new one
    end
end

function Enlightenment:_DoDisable()
    -- _DoDisable: linger expired, attempting to disable...
    self.linger_task = nil
    if not self.enabled then
        -- _DoDisable: already disabled, skip
        return
    end
    self.enabled = false
    self.behaviour_level = 1
    self.speed_penalty = 0

    local sanity = self.inst.components.sanity
    -- >>> DISABLED <<< diagnostics removed

    -- 清除所有月灵
    -- _DoDisable: despawning gestalts
    self:_DespawnAllGestalts()

    -- 立即停止 sanity regen（在推送事件之前停止，避免事件处理器再次添加）
    if sanity then
        local had_custom_rate = sanity.custom_rate_fn ~= nil
        sanity.custom_rate_fn = self.inst._saved_custom_rate_fn
        self.inst._saved_custom_rate_fn = nil
        -- _DoDisable: restored custom_rate_fn
    end

    -- 强制 sanitymonsterspawner 立即按实际理智重新评估
    local spawner = self.inst.components.sanitymonsterspawner
    if spawner then
        spawner.popchangetimer = 0
        spawner.spawntimer = 0
        spawner:UpdateMonsters(0)
        -- _DoDisable: spawner force-updated
    end

    -- 不推 goinsane/gosane 事件，避免退出启蒙后图标永久变红
    self.inst:PushEvent("enlightenment_disabled")
    -- _DoDisable: pushed event (diagnostic removed)

    -- 验证：检查 sanity 覆写是否仍处于激活状态
    if self.inst and self.inst.components.sanity then
        local san = self.inst.components.sanity
        local still_overridden = (san.GetPercent ~= nil and san._GetPercent ~= nil and san.GetPercent ~= san._GetPercent)
            or (san.IsCrazy ~= nil and san._IsCrazy ~= nil and san.IsCrazy ~= san._IsCrazy)
        -- _DoDisable: sanity overrides diagnostic removed
    end

    -- 验证：月灵是否完全清除
    -- _DoDisable: gestalt count diagnostic removed

    -- 文字提示
    if self.inst.components.talker then
        self.inst.components.talker:Say(ANNOUNCE_ENLIGHTENMENT_END or "启蒙的感觉消退了")
    end
end

-- 阈值检查与事件触发（由外部周期调用，读 sanity 百分比）
local _ct_diag_counter = 0
function Enlightenment:CheckThresholds()
    if not self.enabled then
        _ct_diag_counter = _ct_diag_counter + 1
        if _ct_diag_counter % 30 == 1 then
            -- CheckThresholds: SKIP (not enabled)
        end
        return
    end
    -- linger 期间不生成月灵（Disable 已设置 behaviour_level=0）
    if self.behaviour_level <= 0 then
        _ct_diag_counter = _ct_diag_counter + 1
        if _ct_diag_counter % 15 == 1 then
            -- CheckThresholds: SKIP (behaviour_level=0, linger mode)
        end
        return
    end
    local pct = self:GetPercent()
    _ct_diag_counter = _ct_diag_counter + 1
    -- 每 5 秒打印一次状态摘要（诊断已移除）
    if _ct_diag_counter % 5 == 1 then
        -- CheckThresholds: pct/level/gestalts diagnostic removed
    end

    local new_level = 0
    if pct >= (TUNING.ENLIGHTENMENT_THRESH_LEVEL3 or 0.9) then
        new_level = 3
    elseif pct >= (TUNING.ENLIGHTENMENT_THRESH_LEVEL2 or 0.8) then
        new_level = 2
    elseif pct >= (TUNING.ENLIGHTENMENT_THRESH_SPAWN or 0.6) then
        new_level = 1
    end

    -- 更新月灵行为等级
    if new_level ~= self.behaviour_level then
        -- CheckThresholds: level changed diagnostic removed
        self.behaviour_level = new_level
        -- 同步所有现存月灵的行为等级 + 强制 brain 刷新
        for _, g in ipairs(self.gestalts) do
            if g:IsValid() then
                g.behaviour_level = new_level
                -- 强制 brain 重新评估（BT 默认 tick 较慢，手动刷新）
                if g.brain and g.brain.bt then
                    g.brain.bt:ForceUpdate() -- DS BT 无 RunTick，用 ForceUpdate 代替
                end
            end
        end
        -- 移速惩罚
        self.speed_penalty = new_level >= 3 and (TUNING.ENLIGHTENMENT_SPEED_PENALTY_L3 or 0.2)
                          or new_level >= 2 and (TUNING.ENLIGHTENMENT_SPEED_PENALTY_L2 or 0.1)
                          or 0
    end

    -- 生成月灵
    local spawn_thresh = TUNING.ENLIGHTENMENT_THRESH_SPAWN or 0.6
    if pct >= spawn_thresh and #self.gestalts < (TUNING.ENLIGHTENMENT_MAX_GESTALTS or 3) then
        -- SPAWN gestalt diagnostic removed
        self:_TrySpawnGestalt()
    end

    -- 低于生成阈值时清除月灵
    if pct < spawn_thresh and #self.gestalts > 0 then
        -- DESPAWN gestalts diagnostic removed
        self:_DespawnAllGestalts()
    end
end

-- 尝试在玩家附近生成一只月灵
function Enlightenment:_TrySpawnGestalt()
    local max = TUNING.ENLIGHTENMENT_MAX_GESTALTS or 3
    if #self.gestalts >= max then return end

    local spawn_dist = TUNING.GESTALT_SPAWN_DIST or 14
    local spawn_var = TUNING.GESTALT_SPAWN_DIST_VAR or 3
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local angle = math.random() * 2 * PI
    local dist = spawn_dist + math.random() * spawn_var
    local sx = x + math.cos(angle) * dist
    local sz = z - math.sin(angle) * dist

    local gestalt_ok, gestalt_or_err = pcall(SpawnPrefab, "gestalt")
    if gestalt_ok and gestalt_or_err then
        local gestalt = gestalt_or_err
        gestalt.Transform:SetPosition(sx, 0, sz)
        gestalt.behaviour_level = self.behaviour_level
        gestalt.enlightenment_owner = self.inst
        table.insert(self.gestalts, gestalt)
        gestalt:ListenForEvent("onremove", function(g)
            self:_OnGestaltRemoved(g)
        end)
        -- Gestalt spawned successfully (diagnostic removed)
    else
        -- SpawnPrefab('gestalt') FAILED (diagnostic removed)
    end
end

function Enlightenment:_OnGestaltRemoved(g)
    local before = #self.gestalts
    for i, v in ipairs(self.gestalts) do
        if v == g then
            table.remove(self.gestalts, i)
            break
        end
    end
    -- GestaltRemoved: diagnostic removed
end

function Enlightenment:_DespawnAllGestalts()
    local count = #self.gestalts
    for _, g in ipairs(self.gestalts) do
        if g:IsValid() then
            g.sg:GoToState("death")
        end
    end
    self.gestalts = {}
    if count > 0 then
        -- DespawnAllGestalts: cleared
    end
end

-- 清理过期激活源（由外部周期性调用）
function Enlightenment:CleanupExpiredSources()
    local now = GetTime()
    for k, expiry in pairs(self.sources) do
        if expiry ~= true and expiry ~= nil and expiry <= now then
            -- CleanupExpiredSources: source expired
            self.sources[k] = nil
            self:Disable(k)
        end
    end
end

function Enlightenment:OnSave()
    local data = {
        enabled = self.enabled,
        sources = {},
        behaviour_level = self.behaviour_level,
    }
    -- 保存 sources（key=string, value=number/true）
    for k, v in pairs(self.sources) do
        data.sources[k] = v
    end
    -- 保存 lingering 状态（如果 linger_task 存在说明正在退出过程中）
    data.was_lingering = self.linger_task ~= nil
    -- OnSave: diagnostics removed
    return data
end

function Enlightenment:OnLoad(data)
    if not data then return end
    -- OnLoad: enabled diagnostic removed

    -- 恢复 sources
    if data.sources then
        for k, v in pairs(data.sources) do
            self.sources[k] = v
        end
    end
    self.behaviour_level = data.behaviour_level or 1

    -- 恢复启蒙状态
    if data.enabled then
        -- 直接设置 enabled，不走完整 Enable 流程（避免重复推事件、重置 spawner 等）
        -- 因为 OnLoad 时 spawner 还没加载完，推事件可能导致 nil 引用
        self.enabled = true

        -- 取消 linger（存档时如果有 linger，说明正在退出过程中）
        if self.linger_task then
            self.linger_task:Cancel()
            self.linger_task = nil
        end

        -- 清除可能残留的影怪
        self:_DespawnShadowMonsters()

        -- 推迟到下一帧再推事件和设置 regen，此时所有组件都已加载完毕
        self.inst:DoTaskInTime(0, function()
            -- OnLoad: deferred enable - pushing events
            self.inst:PushEvent("enlightenment_enabled")
        end)

        -- OnLoad: restored enlightenment state (deferred event push)
    end
end

return Enlightenment
