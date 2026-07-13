-- ========== RuinsRespawner 模块（原 ruinsrespawner.lua，已合并至此） ==========
local function onnewobjectfn(inst, obj)
    inst:ListenForEvent("onremove", function(obj)
        local objects = inst.components.objectspawner.objects
        for i = #objects, 1, -1 do
            if objects[i] == obj then
                table.remove(objects, i)
                break
            end
        end
    end, obj)

    if inst.listenforprefabsawp then
        inst:ListenForEvent("onprefabswaped", function(_, data)
            inst.components.objectspawner:TakeOwnership(data.newobj)
        end, obj)
    end
end

local TRYSPAWN_CANT_TAGS = { "INLIMBO" }

local function tryspawn(inst)
    if inst.resetruins and #inst.components.objectspawner.objects <= 0 then
        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, 1, nil, TRYSPAWN_CANT_TAGS)) do
            if v.components.workable ~= nil and v.components.workable:GetWorkAction() ~= ACTIONS.NET then
                v.components.workable:Destroy(v)
            end
        end

        local obj = inst.components.objectspawner:SpawnObject(inst.spawnprefab)
        obj.spawnlocation = Vector3(x, y, z)
        obj.Transform:SetPosition(x, y, z)
        if inst.onrespawnfn ~= nil then
            inst.onrespawnfn(obj, inst)
        end
    end

    inst.resetruins = nil
end

local function onsave(inst, data)
    data.resetruins = inst.resetruins
end

local function onload(inst, data)
    if data ~= nil then
        inst.resetruins = data.resetruins
    end
end

local function OnLoadPostPass(inst)
    if inst.resetruins then
        tryspawn(inst)
    end
end

local function MakeFn(obj, onrespawnfn, data)
    local fn = function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        --[[Non-networked entity]]

        inst:AddTag("CLASSIFIED")

        inst.spawnprefab = obj
        inst.onrespawnfn = onrespawnfn

        inst:AddComponent("objectspawner")
        inst.components.objectspawner.onnewobjectfn = onnewobjectfn

        inst:ListenForEvent("resetruins", function()
            inst.resetruins = true
            inst:DoTaskInTime(math.random()*0.75, function() tryspawn(inst) end)
        end, GetWorld())

        inst.OnSave = onsave
        inst.OnLoad = onload
        inst.OnLoadPostPass = OnLoadPostPass

        inst.listenforprefabsawp = data ~= nil and data.listenforprefabsawp or nil

        return inst
    end
    return fn
end

local function MakeRuinsRespawnerInst(obj, onrespawnfn, data)
    return Prefab(obj.."_ruinsrespawner_inst", MakeFn(obj, onrespawnfn, data), nil, { obj, obj.."_spawner" })
end

local function MakeRuinsRespawnerWorldGen(obj, onrespawnfn, data)
    local function worldgenfn()
        local inst = MakeFn(obj, onrespawnfn, data)()

        inst:SetPrefabName(obj.."_ruinsrespawner_inst")

        inst.resetruins = true
        inst:DoTaskInTime(0, tryspawn)

        return inst
    end

    return Prefab(obj.."_spawner", worldgenfn, nil, { obj })
end

local RuinsRespawner = {Inst = MakeRuinsRespawnerInst, WorldGen = MakeRuinsRespawnerWorldGen}

-- 兼容 minotaur_spawner.lua 的 require("prefabs/cave/ruinsrespawner")
package.loaded["prefabs/cave/ruinsrespawner"] = RuinsRespawner

-- ========== 原 ruins_spawners.lua 内容 ==========

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

-- ==================== 标准 1:1 映射 ====================
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
    -- 非猴岛的：猴子桶
    RuinsRespawner.WorldGen("cave/objects/monkeybarrel"),
    RuinsRespawner.Inst("cave/objects/monkeybarrel"),
    -- 远古祭坛（带 prefab swap 监听）
    RuinsRespawner.WorldGen("common/objects/ancient_altar", nil, { listenforprefabsawp = true }),
    RuinsRespawner.Inst("common/objects/ancient_altar", nil, { listenforprefabsawp = true }),
    RuinsRespawner.WorldGen("common/objects/ancient_altar_broken", nil, { listenforprefabsawp = true }),
    RuinsRespawner.Inst("common/objects/ancient_altar_broken", nil, { listenforprefabsawp = true })
