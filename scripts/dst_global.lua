
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

require("physics")
require "recipe"
require("behaviourtree")
--------------------------<增加全局>--------------------------

-- 确保沙箱中存在 CommonHandlers/CommonStates，避免 dst_global.lua 加载时 nil 崩溃
CommonHandlers = CommonHandlers or {}
CommonStates = CommonStates or {}

GLOBAL.PI2 = PI*2
GLOBAL.TWOPI = PI2
GLOBAL.COLLISION.SMALLOBSTACLES = 8192
GLOBAL.COLLISION.GIANTS = 16384

local sqrt = math.sqrt
GLOBAL.VecUtil_LengthSq = function(p1_x, p1_z)
    return p1_x * p1_x + p1_z * p1_z
end

GLOBAL.VecUtil_Length = function(p1_x, p1_z)
    return sqrt(p1_x * p1_x + p1_z * p1_z)
end

GLOBAL.VecUtil_Normalize = function(p1_x, p1_z)
    local x_sq = p1_x * p1_x
    local z_sq = p1_z * p1_z
    local length = sqrt(x_sq + z_sq)
    return p1_x / length, p1_z / length
end

GLOBAL.ErodeAway = function(inst, erode_time)
    local time_to_erode = erode_time or 1
    local tick_time = TheSim:GetTickTime()

    if inst.DynamicShadow ~= nil then
        inst.DynamicShadow:Enable(false)
    end

    inst:StartThread(function()
        local ticks = 0
        while ticks * tick_time < time_to_erode do
            local erode_amount = ticks * tick_time / time_to_erode
            inst.AnimState:SetErosionParams(erode_amount, 0.1, 1.0)
            ticks = ticks + 1
            Yield()
        end
        inst:Remove()
    end)
end

--蘑菇的获取双方距离
GLOBAL.GetDistanceSq = function(inst, target)
  if not inst or not target then return nil end
  if not target["Transform"] then return nil end
   local pt1 = Vector3(inst.Transform:GetWorldPosition()) 
   local pt2 = Vector3(target.Transform:GetWorldPosition()) 
   local sq = pt1:Dist(pt2) 
 return sq
end

GLOBAL.RoundBiasedDown = function(num, idp)
    local mult = 10^(idp or 0)
    return math.ceil(num * mult - 0.5) / mult
end

