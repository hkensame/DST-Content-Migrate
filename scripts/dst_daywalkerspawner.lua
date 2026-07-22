-- ==================== DaywalkerSpawner 初始化 ====================
-- 从 dst_nightmare.lua 拆分至此，职责分离
-- DS 中 TheWorld 不可通过 rawget(GLOBAL, "TheWorld") 可靠获取，
-- 因此依赖 _cave_world 缓存（从 archive_hooks.lua 导入）

AddPrefabPostInit("cave", function(inst)
    inst:DoTaskInTime(0, function()
        if not (inst.meta and inst.meta.level_id == "DST_CAVE") then
            return
        end

        -- 梦魇疯猪 daywalkerspawner
        if not inst.components.daywalkerspawner then
            inst:AddComponent("daywalkerspawner")
            inst.components.daywalkerspawner:OnPostInit()
        end
    end)
end)

-- ==================== Spawning Ground 注册 ====================
AddPrefabPostInit("daywalkerspawningground", function(inst)
    inst:DoTaskInTime(0, function()
        local theWorld = rawget(GLOBAL, "TheWorld")
        if theWorld == nil then return end
        theWorld:PushEvent("ms_registerdaywalkerspawningground", inst)
    end)
end)
