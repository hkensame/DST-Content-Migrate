local RuinsRespawner = require "prefabs/cave/ruinsrespawner"

local function GetTheWorld()
    return rawget(_G, "TheWorld")
end

local function removearrayvalue(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then
            table.remove(tbl, i)
            return true
        end
    end
    return false
end

-- ==================== chessjunk 特殊处理 ====================
-- DS 没有 `chessjunk` prefab（只有 chessjunk1/2/3），
-- 所以需要自定义 spawner 随机选变种 + 手动管理重生
local chessjunk_assets =
{
    Asset("ANIM", "anim/chessmonster_ruins.zip"),
}

local function MakeChessJunkSpawner()
    -- WorldGen: 生成时创建一个持久 respawner，立即 spawn 随机变种
    local function worldgenfn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst:AddTag("CLASSIFIED")

        inst.spawnprefab = nil  -- 不用默认 spawnprefab，手动处理
        inst:AddComponent("objectspawner")
        inst.components.objectspawner.onnewobjectfn = function(spawner, obj)
            spawner:ListenForEvent("onremove", function(obj)
                removearrayvalue(spawner.components.objectspawner.objects, obj)
            end, obj)
        end

        -- 立即生成一个随机 chessjunk
        local x, y, z = inst.Transform:GetWorldPosition()
        local style = math.random(3)
        local target = SpawnPrefab("common/objects/chessjunk" .. style)
        if target then
            target.Transform:SetPosition(x, y, z)
            inst.components.objectspawner:TakeOwnership(target)
        end

        -- 监听 resetruins 重生
        inst:ListenForEvent("resetruins", function()
            if #inst.components.objectspawner.objects <= 0 then
                local px, py, pz = inst.Transform:GetWorldPosition()
                local style = math.random(3)
                local obj = SpawnPrefab("common/objects/chessjunk" .. style)
                if obj then
                    obj.Transform:SetPosition(px, py, pz)
                    inst.components.objectspawner:TakeOwnership(obj)
                end
            end
        end, GetTheWorld())

        inst:SetPrefabName("chessjunk_ruinsrespawner_inst")

        return inst
    end

    -- Inst: 用于 retrofit（DS 不需要，但保留注册保持接口一致）
    local function instfn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst:AddTag("CLASSIFIED")
        inst:AddComponent("objectspawner")
        return inst
    end

    return Prefab("chessjunk_spawner", worldgenfn, chessjunk_assets, { "common/objects/chessjunk1", "common/objects/chessjunk2", "common/objects/chessjunk3" }),
           Prefab("chessjunk_ruinsrespawner_inst", instfn, nil, { "common/objects/chessjunk1", "common/objects/chessjunk2", "common/objects/chessjunk3" })
end

-- ==================== 标准 1:1 映射（使用 cave/ruinsrespawner）====================
-- 每个 prefab 同时注册 WorldGen（_spawner）和 Inst（_ruinsrespawner_inst）

return MakeChessJunkSpawner(),
    RuinsRespawner.WorldGen("cave/monsters/rook_nightmare"),
    RuinsRespawner.Inst("cave/monsters/rook_nightmare"),
    RuinsRespawner.WorldGen("cave/monsters/bishop_nightmare"),
    RuinsRespawner.Inst("cave/monsters/bishop_nightmare"),
    RuinsRespawner.WorldGen("cave/monsters/knight_nightmare"),
    RuinsRespawner.Inst("cave/monsters/knight_nightmare"),
    RuinsRespawner.WorldGen("cave/objects/ruins_statue_head"),
    RuinsRespawner.Inst("cave/objects/ruins_statue_head"),
    RuinsRespawner.WorldGen("cave/objects/ruins_statue_head_nogem"),
    RuinsRespawner.Inst("cave/objects/ruins_statue_head_nogem"),
    RuinsRespawner.WorldGen("cave/objects/ruins_statue_mage"),
    RuinsRespawner.Inst("cave/objects/ruins_statue_mage"),
    RuinsRespawner.WorldGen("cave/objects/ruins_statue_mage_nogem"),
    RuinsRespawner.Inst("cave/objects/ruins_statue_mage_nogem"),
    -- 洞穴生物：蠕虫、粘液虫
    RuinsRespawner.WorldGen("cave/monsters/worm"),
    RuinsRespawner.Inst("cave/monsters/worm"),
    RuinsRespawner.WorldGen("cave/monsters/slurper"),
    RuinsRespawner.Inst("cave/monsters/slurper"),
    -- 猴岛：猴尾桶
    RuinsRespawner.WorldGen("cave/objects/monkeybarrel"),
    RuinsRespawner.Inst("cave/objects/monkeybarrel"),
    -- 远古祭坛（带 prefab swap 监听）
    RuinsRespawner.WorldGen("common/objects/ancient_altar", nil, { listenforprefabsawp = true }),
    RuinsRespawner.Inst("common/objects/ancient_altar", nil, { listenforprefabsawp = true }),
    RuinsRespawner.WorldGen("common/objects/ancient_altar_broken", nil, { listenforprefabsawp = true }),
    RuinsRespawner.Inst("common/objects/ancient_altar_broken", nil, { listenforprefabsawp = true })
