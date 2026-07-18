-- ==================== 档案馆 Prefab TheWorld 注入 ====================
-- prefab 沙箱不暴露 GLOBAL/TheWorld，通过 modimport 注入
-- 从 modmain.lua 加载

-- 辅助函数：立即注入 inst.GetTheWorld()
-- DS 中 TheWorld 不可通过 rawget(GLOBAL, "TheWorld") 可靠获取，
-- 因此依赖 _cave_world 缓存（由 cave postinit 设置，modmain.lua 也引用此全局）
_cave_world = nil
local function _injectGetTheWorld(inst)
    inst.GetTheWorld = function() return _cave_world end
end

-- archive_chandelier：注册档案馆电源事件
AddPrefabPostInit("archive_chandelier", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = _cave_world
        if theWorld == nil then return end
        print("[ARCHIVE] archive_chandelier listening for arhivepoweron/off")
        inst:ListenForEvent("arhivepoweron", function() print("[ARCHIVE] archive_chandelier got arhivepoweron"); inst:updatelight() end, theWorld)
        inst:ListenForEvent("arhivepoweroff", function() print("[ARCHIVE] archive_chandelier got arhivepoweroff"); inst:updatelight() end, theWorld)
    end)
end)

-- vault_chandelier：注册保险库玩家进出事件
AddPrefabPostInit("vault_chandelier", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = _cave_world
        if theWorld == nil then return end
        inst:ListenForEvent("ms_vaultroom_vault_playerleft", function() inst:updatelight() end, theWorld)
        inst:ListenForEvent("ms_vaultroom_vault_playerentered", function() inst:updatelight() end, theWorld)
    end)
end)

-- vault_crawler_chandelier：注册保险库玩家进出事件
AddPrefabPostInit("vault_crawler_chandelier", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = _cave_world
        if theWorld == nil then return end
        inst:ListenForEvent("ms_vaultroom_vault_playerleft", function() inst:updatelight() end, theWorld)
        inst:ListenForEvent("ms_vaultroom_vault_playerentered", function() inst:updatelight() end, theWorld)
    end)
end)

-- archive_switch_base：注册电源开/关动画
AddPrefabPostInit("archive_switch_base", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = _cave_world
        if theWorld == nil then return end
        print("[ARCHIVE] archive_switch_base listening for arhivepoweron/off")
        inst:ListenForEvent("arhivepoweron", function()
                print("[ARCHIVE] archive_switch_base: power ON animation")
                inst.AnimState:PlayAnimation("activate", false)
                inst.AnimState:PushAnimation("activate_loop", true)
                inst.SoundEmitter:PlaySound("grotto/common/archive_switch/LP","loop")
            end, theWorld)
        inst:ListenForEvent("arhivepoweroff", function()
                print("[ARCHIVE] archive_switch_base: power OFF animation")
                inst.AnimState:PlayAnimation("deactivate", false)
                inst.AnimState:PushAnimation("idle", true)
                inst.SoundEmitter:KillSound("loop")
            end, theWorld)
    end)
end)

-- archive_portal：注册传送门出口目标
AddPrefabPostInit("archive_portal", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = _cave_world
        if theWorld == nil then return end
        theWorld:PushEvent("ms_register_vault_lobby_exit_target", inst)
    end)
end)

-- archive_ambient_sfx：注册档案馆环境音效事件
AddPrefabPostInit("archive_ambient_sfx", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = _cave_world
        if theWorld == nil then return end
        inst:ListenForEvent("arhivepoweron", function()
                inst.SoundEmitter:PlaySound("grotto/common/archive_on/"..math.random(1,4),"loop")
            end, theWorld)
        inst:ListenForEvent("arhivepoweroff", function()
                inst.SoundEmitter:KillSound("loop")
            end, theWorld)
    end)
end)

-- 将 archivemanager + nightmareclock 组件添加到 DST_CAVE 洞穴世界
-- DS 的世界实体 prefab 名是 "cave" 或 "forest"，不是 "world"
-- ===== 立即注册：archivemanager（电源系统） =====
-- addcomponent 不依赖 meta，必须立即执行，让 OnLoadPostPass 能读到
AddPrefabPostInit("cave", function(inst)
    if not inst.components.archivemanager then
        inst:AddComponent("archivemanager")
        _cave_world = inst
        print("[DST] archivemanager component ADDED to cave (immediate)")
    end
end)