GLOBAL.RoundBiasedUp = function(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

GLOBAL.GetCurrentAnimationLength = function(inst)
  local _,_,anim = inst.entity:GetDebugString():find("p:(.-)%sF")
  if not anim then return 1.5 end
  local total = inst.AnimState:GetTotalTime(anim)
  local per = inst.AnimState:GetPercent()
  return total*(1-per)
end

GLOBAL.GetCurrentAnimationFrame = function(inst)
  local _,_,anim = inst.entity:GetDebugString():find("p:(.-)%sF")
  if not anim then return 1.5 end
  local total = inst.AnimState:GetTotalTime(anim)
  return total
end

--inst:DoTaskInTime(inst.AnimState:GetTotalTime("summon_pre"), pre_over)

------------------------补全的函数------------------------
TRANSFORMBAN = {}
BANKOWNERENTITY = {}

--if GLOBAL.PLATFORM == "Android" and GetPlayer():HasTag("qqcykbz") then
  function AnimState:GetCurrentAnimationLengthSummary()
    local anim = self:GetCurrentAnim()
    if anim then
      local a = self:GetTotalTime(anim)
      local b = self:GetPercent()
      return {anim=anim,total=a,curtotal=a*(1-b)}
    end
    return nil
  end

  function AnimState:GetCurrentAnimationLength()
    local len = self:GetCurrentAnimationLengthSummary()
    if len then
      return len.curtotal
    end
    return 0
  end

  function AnimState:GetCurrentAnimationNumFrames()
    return self:GetCurrentAnimationLength()/FRAMES
  end

  function AnimState:SetFrame(num)
    self:SetTime(num*FRAMES)
  end

  function AnimState:GetCurrentAnim()
    if not BANKOWNERENTITY[self] then
      for k,v in pairs(Ents) do
        if v and v.AnimState and v.AnimState == self then
          BANKOWNERENTITY[self] = v
        break
        end
      end
    end
    if not BANKOWNERENTITY[self] then 
      BANKOWNERENTITY[self] = true
    end
    if BANKOWNERENTITY[self] and type(BANKOWNERENTITY[self]) ~= "boolean" then
      local _,_,anim = BANKOWNERENTITY[self].entity:GetDebugString():find("p:(.-)%sF")
      return anim
    end
  return "NULL"
  end
--end
--------------------------------------------

GLOBAL.FindClosestPlayerInRangeSq = function(x, y, z, rangesq, isalive)
    local closestPlayer = nil
    local v = GetPlayer()
    --for i, v in ipairs(AllPlayers) do
        if (isalive == nil or isalive ~= v.components.health:IsDead()) and
            v.entity:IsVisible() then
            local distsq = v:GetDistanceSqToPoint(x, y, z)
            if distsq < rangesq then
                rangesq = distsq
                closestPlayer = v
            end
        end
    --end
    return closestPlayer, closestPlayer ~= nil and rangesq or nil
end

GLOBAL.FindClosestPlayerInRange = function(x, y, z, range, isalive)
    return FindClosestPlayerInRangeSq(x, y, z, range * range, isalive)
end

GLOBAL.FindClosestPlayerToInst = function(inst, range, isalive)
    local x, y, z = inst.Transform:GetWorldPosition()
    return FindClosestPlayerInRange(x, y, z, range, isalive)
end

GLOBAL.IsAnyPlayerInRangeSq = function(x, y, z, rangesq, isalive)
    local v = GetPlayer()
    --for i, v in ipairs(AllPlayers) do
        if (isalive == nil or isalive ~= v.components.health:IsDead()) and
            v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < rangesq then
            return true
        end
    --end
    return false
end

GLOBAL.IsAnyPlayerInRange = function(x, y, z, range, isalive)
    return IsAnyPlayerInRangeSq(x, y, z, range * range, isalive)
end

GLOBAL.Launch = function(inst, launcher, basespeed)
    if inst ~= nil and inst.Physics ~= nil and inst.Physics:IsActive() and launcher ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = launcher.Transform:GetWorldPosition()
        local vx, vz = x - x1, z - z1
        local spd = math.sqrt(vx * vx + vz * vz)
        local angle =
            spd > 0 and
            math.atan2(vz / spd, vx / spd) + (math.random() * 20 - 10) * DEGREES or
            math.random() * 2 * PI
        spd = (basespeed or 5) + math.random() * 2
        inst.Physics:Teleport(x, .1, z)
        inst.Physics:SetVel(math.cos(angle) * spd, 10, math.sin(angle) * spd)
    end
end

GLOBAL.LaunchAt = function(inst, launcher, target, speedmult, startheight, startradius, randomangleoffset)
    if inst ~= nil and inst.Physics ~= nil and inst.Physics:IsActive() and launcher ~= nil then
        local x, y, z = launcher.Transform:GetWorldPosition()
        local angleoffset = randomangleoffset or 30
        local angle
        if target ~= nil then
            local start_angle = 180 - angleoffset
            angle = (start_angle + (math.random() * angleoffset * 2) - target:GetAngleToPoint(x, 0, z)) * DEGREES
        else
            local down = TheCamera:GetDownVec()
            angle = math.atan2(down.z, down.x) + (math.random() * angleoffset * 2 - angleoffset) * DEGREES
        end
        local sina, cosa = math.sin(angle), math.cos(angle)
        local spd = (math.random() * 2 + 1) * (speedmult or 1)
        inst.Physics:Teleport(x + (startradius or 0) * cosa, startheight or .1, z + (startradius or 0) * sina)
        inst.Physics:SetVel(spd * cosa, math.random() * 2 + 4 + 2 * (speedmult or 1), spd * sina)
    end
end

--------
TUNING.MAX_WALKABLE_PLATFORM_RADIUS  = 4
local MAX_GROUND_TARGET_BLOCKER_RADIUS = 0
GLOBAL.RegisterGroundTargetBlocker = function(radius)
    MAX_GROUND_TARGET_BLOCKER_RADIUS = math.max(radius, MAX_GROUND_TARGET_BLOCKER_RADIUS)
end

local WALKABLE_PLATFORM_TAGS = {"walkableplatform"}

GLOBAL.IsPassableAtPoint = function(x, y, z, allow_water, exclude_boats)
    return IsPassableAtPointWithPlatformRadiusBias(x, y, z, allow_water, exclude_boats, 0)
end

GLOBAL.IsPassableAtPointWithPlatformRadiusBias = function(x, y, z, allow_water, exclude_boats, platform_radius_bias, ignore_land_overhang)
    local valid_tile = IsAboveGroundAtPoint(x, y, z, allow_water)
    local is_overhang = false
    if not valid_tile then
        valid_tile = ((not ignore_land_overhang) --[[and self:IsVisualGroundAtPoint(x,y,z)--]] or false)
        if valid_tile then
            is_overhang = true
        end
    end
    if not allow_water and not valid_tile then
        if not exclude_boats then
            local entities = TheSim:FindEntities(x, 0, z, TUNING.MAX_WALKABLE_PLATFORM_RADIUS + platform_radius_bias, WALKABLE_PLATFORM_TAGS)
            for i, v in ipairs(entities) do
                local walkable_platform = v.components.walkableplatform            
                if walkable_platform ~= nil then  
                    local platform_x, platform_y, platform_z = v.Transform:GetWorldPosition()
                    local distance_sq = VecUtil_LengthSq(x - platform_x, z - platform_z)
                    return distance_sq <= walkable_platform.radius * walkable_platform.radius
                end
            end
        end
		return false
    end
	return valid_tile, is_overhang
end

GLOBAL.IsAboveGroundAtPoint = function(x, y, z, allow_water)
    local theWorld = GetWorld()
    if theWorld == nil or theWorld.Map == nil then
        return false
    end
    local tile = theWorld.Map:GetTileAtPoint(x, y, z)
    if tile == nil then
        return false
    end
    local valid_water_tile = false
    if allow_water == true and GROUND.OCEAN_START ~= nil and GROUND.OCEAN_END ~= nil then
        valid_water_tile = tile >= GROUND.OCEAN_START and tile <= GROUND.OCEAN_END
    end
    return (tile < GROUND.UNDERGROUND or valid_water_tile) and
        tile ~= GROUND.IMPASSABLE and
        tile ~= GROUND.INVALID
end

local WALKABLE_PLATFORM_TAGS = {"walkableplatform"}

GLOBAL.GetPlatformAtPoint = function(pos_x, pos_y, pos_z, extra_radius)
	if pos_z == nil then -- to support passing in (x, z) instead of (x, y, x)
		pos_z = pos_y
		pos_y = 0
	end
    local entities = TheSim:FindEntities(pos_x, pos_y, pos_z, TUNING.MAX_WALKABLE_PLATFORM_RADIUS + (extra_radius or 0), WALKABLE_PLATFORM_TAGS)
    for i, v in ipairs(entities) do
        return v 
    end
    return nil
end

local DEPLOY_EXTRA_SPACING = 0
GLOBAL.IsPointNearHole = function(pt, range)
    range = range or .5
    for i, v in ipairs(TheSim:FindEntities(pt.x, 0, pt.z, DEPLOY_EXTRA_SPACING + range, HOLE_TAGS)) do
        local radius = v:GetPhysicsRadius(0) + range
        if v:GetDistanceSqToPoint(pt) < radius * radius then
            return true
        end
    end
    return false
end

--------

GLOBAL.GetAllKnownRecipes = function()
    local valid_recipes = Common_Recipes
    valid_recipes = MergeMaps(valid_recipes, Vanilla_Recipes)
    valid_recipes = MergeMaps(valid_recipes, RoG_Recipes)
    valid_recipes = MergeMaps(valid_recipes, Shipwrecked_Recipes)
	return valid_recipes
end

--蜂王行为树
GLOBAL.FailIfSuccessDecorator = Class(DecoratorNode, function(self, child)
    DecoratorNode._ctor(self, "FailIfSuccess", child)
end)

function FailIfSuccessDecorator:Visit()
	local child = self.children[1]
	child:Visit()
	if child.status == SUCCESS then
		self.status = FAILED
	else
		self.status = child.status
	end
end

--水中木叶子界面
local Leafcanopy = require "widgets/leafcanopy"
AddClassPostConstruct("screens/playerhud", function(self)
    local Old_CreateOverlays = self.CreateOverlays
    function self:CreateOverlays(owner)
        Old_CreateOverlays(self, owner)
        self.leafcanopy = self.overlayroot:AddChild(Leafcanopy(owner))       
    end

    local Old_OnUpdate = self.OnUpdate
    function self:OnUpdate(dt)
        Old_OnUpdate(self, dt)
        if self.leafcanopy then
            self.leafcanopy:OnUpdate(dt)
        end                 
    end   
end)

AddGlobalClassPostConstruct("vector3", "Vector3", function(self)
  function self:GetNormalizedAndLength()
    local len = self:Length()
    return (len > 0 and self / len) or self, len
  end
end)

AddGlobalClassPostConstruct("entityscript", "EntityScript", function(self)
  function self.GetDistanceSqToInst(self, inst)
    local p1x, p1y, p1z = self.Transform:GetWorldPosition()
    local p2x, p2y, p2z = inst.Transform:GetWorldPosition()
    if p1x and p1z and p2x and p2z then
      return distsq(p1x, p1z, p2x, p2z)
    else
      return 100
    end
  end

  function self:GetDistanceSqToPoint(x, y, z)
    if y == nil and z == nil and x ~= nil then
        x, y, z = x:Get()
    end
    local x1, y1, z1 = self.Transform:GetWorldPosition()
    return distsq(x, z, x1, z1)
  end
  
  function self:SetPhysicsRadiusOverride(radius)
    self.physicsradiusoverride = radius
  end

  function self:GetPhysicsRadius(default)
    return self.physicsradiusoverride or (self.Physics ~= nil and self.Physics:GetRadius()) or default
  end

  function self:IsOnPassablePoint(include_water, floating_platforms_are_not_passable)
    local x, y, z = self.Transform:GetWorldPosition()
    return IsPassableAtPoint(x, y, z, include_water or false, floating_platforms_are_not_passable or false)
  end

  function self:IsNearPlayer(range, isalive)
    local x, y, z = self.Transform:GetWorldPosition()
    return IsAnyPlayerInRange(x, y, z, range, isalive)
  end

  -- DST API 补充：IsNear(other, range) - 检查两个实体是否在指定距离内
  function self:IsNear(other, range)
    if other == nil then return false end
    local x1, y1, z1 = self.Transform:GetWorldPosition()
    local x2, y2, z2 = other.Transform:GetWorldPosition()
    local dx, dz = x1 - x2, z1 - z2
    return dx * dx + dz * dz <= range * range
  end

  function self:SetEngaged(engaged)
    -- DST API stub for DS compatibility: no-op
  end
  
 --暗影织影者
function EntityScript:DebuffsEnabled()
    return self.components.debuffable == nil or self.components.debuffable:IsEnabled()
end

function EntityScript:HasDebuff(name)
    return (self.components.debuffable ~= nil and self.components.debuffable:HasDebuff(name))
        or false
end

function EntityScript:GetDebuff(name)
    return (self.components.debuffable ~= nil and self.components.debuffable:GetDebuff(name))
        or nil
end

function EntityScript:AddDebuff(name, prefab, data, skip_test, pre_buff_fn)
    if self.components.debuffable == nil then
        self:AddComponent("debuffable")
    end

    if skip_test or (self:DebuffsEnabled()) then -- and not IsEntityDeadOrGhost(self)) then
        if pre_buff_fn then
            pre_buff_fn()
        end
        self.components.debuffable:AddDebuff(name, prefab, data)
        return true
    end

    return false
end

function EntityScript:RemoveDebuff(name)
    if self.components.debuffable then
        self.components.debuffable:RemoveDebuff(name)
    end
end
end)

