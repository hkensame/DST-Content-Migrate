require "prefabutil"

-- DS 兼容：prefab 中安全访问 TheWorld
local _TheWorld = rawget(_G, "TheWorld")

local assets =
{
    Asset("ANIM", "anim/wall.zip"),
    Asset("ANIM", "anim/wall_dreadstone.zip"),
    Asset("ATLAS", "images/wall_dreadstone.xml"),
}

local prefabs =
{
    "collapse_small",
}

local anims =
{
    { threshold = 0, anim = "broken" },
    { threshold = 0.4, anim = "onequarter" },
    { threshold = 0.5, anim = "half" },
    { threshold = 0.99, anim = "threequarter" },
    { threshold = 1, anim = { "fullA", "fullB", "fullC" } },
}

local function resolveanimtoplay(inst, percent)
    for i, v in ipairs(anims) do
        if percent <= v.threshold then
            if type(v.anim) == "table" then
                local x, y, z = inst.Transform:GetWorldPosition()
                local x = math.floor(x)
                local z = math.floor(z)
                local q1 = #v.anim + 1
                local q2 = #v.anim + 4
                local t = (((x % q1) * (x + 3) % q2) + ((z % q1) * (z + 3) % q2)) % #v.anim + 1
                return v.anim[t]
            else
                return v.anim
            end
        end
    end
end

local function makeobstacle(inst)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:SetMass(0)
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    if rawget(_G, "COLLISION") and COLLISION.WAVES then
        inst.Physics:CollidesWith(COLLISION.WAVES)
    end
    inst.Physics:SetActive(true)
    local ground = GetWorld()
    if ground then
        local pt = Point(inst.Transform:GetWorldPosition())
        ground.Pathfinder:AddWall(pt.x, pt.y, pt.z)
    end
end

local function clearobstacle(inst)
    inst:DoTaskInTime(2 * FRAMES, function()
        if inst:IsValid() then
            inst.Physics:SetActive(false)
        end
    end)
    local ground = GetWorld()
    if ground then
        local pt = Point(inst.Transform:GetWorldPosition())
        ground.Pathfinder:RemoveWall(pt.x, pt.y, pt.z)
    end
end

local function onhealthchange(inst, old_percent, new_percent)
    local anim_to_play = resolveanimtoplay(inst, new_percent)
    if new_percent > 0 then
        if old_percent <= 0 then
            makeobstacle(inst)
        end
        inst.AnimState:PlayAnimation(anim_to_play .. "_hit")
        inst.AnimState:PushAnimation(anim_to_play, false)
    else
        if old_percent > 0 then
            clearobstacle(inst)
        end
        inst.AnimState:PlayAnimation(anim_to_play)
    end
end

local function keeptargetfn()
    return false
end

local function ondeploywall(inst, pt, deployer)
    local wall = SpawnPrefab("wall_dreadstone")
    if wall then
        local x = math.floor(pt.x) + .5
        local z = math.floor(pt.z) + .5
        wall.Physics:SetCollides(false)
        wall.Physics:Teleport(x, 0, z)
        wall.Physics:SetCollides(true)
        inst.components.stackable:Get():Remove()

        local ground = GetWorld()
        if ground then
            ground.Pathfinder:AddWall(x, 0, z)
        end
    end
end

local function test_wall(inst, pt)
    local map = GetWorld().Map
    local tiletype = GetGroundTypeAtPosition(pt)
    local ground_OK = tiletype ~= GROUND.IMPASSABLE
    ground_OK = ground_OK and not map:IsWater(tiletype)

    if ground_OK then
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 2, nil, {"NOBLOCK", "player", "FX", "INLIMBO", "DECOR"})

        for k, v in pairs(ents) do
            if v ~= inst and v:IsValid() and v.entity:IsVisible() and not v.components.placer and v.parent == nil then
                local dsq = distsq(Vector3(v.Transform:GetWorldPosition()), pt)
                if v:HasTag("wall") then
                    if dsq < 0.1 then return false end
                else
                    if dsq < 1 then return false end
                end
            end
        end

        local playerPos = GetPlayer():GetPosition()
        local xDiff = playerPos.x - pt.x
        local zDiff = playerPos.z - pt.z
        local dsq = xDiff * xDiff + zDiff * zDiff
        if dsq < .5 then
            return false
        end
        return true
    end
    return false
end

