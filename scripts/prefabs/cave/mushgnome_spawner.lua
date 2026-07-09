-- DS 适配版 mushgnome_spawner.lua
-- 从 DST 源码 scripts/prefabs/mushgnome_spawner.lua 移植
-- 改动：
--   🔴 移除 require("worldsettingsutil") 及 WorldSettings_* 调用
--   🟡 AllPlayers 循环改为 GetPlayer()（DS 单机）
--   🔴 移除 areaaware 组件检查（DS 无此组件）

local assets = nil

local prefabs =
{
    "mushgnome",
}

local ZERO = Vector3(0,0,0)
local function zero_spawn_offset(inst)
    return ZERO
end

local function on_gnome_spawned(inst, gnome)
    gnome:PushEvent("spawn")
end

local function do_spawn_test(inst)
    if not inst.components.childspawner:CanSpawn() then
        if inst._PeriodicSpawnTesting ~= nil then
            inst._PeriodicSpawnTesting:Cancel()
            inst._PeriodicSpawnTesting = nil
        end
        return
    end

    local ix, iy, iz = inst.Transform:GetWorldPosition()

    -- 🟡 DS 单机：用 GetPlayer() 代替 AllPlayers 循环
    local player = GetPlayer()
    if player == nil then return end

    local dsq_to_player = player:GetDistanceSqToPoint(ix, iy, iz)
    if dsq_to_player > TUNING.MUSHGNOME_SPAWN_RADIUSSQ then
        return
    end

    local gnome = inst.components.childspawner:SpawnChild()
    if gnome == nil then
        return
    end

    local spawn_distance = Lerp(2, 20, math.sqrt(math.random()))
    local player_position = player:GetPosition()

    local offset = FindWalkableOffset(
        player_position,
        math.random() * TWOPI,
        spawn_distance,
        nil,
        false,
        true
    )
    if offset == nil then
        return
    end

    gnome.Transform:SetPosition((player_position + offset):Get())
end

local TEST_FREQUENCY = 10
local function StartTesting(inst)
    inst._PeriodicSpawnTesting = inst:DoPeriodicTask(TEST_FREQUENCY, do_spawn_test)
end

local function on_entity_wake(inst)
    StartTesting(inst)
end

local function on_entity_sleep(inst)
    if inst._PeriodicSpawnTesting ~= nil then
        inst._PeriodicSpawnTesting:Cancel()
        inst._PeriodicSpawnTesting = nil
    end
end

local function spawner()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]
    inst:AddTag("CLASSIFIED")

    inst:AddComponent("childspawner")
    inst.components.childspawner:SetSpawnPeriod(TUNING.MUSHGNOME_RELEASE_TIME)
    inst.components.childspawner:SetRegenPeriod(TUNING.MUSHGNOME_REGEN_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.MUSHGNOME_MAX_CHILDREN)

    -- 🔴 移除 WorldSettings_ChildSpawner_* 调用
    if not TUNING.MUSHGNOME_ENABLED then
        inst.components.childspawner.childreninside = 0
    end

    inst.components.childspawner:SetSpawnedFn(on_gnome_spawned)
    inst.components.childspawner:SetOccupiedFn(StartTesting)

    inst.components.childspawner.childname = "mushgnome"
    inst.components.childspawner.overridespawnlocation = zero_spawn_offset

    inst.components.childspawner:StartRegen()

    inst.OnEntityWake = on_entity_wake
    inst.OnEntitySleep = on_entity_sleep

    return inst
end

return Prefab("mushgnome_spawner", spawner, assets, prefabs)