--克劳斯、蛤蟆物理
GLOBAL.MakeGiantCharacterPhysics = function(inst, mass, rad)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.GIANTS or 16384)
    phys:ClearCollisionMask()
    phys:CollidesWith(SJ and COLLISION.WORLD or 192)
    phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS or 16384)
    phys:SetCapsule(rad, 1)
    return phys
end

--增加天体、克眼飞行物理
GLOBAL.MakeTinyFlyingCharacterPhysics = function(inst, mass, rad)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.CHARACTERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.GROUND)
    phys:SetCapsule(rad, 1)
end

--暗影三基佬
GLOBAL.MakeSmallHeavyObstaclePhysics = function(inst, rad, height)
    inst:AddTag("blocker")
    local phys = inst.entity:AddPhysics()
    --inventory physics
    phys:SetFriction(.1)
    phys:SetDamping(0)
    phys:SetRestitution(0)
    --obstacle physics
    phys:SetMass(0)
    phys:SetCollisionGroup(COLLISION.SMALLOBSTACLES or 8192)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.ITEMS)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:SetCapsule(rad, height or 2)
    return phys
end
--[[
GLOBAL.MakeInventoryPhysics = function(inst)
    inst.entity:AddPhysics()
    inst.Physics:SetSphere(.5)
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(.1)
    inst.Physics:SetDamping(0)
    inst.Physics:SetRestitution(.5)
    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND) 
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
end
--]]
--暗影三基佬
GLOBAL.GROUND_FLOORING =
{
    [GROUND.WOODFLOOR] = true,
    [GROUND.CARPET] = true,
    [GROUND.CHECKER] = true,
    --[GROUND.SCALE] = true,
}

