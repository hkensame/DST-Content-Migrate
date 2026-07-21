-- ==================== DS 原版暴动预制体延迟注册 ====================
-- DS 原版 nightmarelight/fissure/statue 在 fn() 构造时调用 GetNightmareClock()，
-- 此时 dst_nightmareclock 尚未添加到 TheWorld，导致条件失败不注册 phasechange 监听。
-- 通过 AddPrefabPostInit 在组件就绪后重新注入事件监听和初始同步。

-- 暴动灯 nightmarelight：calm→关闭，warn→微光，nightmare→全开+刷怪，dawn→关闭过渡
AddPrefabPostInit("common/objects/nightmarelight", function(inst)
    inst:DoTaskInTime(0, function()
        local clock = GetNightmareClock()
        if not clock then return end
        local theWorld = GetWorld()
        if not theWorld then return end

        local function _spawnfx()
            if not inst.fx then
                inst.fx = SpawnPrefab("nightmarelightfx")
                if inst.fx then
                    local pt = inst:GetPosition()
                    inst.fx.Transform:SetPosition(pt.x, -0.1, pt.z)
                end
            end
        end

        local function _turnoff(light)
            if light then light:Enable(false) end
        end

        local function _ReturnChildren()
            if not inst.components.childspawner then return end
            for k, child in pairs(inst.components.childspawner.childrenoutside) do
                if child.components.combat then child.components.combat:SetTarget(nil) end
                if child.components.lootdropper then child.components.lootdropper:SetLoot({}) end
                if child.components.health then child.components.health:Kill() end
            end
        end

        local function _applyState(phase, instant)
            _spawnfx()
            local fx = inst.fx
            local t = instant and 0 or 1
            local tt = instant and 0 or 0.5
            if phase == "calm" then
                inst.SoundEmitter:KillSound("warnLP")
                inst.SoundEmitter:KillSound("nightmareLP")
                inst.Light:Enable(true)
                inst.components.lighttweener:StartTween(nil, 0, nil, nil, nil, t, _turnoff)
                if instant then
                    inst.AnimState:PlayAnimation("idle_closed")
                    if fx then fx.AnimState:PlayAnimation("idle_closed") end
                else
                    inst.AnimState:PushAnimation("close_2")
                    inst.AnimState:PushAnimation("idle_closed")
                    if fx then
                        fx.AnimState:PushAnimation("close_2")
                        fx.AnimState:PushAnimation("idle_closed")
                    end
                    inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_close")
                end
                if inst.components.childspawner then
                    inst.components.childspawner:StopSpawning()
                    inst.components.childspawner:StartRegen()
                    _ReturnChildren()
                end
            elseif phase == "warn" then
                inst.Light:Enable(true)
                inst.components.lighttweener:StartTween(nil, 3, nil, nil, nil, tt)
                inst.AnimState:PlayAnimation("open_1")
                if fx then fx.AnimState:PlayAnimation("open_1") end
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_warning")
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_warning_LP", "warnLP")
            elseif phase == "nightmare" then
                inst.SoundEmitter:KillSound("warnLP")
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_LP", "nightmareLP")
                inst.Light:Enable(true)
                inst.components.lighttweener:StartTween(nil, 6, nil, nil, nil, tt)
                if instant then
                    inst.AnimState:PlayAnimation("idle_open")
                    if fx then fx.AnimState:PlayAnimation("idle_open") end
                else
                    inst.AnimState:PlayAnimation("open_2")
                    inst.AnimState:PushAnimation("idle_open")
                    if fx then
                        fx.AnimState:PlayAnimation("open_2")
                        fx.AnimState:PushAnimation("idle_open")
                    end
                    inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open")
                end
                if inst.components.childspawner then
                    inst.components.childspawner:StartSpawning()
                    inst.components.childspawner:StopRegen()
                end
            elseif phase == "dawn" then
                inst.SoundEmitter:KillSound("nightmareLP")
                inst.Light:Enable(true)
                inst.components.lighttweener:StartTween(nil, 3, nil, nil, nil, tt)
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_close")
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_LP", "nightmareLP")
                inst.AnimState:PlayAnimation("close_1")
                if fx then fx.AnimState:PlayAnimation("close_1") end
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open")
                if inst.components.childspawner then
                    inst.components.childspawner:StartSpawning()
                    inst.components.childspawner:StopRegen()
                end
            end
        end

        -- 注册 phasechange 事件监听
        inst:ListenForEvent("phasechange", function(world, data)
            if POPULATING then return end
            local phase = data and data.newphase
            if not phase then return end
            inst.rockstate = phase
            inst:DoTaskInTime(math.random() * 2, _applyState, phase, false)
        end, theWorld)

        -- 初始同步到当前阶段
        local phase = clock:GetPhase()
        inst.rockstate = phase
        _applyState(phase, true)
    end)
end)

