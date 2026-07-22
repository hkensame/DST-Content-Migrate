-- DST drownable 组件 DS 移植版
local FALLINGREASON = rawget(_G, "FALLINGREASON") or { OCEAN = "ocean", VOID = "void" }

local Drownable = Class(function(self, inst)
    self.inst = inst
    self.enabled = nil
    self.inst:DoTaskInTime(0, function()
        if self.enabled == nil then
            self.enabled = true
        end
    end)
end)

function Drownable:SetOnTakeDrowningDamageFn(fn)
    self.ontakedrowningdamage = fn
end

function Drownable:SetCustomTuningsFn(fn)
    self.customtuningsfn = fn
end

function Drownable:IsInDrownableMapBounds(x, y, z)
    return TheWorld.Map:IsInMapBounds(x, y, z)
end

function Drownable:IsSafeFromFalling()
    if self.inst:GetCurrentPlatform() then
        return true
    end
    local x, y, z = self.inst.Transform:GetWorldPosition()
    if not self:IsInDrownableMapBounds(x, y, z) then
        return true
    end
    if TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
        return true
    end
    return false
end

function Drownable:IsOverVoid()
    if self:IsSafeFromFalling() then
        return false
    end
    local x, y, z = self.inst.Transform:GetWorldPosition()
    return TheWorld.Map:IsInvalidTileAtPoint(x, y, z)
end

function Drownable:IsOverWater()
    if self:IsSafeFromFalling() then
        return false
    end
    local x, y, z = self.inst.Transform:GetWorldPosition()
    return TheWorld.Map:IsOceanTileAtPoint(x, y, z)
end

function Drownable:ShouldX_InternalCheck()
    if not self.enabled then
        return false
    end
    if self.inst.components.health and self.inst.components.health:IsInvincible() then
        return false
    end
    return true
end

function Drownable:ShouldDrown()
    if not self:ShouldX_InternalCheck() then
        return false
    end
    return self:IsOverWater()
end

function Drownable:ShouldFallInVoid()
    if not self:ShouldX_InternalCheck() then
        return false
    end
    return self:IsOverVoid()
end

function Drownable:GetFallingReason()
    if self:ShouldDrown() then
        return FALLINGREASON.OCEAN
    elseif self:ShouldFallInVoid() then
        return FALLINGREASON.VOID
    end
end

function Drownable:CheckDrownable()
    local fallingreason = self:GetFallingReason()
    if fallingreason == FALLINGREASON.OCEAN then
        self.inst:PushEvent("onsink")
        return true
    elseif fallingreason == FALLINGREASON.VOID then
        self.inst:PushEvent("onfallinvoid")
        return true
    end
    return false
end

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function NoPlayersOrHoles(pt)
    return not (IsAnyPlayerInRange(pt.x, 0, pt.z, 2) or TheWorld.Map:IsPointNearHole(pt))
end

function Drownable:Teleport()
    local target_x, target_y, target_z = self.dest_x, self.dest_y, self.dest_z
    local radius = 2 + math.random() * 3
    local pt = Vector3(target_x, target_y, target_z)
    local angle = math.random() * TWOPI
    local offset =
        FindWalkableOffset(pt, angle, radius, 8, true, false, NoPlayersOrHoles) or
        FindWalkableOffset(pt, angle, radius * 1.5, 6, true, false, NoPlayersOrHoles) or
        FindWalkableOffset(pt, angle, radius, 8, true, false, NoHoles) or
        FindWalkableOffset(pt, angle, radius * 1.5, 6, true, false, NoHoles)
    if offset ~= nil then
        target_x = target_x + offset.x
        target_z = target_z + offset.z
    end
    if self.inst.Physics ~= nil then
        self.inst.Physics:Teleport(target_x, target_y, target_z)
    elseif self.inst.Transform ~= nil then
        self.inst.Transform:SetPosition(target_x, target_y, target_z)
    end
end

-- FindRandomPointOnShoreFromOcean 仅在 DST 有，DS 无此函数
function Drownable:GetWashingAshoreTeleportSpot(excludeclosest)
    local ex, ey, ez = self.inst.Transform:GetWorldPosition()
    local x, y, z
    if FindRandomPointOnShoreFromOcean then
        x, y, z = FindRandomPointOnShoreFromOcean(ex, ey, ez, excludeclosest)
    end
    if x == nil then
        x, y, z = ex, ey, ez
    end

    local radius = 2 + math.random() * 3
    local angle = math.random() * TWOPI
    local pt = Vector3(x, y, z)
    local offset =
        FindWalkableOffset(pt, angle, radius, 8, true, false, NoPlayersOrHoles) or
        FindWalkableOffset(pt, angle, radius * 1.5, 6, true, false, NoPlayersOrHoles) or
        FindWalkableOffset(pt, angle, radius, 8, true, false, NoHoles) or
        FindWalkableOffset(pt, angle, radius * 1.5, 6, true, false, NoHoles)
    if offset ~= nil then
        x = x + offset.x
        z = z + offset.z
    end
    return x, y, z
end

local function _oncameraarrive(inst)
    inst:SnapCamera()
    inst:ScreenFade(true, 2)
end

local function _onarrive(inst)
    if inst.sg and inst.sg.statemem and inst.sg.statemem.teleportarrivestate ~= nil then
        inst.sg:GoToState(inst.sg.statemem.teleportarrivestate)
    end
    inst:PushEvent("on_washed_ashore")
end

function Drownable:WashAshore()
    self:Teleport()
    if self.inst:IsValid() then
        self.inst:DoTaskInTime(1, _onarrive)
        self.inst:DoTaskInTime(1.5, _oncameraarrive)
    end
end

return Drownable