GLOBAL.CanPlantAtPoint = function(x, y, z)
    local tile = GetWorld().Map:GetTileAtPoint(x, y, z)
    return tile ~= GROUND.ROCKY and
        tile ~= GROUND.ROAD and
        tile ~= GROUND.UNDERROCK and
        tile < GROUND.UNDERGROUND and
        tile ~= GROUND.IMPASSABLE and
        tile ~= GROUND.INVALID and
        not GROUND_FLOORING[tile]
end

GLOBAL.MakeMediumPropagator = function(inst)
    inst:AddComponent("propagator")
    inst.components.propagator.acceptsheat = true
    inst.components.propagator:SetOnFlashPoint(DefaultIgniteFn)
    inst.components.propagator.flashpoint = 15+math.random()*10
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.propagaterange = 5 + math.random()*2
    inst.components.propagator.heatoutput = 5 + math.random()*3.5--12

    inst.components.propagator.damagerange = 3
    inst.components.propagator.damages = true
end

--暗影织影者
GLOBAL.IsDeployPointClear = function(pt, inst, min_spacing, min_spacing_sq_fn, near_other_fn, check_player, custom_ignore_tags)
    local min_spacing_sq = min_spacing ~= nil and min_spacing * min_spacing or nil
    near_other_fn = near_other_fn or IsNearOther
    for i, v in ipairs(TheSim:FindEntities(pt.x, 0, pt.z, math.max(DEPLOY_EXTRA_SPACING, min_spacing), nil, custom_ignore_tags ~= nil and custom_ignore_tags or check_player and DEPLOY_IGNORE_TAGS_NOPLAYER or DEPLOY_IGNORE_TAGS)) do
        if v ~= inst and
            v.entity:IsVisible() and
            v.components.placer == nil and
            v.entity:GetParent() == nil then --and
            --near_other_fn(v, pt, min_spacing_sq_fn ~= nil and min_spacing_sq_fn(v) or min_spacing_sq) then
            return false
        end
    end
    return true
