-- ==================== 暴动时钟 + DaywalkerSpawner 初始化 ====================
-- 从 archive_hooks.lua 拆分至此，职责分离

-- 辅助函数：获取世界实体（由 modmain.lua 设置）
-- DS 中 TheWorld 不可通过 rawget(GLOBAL, "TheWorld") 可靠获取，
-- 因此依赖 _cave_world 缓存（从 archive_hooks.lua 导入）
-- _cave_world 由 archive_hooks.lua 中 cave postinit 设置

-- ===== 延迟注册：nightmareclock + daywalkerspawner =====
-- 注意：AddPrefabPostInit 触发时 inst.meta 尚未被设置（gamelogic.lua 中 ground.meta=savedata.meta 在之后），
-- 必须延迟到下一帧才能正确读取 meta.level_id
AddPrefabPostInit("cave", function(inst)
    inst:DoTaskInTime(0, function()
        if not (inst.meta and inst.meta.level_id == "DST_CAVE") then
            -- cave level is NOT DST_CAVE, skipping nightmare clock and daywalkerspawner
            return
        end

        -- 注册 dst_nightmareclock（暴动系统）
        if not inst.components.dst_nightmareclock then
            inst:AddComponent("dst_nightmareclock")
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
        end
    end)
end)
