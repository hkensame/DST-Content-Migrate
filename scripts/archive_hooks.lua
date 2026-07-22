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
        inst:ListenForEvent("arhivepoweron", function() inst:updatelight() end, theWorld)
        inst:ListenForEvent("arhivepoweroff", function() inst:updatelight() end, theWorld)
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

-- 将 archivemanager 组件添加到 DST_CAVE 洞穴世界
-- DS 的世界实体 prefab 名是 "cave" 或 "forest"，不是 "world"
-- addcomponent 不依赖 meta，必须立即执行，让 OnLoadPostPass 能读到
AddPrefabPostInit("cave", function(inst)
    if not inst.components.archivemanager then
        inst:AddComponent("archivemanager")
        _cave_world = inst
    end
end)

-- 说明：dst_nightmareclock（暴动系统）和 daywalkerspawner（梦魇疯猪）
-- 的初始化已移至 dst_nightmare.lua，与档案馆电源系统职责分离

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
        if archive and not power then
            inst.components.activatable.inactive = true
        else
            inst.components.activatable.inactive = false
        end
        inst:ListenForEvent("arhivepoweron", function()
            inst.components.activatable.inactive = false
        end, theWorld)
        inst:ListenForEvent("arhivepoweroff", function()
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
        if not inst.gem and inst.components.trader and _opal_inserted < 2 then
            local opal = SpawnPrefab("opalpreciousgem")
            if opal then
                inst.components.trader:AcceptGift(nil, opal)
                _opal_inserted = _opal_inserted + 1
            end
        end
    end)
end)

-- archive_resonator：注入 GetTheWorld（供 scanfordevice 调用 TheWorld:PushEvent）
AddPrefabPostInit("archive_resonator", _injectGetTheWorld)

-- tree_rocks：注入 GetTheWorld（供 GetLootWeightedTable 调用 TheWorld.Map）
AddPrefabPostInit("tree_rocks", _injectGetTheWorld)
