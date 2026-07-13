-- ==================== 档案馆 Prefab TheWorld 注入 ====================
-- prefab 沙箱不暴露 GLOBAL/TheWorld，通过 modimport 注入
-- 从 modmain.lua 加载

-- 辅助函数：立即注入 inst.GetTheWorld()
local function _injectGetTheWorld(inst)
    inst.GetTheWorld = function() return rawget(GLOBAL, "TheWorld") end
end

-- archive_chandelier：注册档案馆电源事件
AddPrefabPostInit("archive_chandelier", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = rawget(GLOBAL, "TheWorld")
        if theWorld == nil then return end
        inst:ListenForEvent("arhivepoweron", function() inst:updatelight() end, theWorld)
        inst:ListenForEvent("arhivepoweroff", function() inst:updatelight() end, theWorld)
    end)
end)

-- vault_chandelier：注册保险库玩家进出事件
AddPrefabPostInit("vault_chandelier", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = rawget(GLOBAL, "TheWorld")
        if theWorld == nil then return end
        inst:ListenForEvent("ms_vaultroom_vault_playerleft", function() inst:updatelight() end, theWorld)
        inst:ListenForEvent("ms_vaultroom_vault_playerentered", function() inst:updatelight() end, theWorld)
    end)
end)

-- vault_crawler_chandelier：注册保险库玩家进出事件
AddPrefabPostInit("vault_crawler_chandelier", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = rawget(GLOBAL, "TheWorld")
        if theWorld == nil then return end
        inst:ListenForEvent("ms_vaultroom_vault_playerleft", function() inst:updatelight() end, theWorld)
        inst:ListenForEvent("ms_vaultroom_vault_playerentered", function() inst:updatelight() end, theWorld)
    end)
end)

-- archive_switch_base：注册电源开/关动画
AddPrefabPostInit("archive_switch_base", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = rawget(GLOBAL, "TheWorld")
        if theWorld == nil then return end
        inst:ListenForEvent("arhivepoweron", function()
                inst.AnimState:PlayAnimation("activate", false)
                inst.AnimState:PushAnimation("activate_loop", true)
                inst.SoundEmitter:PlaySound("grotto/common/archive_switch/LP","loop")
            end, theWorld)
        inst:ListenForEvent("arhivepoweroff", function()
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
        local theWorld = rawget(GLOBAL, "TheWorld")
        if theWorld == nil then return end
        theWorld:PushEvent("ms_register_vault_lobby_exit_target", inst)
    end)
end)

-- archive_ambient_sfx：注册档案馆环境音效事件
AddPrefabPostInit("archive_ambient_sfx", function(inst)
    _injectGetTheWorld(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = rawget(GLOBAL, "TheWorld")
        if theWorld == nil then return end
        inst:ListenForEvent("arhivepoweron", function()
                inst.SoundEmitter:PlaySound("grotto/common/archive_on/"..math.random(1,4),"loop")
            end, theWorld)
        inst:ListenForEvent("arhivepoweroff", function()
                inst.SoundEmitter:KillSound("loop")
            end, theWorld)
    end)
end)

-- 将 archivemanager 组件添加到 DST_CAVE 洞穴世界
-- DS 的世界实体 prefab 名是 "cave" 或 "forest"，不是 "world"
-- 注意：AddPrefabPostInit 触发时 inst.meta 尚未被设置（gamelogic.lua 中 ground.meta=savedata.meta 在之后），
-- 必须延迟到下一帧才能正确读取 meta.level_id
AddPrefabPostInit("cave", function(inst)
    inst:DoTaskInTime(0, function()
        if inst.meta and inst.meta.level_id == "DST_CAVE" then
            if not inst.components.archivemanager then
                inst:AddComponent("archivemanager")
            end
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
        local theWorld = rawget(GLOBAL, "TheWorld")
        if theWorld == nil then return end
        inst:ListenForEvent("arhivepoweron", function()
            inst.components.activatable.inactive = false
        end, theWorld)
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
        local theWorld = rawget(GLOBAL, "TheWorld")
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
