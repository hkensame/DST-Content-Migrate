-- enlightenment_triggers.lua - Enlightenment trigger logic
-- Plan B: Moon tile density (main)
-- Plan C: Lunar enemy attack
-- Plan D: Moon food consumption
-- Plan F: Moon altar proximity
--
-- Also fixes:
--   - Shadow monster suppression: hook sanitymonsterspawner.OnUpdate
--   - PostProcessor distortion suppression: hook sanity.OnUpdate

----------------------<Plan B: Moon Tile Density>----------------------

local MOON_TILES = {}
local _scan_diag = { last_ratio = nil }  -- 诊断用：记录上次扫描比率

local function InitMoonTiles()
    if GROUND.METEOR then MOON_TILES[GROUND.METEOR] = true end
    if GROUND.FUNGUSMOON then MOON_TILES[GROUND.FUNGUSMOON] = true end
    if GROUND.ARCHIVE then MOON_TILES[GROUND.ARCHIVE] = true end
    if GROUND.MONKEY_GROUND then MOON_TILES[GROUND.MONKEY_GROUND] = true end
    if GROUND.SHELLBEACH then MOON_TILES[GROUND.SHELLBEACH] = true end
    if GROUND.PEBBLEBEACH then MOON_TILES[GROUND.PEBBLEBEACH] = true end
    -- 诊断：打印所有注册的月亮地皮 ID
    local ids = {}
    for k, v in pairs(MOON_TILES) do table.insert(ids, k) end
    print("[ENLIGHTEN] InitMoonTiles: registered tile IDs = [" .. table.concat(ids, ",") .. "]")
end

local function ScanMoonTileDensity(inst)
    local radius = TUNING.ENLIGHTENMENT_TILE_SCAN_RADIUS or 20
    local x, y, z = inst.Transform:GetWorldPosition()
    local map = GetWorld().Map
    if not map then return false end

    local total = 0
    local moon_count = 0
    local step = 2
    for dx = -radius, radius, step do
        for dz = -radius, radius, step do
            if dx * dx + dz * dz <= radius * radius then
                total = total + 1
                local tile = map:GetTileAtPoint(x + dx, y, z + dz)
                if MOON_TILES[tile] then
                    moon_count = moon_count + 1
                end
            end
        end
    end

    if total == 0 then return false end
    local ratio = moon_count / total

    -- 滞后阈值：已激活时用较低阈值停用，防止月岛边缘抖动
    local enlight = inst.components.enlightenment
    local is_latched = enlight and enlight.sources["tile_density"] ~= nil
    local threshold = is_latched
        and (TUNING.ENLIGHTENMENT_TILE_DISABLE_THRESHOLD or 0.40)  -- 停用阈值
        or (TUNING.ENLIGHTENMENT_TILE_ENABLE_THRESHOLD or 0.60)    -- 激活阈值

    -- 诊断：首次扫描或比率变化时打印
    if _scan_diag.last_ratio == nil or math.abs(ratio - _scan_diag.last_ratio) > 0.05 then
        _scan_diag.last_ratio = ratio
        print(string.format("[ENLIGHTEN] TileScan: moon=%d/%d ratio=%.2f thresh=%.2f pass=%s latched=%s",
            moon_count, total, ratio, threshold, tostring(ratio >= threshold), tostring(is_latched)))
    end
    return ratio >= threshold
end

----------------------<Plan C: Lunar Enemy Attack>----------------------

local LUNAR_ENEMY_TAGS = {"brightmare_gestalt", "lunar_aligned"}

local function OnPlayerAttacked(inst, data)
    if not inst.components.enlightenment then return end
    local attacker = data and data.attacker
    if not attacker then return end
    for _, tag in ipairs(LUNAR_ENEMY_TAGS) do
        if attacker:HasTag(tag) then
            print(string.format("[ENLIGHTEN] LunarCombat: attacked by '%s' (tag=%s)", tostring(attacker.prefab), tag))
            inst.components.enlightenment:Enable("lunar_combat", TUNING.ENLIGHTENMENT_COMBAT_DURATION or 10)
            return
        end
    end
