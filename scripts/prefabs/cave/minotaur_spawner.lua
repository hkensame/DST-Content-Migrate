-- DST 移植版：远古守卫者重生生成器 + 宝箱掉落物替换
-- 基于 ruinsrespawner.lua 框架。
-- 仅影响 DST_CAVE 的犀牛（加 tag 隔离，由本 spawner 生成的），
-- 不影响 DS 原版洞穴中直接放置的 minotaur。

local RuinsRespawner = require "prefabs/cave/ruinsrespawner"

-- 在死亡位置附近找 sacred_chest，替换 loot
local function replace_chest_loot(x, y, z)
    local ents = TheSim:FindEntities(x, y, z, 6, nil, {"FX", "DECOR", "INLIMBO", "NOCLICK"})
    for _, chest in ipairs(ents) do
        if chest.prefab == "sacred_chest" and chest.components.container then
            local container = chest.components.container
            -- 遍历所有格子移除毁灭之种
            for i = 1, container:GetNumSlots() do
                local item = container:GetItemInSlot(i)
                if item and item.prefab == "cave_regenerator" then
                    item:Remove()
                end
            end
            -- 添加远古大门钥匙
            local key = SpawnPrefab("atrium_key")
            if key then
                container:GiveItem(key)
            end
            return true
        end
    end
    return false
end

-- 犀牛生成后的初始化回调（由 ruinsrespawner 在 spawn 后调用）
local function on_dst_minotaur_spawned(minotaur)
    -- 加 tag 隔离：标记这只犀牛是 DST_CAVE 系统的，不影响 DS 原版
    minotaur:AddTag("dst_minotaur")

    -- 注册死亡事件
    minotaur:ListenForEvent("death", function()
        -- 死亡时立即保存坐标，不依赖后续实体是否存活
        local x, y, z = minotaur.Transform:GetWorldPosition()

        -- 重试循环：DS 原版 sacred_chest 的生成时机不确定
        -- 可能在死亡动画中/后生成，所以每隔 0.5s 试一次，最多试 10 次（5 秒）
        local retry_count = 0
        local max_retries = 10
        local retry_task = nil

        local function try_find_chest()
            retry_count = retry_count + 1
            if retry_count > max_retries then
                return  -- 超时放弃
            end
            if replace_chest_loot(x, y, z) then
                return  -- 找到并替换成功
            end
            -- 没找到，继续等
            retry_task = minotaur:DoTaskInTime(0.5, try_find_chest)
        end

        -- 延迟一小帧开始找，给 DS 原版 sacred_chest 一点生成时间
        -- 用 DoTaskInTime(0) 推到下一帧而不是硬等 0.5s
        minotaur:DoTaskInTime(0, try_find_chest)
    end)
end

return RuinsRespawner.WorldGen("minotaur", on_dst_minotaur_spawned),
       RuinsRespawner.Inst("minotaur", on_dst_minotaur_spawned)
