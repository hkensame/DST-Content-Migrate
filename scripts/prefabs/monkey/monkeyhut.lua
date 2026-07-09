-- 猴子窝 (monkeyhut)
-- 移植自 DST，适配 DS 单机模式
-- 移除：AddNetwork, SetPristine, ismastersim, worldsettingsutil, piratespawner
-- 适配：TheWorld.state.iswinter → GetSeasonManager():IsWinter()
--       TheWorld.state.isnight → GetClock():IsNight()
--       WatchWorldState("isnight") → ListenForEvent("daytime", GetWorld())
--       SetLunarHailBuildupAmountLarge 注释(DS不存在)
--       hauntable 注释

local assets =
{
    Asset("ANIM", "anim/monkey/monkeyhut.zip"),
    Asset("MINIMAP_IMAGE", "monkeyhut"),
}

local prefabs =
{
    "powder_monkey",
    "collapse_big",

    --loot:
    "boards",
    "rocks",
}

local loot =
{
    "boards",
    "rocks",
}

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst:RemoveComponent("childspawner")
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    -- DS: no SetMaterial
    --fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.childspawner ~= nil then
            inst.components.childspawner:ReleaseAllChildren(worker)
        end
        inst.AnimState:PlayAnimation("hit")
        if inst._lightson then
            inst.AnimState:PushAnimation("windowlight_idle")
            if inst._window ~= nil then
                inst._window.AnimState:PlayAnimation("glow_hit")
                inst._window.AnimState:PushAnimation("glow")
            end
        else
            inst.AnimState:PushAnimation("idle")
        end
    end
end

local function StartSpawning(inst)
    local is_winter = GetSeasonManager() and GetSeasonManager():IsWinter()
    if not is_winter and inst.components.childspawner ~= nil and
            not inst:HasTag("burnt") then
        inst.components.childspawner:StartSpawning()
    end
end

local function StopSpawning(inst)
    if inst.components.childspawner ~= nil and not inst:HasTag("burnt") then
        inst.components.childspawner:StopSpawning()
    end
end

local function give_child_gear(child, gear_prefab)
    local gear = SpawnPrefab(gear_prefab)
    gear:AddTag("personal_possession")
    child.components.inventory:GiveItem(gear)
    child.components.inventory:Equip(gear)
end

local function OnSpawned(inst, child)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
        if GetClock():IsNight() and
                child.components.combat.target == nil and
                inst.components.childspawner ~= nil and
                inst.components.childspawner:CountChildrenOutside() >= 1 then
            StopSpawning(inst)
        end
    end

    give_child_gear(child, "cutless")
    if math.random() < 0.3 then
        give_child_gear(child, "monkey_smallhat")
    end

    local cx, cy, cz = child.Transform:GetWorldPosition()
    if not child:IsOnValidGround() then
        SpawnPrefab("splash_sink").Transform:SetPosition(cx, cy, cz)
        child:Remove()
    end
end

local function OnGoHome(inst, child)
    if not inst:HasTag("burnt") then
        -- DS 无 piratespawner 组件，跳过

        inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")

        if inst.components.childspawner ~= nil and
            inst.components.childspawner:CountChildrenOutside() < 1 then
            StartSpawning(inst)
        end
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function onignite(inst)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren()
    end
end

local function onburntup(inst)
    inst.AnimState:PlayAnimation("burnt")

    inst:RemoveTag("shelter")

    if inst._window ~= nil then
        inst._window:Remove()
        inst._window = nil
    end
end

local function LightsOff(inst)
    if not inst:HasTag("burnt") and inst._lightson then
        inst.Light:Enable(false)
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:SetLightOverride(0)
        inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lightoff")

        inst._lightson = false
        if inst._window ~= nil then
            inst._window:Hide()
        end
    end
end

local function LightsOn(inst)
    if not inst:HasTag("burnt") and not inst._lightson then
        inst.Light:Enable(true)
        inst.AnimState:PlayAnimation("windowlight_idle", true)
        inst.AnimState:SetLightOverride(0.2)
        inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lighton")

        inst._lightson = true
        if inst._window ~= nil then
            inst._window:Show()
        end
    end
end