end

-- ==================== DST 扩展 CommonHandlers / CommonStates ====================
-- DS 游戏引擎启动时已缓存自带的 stategraphs/commonstates.lua，
-- 其中只有 OnSleep/OnWake 等标准 handlers，没有 DST 专属的 OnSleepEx 等。
-- 而模组 SG 文件 require("stategraphs/commonstates") 会取到缓存版本，
-- 导致 OnSleepEx 为 nil 而崩溃。
-- 这里将 DST 专属定义补充到现有 CommonHandlers/CommonStates 表中。

if CommonHandlers.OnSleepEx == nil then
    local function onsleepex(inst)
        inst.sg.mem.sleeping = true
        if not (inst.sg:HasStateTag("nosleep") or inst.sg:HasStateTag("sleeping") or
                (inst.components.health ~= nil and inst.components.health:IsDead())) then
            inst.sg:GoToState("sleep")
        end
    end
    CommonHandlers.OnSleepEx = function()
        return EventHandler("gotosleep", onsleepex)
    end
end

if CommonHandlers.OnWakeEx == nil then
    local function onwakeex(inst)
        inst.sg.mem.sleeping = false
        if inst.sg:HasStateTag("sleeping") and not inst.sg:HasStateTag("nowake") and
            not (inst.components.health ~= nil and inst.components.health:IsDead()) then
            inst.sg.statemem.continuesleeping = true
            inst.sg:GoToState("wake")
        end
    end
    CommonHandlers.OnWakeEx = function()
        return EventHandler("onwakeup", onwakeex)
    end
