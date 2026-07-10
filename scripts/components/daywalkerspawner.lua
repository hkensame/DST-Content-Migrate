local COLLAPSIBLE_WORK_ACTIONS = { CHOP = true, DIG = true, HAMMER = true, MINE = true }
local COLLAPSIBLE_TAGS = { "NPC_workable", "structure", "plant", "tree" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do table.insert(COLLAPSIBLE_TAGS, k.."_workable") end
local NON_COLLAPSIBLE_TAGS = { "locomotor", "FX", "DECOR", "INLIMBO" }
local STRUCTURES_TAGS = {"structure", "blocker"}
local CANT_SPAWN_NEAR_TAGS = {"antlion_sinkhole_blocker"}
local IS_CLEAR_AREA_RADIUS = TUNING.DAYWALKER_ARENA_CLEAR_RADIUS
local DESTROY_AREA_RADIUS = TUNING.DAYWALKER_ARENA_CLEAR_RADIUS
local NO_PLAYER_RADIUS = TUNING.DAYWALKER_SPAWN_NO_PLAYER_RADIUS
local ARENA_RADIUS = TUNING.DAYWALKER_ARENA_RADIUS
local ARENA_PILLARS = TUNING.DAYWALKER_ARENA_PILLARS

return Class(function(self, inst)
    self.inst = inst
    self.days_to_spawn = 0
    self.power_level = 1
    self.spawnpoints = {}
    self.daywalker = nil

    inst:ListenForEvent("ms_registerdaywalkerspawningground", function(_, spawnpoint)
        self:TryToRegisterSpawningPoint(spawnpoint)
    end)

    function self:UnregisterDayWalkerSpawningPoint(spawnpoint)
        table.removearrayvalue(self.spawnpoints, spawnpoint)
    end

    function self:RegisterDayWalkerSpawningPoint(spawnpoint)
        table.insert(self.spawnpoints, spawnpoint)
        self.inst:ListenForEvent("onremove", function() self:UnregisterDayWalkerSpawningPoint(spawnpoint) end, spawnpoint)
    end

    function self:TryToRegisterSpawningPoint(spawnpoint)
        if table.contains(self.spawnpoints, spawnpoint) then return false end
        self:RegisterDayWalkerSpawningPoint(spawnpoint)
        return true
    end

    function self:IncrementPowerLevel()
        self.power_level = math.min(self.power_level + 1, 2)
    end

    function self:GetPowerLevel()
        return self.power_level
    end

    function self:IsValidSpawningPoint(x, y, z)
        for dx = -1, 1 do
            for dz = -1, 1 do
                if not TheWorld.Map:IsAboveGroundAtPoint(x + dx * TILE_SCALE, 0, z + dz * TILE_SCALE, false) then
                    return false
                end
            end
        end
        return true
    end

    function self:SpawnDayWalkerArena(x, y, z)
        local daywalker = SpawnPrefab("daywalker")
        daywalker.Transform:SetPosition(x, y, z)

        local todestroy = TheSim:FindEntities(x, y, z, DESTROY_AREA_RADIUS, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)
        for i, v in ipairs(todestroy) do
            if v:IsValid() then
                local isworkable = false
                if v:HasTag("structure") then
                    if v.components.workable ~= nil then isworkable = true else v:Remove() end
                elseif v:HasTag("plant") or v:HasTag("tree") then
                    v:Remove()
                elseif v.components.workable ~= nil then
                    local work_action = v.components.workable:GetWorkAction()
                    isworkable = ((work_action == nil and v:HasTag("NPC_workable")) or
                        (v.components.workable:CanBeWorked() and work_action ~= nil and COLLAPSIBLE_WORK_ACTIONS[work_action.id]))
                end
                if isworkable then
                    v.components.workable:Destroy(daywalker)
                    if v:IsValid() and v:HasTag("stump") then v:Remove() end
                end
            end
        end

        for i = 1, ARENA_PILLARS do
            local theta = i * TWOPI / ARENA_PILLARS + PI * 3 / 4
            local px, pz = x + math.cos(theta) * ARENA_RADIUS, z - math.sin(theta) * ARENA_RADIUS
            local pillar = SpawnPrefab("daywalker_pillar")
            pillar.Transform:SetPosition(px, 0, pz)
            pillar:SetPrisoner(daywalker)
        end
        return daywalker
    end

    function self:FindBestSpawningPoint()
        local structuresatspawnpoints = {}
        local x, y, z
        local valid = false
        local spawnpointscount = #self.spawnpoints
        if spawnpointscount == 0 then return nil, nil, nil end

        for _, v in ipairs(self.spawnpoints) do
            x, y, z = v.Transform:GetWorldPosition()
            if self:IsValidSpawningPoint(x, y, z) and not IsAnyPlayerInRange(x, y, z, NO_PLAYER_RADIUS) then
                if TheSim:FindEntities(x, y, z, IS_CLEAR_AREA_RADIUS, CANT_SPAWN_NEAR_TAGS)[1] == nil then
                    local structures = #TheSim:FindEntities(x, y, z, IS_CLEAR_AREA_RADIUS, nil, nil, STRUCTURES_TAGS)
                    if structures == 0 then valid = true; break end
                    structuresatspawnpoints[v] = structures
                end
            end
        end

        if not valid then
            local best_count = 12345
            for spawner, structs in pairs(structuresatspawnpoints) do
                if structs < best_count then
                    best_count = structs
                    x, y, z = spawner.Transform:GetWorldPosition()
                    valid = true
                end
            end
        end

        if not valid then
            local spawner = self.spawnpoints[math.random(spawnpointscount)]
            local pos = spawner:GetPosition()
            x, y, z = pos:Get()
            local function IsValidSpawningPoint_Bridge(pt) return self:IsValidSpawningPoint(pt.x, pt.y, pt.z) end
            for r = 5, 15, 5 do
                local offset = FindWalkableOffset(pos, math.random() * TWOPI, r, 8, false, false, IsValidSpawningPoint_Bridge)
                if offset ~= nil then x = x + offset.x; z = z + offset.z; valid = true; break end
            end
        end
        return x, y, z
    end

    function self:TryToSpawnDayWalkerArena()
        self.spawnpoints = shuffleArray(self.spawnpoints)
        local x, y, z = self:FindBestSpawningPoint()
        if x ~= nil then
            x, y, z = TheWorld.Map:GetTileCenterPoint(x, y, z)
            return self:SpawnDayWalkerArena(x, y, z)
        end
        return nil
    end

    function self:OnDayChange()
        if self.daywalker ~= nil then return end
        if self.days_to_spawn > 0 then
            self.days_to_spawn = self.days_to_spawn - 1
            return
        end
        local daywalker = self:TryToSpawnDayWalkerArena()
        if daywalker == nil then return end
        self:WatchDaywalker(daywalker)
        self.days_to_spawn = TUNING.DAYWALKER_RESPAWN_DAYS_COUNT
    end

    function self:WatchDaywalker(daywalker)
        self.daywalker = daywalker
        self.inst:ListenForEvent("onremove", function()
            if self.daywalker.defeated then self:IncrementPowerLevel() end
            self.daywalker = nil
        end, self.daywalker)
    end

    function self:OnPostInit()
        if TUNING.SPAWN_DAYWALKER then
            self.inst:WatchWorldState("cycles", self.OnDayChange)
            if self.days_to_spawn <= 0 then self:OnDayChange() end
        end
    end

    function self:OnSave()
        local data = { days_to_spawn = self.days_to_spawn, power_level = self.power_level }
        local refs = nil
        if self.daywalker ~= nil then
            data.daywalker_GUID = self.daywalker.GUID
            refs = {self.daywalker.GUID}
        end
        return data, refs
    end

    function self:OnLoad(data)
        if not data then return end
        if data.days_to_spawn then self.days_to_spawn = math.min(TUNING.DAYWALKER_RESPAWN_DAYS_COUNT, data.days_to_spawn) end
        self.power_level = data.power_level or self.power_level
    end

    function self:LoadPostPass(ents, data)
        local daywalker_GUID = data.daywalker_GUID
        if daywalker_GUID ~= nil then
            local daywalker = ents[daywalker_GUID]
            if daywalker ~= nil and daywalker.entity ~= nil then
                self:WatchDaywalker(daywalker.entity)
            end
        end
    end
end)
