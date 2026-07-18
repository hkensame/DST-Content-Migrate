-- 猴子投射物 (monkeyprojectile)
-- 移植自 DST，适配 DS 单机模式
-- 移除：AddNetwork, SetPristine, ismastersim 网络门控
-- 适配：TheWorld.Map:IsPointNearHole → rawget 保护（DS 无海洋）

local assets =
{
    Asset("ANIM", "anim/monkey_projectile.zip"),
}

local prefabs =
{
    "poop",
    "splash_ocean",
}

local function SplashOceanPoop(poop)
    if not poop.components.inventoryitem:IsHeld() then
        local x, y, z = poop.Transform:GetWorldPosition()
        -- DS 无海洋系统，IsPointNearHole 可能不存在
        local near_hole = false
        local world = rawget(_G, "TheWorld")
        if world and world.Map and world.Map.IsPointNearHole then
            near_hole = world.Map:IsPointNearHole(Vector3(x, 0, z))
        end
        if not poop:IsOnValidGround() or near_hole then
            SpawnPrefab("splash_ocean").Transform:SetPosition(x, y, z)
            poop:Remove()
        end
    end
end

local function SpawnPoop(inst, owner, target)
    local poop = SpawnPrefab("poop")
    poop.SoundEmitter:PlaySound("dontstarve/creatures/monkey/poopsplat")
    if target ~= nil and target:IsValid() then
        LaunchAt(poop, target, owner ~= nil and owner:IsValid() and owner or inst)
    else
        poop.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if poop:IsAsleep() then
            SplashOceanPoop(poop)
        else
            poop:DoTaskInTime(8 * FRAMES, SplashOceanPoop)
        end
    end
end

local function OnHit(inst, owner, target)
    if target.components.sanity ~= nil then
        target.components.sanity:DoDelta(-TUNING.SANITY_SMALL)
    end
    SpawnPoop(inst, owner, target)
    target:PushEvent("attacked", { attacker = owner, damage = 0 })
    inst:Remove()
end

local function OnMiss(inst, owner, target)
    SpawnPoop(inst, owner, nil)
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetFourFaced()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("monkey_projectile")
    inst.AnimState:SetBuild("monkey_projectile")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("projectile")

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(25)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(1.5)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile.range = 30

    return inst
end

return Prefab("monkeyprojectile", fn, assets, prefabs)
