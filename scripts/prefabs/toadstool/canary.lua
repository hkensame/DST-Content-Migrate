--[[
canary.lua
金丝雀（Canary）
移植自 A New Reign DLC
完整金丝雀→中毒金丝雀链条：
  在鸟笼中的金丝雀靠近毒菌蛤蟆毒气 → 吸入毒气 → 变为中毒金丝雀
依赖资源：anim/canary.zip, anim/canary_build.zip, sound/birds.fsb
]]--

local brain = require "brains/birdbrain"

local function ShouldSleep(inst)
    return DefaultSleepTest(inst) and not inst.sg:HasStateTag("flight")
end

local BIRD_TAGS = { "bird" }
local function OnAttacked(inst, data)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, BIRD_TAGS)
    local num_friends = 0
    local maxnum = 5
    for k, v in pairs(ents) do
        if v ~= inst then
            v:PushEvent("gohome")
            num_friends = num_friends + 1
        end
        if num_friends > maxnum then
            return
        end
    end
end

local function OnTrapped(inst, data)
    if data and data.trapper and data.trapper.settrapsymbols then
        data.trapper.settrapsymbols(inst.trappedbuild)
    end
end

local function OnPutInInventory(inst)
    inst.sg:GoToState("idle")
end

local function OnDropped(inst)
    inst.sg:GoToState("stunned")
end

--------------------------------------------------------------------------
-- 毒气交互（金丝雀→中毒金丝雀）
--------------------------------------------------------------------------

local function StopExhalingGas(inst)
    if inst._gasdowntask ~= nil then
        inst._gasdowntask:Cancel()
        inst._gasdowntask = nil
    end
end

local function OnExhaleGas(inst)
    if inst._gaslevel > 1 then
        inst._gaslevel = inst._gaslevel - 1
    else
        inst._gaslevel = 0
        StopExhalingGas(inst)
    end
end

local function StartExhalingGas(inst)
    if inst._gaslevel > 0 and inst._gasdowntask == nil then
        inst._gasdowntask = inst:DoPeriodicTask(TUNING.SEG_TIME, OnExhaleGas, TUNING.SEG_TIME * (.5 + math.random() * .5))
    end
end

local function TestGasLevel(inst, gaslevel)
    --Trigger with increasing chance from level 12 -> 24
    if gaslevel > 12 and math.random() * 12 < gaslevel - 12 then
        local cage = inst.components.occupier:GetOwner()
        if cage ~= nil and cage:HasTag("cage") then
            local data = { bird = inst, poisoned_prefab = "canary_poisoned" }
            TheWorld:PushEvent("birdpoisoned", data)
            cage:PushEvent("birdpoisoned", data)
        end
    end
end

local function OnInhaleGas(inst)
    if TheWorld.components.toadstoolspawner:IsEmittingGas() then
        inst._gaslevel = inst._gaslevel + 1
        TestGasLevel(inst, inst._gaslevel)
    elseif inst._gaslevel > 0 then
        inst._gaslevel = math.max(0, inst._gaslevel - 1)
    end
end

local function StopInhalingGas(inst)
    if inst._gasuptask ~= nil then
        inst._gasuptask:Cancel()
        inst._gasuptask = nil
        StartExhalingGas(inst)
    end
end

local function StartInhalingGas(inst)
    if inst._gasuptask == nil then
        inst._gasuptask = inst:DoPeriodicTask(TUNING.SEG_TIME, OnInhaleGas, TUNING.SEG_TIME * (.5 + math.random() * .5))
        StopExhalingGas(inst)
    end
end

local function OnCanaryOccupied(inst, cage)
    if cage ~= nil and cage:HasTag("cage") then
        StartInhalingGas(inst)
    else
        StopInhalingGas(inst)
    end
end

local function OnCanarySave(inst, data)
    data.gaslevel = inst._gaslevel > 0 and math.ceil(inst._gaslevel) or nil
end

local function OnCanaryLoad(inst, data)
    if data ~= nil and data.gaslevel ~= nil then
        inst._gaslevel = math.max(0, math.floor(data.gaslevel))
    end
end

--------------------------------------------------------------------------
-- 资源
--------------------------------------------------------------------------

local assets =
{
    Asset("ANIM", "anim/crow.zip"),
    Asset("ANIM", "anim/toadstool/canary_build.zip"),
    Asset("SOUND", "sound/birds.fsb"),
}