end

if CommonHandlers.OnFreezeEx == nil then
    local function onfreezeex(inst)
        if not (inst.components.health ~= nil and inst.components.health:IsDead()) then
            inst.sg:GoToState("frozen")
        end
    end
    CommonHandlers.OnFreezeEx = function()
        return EventHandler("freeze", onfreezeex)
    end
end

if CommonStates.AddSleepExStates == nil then
    local function sleepexonanimover(inst)
        if inst.AnimState:AnimDone() then
            inst.sg.statemem.continuesleeping = true
            inst.sg:GoToState(inst.sg.mem.sleeping and "sleeping" or "wake")
        end
    end
    local function sleepingexonanimover(inst)
        if inst.AnimState:AnimDone() then
            inst.sg.statemem.continuesleeping = true
            inst.sg:GoToState("sleeping")
        end
    end
    local function wakeexonanimover(inst)
        if inst.AnimState:AnimDone() then
            inst.sg:GoToState(inst.sg.mem.sleeping and "sleep" or "idle")
        end
    end
    CommonStates.AddSleepExStates = function(states, timelines, fns)
        table.insert(states, State{
            name = "sleep",
            tags = { "busy", "sleeping", "nowake" },
            onenter = function(inst)
                if inst.components.locomotor ~= nil then
                    inst.components.locomotor:StopMoving()
                end
                inst.AnimState:PlayAnimation("sleep_pre")
                if fns ~= nil and fns.onsleep ~= nil then
                    fns.onsleep(inst)
                end
            end,
            timeline = timelines ~= nil and timelines.starttimeline or nil,
            events = { EventHandler("animover", sleepexonanimover) },
            onexit = function(inst)
                if not inst.sg.statemem.continuesleeping and inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                    inst.components.sleeper:WakeUp()
                end
                if fns ~= nil and fns.onexitsleep ~= nil then
                    fns.onexitsleep(inst)
                end
            end,
        })
        table.insert(states, State{
            name = "sleeping",
            tags = { "busy", "sleeping" },
            onenter = function(inst)
                inst.AnimState:PlayAnimation("sleep_loop")
                if fns ~= nil and fns.onsleeping ~= nil then
                    fns.onsleeping(inst)
                end
            end,
            timeline = timelines ~= nil and timelines.sleeptimeline or nil,
            events = { EventHandler("animover", sleepingexonanimover) },
            onexit = function(inst)
                if not inst.sg.statemem.continuesleeping and inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                    inst.components.sleeper:WakeUp()
                end
                if fns ~= nil and fns.onexitsleeping ~= nil then
                    fns.onexitsleeping(inst)
                end
            end,
        })
        table.insert(states, State{
            name = "wake",
            tags = { "busy", "waking", "nosleep" },
            onenter = function(inst)
                if inst.components.locomotor ~= nil then
                    inst.components.locomotor:StopMoving()
                end
                inst.AnimState:PlayAnimation("sleep_pst")
                if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                    inst.components.sleeper:WakeUp()
                end
                if fns ~= nil and fns.onwake ~= nil then
                    fns.onwake(inst)
                end
            end,
            timeline = timelines ~= nil and timelines.waketimeline or nil,
            events = { EventHandler("animover", wakeexonanimover) },
            onexit = fns ~= nil and fns.onexitwake or nil,
        })
    end
