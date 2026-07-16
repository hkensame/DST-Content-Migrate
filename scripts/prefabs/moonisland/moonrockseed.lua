-- moonrockseed.lua — DS 适配版（未升级版本）
-- 月岩种子：可拾取的天体制作站，提供 CELESTIAL = 1 科技解锁
local easing = require("easing")

local assets =
{
    Asset("ANIM", "anim/moonisland/moonrock_seed.zip"),
}

local prefabs =
{
    "moonrockseed_icon",
}

local UPGRADED_LIGHT_RADIUS = 2.5

local function updatelight(inst)
    inst._light = inst._light < inst._targetlight and math.min(inst._targetlight, inst._light + .04) or math.max(inst._targetlight, inst._light - .02)
    inst.AnimState:SetLightOverride(inst._light)
    inst.Light:SetRadius(UPGRADED_LIGHT_RADIUS * inst._light / inst._targetlight)
    if inst._light == inst._targetlight then
        inst._task:Cancel()
        inst._task = nil
    end
end

local function fadelight(inst, target, instant)
    inst._targetlight = target
    if inst._light ~= target then
        if instant then
            if inst._task ~= nil then
                inst._task:Cancel()
                inst._task = nil
            end
            inst._light = target
            inst.AnimState:SetLightOverride(target)
            inst.Light:SetRadius(UPGRADED_LIGHT_RADIUS)
        elseif inst._task == nil then
            inst._task = inst:DoPeriodicTask(FRAMES, updatelight)
        end
    elseif inst._task ~= nil then
        inst._task:Cancel()
        inst._task = nil
    end
end

local function cancelblink(inst)
    if inst._blinktask ~= nil then
        inst._blinktask:Cancel()
        inst._blinktask = nil
    end
end

local function updateblink(inst, data)
    local c = easing.outQuad(data.blink, 0, 1, 1)
    inst.AnimState:SetAddColour(c, c, c, 0)
    if data.blink > 0 then
        data.blink = math.max(0, data.blink - .05)
    else
        inst._blinktask:Cancel()
        inst._blinktask = nil
    end
end

local function blink(inst)
    if inst._blinktask ~= nil then
        inst._blinktask:Cancel()
    end
    local data = { blink = 1 }
    inst._blinktask = inst:DoPeriodicTask(FRAMES, updateblink, nil, data)
    updateblink(inst, data)
end

local function dodropsound(inst, taskid, volume)
    inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt", nil, volume)
    inst._tasks[taskid] = nil
end

local function canceldropsounds(inst)
    local k, v = next(inst._tasks)
    while k ~= nil do
        v:Cancel()
        inst._tasks[k] = nil
        k, v = next(inst._tasks)
    end
end

local function scheduledropsounds(inst)
    inst._tasks[1] = inst:DoTaskInTime(6 * FRAMES, dodropsound, 1)
    inst._tasks[2] = inst:DoTaskInTime(13 * FRAMES, dodropsound, 2, .5)
    inst._tasks[3] = inst:DoTaskInTime(18 * FRAMES, dodropsound, 2, .15)
end

local function onturnon(inst)
    canceldropsounds(inst)
    inst.AnimState:PlayAnimation("proximity_pre")
    inst.AnimState:PushAnimation("proximity_loop", true)
    fadelight(inst, .15, false)
    if not inst.SoundEmitter:PlayingSound("idlesound") then
        inst.SoundEmitter:PlaySound("dontstarve/common/together/celestial_orb/idle_LP", "idlesound")
    end
end

local function onturnoff(inst)
    canceldropsounds(inst)
    inst.SoundEmitter:KillSound("idlesound")
    inst.Light:Enable(false)
    inst.Light:SetRadius(0)
    if not inst.components.inventoryitem:IsHeld() then
        inst.AnimState:PlayAnimation("proximity_pst")
        inst.AnimState:PushAnimation("idle", false)
        fadelight(inst, 0, false)
        scheduledropsounds(inst)
    else
        inst.AnimState:PlayAnimation("idle")
        fadelight(inst, 0, true)
    end
end

