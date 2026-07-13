-- DS 移植版：简化 areaaware 检测
-- cave_vent_mite_spawner.lua — 地热螨生成器

local prefabs =
{
    "cave_vent_mite",
}

local function OnMiteSpawned(inst, mite)
    mite:PushEvent("spawn")
end

local function DoSpawnTest(inst)
    if not inst.components.childspawner:CanSpawn() then
        if inst._PeriodicSpawnTesting ~= nil then
            inst._PeriodicSpawnTesting:Cancel()
            inst._PeriodicSpawnTesting = nil
        end
        return
    end

    local ix, iy, iz = inst.Transform:GetWorldPosition()

    -- DS 单机：只有一个玩家，用 GetPlayer() 替代 AllPlayers
    local player = GetPlayer()
    if player == nil then return end
    local dsq_to_player = player:GetDistanceSqToPoint(ix, iy, iz)
    if dsq_to_player > TUNING.CAVE_MITE_SPAWN_RADIUSSQ then
        return
    end

    local mite = inst.components.childspawner:SpawnChild()
    if mite == nil then
        return
    end

    local spawn_distance = Lerp(10, 16, math.sqrt(math.random()))
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

    mite.Transform:SetPosition((player_position + offset):Get())
end

local TEST_FREQUENCY = 10
local function StartTesting(inst)
    if inst._PeriodicSpawnTesting ~= nil then
        inst._PeriodicSpawnTesting:Cancel()
        inst._PeriodicSpawnTesting = nil
    end
    inst._PeriodicSpawnTesting = inst:DoPeriodicTask(TEST_FREQUENCY, DoSpawnTest)
end

local function OnEntityWake(inst)
    StartTesting(inst)
end

local function OnEntitySleep(inst)
    if inst._PeriodicSpawnTesting ~= nil then
        inst._PeriodicSpawnTesting:Cancel()
        inst._PeriodicSpawnTesting = nil
    end
end

local function spawnerfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]
    inst:AddTag("CLASSIFIED")

    inst:AddComponent("childspawner")
    inst.components.childspawner:SetSpawnPeriod(TUNING.CAVE_MITE_RELEASE_TIME)
    inst.components.childspawner:SetRegenPeriod(TUNING.CAVE_MITE_REGEN_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.CAVE_MITE_MAX_CHILDREN)

    -- DS 移植：WorldSettings_ChildSpawner_* 依赖 worldsettingstimer 组件，DS 无此组件
    if not TUNING.CAVE_MITE_ENABLED then
        inst.components.childspawner.childreninside = 0
    end

    inst.components.childspawner:SetSpawnedFn(OnMiteSpawned)
    inst.components.childspawner:SetOccupiedFn(StartTesting)

    inst.components.childspawner.childname = "cave_vent_mite"

    inst.components.childspawner:StartRegen()

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    return inst
end

return Prefab("cave_vent_mite_spawner", spawnerfn, nil, prefabs)
