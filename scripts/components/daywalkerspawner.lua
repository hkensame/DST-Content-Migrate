local function removearrayvalue(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then table.remove(tbl, i) return true end
    end
    return false
end

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

local function GetTheWorld()
    return rawget(_G, "TheWorld")
end

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
        removearrayvalue(self.spawnpoints, spawnpoint)
    end

    function self:RegisterDayWalkerSpawningPoint(spawnpoint)
        table.insert(self.spawnpoints, spawnpoint)
        self.inst:ListenForEvent("onremove", function() self:UnregisterDayWalkerSpawningPoint(spawnpoint) end, spawnpoint)
    end

    function self:TryToRegisterSpawningPoint(spawnpoint)
        if table.contains(self.spawnpoints, spawnpoint) then
            print("[DAYWALKER] TryToRegisterSpawningPoint: DUPLICATE, rejected")
            return false
        end
        self:RegisterDayWalkerSpawningPoint(spawnpoint)
        print(string.format("[DAYWALKER] TryToRegisterSpawningPoint: registered, total=%d", #self.spawnpoints))
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
                local theWorld = GetTheWorld()
                if not theWorld or not theWorld.Map:IsAboveGroundAtPoint(x + dx * TILE_SCALE, 0, z + dz * TILE_SCALE, false) then
                    return false
                end
            end
        end
        return true
    end

    function self:SpawnDayWalkerArena(x, y, z)
        print(string.format("[DAYWALKER] SpawnDayWalkerArena at (%.1f, %.1f, %.1f)", x, y, z))
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
        if spawnpointscount == 0 then
            print("[DAYWALKER] FindBestSpawningPoint: NO spawnpoints registered!")
            return nil, nil, nil
        end

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
        print(string.format("[DAYWALKER] TryToSpawnDayWalkerArena: spawnpoints=%d", #self.spawnpoints))
        self.spawnpoints = shuffleArray(self.spawnpoints)
        local x, y, z = self:FindBestSpawningPoint()
        if x ~= nil then
            local theWorld = GetTheWorld()
            x, y, z = theWorld and theWorld.Map:GetTileCenterPoint(x, y, z) or x, y, z
            print(string.format("[DAYWALKER] TryToSpawnDayWalkerArena: found point at (%.1f, %.1f, %.1f)", x, y, z))
            return self:SpawnDayWalkerArena(x, y, z)
        end
        print("[DAYWALKER] TryToSpawnDayWalkerArena: no valid point found")
        return nil
    end

    function self:OnDayChange()
        print(string.format("[DAYWALKER] OnDayChange: daywalker=%s days_to_spawn=%d spawnpoints=%d",
            self.daywalker ~= nil and tostring(self.daywalker.GUID) or "nil",
            self.days_to_spawn, #self.spawnpoints))
        if self.daywalker ~= nil then return end
        if self.days_to_spawn > 0 then
            self.days_to_spawn = self.days_to_spawn - 1
            return
        end
        local daywalker = self:TryToSpawnDayWalkerArena()
        if daywalker == nil then return end
        self:WatchDaywalker(daywalker)
        self.days_to_spawn = TUNING.DAYWALKER_RESPAWN_DAYS_COUNT
        print(string.format("[DAYWALKER] OnDayChange: spawned daywalker GUID=%s, next spawn in %d days",
            tostring(daywalker.GUID), self.days_to_spawn))
    end

    function self:WatchDaywalker(daywalker)
        self.daywalker = daywalker
        self.inst:ListenForEvent("onremove", function()
            if self.daywalker.defeated then self:IncrementPowerLevel() end
            self.daywalker = nil
        end, self.daywalker)
    end

    function self:OnPostInit()
        print(string.format("[DAYWALKER] OnPostInit: SPAWN_DAYWALKER=%s", tostring(TUNING.SPAWN_DAYWALKER)))
        if TUNING.SPAWN_DAYWALKER then
            -- 补注册：扫描世界中已存在的 daywalkerspawningground
            -- 因为世界生成时推送的 ms_registerdaywalkerspawningground 事件
            -- 当时组件尚未创建，事件已丢失，需要手动补注册
            local x, y, z = self.inst.Transform:GetWorldPosition()
            local existing = TheSim:FindEntities(x, y, z, 10000, nil, nil, {"daywalkerspawningground"})
            for i, ground in ipairs(existing) do
                self:TryToRegisterSpawningPoint(ground)
            end
            -- DS 洞穴没有连续的 daytime 事件（时钟一直处于 day 阶段），
            -- 改用 DoPeriodicTask 定时检测，确保生成条件和重生延迟正常工作。
            -- 30 秒 ≈ 现实 30 秒检测一次，不会密集也不会过于稀疏。
            self.inst:DoPeriodicTask(30, function() self:OnDayChange() end)
            print("[DAYWALKER] OnPostInit: DoPeriodicTask(30) installed")
            -- 延迟到下一帧再首次尝试，给 daywalkerspawningground 注册的时间
            self.inst:DoTaskInTime(1, function()
                print(string.format("[DAYWALKER] DoTaskInTime(1) fired: days_to_spawn=%d", self.days_to_spawn))
                if self.days_to_spawn <= 0 then self:OnDayChange() end
            end)
        else
            print("[DAYWALKER] OnPostInit: SKIPPED (SPAWN_DAYWALKER disabled)")
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