-- 下层裂隙 fissure_lower（上层 fissure 有自己的独立周期，不依赖暴动时钟）
AddPrefabPostInit("cave/objects/fissure_lower", function(inst)
    inst:DoTaskInTime(0, function()
        local clock = GetNightmareClock()
        if not clock then return end
        local theWorld = GetWorld()
        if not theWorld then return end

        local function _spawnfx()
            if not inst.fx then
                inst.fx = SpawnPrefab("nightmarefissurefx")
                if inst.fx then
                    local pt = inst:GetPosition()
                    inst.fx.Transform:SetPosition(pt.x, -0.1, pt.z)
                end
            end
        end

        local function _turnoff(light)
            if light then light:Enable(false) end
        end

        local function _applyFissureState(phase, instant)
            _spawnfx()
            local fx = inst.fx
            local t = instant and 0 or 0.33
            local tt = instant and 0 or 0.5
            if phase == "calm" then
                inst.SoundEmitter:KillSound("loop")
                RemovePhysicsColliders(inst)
                inst.Light:Enable(true)
                inst.components.lighttweener:StartTween(nil, 0, nil, nil, nil, t, _turnoff)
                if instant then
                    inst.AnimState:PlayAnimation("idle_closed")
                    if fx then fx.AnimState:PlayAnimation("idle_closed") end
                else
                    inst.AnimState:PushAnimation("close_2")
                    inst.AnimState:PushAnimation("idle_closed")
                    if fx then
                        fx.AnimState:PushAnimation("close_2")
                        fx.AnimState:PushAnimation("idle_closed")
                    end
                    inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_close")
                end
                if inst.components.childspawner then
                    inst.components.childspawner:StopSpawning()
                    inst.components.childspawner:StartRegen()
                    for k, child in pairs(inst.components.childspawner.childrenoutside) do
                        if child.components.combat then child.components.combat:SetTarget(nil) end
                        if child.components.lootdropper then child.components.lootdropper:SetLoot({}) end
                        if child.components.health then child.components.health:Kill() end
                    end
                end
            elseif phase == "warn" then
                ChangeToObstaclePhysics(inst)
                inst.Light:Enable(true)
                inst.components.lighttweener:StartTween(nil, 2, nil, nil, nil, tt)
                inst.AnimState:PlayAnimation("open_1")
                if fx then fx.AnimState:PlayAnimation("open_1") end
                inst.SoundEmitter:KillSound("loop")
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open_warning")
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open_LP", "loop")
            elseif phase == "nightmare" then
                ChangeToObstaclePhysics(inst)
                inst.Light:Enable(true)
                inst.components.lighttweener:StartTween(nil, 5, nil, nil, nil, tt)
                inst.SoundEmitter:KillSound("loop")
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open")
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open_LP", "loop")
                if instant then
                    inst.AnimState:PlayAnimation("idle_open")
                    if fx then fx.AnimState:PlayAnimation("idle_open") end
                else
                    inst.AnimState:PlayAnimation("open_2")
                    inst.AnimState:PushAnimation("idle_open")
                    if fx then
                        fx.AnimState:PlayAnimation("open_2")
                        fx.AnimState:PushAnimation("idle_open")
                    end
                    inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open")
                end
                if inst.components.childspawner then
                    inst.components.childspawner:StartSpawning()
                    inst.components.childspawner:StopRegen()
                end
            elseif phase == "dawn" then
                ChangeToObstaclePhysics(inst)
                inst.Light:Enable(true)
                inst.components.lighttweener:StartTween(nil, 2, nil, nil, nil, tt)
                inst.SoundEmitter:KillSound("loop")
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open")
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open_LP", "loop")
                inst.AnimState:PlayAnimation("close_1")
                if fx then fx.AnimState:PlayAnimation("close_1") end
                inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open")
                if inst.components.childspawner then
                    inst.components.childspawner:StartSpawning()
                    inst.components.childspawner:StopRegen()
                end
            end
        end

        -- 注册 phasechange 事件监听
        inst:ListenForEvent("phasechange", function(world, data)
            if POPULATING then return end
            local phase = data and data.newphase
            if not phase then return end
            inst.state = phase
            inst:DoTaskInTime(math.random() * 2, _applyFissureState, phase, false)
        end, theWorld)

        -- 初始同步
        local phase = clock:GetPhase()
        inst.state = phase
        _applyFissureState(phase, true)
    end)
end)