end

----------------------<Plan D: Moon Food>----------------------

local MOON_FOODS = {
    moon_mushroom = true,
    moon_cap = true,
    moon_tree_blossom = true,
}

local function OnPlayerEat(inst, data)
    if not inst.components.enlightenment then return end
    local food = data and data.food
    if not food then return end
    if MOON_FOODS[food.prefab] then
        print(string.format("[ENLIGHTEN] MoonFood: ate '%s'", tostring(food.prefab)))
        inst.components.enlightenment:Enable("moon_food", TUNING.ENLIGHTENMENT_FOOD_DURATION or 30)
    end
end

----------------------<Plan F: Moon Altar Proximity>----------------------

local MOON_ALTAR_PREFABS = {
    moon_altar = true,
    moon_altar_idol = true,
    moon_altar_glass = true,
    moon_altar_seed = true,
    moon_altar_crown = true,
    moon_altar_ward = true,
    moon_altar_icon = true,
    moon_altar_cosmic = true,
    moon_altar_astral = true,
}

local ALTAR_RANGE = 5

local function IsNearMoonAltar(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, ALTAR_RANGE)
    for _, v in ipairs(ents) do
        if MOON_ALTAR_PREFABS[v.prefab] then
            return true
        end
    end
    return false
end

----------------------<Sanity Regen Injection>----------------------

local function EnableEnlightenmentRegen(inst)
    local sanity = inst.components.sanity
    if not sanity then
        print("[ENLIGHTEN] EnableRegen: no sanity component!")
        return
    end
    -- 固定回复 6/60 san/s，加在原生 rate 之上（不替换光照/装备/天气等因素）
    local regen = TUNING.ENLIGHTENMENT_SANITY_REGEN or (6/60)
    inst._saved_custom_rate_fn = sanity.custom_rate_fn
    local had_prev = sanity.custom_rate_fn ~= nil
    sanity.custom_rate_fn = function(inst)
        local base = inst._saved_custom_rate_fn and inst._saved_custom_rate_fn(inst) or 0
        return base + regen
    end
    print(string.format("[ENLIGHTEN] EnableRegen: +%.4f/s sanity regen installed (had_prev_custom=%s)", regen, tostring(had_prev)))
end

local function DisableEnlightenmentRegen(inst)
    local sanity = inst.components.sanity
    if not sanity then
        print("[ENLIGHTEN] DisableRegen: no sanity component!")
        return
    end
    sanity.custom_rate_fn = inst._saved_custom_rate_fn
    inst._saved_custom_rate_fn = nil
    print("[ENLIGHTEN] DisableRegen: custom_rate_fn restored")
end

----------------------<Shadow Monster Suppression (Correct)>----------------------
-- DS uses sanitymonsterspawner which reads sanity:GetPercent() directly
-- The goinsane event handler cannot prevent shadow monster spawning
-- Correct solution: hook sanitymonsterspawner.OnUpdate

-- 暗影生物抑制（虚拟 sanity 视图方案）
-- 不在启蒙期间直接 return，否则会断 spawner 计时器链，导致退出后暗影生物永久消失
-- 虚拟 sanity 视图（sanity:GetPercent/IsCrazy override）已让 spawner 自动读到满理智
-- 所以 targetpop=0，不会有生物生成，但计时器链正常运转
-- 参见下方 HookSanityOnUpdate 中的 sanity.GetPercent 和 sanity.IsCrazy 覆写
-- 这个 hook 改为仅做防御性保护，不阻断 OnUpdate

