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

-- 将 archivemanager 组件添加到 TheWorld
AddPrefabPostInit("world", function(inst)
    if not inst.components.archivemanager then
        inst:AddComponent("archivemanager")
    end
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