-- 远古雕像 ruins_statue：暴动期间切换 _night 动画 + 灯光淡入/淡出 + 过渡特效
-- 完整还原 DS 原版 statueruins.lua 的行为
local _statue_nightmare_prefabs = {
    "ruins_statue_head",
    "ruins_statue_head_nogem",
    "ruins_statue_mage",
    "ruins_statue_mage_nogem",
}
for _, _name in ipairs(_statue_nightmare_prefabs) do
    AddPrefabPostInit(_name, function(inst)
        inst:DoTaskInTime(0, function()
            local theWorld = GetWorld()
            if not theWorld then return end

            -- 取消 DST 原版灯光插值任务（statueruins.lua 的 _lighttask），由我们的系统接管
            if inst._lighttask then
                inst._lighttask:Cancel()
                inst._lighttask = nil
            end

            -- 过渡特效（紫烟 + 光柱）
            local function _DoFx()
                if ExecutingLongUpdate then return end
                inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")
                local fx = SpawnPrefab("statue_transition_2")
                if fx then
                    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    fx.AnimState:SetScale(1, 2, 1)
                end
                fx = SpawnPrefab("statue_transition")
                if fx then
                    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    fx.AnimState:SetScale(1, 1.5, 1)
                end
            end

            -- 灯光淡入（warn 阶段），DST 雕像无 lighttweener，直接控制灯光
            local function _fadeIn()
                if inst.Light then
                    inst.Light:Enable(true)
                    inst.Light:SetRadius(3)
                    inst.Light:SetIntensity(.9)
                    inst.Light:SetFalloff(.9)
                    inst.Light:SetColour(1, 1, 1)
                end
            end

            -- 灯光淡出（calm 阶段）
            local function _fadeOut()
                if inst.Light then
                    inst.Light:SetRadius(0)
                    inst.Light:Enable(false)
                end
            end

            local function _updateStatue(data)
                if inst.fading then return end
                -- 每次调用重新查询时钟，避免初始化时 dst_nightmareclock 尚未添加导致捕获到 nil
                local clock = GetNightmareClock()
                if not clock then return end

                -- 暴动阶段 → 动画后缀 & bloom 特效
                local suffix = ""
                if clock:IsNightmare() then
                    suffix = "_night"
                    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                    if not (data and data.fromwork) then
                        _DoFx()
                    end
                else
                    inst.AnimState:ClearBloomEffectHandle()
                end

                -- 阶段过渡灯光淡入/淡出（参考 DS 原版 ShowState）
                -- 使用 inst.dst_phase 而非 inst.phase 避免与 DS 原版 statueruins.lua
                -- 的 ShowState 函数冲突（DS 原版也在同一雕像上注册了 phasechange 监听）
                if data and data.newphase and inst.dst_phase ~= data.newphase and data.newphase ~= "nightmare" then
                    if data.newphase == "warn" then
                        _fadeIn()
                    elseif data.newphase == "calm" then
                        _fadeOut()
                    else
                        -- dawn：清除 bloom + 过渡特效
                        _DoFx()
                    end
                    inst.dst_phase = data.newphase
                end

                -- 根据耐久度播放对应动画
                local workleft = inst.components.workable.workleft
                if workleft < TUNING.MARBLEPILLAR_MINE * (1/3) then
                    inst.AnimState:PlayAnimation("hit_low" .. suffix, true)
                elseif workleft < TUNING.MARBLEPILLAR_MINE * (2/3) then
                    inst.AnimState:PlayAnimation("hit_med" .. suffix, true)
                else
                    inst.AnimState:PlayAnimation("idle_full" .. suffix, true)
                end
            end

            inst:ListenForEvent("phasechange", function(world, data)
                if POPULATING then return end
                local _c = GetNightmareClock()
                print("[DST_STATUE] phasechange: new="..tostring(data and data.newphase).." dst_phase="..tostring(inst.dst_phase).." clock="..tostring(_c and _c:GetPhase()))
                _updateStatue(data)
            end, theWorld)

            _updateStatue()
            local _init_c = GetNightmareClock()
            print("[DST_STATUE] init done, dst_phase="..tostring(inst.dst_phase).." clock_phase="..tostring(_init_c and _init_c:GetPhase()))
        end)
    end)