local function onactivate(inst)
    blink(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/celestial_orb/active")
    OnFX(inst)
end

local function storeincontainer(inst, container)
    if container ~= nil and container.components.container ~= nil then
        inst:ListenForEvent("onputininventory", inst._oncontainerownerchanged, container)
        inst:ListenForEvent("ondropped", inst._oncontainerownerchanged, container)
        inst:ListenForEvent("onremove", inst._oncontainerremoved, container)
        inst._container = container
    end
end

local function unstore(inst)
    if inst._container ~= nil then
        inst:RemoveEventCallback("onputininventory", inst._oncontainerownerchanged, inst._container)
        inst:RemoveEventCallback("ondropped", inst._oncontainerownerchanged, inst._container)
        inst:RemoveEventCallback("onremove", inst._oncontainerremoved, inst._container)
        inst._container = nil
    end
end

local function tostore(inst, owner)
    if inst._container ~= owner then
        unstore(inst)
        storeincontainer(inst, owner)
    end
    owner = owner.components.inventoryitem ~= nil and owner.components.inventoryitem:GetGrandOwner() or owner
    if inst._owner ~= owner then
        inst._owner = owner
        if inst.icon ~= nil then
            inst.icon.entity:SetParent(owner.entity)
        end
    end
end

local function topocket(inst, owner)
    if owner == nil then return end
    cancelblink(inst)
    onturnoff(inst)
    tostore(inst, owner)
end

local function toground(inst)
    if inst.components.prototyper.on then
        onturnon(inst)
    end
    unstore(inst)
    inst._owner = nil
    if inst.icon ~= nil then
        inst.icon.entity:SetParent(inst.entity)
    end
end

local function OnFX(inst)
    if not inst:HasTag("INLIMBO") then
        local fx = CreateEntity()
        fx:AddTag("FX")
        fx.entity:SetCanSleep(false)
        fx.persists = false

        fx.entity:AddTransform()
        fx.entity:AddAnimState()

        -- DS: 用手动位置复制代替 SetFromProxy
        local x, y, z = inst.Transform:GetWorldPosition()
        fx.Transform:SetPosition(x, y, z)

        fx.AnimState:SetBank("moonrock_seed")
        fx.AnimState:SetBuild("moonrock_seed")
        fx.AnimState:PlayAnimation("use")
        fx.AnimState:SetFinalOffset(3)

        fx:ListenForEvent("animover", fx.Remove)
    end
end

local function OnSpawned(inst)
    if not (inst.components.prototyper.on or inst.components.inventoryitem:IsHeld()) then
        canceldropsounds(inst)
        scheduledropsounds(inst)
        inst.AnimState:PlayAnimation("proximity_pst")
        inst.AnimState:PushAnimation("idle", false)
    end
end

local function OnRemoveEntity(inst)
    if inst.icon ~= nil then
        inst.icon:Remove()
    end
end

local function ondropped(inst)
    inst.Light:Enable(false)
end

local function DoUpgrade(inst)
    inst._upgraded = true
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.MOON_ALTAR_FULL
end

local function OnSave(inst, data)
    data._upgraded = inst._upgraded
end

local function OnLoad(inst, data)
    if data ~= nil and data._upgraded then
        inst:DoUpgrade()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("moonrock_seed")
    inst.AnimState:SetBuild("moonrock_seed")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("prototyper")
    inst:AddTag("irreplaceable")
    inst:AddTag("nonpotatable")
    inst:AddTag("celestial_station")

    inst.Light:SetFalloff(1.15)
    inst.Light:SetIntensity(.7)
    inst.Light:SetRadius(0)
    inst.Light:SetColour(150 / 255, 180 / 255, 200 / 255)
    inst.Light:Enable(false)

    -- DS 无 WORLDSTATETAGS 系统，跳过天体标记
    local wst = rawget(_G, "WORLDSTATETAGS")
    -- if wst ~= nil and wst.SetTagEnabled ~= nil then
    --     wst.SetTagEnabled("CELESTIAL_ORB_FOUND", true)
    -- end

    inst._tasks = {}
    inst._light = 0
    inst._targetlight = 0
    inst._owner = nil
    inst._container = nil

    inst._oncontainerownerchanged = function(container)
        tostore(inst, container)
    end

    inst._oncontainerremoved = function()
        unstore(inst)
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem:SetSinks(true)
    inst.components.inventoryitem.atlasname = "images/moonrockseed.xml"
    inst.components.inventoryitem.imagename = "moonrockseed"
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)

    inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = onturnon
    inst.components.prototyper.onturnoff = onturnoff
    inst.components.prototyper.onactivate = onactivate
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.MOON_ALTAR

    -- DS: 无 MakeHauntableLaunch

    inst.icon = SpawnPrefab("moonrockseed_icon")
    if inst.icon ~= nil then
        inst.icon.entity:SetParent(inst.entity)
    end
    inst:ListenForEvent("onputininventory", topocket)
    inst:ListenForEvent("ondropped", toground)

    inst.OnSpawned = OnSpawned
    inst.OnRemoveEntity = OnRemoveEntity

    inst.DoUpgrade = DoUpgrade
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

----------------<小地图图标>----------------
local function iconfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("moonrockseed.tex")
    inst.MiniMapEntity:SetPriority(11)
    if inst.MiniMapEntity.SetCanUseCache ~= nil then
        inst.MiniMapEntity:SetCanUseCache(false)
    end
    if inst.MiniMapEntity.SetDrawOverFogOfWar ~= nil then
        inst.MiniMapEntity:SetDrawOverFogOfWar(true)
    end

    inst:AddTag("CLASSIFIED")

    inst.persists = false

    return inst
end

return Prefab("moonrockseed", fn, assets, prefabs),
    Prefab("moonrockseed_icon", iconfn, assets, prefabs)