----------------------<PostProcessor Distortion Suppression>----------------------
-- DS sanity.OnUpdate sets PostProcessor EVERY frame:
--   self.fxtime = self.fxtime + dt*speed
--   PostProcessor:SetEffectTime(self.fxtime)
--   PostProcessor:SetDistortionFactor(distortion_value)
--
-- AddComponentPostInit("sanity") may NOT fire for the player's already-existing
-- sanity component. So we also install the hook directly in InstallEnlightenment
-- via AddPlayerPostInit (see below).

local function HookSanityOverrides(sanity)
    -- 虚拟 sanity 视图：启蒙期间对外部系统报告满理智
    -- 这样所有下游系统（sanitymonsterspawner、stategraph 握头、camera 抖动、
    -- sound 恐怖音效、red tendrils 红色边框等）全都自动不触发
    -- 自动兼容所有 mod 角色，因为所有 stategraph 都读 sanity:GetPercent()
    if not sanity then return end
    -- [FIX] 防止双重重置（既有从 HookSanityOnUpdate 调用，又有 AddComponentPostInit）
    if sanity._enlightenment_override_hooked then return end
    sanity._enlightenment_override_hooked = true
    
    -- [A] Override GetPercent: 启蒙期间报告 1.0（满理智）
    -- 注意：enlightenment:GetPercent() 直接读 sanity.current/sanity.max 不受影响
    -- 注意：DS 的 GetPercent(usepenalty) 有可选参数，需用 ... 透传
    -- 注意：用 behaviour_level > 0 而非 IsEnabled()，因为 linger 期间
    --       (behaviour_level=0, enabled=true) 应暴露真实理智让 spawner 积累压力
    local _GetPercent = sanity.GetPercent
    sanity.GetPercent = function(self, ...)
        local enlight = self.inst and self.inst.components.enlightenment
        if enlight and enlight:IsEnabled() and enlight.behaviour_level > 0 then
            return 1.0
        end
        return _GetPercent(self, ...)
    end
    
    -- [B] Override IsCrazy: 启蒙期间报告 false（不疯狂）
    local _IsCrazy = sanity.IsCrazy
    sanity.IsCrazy = function(self, ...)
        local enlight = self.inst and self.inst.components.enlightenment
        if enlight and enlight:IsEnabled() and enlight.behaviour_level > 0 then
            return false
        end
        return _IsCrazy(self, ...)
    end

    -- [C] Override IsSane: 启蒙期间报告 true（理智）
    -- 防止低san时播放摸头动画（SGwilson idle 检查 IsSane）
    local _IsSane = sanity.IsSane
    sanity.IsSane = function(self, ...)
        local enlight = self.inst and self.inst.components.enlightenment
        if enlight and enlight:IsEnabled() and enlight.behaviour_level > 0 then
            return true
        end
        return _IsSane(self, ...)
    end
end

local function HookSanityOnUpdate(sanity)
    if not sanity or sanity._enlightenment_hooked then return end
    sanity._enlightenment_hooked = true
    
    -- 先安装虚拟 sanity 视图
    HookSanityOverrides(sanity)
    
    local _SanityOnUpdate = sanity.OnUpdate
    local _pp_diag_count = 0
    local _was_enlightened = false
    sanity.OnUpdate = function(self, dt)
        local is_enlight = self.inst and self.inst.components.enlightenment
           and self.inst.components.enlightenment:IsEnabled()

        -- Log state transitions
        if is_enlight and not _was_enlightened then
            print("[ENLIGHTEN] SanityOnUpdate: transition INTO enlightenment")
            _was_enlightened = true
        elseif not is_enlight and _was_enlightened then
            print("[ENLIGHTEN] SanityOnUpdate: transition OUT OF enlightenment")
            _was_enlightened = false
        end

        if is_enlight then
            -- [0] Force sane flag: DS sanity:DoDelta() reads self.current/self.max
            -- directly (bypassing GetPercent override) and pushes goinsane when
            -- sanity drops below BECOME_INSANE_THRESH. Prevent this by keeping
            -- self.sane=true during enlightenment.
            if not self.sane then
                self.sane = true
                self.inst:PushEvent("gosane")
                print("[ENLIGHTEN] SanityOnUpdate: forced sane=true + gosane")
            end

            -- During enlightenment: 
            -- 1. Reset fxtime to prevent accumulation (否则退出时跳变)
            self.fxtime = 0
            -- 2. Keep Recalc running so sanity still changes
            if self.inst.components.health.invincible ~= true
               and not self.inst.is_teleporting then
                self:Recalc(dt)
            end
            -- 3. Full suppress all PostProcessor low-sanity effects
            if PostProcessor then
                PostProcessor:SetEffectTime(0)
                PostProcessor:SetDistortionFactor(1)  -- 1 = 无扭曲 (0 = 最大波浪)
                PostProcessor:SetDistortionRadii(0, 1) -- 内外半径相同 = 无波浪区域
                _pp_diag_count = _pp_diag_count + 1
                if _pp_diag_count <= 3 then
                    print("[ENLIGHTEN] PostProcessor suppressed (frame " .. _pp_diag_count .. ")")
                end
            end
        else
            _SanityOnUpdate(self, dt)
        end
    end