end

-- ==================== 暴动 Colour Cube 画面滤镜系统 ====================
-- 使用 PostProcessor 切换全局色彩烘焙（Colour Cube），实现遗迹层暴动色调变化
-- 参考 DS 原版 colourcubemanager.lua：暴动阶段映射 ruins_dark/dim/light_cc.tex
-- 依赖：dst_nightmareclock 组件必须已添加到 TheWorld（由 archive_hooks.lua 负责）

local NIGHTMARE_CC = {
    calm = "images/colour_cubes/ruins_dark_cc.tex",
    warn = "images/colour_cubes/ruins_dim_cc.tex",
    nightmare = "images/colour_cubes/ruins_light_cc.tex",
    dawn = "images/colour_cubes/ruins_dim_cc.tex",
}

local function _initCC(inst, pp, clock)
    print("[DST_CC] Initializing nightmare colour cube filter")

    local _currentCC = nil
    local _blendTimeLeft = 0
    local _totalBlendTime = 0
    local _srcCC = nil
    local _dstCC = nil

    local function _setCC(phase, instant)
        local key = phase == "wild" and "nightmare" or phase
        local ccPath = NIGHTMARE_CC[key]
        if not ccPath or ccPath == _currentCC then return end

        _srcCC = _currentCC or NIGHTMARE_CC.calm
        _dstCC = ccPath
        _currentCC = ccPath

        local blendSecs = instant and 0 or (GLOBAL.TUNING.TRANSITIONTIME and GLOBAL.TUNING.TRANSITIONTIME[string.upper(key)] or 2)
        if blendSecs <= 0 then
            pp:SetColourCubeData(0, _dstCC, _dstCC)
            pp:SetColourCubeLerp(0, 1)
            _blendTimeLeft = 0
        else
            pp:SetColourCubeData(0, _srcCC, _dstCC)
            pp:SetColourCubeLerp(0, 0)
            _totalBlendTime = blendSecs
            _blendTimeLeft = blendSecs
        end
        print(string.format("[DST_CC] phase=%s → cc=%s blend=%.1fs", tostring(phase), ccPath, blendSecs))
    end

    -- 监听 phasechange 事件
    inst:ListenForEvent("phasechange", function(_, data)
        if data and data.newphase then
            _setCC(data.newphase)
        end
    end, inst)

    -- 初始同步到当前阶段
    _setCC(clock:GetPhase(), true)

    -- 每帧推进 blend 插值
    inst:DoPeriodicTask(0, function()
        if _blendTimeLeft > 0 then
            local dt = GLOBAL.FRAMES or 0.033
            _blendTimeLeft = _blendTimeLeft - dt
            if _blendTimeLeft <= 0 then
                pp:SetColourCubeLerp(0, 1)
                _blendTimeLeft = 0
            else
                local t = 1 - _blendTimeLeft / _totalBlendTime
                pp:SetColourCubeLerp(0, math.min(t, 1))
            end
        end
    end)

    print("[DST_CC] Nightmare colour cubes: calm="..NIGHTMARE_CC.calm.." warn="..NIGHTMARE_CC.warn.." nightmare="..NIGHTMARE_CC.nightmare.." dawn="..NIGHTMARE_CC.dawn)
end

AddPrefabPostInit("cave", function(inst)
    inst:DoTaskInTime(0, function()
        -- 仅 DST_CAVE 层级启用
        if not (inst.meta and inst.meta.level_id == "DST_CAVE") then
            return
        end

        local pp = rawget(GLOBAL, "PostProcessor")
        if pp == nil then
            print("[DST_CC] PostProcessor not available, skipping colour cubes")
            return
        end

        -- 确保 dst_nightmareclock 已就绪
        local clock = inst.components.dst_nightmareclock
        if not clock then
            print("[DST_CC] dst_nightmareclock not ready, will retry")
            inst:DoTaskInTime(FRAMES * 5, function()
                local pp2 = rawget(GLOBAL, "PostProcessor")
                local clock2 = inst.components.dst_nightmareclock
                if pp2 and clock2 then
                    _initCC(inst, pp2, clock2)
                end
            end)
            return
        end

        _initCC(inst, pp, clock)
    end)
end)
