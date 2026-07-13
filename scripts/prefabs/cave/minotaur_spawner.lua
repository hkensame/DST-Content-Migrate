-- DST 移植版：远古守卫者重生生成器 + 宝箱掉落物替换
-- 基于 ruinsrespawner.lua 框架。
-- 仅影响 DST_CAVE 的犀牛（加 tag 隔离，由本 spawner 生成的），
-- 不影响 DS 原版洞穴中直接放置的 minotaur。
--
-- 宝箱替换方案：
-- minotaurchest 没有 Physics 组件，FindEntities 无法找到它。
-- 因此用 AddPrefabPostInit("minotaurchest") 在 chest 创建时直接替换内容。
-- 死亡时设置全局标记 _DST_CAVE_MINOTAUR_DEAD = {x,y,z}，
-- PostInit 检查标记 + 距离匹配后替换 cave_regenerator → atrium_key。

local RuinsRespawner = require "prefabs/cave/ruinsrespawner"

-- 犀牛生成后的初始化回调（由 ruinsrespawner 在 spawn 后调用）
local function on_dst_minotaur_spawned(minotaur)
    -- 加 tag 隔离：标记这只犀牛是 DST_CAVE 系统的，不影响 DS 原版
    minotaur:AddTag("dst_minotaur")

    -- 注册死亡事件：死亡时记录位置，供 PostInit 使用
    minotaur:ListenForEvent("death", function()
        local x, y, z = minotaur.Transform:GetWorldPosition()
        rawset(_G, "_DST_CAVE_MINOTAUR_DEAD", {x = x, y = y, z = z})

        -- 安全超时：10 秒后清除标记，防止误替换后续宝箱
        local theWorld = rawget(_G, "TheWorld")
        if theWorld then
            theWorld:DoTaskInTime(10, function()
                rawset(_G, "_DST_CAVE_MINOTAUR_DEAD", nil)
            end)
        end
    end)
end

return RuinsRespawner.WorldGen("minotaur", on_dst_minotaur_spawned),
       RuinsRespawner.Inst("minotaur", on_dst_minotaur_spawned)