end

-- Backup hook via AddComponentPostInit (fires for NEW sanity components)
AddComponentPostInit("sanity", function(self)
    HookSanityOnUpdate(self)
end)

-- 单独的 AddComponentPostInit 也已确保虚拟 sanity 视图覆盖新组件
-- 注意：HookSanityOverrides 内部已有 _enlightenment_override_hooked 防双重安装
AddComponentPostInit("sanity", function(self)
    HookSanityOverrides(self)
end)

----------------------<ColourCube Insanity CC Suppression>----------------------
-- colourcubemanager.OnUpdate sets PostProcessor:SetColourCubeLerp(1, san)
-- EVERY frame based on sanity:GetPercent(). This applies the "insane" colour
-- grading (insane_day_cc / insane_dusk_cc / insane_night_cc) as a screen tint.
-- This is a SEPARATE PostProcessor channel from the distortion effects.
-- Must hook this too to fully suppress low-sanity visuals.
--
-- Exit fallback: smooth 1s transition from 0 → actual san value to avoid
-- a harsh visual snap when enlightenment ends.

AddComponentPostInit("colourcubemanager", function(self)
    local _CCMOnUpdate = self.OnUpdate
    local was_enlightened = false
    local cc_transition = 0   -- current override lerp value (0 = suppressed)
    local CC_FADE_SPEED = 1.0 -- 1 second to fully fade in

    self.OnUpdate = function(self, dt)
        _CCMOnUpdate(self, dt)

        local player = GetPlayer()
        local enlight = player and player.components.enlightenment
        local is_enlightened = enlight and enlight:IsEnabled()

        if is_enlightened then
            -- During enlightenment: suppress insanity CC entirely
            PostProcessor:SetColourCubeLerp(1, 0)
            cc_transition = 0
            if not was_enlightened then
                print("[ENLIGHTEN] CC: suppressing insanity colour cube")
            end
            was_enlightened = true
        elseif was_enlightened then
            -- Exiting enlightenment: smooth fade from 0 → actual san value
            local san = 1 - (player.components.sanity and player.components.sanity:GetPercent() or 1)
            cc_transition = math.min(cc_transition + dt * CC_FADE_SPEED, 1)
            local lerp_val = san * cc_transition
            PostProcessor:SetColourCubeLerp(1, lerp_val)
            if cc_transition >= 1 then
                was_enlightened = false -- transition complete, let normal code handle it
                print(string.format("[ENLIGHTEN] CC: fade complete, san_pct=%.2f", 1 - san))
            end
        end
        -- When !was_enlightened && !is_enlightened: original OnUpdate handles it
    end
end)

----------------------<Main Update Loop>----------------------

print("[ENLIGHTEN] enlightenment_triggers.lua loaded successfully")

