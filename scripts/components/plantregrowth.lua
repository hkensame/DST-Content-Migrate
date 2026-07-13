-- DS 移植版：移除 net_*/SetPristine/ismastersim，补充 TUNING 兜底
-- DST 植物再生管理器（全局定时器驱动）

require "regrowthutil"

local UPDATE_PERIOD = 31

local UpdateBuckets = nil
local UpdateTask = nil
local CurrentBucket = nil

local LastTime = 0
local InternalTimes = {}

local BASE_RADIUS = 8

-- 安全获取 TheWorld，绕过 DS strict.lua 的 __index 拦截
local function GetTheWorld()
    return rawget(_G, "TheWorld")
end

local TimeMultipliers = {
    ["mushtree_moon"] = function()
        local theWorld = GetTheWorld()
        return (TUNING.MOONMUSHTREE_REGROWTH_TIME_MULT or 1) * ((theWorld and theWorld.state.iswinter and 0) or 1)
    end,
    ["tree_rock1"] = function()
        return TUNING.TREE_ROCK_REGROWTH_TIME_MULT or 1
    end,
    ["tree_rock2"] = function()
        return TUNING.TREE_ROCK_REGROWTH_TIME_MULT or 1
    end,
}

local function DoUpdate()
    local dt = GetTime() - LastTime
    LastTime = GetTime()
    for k, v in pairs(InternalTimes) do
        local timemult = TimeMultipliers[k] ~= nil and TimeMultipliers[k]() or 1
        InternalTimes[k] = InternalTimes[k] + dt * timemult * (TUNING.REGROWTH_TIME_MULTIPLIER or 1)
    end

    CurrentBucket = CurrentBucket < #UpdateBuckets and CurrentBucket + 1 or 1
    for i, v in ipairs(UpdateBuckets[CurrentBucket]) do
        v:TrySpawnNearby()
    end
end

local function RegisterUpdate(self)
    if InternalTimes[self.inst.prefab] == nil then
        InternalTimes[self.inst.prefab] = 0
    end

    if UpdateBuckets == nil then
        assert(UpdateTask == nil)
        local theWorld = GetTheWorld()
        if theWorld == nil then return end
        UpdateTask = theWorld:DoPeriodicTask(UPDATE_PERIOD, DoUpdate)
        self._bucket = { self }
        UpdateBuckets = { self._bucket }
        CurrentBucket = 1
        LastTime = GetTime()
        return
    end

    for i, v in ipairs(UpdateBuckets) do
        if #v < 50 then
            self._bucket = v
            table.insert(v, self)
            return
        end
    end
    self._bucket = { self }
    table.insert(UpdateBuckets, 1, self._bucket)
    CurrentBucket = CurrentBucket + 1
end

local function UnregisterUpdate(self)
    if self._bucket == nil then
        return
    end
    for i, v in ipairs(self._bucket) do
        if v == self then
            table.remove(self._bucket, i)
            if #self._bucket <= 0 then
                for i2, v2 in ipairs(UpdateBuckets) do
                    if v2 == self._bucket then
                        table.remove(UpdateBuckets, i2)
                        if #UpdateBuckets <= 0 then
                            UpdateTask:Cancel()
                            UpdateTask = nil
                            UpdateBuckets = nil
                            CurrentBucket = nil
                        elseif CurrentBucket > i2 then
                            CurrentBucket = CurrentBucket - 1
                        elseif CurrentBucket > #UpdateBuckets then
                            CurrentBucket = 1
                        end
                        break
                    end
                end
            end
            self._bucket = nil
            return
        end
    end
end

local PlantRegrowth = Class(function(self, inst)
    self.inst = inst

    self.regrowthrate = nil
    self.product = nil
    self.searchtag = nil

    self.nextregrowth = 0

    self.area = nil
end)

PlantRegrowth.TimeMultipliers = TimeMultipliers

function PlantRegrowth:ResetGrowthTime()
    self.nextregrowth = InternalTimes[self.inst.prefab] + GetRandomWithVariance(self.regrowthrate, self.regrowthrate * 0.2)