end

if CommonStates.AddFrozenStates2 == nil then
    local function onunfreeze(inst)
        inst.sg:GoToState(inst.sg.sg.states.hit ~= nil and "hit" or "idle")
    end
    local function onthaw(inst)
        inst.sg:GoToState("thaw")
    end
    local function onenterfrozenpre(inst)
        if inst.components.locomotor ~= nil then
            inst.components.locomotor:StopMoving()
        end
        inst.AnimState:PlayAnimation("frozen")
        inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
        inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
    end
    local function onenterfrozenpst(inst)
        if inst.components.freezable == nil then
            onunfreeze(inst)
        elseif inst.components.freezable:IsThawing() then
            onthaw(inst)
        elseif not inst.components.freezable:IsFrozen() then
            onunfreeze(inst)
        end
    end
    local function onexitfrozen(inst)
        inst.AnimState:ClearOverrideSymbol("swap_frozen")
    end
    local function onenterthawpre(inst)
        if inst.components.locomotor ~= nil then
            inst.components.locomotor:StopMoving()
        end
        inst.AnimState:PlayAnimation("frozen_loop_pst", true)
        inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
        inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
    end
    local function onenterthawpst(inst)
        if inst.components.freezable == nil or not inst.components.freezable:IsFrozen() then
            onunfreeze(inst)
        end
    end
    local function onexitthaw(inst)
        inst.SoundEmitter:KillSound("thawing")
        inst.AnimState:ClearOverrideSymbol("swap_frozen")
    end
    CommonStates.AddFrozenStates2 = function(states, onoverridesymbols, onclearsymbols)
        table.insert(states, State{
            name = "frozen",
            tags = { "busy", "frozen" },
            onenter = onoverridesymbols ~= nil and function(inst)
                onenterfrozenpre(inst)
                onoverridesymbols(inst)
                onenterfrozenpst(inst)
            end or function(inst)
                onenterfrozenpre(inst)
                onenterfrozenpst(inst)
            end,
            events = {
                EventHandler("unfreeze", onunfreeze),
                EventHandler("onthaw", onthaw),
            },
            onexit = onclearsymbols ~= nil and function(inst)
                onexitfrozen(inst)
                onclearsymbols(inst)
            end or onexitfrozen,
        })
        table.insert(states, State{
            name = "thaw",
            tags = { "busy", "thawing" },
            onenter = onoverridesymbols ~= nil and function(inst)
                onenterthawpre(inst)
                onoverridesymbols(inst)
            end or onenterthawpre,
            events = { EventHandler("unfreeze", onunfreeze) },
            onexit = onclearsymbols ~= nil and function(inst)
                onexitthaw(inst)
                onclearsymbols(inst)
            end or onexitthaw,
        })
    end
