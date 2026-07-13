local function removearrayvalue(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then table.remove(tbl, i) return true end
    end
    return false
end

local assets =
{
    Asset("ANIM", "anim/cave_hole.zip"),
}

local prefabs =
{
    "small_puff",
    "common/fx/cavehole_flick_warn",
    "common/fx/cavehole_flick",
}

local loot =
{
    greengem = 0.1,
    yellowgem = 0.4,
    orangegem = 0.4,
    purplegem = 0.4,
    thulecite = 1.0,
    thulecite_pieces = 1.0,
    nightmare_timepiece = 0.1,
}

local loot_stacksize =
{
    thulecite           = function() return math.random(3) end,
    thulecite_pieces    = function() return 4 + math.random(3) end,
}

for k, _ in pairs(loot) do
    table.insert(prefabs, k)
end

local function SetObjectInHole(inst, obj)
    obj.Physics:SetActive(false)
    obj:AddTag("outofreach")
    inst:ListenForEvent("onremove", inst._onremoveobj, obj)
    inst:ListenForEvent("onpickup", inst._onpickupobj, obj)
end

local function tryspawn(inst)
    if inst.allowspawn and #inst.components.objectspawner.objects <= 0 then
        local lootobj = inst.components.objectspawner:SpawnObject(weighted_random_choice(loot))

        if loot_stacksize[lootobj.prefab] ~= nil and lootobj.components.stackable ~= nil then
            local stacksize = loot_stacksize[lootobj.prefab]()
            lootobj.components.stackable:SetStackSize(stacksize)
        end

        local x, y, z = inst.Transform:GetWorldPosition()
        lootobj.Physics:Teleport(x, y, z)

        if not inst:IsAsleep() then
            SpawnPrefab("small_puff").Transform:SetPosition(x, y, z)
        end
    end

    inst.allowspawn = false
end

local function OnSave(inst, data)
    data.allowspawn = inst.allowspawn
end

local function OnLoad(inst, data)
    if data ~= nil then
        inst.allowspawn = data.allowspawn
    end
end

local function CreateSurfaceAnim()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.persists = false

    inst.AnimState:SetBank("cave_hole")
    inst.AnimState:SetBuild("cave_hole")
    inst.AnimState:Hide("hole")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst.Transform:SetEightFaced()

    return inst
end

local OUTER_RADIUS = 2.75
local INNER_RADIUS = 1.5
local FLICK_WARN_TIME = 2
local FLICK_TIME = 2 -- Additional time after FLICK_WARN_TIME.

local function ClearFlickTasks(player)
    if player._caveholecheck_task ~= nil then
        player._caveholecheck_task:Cancel()
        player._caveholecheck_task = nil
    end
    if player._cavehole_task ~= nil then
        player._cavehole_task:Cancel()
        player._cavehole_task = nil
    end
end

local function StopFlickIfAble(player)
    if player.components.health:IsDead() or player:HasTag("playerghost") then
        ClearFlickTasks(player)
        return true
    end
    return false
end

local function ShouldAvoidFlicking(player)
    return player:HasTag("wereplayer")
end

local function DoFlickOn(player, inst)
    if StopFlickIfAble(player) then
        return
    end

    player._cavehole_task = nil

    if ShouldAvoidFlicking(player) then
        return
    end

    if inst:IsValid() then
        local ex, _, ez = player.Transform:GetWorldPosition()
        SpawnPrefab("common/fx/cavehole_flick").Transform:SetPosition(ex, 0, ez)
        -- A fake redirected so that players do not see the red blood flash.
        player:PushEvent("attacked", { attacker = inst, damage = 0, redirected = player })
        player:PushEvent("knockback", { knocker = inst, radius = OUTER_RADIUS + 1 + math.random(), disablecollision = true })
    end
end

local function DoFlickWarnOn(player, inst)
    if StopFlickIfAble(player) then
        return
    end

    if player._cavehole_task ~= nil then
        if ShouldAvoidFlicking(player) then
            player._cavehole_task:Cancel()
            player._cavehole_task = nil
            return
        end
        local ex, _, ez = player.Transform:GetWorldPosition()
        SpawnPrefab("common/fx/cavehole_flick_warn").Transform:SetPosition(ex, 0, ez)
        -- Intentionally replacing this task tracker!
        player._cavehole_task = player:DoTaskInTime(FLICK_TIME, DoFlickOn, inst)
    end
end

local function CheckFlick(player, inst)
    if StopFlickIfAble(player) then
        return
    end

    if ShouldAvoidFlicking(player) then
        return
    end

    if player._cavehole_task == nil then
        player._cavehole_task = player:DoTaskInTime(FLICK_WARN_TIME, DoFlickWarnOn, inst)
    end
end

local function OnPlayerNear(inst)
	local player = GetPlayer()
	if player == nil then return end
    player._caveholecheck_task_count = (player._caveholecheck_task_count or 0) + 1
    if player._caveholecheck_task == nil then
        player._caveholecheck_task = player:DoPeriodicTask(1, CheckFlick, 0, inst)
    end
end

local function OnPlayerFar(inst)
	local player = GetPlayer()
	if player == nil then return end
    player._caveholecheck_task_count = (player._caveholecheck_task_count or 1) - 1
    if player._caveholecheck_task_count == 0 then
        player._caveholecheck_task_count = nil
        ClearFlickTasks(player)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    -- DS 无 AddNetwork（DST 网络系统）
    if inst.entity.AddNetwork then inst.entity:AddNetwork() end

    inst:AddTag("groundhole")
    inst._groundhole_innerradius = INNER_RADIUS
    inst._groundhole_outerradius = OUTER_RADIUS
    inst._groundhole_rangeoverride = 0
    inst:AddTag("blocker")
    inst:AddTag("blinkfocus")

    inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    if inst.Physics.SetCollisionMask then
        -- DST 专用
        inst.Physics:SetCollisionMask(
            COLLISION.ITEMS,
            COLLISION.CHARACTERS,
            COLLISION.GIANTS
        )
    elseif inst.Physics.ClearCollisionMask then
        -- DS 兼容：ClearCollisionMask + CollidesWith
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.ITEMS)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    end
    inst.Physics:SetCapsule(2, 2)

    inst.AnimState:SetBank("cave_hole")
    inst.AnimState:SetBuild("cave_hole")
    inst.AnimState:Hide("surface")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst.MiniMapEntity:SetIcon("cave_hole.png")

    inst.Transform:SetEightFaced()

	if inst.SetDeploySmartRadius then
	    inst:SetDeploySmartRadius(3)
	end

    --NOTE: Shadows are on WORLD_BACKGROUND sort order 1
    --      Hole goes above to hide shadows
    --      Surface goes below to reveal shadows
    --Dedicated server does not need to spawn the local animation
    local theNet = rawget(_G, "TheNet")
    if theNet and not theNet:IsDedicated() then
        CreateSurfaceAnim().entity:SetParent(inst.entity)
    end

    if inst.entity.SetPristine then inst.entity:SetPristine() end

    -- DS 单机无 ismastersim，始终继续执行
    local theWorld = rawget(_G, "TheWorld")
    if theWorld and theWorld.ismastersim == false then
        return inst
    end

    inst:AddComponent("objectspawner")
    inst.components.objectspawner.onnewobjectfn = SetObjectInHole

    inst:AddComponent("playerprox")
    -- DS 单机只有 GetPlayer()，无需 SetTargetMode
    --inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
    inst.components.playerprox:SetOnPlayerNear(OnPlayerNear)
    inst.components.playerprox:SetOnPlayerFar(OnPlayerFar)
    inst.components.playerprox:SetDist(OUTER_RADIUS, OUTER_RADIUS) -- In case a player manages to squeeze inside the doughnut physics.

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.allowspawn = true
    inst:DoTaskInTime(0, tryspawn)

    local theWorld = rawget(_G, "TheWorld")
    if theWorld then
        inst:ListenForEvent("resetruins", function()
            inst.allowspawn = true
            inst:DoTaskInTime(math.random() * .75, tryspawn)
        end, theWorld)
    end

    inst._onremoveobj = function(obj)
        removearrayvalue(inst.components.objectspawner.objects, obj)
    end

    inst._onpickupobj = function(obj)
        obj.Physics:SetActive(true)
        obj:RemoveTag("outofreach")
        inst._onremoveobj(obj)
        inst:RemoveEventCallback("onremove", inst._onremoveobj, obj)
        inst:RemoveEventCallback("onpickup", inst._onpickupobj, obj)
    end

    return inst
end

return Prefab("cave_hole", fn, assets, prefabs)