end

function PlantRegrowth:SetRegrowthRate(rate)
    self.regrowthrate = rate
    RegisterUpdate(self)
    if self.nextregrowth <= InternalTimes[self.inst.prefab] then
        self:ResetGrowthTime()
    end
end

function PlantRegrowth:SetProduct(product)
    self.product = product
end

function PlantRegrowth:SetSearchTag(tag)
    self.searchtag = tag
end

function PlantRegrowth:SetSkipCanPlantCheck(bool)
    self.skip_plant_check = bool
end

function PlantRegrowth:OnRemoveFromEntity()
    UnregisterUpdate(self)
end

function PlantRegrowth:OnRemoveEntity()
    UnregisterUpdate(self)
end

local SPAWN_BLOCKER_TAGS = { "structure", "wall" }
local function GetSpawnPoint(from_pt, radius, prefab, skip_plant_check)
    local theWorld = GetTheWorld()
    local map = theWorld and theWorld.Map
    if map == nil then
        return
    end
    local theta = math.random() * TWOPI
    radius = math.random(radius / 2, radius)
    local steps = 10
    local step_decrement = (TWOPI / steps)
    for _ = 1, steps do
        local offset = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
        local try_pos = from_pt + offset
        if (skip_plant_check or map:CanPlantAtPoint(try_pos:Get()))
            and map:CanPlacePrefabFilteredAtPoint(try_pos.x, try_pos.y, try_pos.z, prefab)
            and not (RoadManager ~= nil and RoadManager:IsOnRoad(try_pos.x, 0, try_pos.z))
            and #TheSim:FindEntities(try_pos.x, try_pos.y, try_pos.z, 3) <= 0
            and #TheSim:FindEntities(try_pos.x, try_pos.y, try_pos.z, BASE_RADIUS, nil, nil, SPAWN_BLOCKER_TAGS) <= 0 then
            return try_pos
        end
        theta = theta - step_decrement
    end
    return nil
end

function PlantRegrowth:TrySpawnNearby()
    if self.nextregrowth > InternalTimes[self.inst.prefab] then
        return
    end

    self:ResetGrowthTime()

    local x, y, z = self.inst.Transform:GetWorldPosition()

    if self.fiveradius == nil then
        self.fiveradius = GetFiveRadius(x, z, self.inst.prefab)

        if self.fiveradius == nil then
            UnregisterUpdate(self)
            return
        end
    end

    local spawnpoint = GetSpawnPoint(Point(x, y, z), self.fiveradius, self.product or self.inst.prefab, self.skip_plant_check)
    if spawnpoint ~= nil then
        local targetradius = GetFiveRadius(spawnpoint.x, spawnpoint.z, self.inst.prefab)
        if targetradius then
            local ents = TheSim:FindEntities(spawnpoint.x, spawnpoint.y, spawnpoint.z, targetradius, { self.searchtag or self.inst.prefab })
            if #ents < 5 then
                local offspring = SpawnPrefab(self.product or self.inst.prefab)
                offspring.Transform:SetPosition(spawnpoint:Get())
            end
        end
    end
end

function PlantRegrowth:OnSave()
    local data =
    {
        regrowthtime = self.nextregrowth - InternalTimes[self.inst.prefab]
    }
    return next(data) ~= nil and data or nil
end

function PlantRegrowth:OnLoad(data)
    if data ~= nil then
        self.nextregrowth = InternalTimes[self.inst.prefab] + data.regrowthtime
    end
end

function PlantRegrowth:GetDebugString()
    if not self.fiveradius then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        self.fiveradius = GetFiveRadius(x, z, self.inst.prefab)
    end
    if self.fiveradius then
        return string.format("fiveradius: %2.2f regrowth time: %2.2f", self.fiveradius, self.nextregrowth - InternalTimes[self.inst.prefab])
    else
        return string.format("NO GROWTH HERE")
    end
end

return PlantRegrowth