local prefabs =
{
    "seeds",
    "smallmeat",
    "cookedsmallmeat",
    "flint",
    "twigs",
    "cutgrass",
    "feather_canary",
    "canary_poisoned",
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddPhysics()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()

    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    if IsDLCEnabled(PORKLAND_DLC) then
        inst.Physics:CollidesWith(COLLISION.WORLD_01)
    else
        inst.Physics:CollidesWith(COLLISION.WORLD)
    end
    inst.Physics:SetMass(1)
    inst.Physics:SetSphere(1)

    inst:AddTag("bird")
    inst:AddTag("canary")
    inst:AddTag("smallcreature")
    inst:AddTag("likewateroffducksback")
    inst:AddTag("stunnedbybomb")
    inst:AddTag("noember")
    inst:AddTag("cookable")

    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank("crow")
    inst.AnimState:SetBuild("canary_build")
    inst.AnimState:PlayAnimation("idle")

    inst.DynamicShadow:SetSize(1, .75)
    inst.DynamicShadow:Enable(false)

    inst.sounds =
    {
        takeoff = "dontstarve/birds/takeoff_canary",
        chirp = "dontstarve/birds/chirp_canary",
        flyin = "dontstarve/birds/flyin",
    }

    inst.trappedbuild = "canary_build"

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst:SetStateGraph("SGbird")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("feather_canary", 1)
    inst.components.lootdropper:AddRandomLoot("smallmeat", 1)
    inst.components.lootdropper.numrandomloot = 1

    inst:AddComponent("occupier")

    inst:AddComponent("eater")
    inst.components.eater:SetBird()

    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true
    inst.components.sleeper:SetSleepTest(ShouldSleep)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true
    inst.components.inventoryitem.imagename = "canary"
    inst.components.inventoryitem.atlasname = "images/canary.xml"

    inst:AddComponent("cookable")
    inst.components.cookable.product = "cookedsmallmeat"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BIRD_HEALTH)
    inst.components.health.murdersound = "dontstarve/wilson/hit_animal"

    inst:AddComponent("inspectable")

    inst.flyawaydistance = TUNING.BIRD_SEE_THREAT_DISTANCE

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "crow_body"

    MakeSmallBurnableCharacter(inst, "crow_body")
    MakeTinyFreezableCharacter(inst, "crow_body")

    inst:SetBrain(brain)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("seeds")
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:SetMinimumSpacing(8)

    inst:ListenForEvent("ontrapped", OnTrapped)
    inst:ListenForEvent("attacked", OnAttacked)

    local birdspawner = GetWorld().components.birdspawner
    inst:ListenForEvent("onremove", StopTrackingInSpawner)
    inst:ListenForEvent("enterlimbo", StopTrackingInSpawner)
    if birdspawner ~= nil then
        inst:ListenForEvent("exitlimbo", birdspawner.StartTrackingFn)
    end

    if IsDLCEnabled(REIGN_OF_GIANTS) or IsDLCEnabled(CAPY_DLC) or IsDLCEnabled(PORKLAND_DLC) then
        MakeFeedablePet(inst, TUNING.BIRD_PERISH_TIME, OnPutInInventory, OnDropped)
    end

    -- 金丝雀毒气交互：在鸟笼中靠近毒菌蛤蟆毒气 → 变为中毒金丝雀
    if TheWorld.components.toadstoolspawner ~= nil then
        inst.components.occupier.onoccupied = OnCanaryOccupied
        inst:ListenForEvent("exitlimbo", StopInhalingGas)
        inst._gasuptask = nil
        inst._gasdowntask = nil
        inst._gaslevel = 0

        inst:ListenForEvent("birdpoisoned", function(world, data)
            if data.bird ~= inst then
                inst._gaslevel = math.min(inst._gaslevel, math.random(6) - 1)
            end
        end, TheWorld)

        inst.OnSave = OnCanarySave
        inst.OnLoad = OnCanaryLoad
    end

    return inst
end

local function TrackInSpawner(inst)
    local ground = GetWorld()
    if ground and ground.components.birdspawner then
        ground.components.birdspawner:StartTracking(inst)
    end
end

local function StopTrackingInSpawner(inst)
    local ground = GetWorld()
    if ground and ground.components.birdspawner then
        ground.components.birdspawner:StopTracking(inst)
    end
end

return Prefab("canary", fn, assets, prefabs)
