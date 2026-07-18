--------------------------------------------------------------------------
--[[ DS 兼容版 Deerherdspawner ]]
-- 从 DST 源码移植，适配 DS 单机模式
-- 改动：
--   WatchWorldState → ListenForEvent(seasonChange)
--   TheWorld.state.isautumn/iswinter → GetSeasonManager():IsAutumn/IsWinter()
--   state.autumnlength → GetSeasonManager():GetSeasonLength("autumn")
--   移除 ismastersim assert
--------------------------------------------------------------------------
local easing = require("easing")

local function GetTheWorld()
    return rawget(_G, "TheWorld")
end

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local HERD_SPAWN_DIST = 35
local HERD_SPAWN_RADIUS = 4
local HERD_SPAWN_SIZE = 5
local HERD_SPAWN_SIZE_VARIANCE = 1
local HERD_OVERPOPULATION_SIZE = HERD_SPAWN_SIZE + HERD_SPAWN_SIZE_VARIANCE + 1

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

self.inst = inst

local _spawners = {}
local _activedeer = {}
local _timetospawn = nil
local _prevherdsummonday = -200
local _timetomigrate = nil

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function RemoveDeer(deer)
    _activedeer[deer] = nil
    self.inst:RemoveEventCallback("onremove", RemoveDeer, deer)
    self.inst:RemoveEventCallback("death", RemoveDeer, deer)
end

local function AddDeer(deer)
    _activedeer[deer] = true
    self.inst:ListenForEvent("onremove", RemoveDeer, deer)
    self.inst:ListenForEvent("death", RemoveDeer, deer)
end

local function OnRemoveSpawner(spawner)
    for i, v in ipairs(_spawners) do
        if v == spawner then
            table.remove(_spawners, i)
            return
        end
    end
end

local function OnRegisterDeerSpawningGround(inst, spawner)
    for i, v in ipairs(_spawners) do
        if v == spawner then
            return
        end
    end
    table.insert(_spawners, spawner)
    inst:ListenForEvent("onremove", OnRemoveSpawner, spawner)
end

inst:ListenForEvent("ms_registerdeerspawningground", OnRegisterDeerSpawningGround)

--------------------------------------------------------------------------
--[[ Season helpers - DS 兼容 ]]
--------------------------------------------------------------------------

local function GetSeasonManager()
    local fn = rawget(_G, "GetSeasonManager")
    return fn and fn()
end

local function IsAutumn()
    local sm = GetSeasonManager()
    return sm ~= nil and sm:IsAutumn()
end

local function IsWinter()
    local sm = GetSeasonManager()
    return sm ~= nil and sm:IsWinter()
end

local function GetAutumnLength()
    local sm = GetSeasonManager()
    -- DS seasonmanager 用 autumnlength 成员变量（天数）
    return sm and sm.autumnlength or 20
end

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function FindExistingHerd()
    local numexistingdeer = 0
    local existingherd = false
    for k, v in pairs(_activedeer) do
        numexistingdeer = numexistingdeer + 1
        existingherd = existingherd or v
    end

    local spawnpt = nil
    if existingherd and inst.components.deerherding then
        spawnpt = inst.components.deerherding.herdlocation

        local notnearplayers = function(pt)
            local x, y, z = pt:Get()
            return not IsAnyPlayerInRange(x, y, z, 35)
        end

        if not notnearplayers(spawnpt) then
            local result_offset = FindWalkableOffset(spawnpt, math.random() * 2 * PI, HERD_SPAWN_DIST, 8, true, false, notnearplayers)
            if result_offset == nil then
                result_offset = FindWalkableOffset(spawnpt, math.random() * 2 * PI, HERD_SPAWN_DIST, 8, true, true, notnearplayers)
            end
            if result_offset ~= nil then
                spawnpt = spawnpt + result_offset
            end
        end
    end

    return numexistingdeer, spawnpt
end

local function FindHerdSpawningGroundPt()
    if #_spawners > 0 then
        _spawners = shuffleArray(_spawners)
        for i, v in ipairs(_spawners) do
            if not v:IsNearPlayer(HERD_SPAWN_DIST) then
                return v:GetPosition()
            end
        end
        return _spawners[1] and _spawners[1]:GetPosition() or nil
    end

    -- DS 无 deerspawningground set_piece 和 GetStartTile，在世界(0,0)附近找落叶林地皮
    local tw = GetTheWorld()
    if tw and tw.Map then
        local pt = Vector3(0, 0, 0)
        local attempts = 30
        while attempts > 0 do
            local offset = FindWalkableOffset(pt, math.random() * 2 * PI, 15 + math.random() * 30, 12, true, true)
            if offset then
                local testpt = pt + offset
                local tile = tw.Map:GetTileAtPoint(testpt.x, 0, testpt.z)
                -- 落叶林 (DECIDUOUS) 或森林 (FOREST) 地皮
                if tile == GROUND.DECIDUOUS or tile == GROUND.FOREST then
                    return testpt
                end
            end
            attempts = attempts - 1
        end
        return pt
    end
    return nil
end