local SCAN_INTERVAL = 1.0
local _enlighten_diag_tick = 0

local function EnlightenmentUpdate(inst)
    local enlight = inst.components.enlightenment
    if not enlight then
        if _enlighten_diag_tick < 5 then
            print("[ENLIGHTEN] EnlightenmentUpdate: no enlightenment component!")
            _enlighten_diag_tick = _enlighten_diag_tick + 1
        end
        return
    end

    -- 诊断日志（每 10 秒打印一次，避免刷屏）
    _enlighten_diag_tick = _enlighten_diag_tick + SCAN_INTERVAL
    if _enlighten_diag_tick >= 10 then
        _enlighten_diag_tick = 0
        local pct = enlight:GetPercent()
        local enabled = enlight:IsEnabled()
        local sources = ""
        for k, v in pairs(enlight.sources) do sources = sources .. k .. "," end
        print(string.format("[ENLIGHTEN] tick: enabled=%s pct=%.2f gestalts=%d sources=[%s]",
            tostring(enabled), pct, #enlight.gestalts, sources))
    end

    local ok, err = pcall(function()
        enlight:CleanupExpiredSources()

        -- Plan B: Tile density
        local tile_pass = ScanMoonTileDensity(inst)
        if tile_pass then
            enlight:Enable("tile_density")
        else
            enlight:Disable("tile_density")
        end

        -- Plan F: Moon altar
        local altar_pass = IsNearMoonAltar(inst)
        if altar_pass then
            enlight:Enable("moon_altar")
        else
            enlight:Disable("moon_altar")
        end

        print(string.format("[ENLIGHTEN] tick: tile=%s altar=%s enabled=%s gestalts=%d",
            tostring(tile_pass), tostring(altar_pass), tostring(enlight:IsEnabled()), #enlight.gestalts))

        enlight:CheckThresholds()
    end)
    if not ok then
        print("[ENLIGHTEN] EnlightenmentUpdate ERROR: " .. tostring(err))
    end
end

----------------------<Install to Player>----------------------

local function InstallEnlightenment(inst)
    print("[ENLIGHTEN] InstallEnlightenment called for " .. tostring(inst.prefab))
    if inst.components.enlightenment then
        print("[ENLIGHTEN] enlightenment component already exists, skipping")
        return
    end

    InitMoonTiles()
    local count = 0
    for k, v in pairs(MOON_TILES) do count = count + 1 end
    print("[ENLIGHTEN] MoonTiles initialized, count=" .. tostring(count))

    local ok, err = pcall(function()
        inst:AddComponent("enlightenment")
    end)
    if not ok then
        print("[ENLIGHTEN] AddComponent('enlightenment') FAILED: " .. tostring(err))
        return
    end
    print("[ENLIGHTEN] enlightenment component added successfully")

    -- Directly hook the player's sanity OnUpdate to suppress PostProcessor distortion
    -- (AddComponentPostInit may not fire for already-existing components)
    if inst.components.sanity then
        HookSanityOnUpdate(inst.components.sanity)
        print("[ENLIGHTEN] Sanity OnUpdate hooked")
    else
        print("[ENLIGHTEN] WARNING: player has no sanity component!")
    end

    inst:ListenForEvent("enlightenment_enabled", function()
        EnableEnlightenmentRegen(inst)
    end)

    inst:ListenForEvent("enlightenment_disabled", function()
        DisableEnlightenmentRegen(inst)
    end)

    inst:ListenForEvent("attacked", OnPlayerAttacked)
    inst:ListenForEvent("oneat", OnPlayerEat)
    inst:ListenForEvent("oneatsomething", OnPlayerEat)

    inst:DoPeriodicTask(SCAN_INTERVAL, EnlightenmentUpdate)
    print("[ENLIGHTEN] Periodic task installed, system ready")
end

AddPlayerPostInit(InstallEnlightenment)
print("[ENLIGHTEN] AddPlayerPostInit registered")
