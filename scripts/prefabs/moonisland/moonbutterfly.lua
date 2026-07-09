require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/butterfly_basic.zip"),
    Asset("ANIM", "anim/moonisland/butterfly_moon.zip"),
    Asset("ANIM", "anim/moonisland/baby_moon_tree.zip"),
    Asset("INV_IMAGE", "moonbutterfly"),
}

local prefabs =
{
    "moonbutterflywings",
    "moonbutterfly_sapling",
}

SetSharedLootTable("moonbutterfly",
{
    {"moonbutterflywings", 1.0},
})

local brain = require "brains/moonbutterflyxbrain"

local LIGHT_RADIUS = .5
local LIGHT_INTENSITY = .5
local LIGHT_FALLOFF = .8

local function OnUpdateFlicker(inst, starttime)
    local time = starttime ~= nil and (GetTime() - starttime) * 15 or 0
    local flicker = math.sin(time * 0.7 + math.sin(time * 6.28)) -- range = [-1 , 1]
    flicker = (1 + flicker) * .5 -- range = 0:1
    inst.Light:SetIntensity(LIGHT_INTENSITY + .05 * flicker)
end

local function OnDropped(inst)
    inst.components.perishable:StopPerishing() -- 野外暂停新鲜度衰减
    inst:RemoveTag("show_spoilage") -- 野外隐藏新鲜度条
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
    inst.Light:Enable(true)

    inst.sg:GoToState("idle")

    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
    end

    while inst.components.stackable:StackSize() > 1 do
        local item = inst.components.stackable:Get()
        if item ~= nil then
		item.Physics:Teleport(inst.Transform:GetWorldPosition())
            if item.components.inventoryitem ~= nil then
                item.components.inventoryitem:OnDropped()
            end
        end
    end
end

local function OnPickedUp(inst)
    inst.components.perishable:StartPerishing() -- 放入背包才开始新鲜度衰减
    inst:AddTag("show_spoilage") -- 背包中显示新鲜度条
    inst.Light:Enable(false)
end

local function OnWorked(inst, worker)
    -- 捕虫网捕获后保持当前新鲜度（与 carrat 行为一致）
    if worker.components.inventory ~= nil then
        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
        worker.SoundEmitter:PlaySound("dontstarve/common/butterfly_trap")
    end
end

local function OnDeploy(inst, pt, deployer)
    local moontree = SpawnPrefab("moonbutterfly_sapling")
    if moontree then
        moontree.Transform:SetPosition(pt:Get())
        moontree.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
        inst.components.stackable:Get():Remove()
    end
end

local function oneat(inst)
    if inst.components.perishable ~= nil then
        inst.components.perishable:SetPercent(1)
    end
end

local function onperish(inst)
    if inst:IsInLimbo() then
        inst:Remove()
    else
        inst.components.workable:SetWorkable(false)
	    inst.Light:Enable(false)
		inst.AnimState:SetLightOverride(0)
        inst:PushEvent("death")
        inst:RemoveTag("spore") -- so crowding no longer detects it
        inst.persists = false
        -- clean up when offscreen, because the death event is handled by the SG
        inst:DoTaskInTime(3, inst.Remove)
    end
end

local function ondeath(inst)
    inst.Light:Enable(false)
	inst.AnimState:SetLightOverride(0)
end

local function fn()
    local inst = CreateEntity()

    --Core components
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()

    --Initialize physics
	MakeCharacterPhysics(inst, 1, .5) --MakeTinyFlyingCharacterPhysics(inst, 1, .5)

    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBuild("butterfly_moon")
    inst.AnimState:SetBank("butterfly")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)
	inst.AnimState:SetLightOverride(0.15)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Light:SetFalloff(LIGHT_FALLOFF)
    inst.Light:SetIntensity(LIGHT_INTENSITY)
    inst.Light:SetRadius(LIGHT_RADIUS)
    inst.Light:SetColour(0.3, 0.55, 0.45)
    inst.Light:Enable(true)
    --inst.Light:EnableClientModulation(true)

    inst:AddTag("butterfly")
    inst:AddTag("moonbutterfly_tag") -- 供月蛾生成器追踪
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("insect")
    inst:AddTag("smallcreature")
    inst:AddTag("cattoyairborne")
    inst:AddTag("wildfireprotected")
    inst:AddTag("show_spoilage")
    inst:AddTag("small_livestock")
    inst:AddTag("deployedplant")
    -- 野外不显示新鲜度条（放入背包时由 OnPickedUp 添加）

    inst:DoPeriodicTask(.1, OnUpdateFlicker, nil, GetTime())
    OnUpdateFlicker(inst)

    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst)
    end

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = TUNING.MOONBUTTERFLY_SPEED

    inst:AddComponent("stackable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.pushlandedevents = false
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPickedUp)
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "butterfly_body"

    inst:AddComponent("knownlocations")

    MakeSmallBurnableCharacter(inst, "butterfly_body")
    MakeTinyFreezableCharacter(inst, "butterfly_body")

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('moonbutterfly')

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnWorked)

    ------------------
    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = OnDeploy
    --inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
	--inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.PLACER_DEFAULT)

    --MakeHauntablePanicAndIgnite(inst)

	inst:AddComponent("eater")
    --inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })
    inst.components.eater:SetVegetarian() --改，可喂素食
    inst.components.eater:SetOnEatFn(oneat)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.MOONBUTTERFLY_PERISH_TIME)
    inst.components.perishable:StopPerishing() -- 野外不降新鲜度，放入背包才开始
    inst:RemoveTag("show_spoilage") -- 初始状态（野外）不显示新鲜度条
    inst.components.perishable:SetOnPerishFn(onperish)

    inst:SetStateGraph("SGbutterfly")
    inst:SetBrain(brain)

    -- 注册到月蛾生成器（类似官方蝴蝶的 butterflyspawner 追踪）
    local moonspawner = nil
    local world = rawget(_G, 'TheWorld')
    if world ~= nil then
        moonspawner = world.components.moonbutterflyspawner
    end
    if moonspawner ~= nil then
        inst.components.inventoryitem:SetOnPutInInventoryFn(function(inst2)
            moonspawner:StopTracking(inst2)
            OnPickedUp(inst2)
        end)
        inst:ListenForEvent("onremove", function() moonspawner:StopTracking(inst) end)
        moonspawner:StartTracking(inst)
    end

	inst:ListenForEvent("death", ondeath)

    return inst
end

return Prefab("moonbutterfly", fn, assets, prefabs),
    MakePlacer("moonbutterfly_placer", "baby_moon_tree", "baby_moon_tree", "idle")