-- ===== 延迟注册：nightmareclock + daywalkerspawner =====
-- 注意：AddPrefabPostInit 触发时 inst.meta 尚未被设置（gamelogic.lua 中 ground.meta=savedata.meta 在之后），
-- 必须延迟到下一帧才能正确读取 meta.level_id
AddPrefabPostInit("cave", function(inst)
    inst:DoTaskInTime(0, function()
        print("[DST] AddPrefabPostInit cave (delayed) - meta="..tostring(inst.meta).." level_id="..(inst.meta and inst.meta.level_id or "nil").." has_archivemanager="..tostring(inst.components.archivemanager))
        if inst.meta and inst.meta.level_id == "DST_CAVE" then
            
            -- 注册 dst_nightmareclock（暴动系统）
            if not inst.components.dst_nightmareclock then
                inst:AddComponent("dst_nightmareclock")
                print("[DST] dst_nightmareclock component ADDED to cave")
            else
                print("[DST] dst_nightmareclock already exists")
            end

            -- DS 原版 gamelogic.lua 也会给 cave 添加 nightmareclock 组件，
            -- 导致两套暴动时钟同时运行，原版预制体访问 .components.nightmareclock 时读的是原版时钟。
            -- 这里禁用原版时钟，并把引用指向 mod 的 dst_nightmareclock。
            local native_clock = inst.components.nightmareclock
            if native_clock then
                if native_clock.task then
                    native_clock.task:Cancel()
                    native_clock.task = nil
                end
                inst:StopUpdatingComponent(native_clock)
                print("[DST] native nightmareclock disabled and replaced with dst_nightmareclock")
            else
                print("[DST] no native nightmareclock found on cave")
            end
            inst.components.nightmareclock = inst.components.dst_nightmareclock

            -- DS 兼容：包装 GetNightmareClock() 以优先返回 dst_nightmareclock
            local orig_GetNightmareClock = GLOBAL.GetNightmareClock
            GLOBAL.GetNightmareClock = function()
                local w = _cave_world
                if w and w.components.dst_nightmareclock then
                    return w.components.dst_nightmareclock
                end
                if orig_GetNightmareClock then
                    return orig_GetNightmareClock()
                end
                return nil
            end

            -- 梦魇疯猪 daywalkerspawner
            if not inst.components.daywalkerspawner then
                inst:AddComponent("daywalkerspawner")
                inst.components.daywalkerspawner:OnPostInit()
                print("[DST] daywalkerspawner component ADDED to cave")
            end

        else
            print("[DST] cave level is NOT DST_CAVE, skipping nightmare clock and daywalkerspawner")
        end
    end)
end)

-- 注入 GetTheWorld（供 prefab runtime 函数调用 TheWorld.components）
AddPrefabPostInit("archive_security_waypoint", _injectGetTheWorld)
AddPrefabPostInit("archive_security_desk", _injectGetTheWorld)
AddPrefabPostInit("archive_switch", _injectGetTheWorld)
AddPrefabPostInit("archive_orchestrina_main", _injectGetTheWorld)
AddPrefabPostInit("archive_orchestrina_small", _injectGetTheWorld)
AddPrefabPostInit("archive_lockbox_dispencer", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = _cave_world
        if theWorld == nil then return end
        local archive = theWorld.components.archivemanager
        local power = archive and archive:GetPowerSetting()
        print("[ARCHIVE] archive_lockbox_dispencer init: power="..tostring(power).." has_archive="..tostring(archive ~= nil))
        if archive and not power then
            inst.components.activatable.inactive = true
            print("[ARCHIVE] archive_lockbox_dispencer: set inactive=true (no power)")
        else
            inst.components.activatable.inactive = false
            print("[ARCHIVE] archive_lockbox_dispencer: set inactive=false (has power)")
        end
        inst:ListenForEvent("arhivepoweron", function()
            print("[ARCHIVE] archive_lockbox_dispencer: arhivepoweron received, setting inactive=false")
            inst.components.activatable.inactive = false
        end, theWorld)
        inst:ListenForEvent("arhivepoweroff", function()
            print("[ARCHIVE] archive_lockbox_dispencer: arhivepoweroff received, setting inactive=true")
            inst.components.activatable.inactive = true
        end, theWorld)
    end)
end)

-- archive_switch：DS 兼容 - 静态布局的 spawnopal 属性在 DS 世界生成时不会传递给实体
-- 因此手动插入 2 颗 opal 宝石（3 个开关中插 2 颗，第 3 颗需要玩家自己找）
-- DST 原版 3 个开关中有 2 个 spawnopal=1，1 个 =0
local _opal_inserted = 0
AddPrefabPostInit("archive_switch", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        print("[ARCHIVE] archive_switch postinit: gem="..tostring(inst.gem).." _opal_inserted=".._opal_inserted)
        if not inst.gem and inst.components.trader and _opal_inserted < 2 then
            local opal = SpawnPrefab("opalpreciousgem")
            if opal then
                inst.components.trader:AcceptGift(nil, opal)
                _opal_inserted = _opal_inserted + 1
                print("[ARCHIVE] auto-inserted opal into archive_switch (total=".._opal_inserted..")")
            end
        else
            print("[ARCHIVE] archive_switch postinit: skip opal insert (gem="..tostring(inst.gem).." trader="..tostring(inst.components.trader).." count=".._opal_inserted..")")
        end
    end)
end)

-- archive_resonator：注入 GetTheWorld（供 scanfordevice 调用 TheWorld:PushEvent）
AddPrefabPostInit("archive_resonator", _injectGetTheWorld)

-- tree_rocks：注入 GetTheWorld（供 GetLootWeightedTable 调用 TheWorld.Map）
AddPrefabPostInit("tree_rocks", _injectGetTheWorld)

-- molebat：注入 GetTheWorld + 注册地震事件（DS 无 TheWorld.net，事件源为 TheWorld 本身）
AddPrefabPostInit("molebat", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = _cave_world
        if theWorld == nil then return end
        inst:ListenForEvent("startquake", function()
            inst._quaking = true
            if inst.components.sleeper then inst.components.sleeper:WakeUp() end
        end, theWorld)
        inst:ListenForEvent("endquake", function()
            inst._quaking = nil
        end, theWorld)
    end)
end)