local function SummonHerd()
    local existingsize, spawnpt = FindExistingHerd()
    print(string.format("[DEER] SummonHerd: existingsize=%d, spawnpt=%s", existingsize, tostring(spawnpt)))
    if existingsize >= HERD_OVERPOPULATION_SIZE then
        return
    end

    if spawnpt == nil then
        spawnpt = FindHerdSpawningGroundPt()
    end

    if spawnpt ~= nil then
        local herd_target_size = GetRandomWithVariance(HERD_SPAWN_SIZE, HERD_SPAWN_SIZE_VARIANCE)
        local num_spawned = 0
        local i = 0
        while num_spawned < herd_target_size and i < herd_target_size + 7 do
            i = i + 1
            local offset = FindWalkableOffset(spawnpt, math.random() * 2 * PI, HERD_SPAWN_RADIUS, 10, true, true)
            if offset ~= nil then
                local deerpos = spawnpt + offset
                self:SpawnDeer(deerpos, spawnpt)
                num_spawned = num_spawned + 1
            end
        end

        if num_spawned > 0 and inst.components.deerherding then
            inst.components.deerherding:Init(spawnpt, self)
        else
            spawnpt = nil
        end
    end

    -- retry later if still autumn
    if spawnpt == nil and IsAutumn() then
        _timetospawn = (1 + math.random()) * TUNING.TOTAL_DAY_TIME
    end
end

local function QueueSummonHerd()
    local tw = GetTheWorld()
    if not IsAutumn() or not tw then return end
    if tw.state.cycles - _prevherdsummonday > GetAutumnLength() then
        _prevherdsummonday = tw.state.cycles
        local spawndelay = GetAutumnLength() * TUNING.TOTAL_DAY_TIME * (tw.state.cycles <= 0 and 0.5 or 0.2)
        local spawnrandom = .33 * spawndelay
        _timetospawn = GetRandomWithVariance(spawndelay, spawnrandom)
        self.inst:StartUpdatingComponent(self)
    end
end

local function QueueHerdMigration()
    if IsWinter() and next(_activedeer) ~= nil then
        local spawndelay = 0.75 * GetAutumnLength() * TUNING.TOTAL_DAY_TIME
        local spawnrandom = 0.1 * GetAutumnLength() * TUNING.TOTAL_DAY_TIME
        _timetomigrate = GetRandomWithVariance(spawndelay, spawnrandom)
        self.inst:StartUpdatingComponent(self)

        for k, _ in pairs(_activedeer) do
            if k:IsValid() then
                k:PushEvent("growantler")
            end
        end
    end
end

local function MigrateHerd()
    local count = 0
    for k, _ in pairs(_activedeer) do
        if k:IsValid() then
            k:PushEvent("despawn")
            count = count + 1
        end
        if count >= 3 then
            break
        end
    end
    if next(_activedeer) ~= nil then
        _timetomigrate = 2 * TUNING.TOTAL_DAY_TIME
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:GetActiveDeer()
    return _activedeer
end

function self:SpawnDeer(pos, center)
    local deer = SpawnPrefab("deer")
    if deer then
        deer.Transform:SetPosition(pos:Get())
        deer.Transform:SetRotation(math.random(360) - 1)
        deer.components.knownlocations:RememberLocation("herdoffset", pos - center)
        AddDeer(deer)
        print(string.format("[DEER] 生成了一只鹿 at (%.1f, %.1f)", pos.x, pos.z))
    else
        print("[DEER] SpawnPrefab(\"deer\") 失败！")
    end
end

function self:OnUpdate(dt)
    if _timetospawn ~= nil then
        _timetospawn = _timetospawn - dt
        if _timetospawn <= 0 then
            _timetospawn = nil
            SummonHerd()
        end
    elseif _timetomigrate ~= nil then
        if next(_activedeer) == nil then
            _timetomigrate = nil
        else
            _timetomigrate = _timetomigrate - dt
            if _timetomigrate <= 0 then
                _timetomigrate = nil
                MigrateHerd()
            end
        end
    else
        self.inst:StopUpdatingComponent(self)
    end
end

function self:OnSave()
    return {
        _prevherdsummonday = _prevherdsummonday,
        _timetospawn = _timetospawn,
        _timetomigrate = _timetomigrate,
    }
end

function self:OnLoad(data)
    if data ~= nil then
        _prevherdsummonday = data._prevherdsummonday or 0
        _timetospawn = data._timetospawn
        _timetomigrate = data._timetomigrate
    end
end

function self:LoadPostPass(newents, data)
    if data ~= nil and data._activedeer ~= nil then
        for k, v in pairs(data._activedeer) do
            local deer = newents[v]
            if deer ~= nil then
                AddDeer(deer.entity)
            end
        end
    end
    if _timetospawn ~= nil or _timetomigrate ~= nil then
        self.inst:StartUpdatingComponent(self)
    end
end

function self:DebugSummonHerd(time)
    _timetospawn = time or 1
    _prevherdsummonday = GetTheWorld() and GetTheWorld().state.cycles or 0
    self.inst:StartUpdatingComponent(self)
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

-- DS 兼容：用 ListenForEvent 替代 WatchWorldState
inst:ListenForEvent("seasonChange", function()
    print("[DEER] 收到 seasonChange 事件")
    QueueSummonHerd()
    QueueHerdMigration()
end, GetTheWorld())

function self:OnPostInit()
    local tw = GetTheWorld()
    print(string.format("[DEER] OnPostInit: cycles=%s, prevherd=%s, isWinter=%s",
        tostring(tw and tw.state.cycles),
        tostring(_prevherdsummonday),
        tostring(IsWinter())))

    -- DST: 开局无条件召唤一次鹿群，确保鹿一开始就在世界上
    SummonHerd()

    if _prevherdsummonday < 0 and tw and tw.state.cycles == 0 and IsWinter() then
        _prevherdsummonday = tw.state.cycles
        print("[DEER] 冬季开局，立即长角+排队迁徙")
        QueueHerdMigration()
    end
    -- 排队秋季召唤（下一批）
    QueueSummonHerd()
end

end)