local function getstatus(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or nil
end

local function OnDaytime(inst)
    -- 白天 → 停止生成，关灯
    if not inst:HasTag("burnt") then
        StartSpawning(inst)
        inst:DoTaskInTime(2*math.random() + 1, LightsOff)
    end
end

local function OnNighttime(inst)
    -- 夜晚 → 停止生成，开灯
    StopSpawning(inst)
    inst:DoTaskInTime(2*math.random() + 1, LightsOn)
end

local function OnDaytimeChanged(inst, data)
    -- "daytime" event from GetWorld(): data = {isday, isnight, isdusk}
    if data.isnight then
        OnNighttime(inst)
    else
        OnDaytime(inst)
    end
end

--------------------------------------------------------------------------------

local function MakeWindow()
    local inst = CreateEntity("MonkeyHut.MakeWindow")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")
    inst.persists = false

    inst.AnimState:SetBank("monkeyhut")
    inst.AnimState:SetBuild("monkeyhut")
    inst.AnimState:PlayAnimation("glow")
    inst.AnimState:SetLightOverride(0.6)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)

    inst:Hide()

    return inst
end

local function gohomevalidatefn(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        return false
    end
    if inst:HasTag("burnt") then
        return false
    end
    return true
end

--------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    MakeObstaclePhysics(inst, 0.25)

    inst:AddTag("shelter")
    inst:AddTag("structure")

    --MakeSnowCoveredPristine(inst) -- DS 不需要

    inst.MiniMapEntity:SetIcon("monkeyhut.tex")

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(false)
    inst.Light:SetColour(180/255, 195/255, 50/255)

    inst.AnimState:SetBank("monkeyhut")
    inst.AnimState:SetBuild("monkeyhut")
    inst.AnimState:PlayAnimation("idle", true)

    -- DS 单机始终创建窗口
    inst._window = MakeWindow()
    inst._window.entity:SetParent(inst.entity)

    -----------------------------------------------------------
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    -----------------------------------------------------------
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(TUNING.MONKEYHUT_WORKS)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    -----------------------------------------------------------
    -- hauntable 组件注释掉 (DS 无幽灵系统)
    --inst:AddComponent("hauntable")
    --inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    --inst.components.hauntable:SetOnHauntFn(OnHaunt)

    -----------------------------------------------------------
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    -----------------------------------------------------------
    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "powder_monkey"
    inst.components.childspawner:SetSpawnedFn(OnSpawned)
    inst.components.childspawner.gohomevalidatefn = gohomevalidatefn
    inst.components.childspawner:SetGoHomeFn(OnGoHome)

    inst.components.childspawner:SetRegenPeriod(TUNING.MONKEYHUT_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.MONKEYHUT_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.MONKEYHUT_MONKEYS)

    -- DST-only emergency childspawner API, guard for DS compatibility
    if inst.components.childspawner.SetMaxEmergencyChildren then
        inst.components.childspawner:SetMaxEmergencyChildren(TUNING.MONKEYHUT_EMERGENCY_MONKEYS)
    end
    if inst.components.childspawner.SetEmergencyRadius then
        inst.components.childspawner:SetEmergencyRadius(TUNING.MONKEYHUT_EMERGENCY_RADIUS)
    end
    -- 属性赋值不会崩溃（Lua table 允许任意字段），但 DS 不会使用这些字段
    inst.components.childspawner.canemergencyspawn = TUNING.MONKEYHUT_ENABLED
    inst.components.childspawner.emergencychildname = "powder_monkey"

    -----------------------------------------------------------
    -- 监听昼夜变化 (替代 WatchWorldState("isnight"))
    inst:ListenForEvent("daytime", OnDaytimeChanged, GetWorld())

    -----------------------------------------------------------
    StartSpawning(inst)

    -----------------------------------------------------------
    MakeMediumBurnable(inst, nil, nil, true)
    MakeLargePropagator(inst)
    inst:ListenForEvent("onignite", onignite)
    inst:ListenForEvent("burntup", onburntup)

    -----------------------------------------------------------
    MakeSnowCovered(inst)
    --SetLunarHailBuildupAmountLarge(inst) -- DS 不存在

    -----------------------------------------------------------
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("monkeyhut", fn, assets, prefabs)