end

-- ==================== 补充: OnNoSleepAnimOver ====================
if CommonHandlers.OnNoSleepAnimOver == nil then
    CommonHandlers.OnNoSleepAnimOver = function(nextstate)
        return EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                if inst.sg.mem.sleeping then
                    inst.sg:GoToState("sleep")
                elseif type(nextstate) == "string" then
                    inst.sg:GoToState(nextstate)
                elseif nextstate ~= nil then
                    nextstate(inst)
                end
            end
        end)
    end
end

-- ==================== 补充: OnNoSleepTimeEvent ====================
if CommonHandlers.OnNoSleepTimeEvent == nil then
    CommonHandlers.OnNoSleepTimeEvent = function(t, fn)
        return TimeEvent(t, function(inst)
            if inst.sg.mem.sleeping and not (inst.components.health ~= nil and inst.components.health:IsDead()) then
                inst.sg:GoToState("sleep")
            elseif fn ~= nil then
                fn(inst)
            end
        end)
    end
end

-- ==================== 补充: HitRecoveryDelay ====================
if CommonHandlers.HitRecoveryDelay == nil then
    local function hit_recovery_delay(inst, delay, max_hitreacts, skip_cooldown_fn)
        local on_cooldown = false
        if (inst._last_hitreact_time ~= nil and inst._last_hitreact_time + (delay or inst.hit_recovery or TUNING.DEFAULT_HIT_RECOVERY) >= GetTime()) then
            max_hitreacts = max_hitreacts or inst._max_hitreacts
            if max_hitreacts then
                if inst._hitreact_count == nil then
                    inst._hitreact_count = 2
                    return false
                elseif inst._hitreact_count < max_hitreacts then
                    inst._hitreact_count = inst._hitreact_count + 1
                    return false
                end
            end
            skip_cooldown_fn = skip_cooldown_fn or inst._hitreact_skip_cooldown_fn
            if skip_cooldown_fn ~= nil then
                on_cooldown = not skip_cooldown_fn(inst, inst._last_hitreact_time, delay)
            elseif inst.components.combat ~= nil then
                on_cooldown = not (inst.components.combat:InCooldown() and inst.sg:HasStateTag("idle"))
            else
                on_cooldown = true
            end
        end
        if inst._hitreact_count ~= nil and not on_cooldown then
            inst._hitreact_count = 1
        end
        return on_cooldown
    end
    CommonHandlers.HitRecoveryDelay = hit_recovery_delay
end

-- ==================== 补充: UpdateHitRecoveryDelay ====================
if CommonHandlers.UpdateHitRecoveryDelay == nil then
    CommonHandlers.UpdateHitRecoveryDelay = function(inst)
        inst._last_hitreact_time = GetTime()
    end
end

-- ==================== 补充: AddHitState ====================
if CommonStates.AddHitState == nil then
    local function idleonanimover(inst)
        if inst.AnimState:AnimDone() then
            inst.sg:GoToState("idle")
        end
    end
    CommonStates.AddHitState = function(states, timeline, anim)
        table.insert(states, State{
            name = "hit",
            tags = { "hit", "busy" },
            onenter = function(inst)
                if inst.components.locomotor ~= nil then
                    inst.components.locomotor:StopMoving()
                end
                local hitanim = (anim == nil and "hit") or (type(anim) ~= "function" and anim) or anim(inst)
                inst.AnimState:PlayAnimation(hitanim)
                if inst.SoundEmitter ~= nil and inst.sounds ~= nil and inst.sounds.hit ~= nil then
                    inst.SoundEmitter:PlaySound(inst.sounds.hit)
                end
            end,
            timeline = timeline,
            events = { EventHandler("animover", idleonanimover) },
        })
    end
end