local function onhammered(inst, worker)
    local healthpercent = inst.components.health:GetPercent()
    local num_loots = math.max(1, math.floor(2 * healthpercent))

    for k = 1, num_loots do
        inst.components.lootdropper:SpawnLootPrefab("dreadstone")
    end

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")

    inst:Remove()
end

local function onhit(inst, data)
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")

    local healthpercent = inst.components.health:GetPercent()
    if healthpercent > 0 then
        local anim_to_play = resolveanimtoplay(inst, healthpercent)
        inst.AnimState:PlayAnimation(anim_to_play .. "_hit")
        inst.AnimState:PushAnimation(anim_to_play, false)
    end
end

local function onrepaired(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone")
    makeobstacle(inst)
end

local function onload(inst, data)
    if inst.components.health:IsDead() then
        clearobstacle(inst)
    end
end

local function onremoveentity(inst)
    clearobstacle(inst)
end

local function ValidRepairFn(inst)
    if inst.Physics:IsActive() then
        return true
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    if _TheWorld ~= nil and _TheWorld.Map:IsAboveGroundAtPoint(x, y, z) then
        return true
    end

    if _TheWorld ~= nil and _TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
        for i, v in ipairs(TheSim:FindEntities(x, 0, z, 1, {"player"})) do
            if v ~= inst and
                v.entity:IsVisible() and
                v.components.placer == nil and
                v.entity:GetParent() == nil then
                local px, _, pz = v.Transform:GetWorldPosition()
                if math.floor(x) == math.floor(px) and math.floor(z) == math.floor(pz) then
                    return false
                end
            end
        end
    end
    return true
end

local function itemfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)

    inst:AddTag("wallbuilder")

    inst.AnimState:SetBank("wall_dreadstone")
    inst.AnimState:SetBuild("wall_dreadstone")
    inst.AnimState:PlayAnimation("idle")
    if inst.AnimState.SetSymbolLightOverride then
        inst.AnimState:SetSymbolLightOverride("wall_segment_red", 1)
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/wall_dreadstone.xml"
    inst.components.inventoryitem.imagename = "wall_dreadstone"

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = "dreadstone"
    inst.components.repairer.healthrepairvalue = TUNING.REPAIR_DREADSTONE_HEALTH or (TUNING.DREADSTONEWALL_HEALTH / 6)

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploywall
    inst.components.deployable.test = test_wall
    inst.components.deployable.min_spacing = 0
    inst.components.deployable.placer = "wall_dreadstone_placer"
    inst.components.deployable.deploydistance = 1.5

    return inst
end

local function fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    trans:SetEightFaced()

    inst:AddTag("wall")
    inst:AddTag("stone")
    inst:AddTag("dreadstone")
    inst:AddTag("noauradamage")
    inst:AddTag("electricdamageimmune")

    MakeObstaclePhysics(inst, .5)
    inst.entity:SetCanSleep(false)

    anim:SetBank("wall_dreadstone")
    anim:SetBuild("wall_dreadstone")
    anim:PlayAnimation("half")
    if inst.AnimState.SetSymbolLightOverride then
        inst.AnimState:SetSymbolLightOverride("wall_segment_red", 1)
    end

    makeobstacle(inst)

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial = "dreadstone"
    inst.components.repairable.onrepaired = onrepaired
    inst.components.repairable.testvalidrepairfn = ValidRepairFn

    inst:AddComponent("combat")
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat.onhitfn = onhit

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.DREADSTONEWALL_HEALTH)
    inst.components.health.currenthealth = TUNING.DREADSTONEWALL_HEALTH / 2
    inst.components.health.ondelta = onhealthchange
    inst.components.health.nofadeout = true
    inst.components.health.canheal = false
    inst.components.health.fire_damage_scale = 0
    if inst.components.health.SetAbsorptionAmountFromPlayer then
        inst.components.health:SetAbsorptionAmountFromPlayer(TUNING.DREADSTONEWALL_PLAYERDAMAGEMOD)
    end

    inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(TUNING.DREADSTONEWALL_WORK)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst.OnLoad = onload
    inst.OnRemoveEntity = onremoveentity

    MakeSnowCovered(inst)

    return inst
end


return Prefab("wall_dreadstone", fn, assets, prefabs),
       Prefab("wall_dreadstone_item", itemfn, assets, {"wall_dreadstone", "wall_dreadstone_placer", "collapse_small"}),
       MakePlacer("wall_dreadstone_placer", "wall_dreadstone", "wall_dreadstone", "half", false, false, true, nil, nil, nil)
