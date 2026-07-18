-- 光飞虫的花 (lightflier_flower)
-- 移植自 DST，适配 DS 单人生存模式
-- 简化版：使用 DS 原生动画，灯光逻辑参考 DS flower_cave

local assets =
{
    -- bulb_plant_single / bulb_plant_springy: DS 原版已有，无需导入
    Asset("SOUND", "sound/common.fsb"),
    Asset("MINIMAP_IMAGE", "bulb_plant"),
}

local prefabs =
{
    "lightflier",
}

local MAX_CHILDREN = 1
local RECALL_FREQUENCY = 8

---------------------------------------------------------------------------
-- childspawner 回调
---------------------------------------------------------------------------

local function OnChildKilled(inst, child)
    if inst.components.childspawner.childrenoutside[child] ~= nil then
        inst.components.childspawner.childrenoutside[child] = nil
        local count = 0
        for _ in pairs(inst.components.childspawner.childrenoutside) do count = count + 1 end
        inst.components.childspawner.numchildrenoutside = count
    end
    inst.components.pickable:Resume()
end

local function OnGoHome(inst, child)
    if not inst.components.pickable:CanBePicked() then
        inst.components.pickable:Regen()
    end
    -- 动画过程：picked → grow → idle（光飞虫回家后的恢复动画）
    inst.AnimState:PlayAnimation("picked")
    inst.AnimState:PushAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
    inst.Light:Enable(true)
end

---------------------------------------------------------------------------
-- 子实体生成
---------------------------------------------------------------------------

local function SpawnLightflierFromStalk(inst)
    local lightflier = SpawnPrefab("lightflier")
    inst.components.childspawner:TakeOwnership(lightflier)
    lightflier.Transform:SetPosition(inst:GetPosition():Get())
    lightflier:PushEvent("startled")
    inst.components.childspawner.childreninside = math.max(inst.components.childspawner.childreninside - 1, 0)

    local function OnChildDeath()
        if inst:IsValid() then
            OnChildKilled(inst, lightflier)
        end
    end
    lightflier:ListenForEvent("death", OnChildDeath)
    lightflier:ListenForEvent("onremove", OnChildDeath)
end

---------------------------------------------------------------------------
-- 召回逻辑
---------------------------------------------------------------------------

local function CancelCallForLightflierTask(inst)
    if inst._call_for_lightflier_task ~= nil then
        inst._call_for_lightflier_task:Cancel()
        inst._call_for_lightflier_task = nil
    end
end

local function CallForLightflier(inst)
    local alive_count = 0
    for k, v in pairs(inst.components.childspawner.childrenoutside) do
        if not v:IsValid() or (v.components.health ~= nil and v.components.health:IsDead()) then
            inst.components.childspawner.childrenoutside[k] = nil
        else
            alive_count = alive_count + 1
        end
    end
    inst.components.childspawner.numchildrenoutside = alive_count

    if alive_count < TUNING.LIGHTFLIER_FLOWER_TARGET_NUM_CHILDREN_OUTSIDE
        and not inst.components.pickable:CanBePicked() then
        CancelCallForLightflierTask(inst)
        inst.components.pickable:Resume()
        return
    end

    if inst.components.pickable:CanBePicked() then
        CancelCallForLightflierTask(inst)
        return
    end

    if inst._lightflier_returning_home ~= nil
        and inst._lightflier_returning_home:IsValid()
        and (inst._lightflier_returning_home.components.health == nil or not inst._lightflier_returning_home.components.health:IsDead()) then
        return
    end

    for k, v in pairs(inst.components.childspawner.childrenoutside) do
        if v:IsValid() and (v.components.health == nil or not v.components.health:IsDead()) then
            inst._lightflier_returning_home = v
            return
        end
    end

    inst._lightflier_returning_home = nil
end

local function StartCallForLightflierTask(inst)
    CancelCallForLightflierTask(inst)
    inst._call_for_lightflier_task = inst:DoPeriodicTask(RECALL_FREQUENCY, CallForLightflier,
        TUNING.LIGHTFLIER_FLOWER_RECALL_DELAY + math.random() * TUNING.LIGHTFLIER_FLOWER_RECALL_DELAY_VARIANCE)
end

---------------------------------------------------------------------------
-- pickable 回调
---------------------------------------------------------------------------

local function makefullfn(inst)
    CancelCallForLightflierTask(inst)
    inst.AnimState:PlayAnimation("idle", true)
    inst.Light:Enable(true)
end

local function onregenfn(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
    inst.Light:Enable(true)
end

local function onpickedfn(inst, picker, loot)
    SpawnLightflierFromStalk(inst)
    inst.Light:Enable(false)

    if picker ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lightbulb")
    end
    inst.AnimState:PlayAnimation("picking")

    if inst.components.pickable:IsBarren() then
        inst.AnimState:PushAnimation("idle_dead")
    else
        inst.AnimState:PushAnimation("picked")
    end

    inst.components.pickable:Pause()
    StartCallForLightflierTask(inst)
end

local function makeemptyfn(inst)
    inst.Light:Enable(false)
    inst.AnimState:PlayAnimation("picked")
end

---------------------------------------------------------------------------
-- 点燃处理
---------------------------------------------------------------------------

local function OnIgnite(inst)
    inst.Light:Enable(false)
    if inst.components.pickable:CanBePicked() then
        inst.components.pickable:Pick()
    elseif not inst.AnimState:IsCurrentAnimation("picking") then
        inst.AnimState:PlayAnimation("picked")
    end
end

---------------------------------------------------------------------------
-- 存档
---------------------------------------------------------------------------

local function OnSave(inst, data)
    data.plantname = inst.plantname
end

local function OnLoad(inst, data)
    if data == nil then return end

    if data.plantname ~= nil then
        inst.plantname = data.plantname
        inst.AnimState:SetBank("bulb_plant" .. inst.plantname)
        inst.AnimState:SetBuild("bulb_plant" .. inst.plantname)
    end

    if not inst.components.pickable:CanBePicked() then
        inst.Light:Enable(false)
    end
end

local function OnLoadPostPass(inst, ents, data)
    if not inst.components.pickable:CanBePicked()
        and inst.components.childspawner.numchildrenoutside >= TUNING.LIGHTFLIER_FLOWER_TARGET_NUM_CHILDREN_OUTSIDE then
        StartCallForLightflierTask(inst)
    end
end

---------------------------------------------------------------------------
-- 唤醒处理（参考 DS flower_cave）
---------------------------------------------------------------------------

local function OnWake(inst)
    if not inst.components.pickable.canbepicked then
        inst.Light:Enable(false)
    end
end

---------------------------------------------------------------------------
-- 主 Prefab
---------------------------------------------------------------------------

local plantnames = { "_single", "_springy" }

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()

    inst:AddTag("plant")
    inst:AddTag("lightflier_home")

    -- 灯光（参考 DS flower_cave 设置，idle 状态下发光）
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(.8)
    inst.Light:SetRadius(1.5)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)

    -- 随机花形态
    inst.plantname = plantnames[math.random(1, #plantnames)]
    inst.AnimState:SetBank("bulb_plant" .. inst.plantname)
    inst.AnimState:SetBuild("bulb_plant" .. inst.plantname)
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetTime(math.random() * 2)

    -- 小地图图标
    inst.MiniMapEntity:SetIcon("bulb_plant_withered.tex")

    -- 颜色随机
    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    -- pickable 组件
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    inst.components.pickable.makefullfn = makefullfn
    inst.components.pickable:SetUp(nil, TUNING.LIGHTFLIER_FLOWER_REGROW_TIME)
    inst.components.pickable.canbepicked = TUNING.LIGHTFLIER_FLOWER_PICKABLE

    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

    -- childspawner：追踪光飞虫归属
    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "lightflier"
    inst.components.childspawner:SetMaxChildren(MAX_CHILDREN)
    inst.components.childspawner:SetSpawnedFn(function(child)
        if child then
            child:ListenForEvent("death", function() OnChildKilled(inst, child) end)
            child:ListenForEvent("onremove", function() OnChildKilled(inst, child) end)
        end
    end)
    inst.components.childspawner:SetGoHomeFn(OnGoHome)

    -- 可燃
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)

    -- 燃烧监听
    inst:ListenForEvent("onignite", OnIgnite)

    -- DST 专属系统（DS 安全跳过）
    if rawget(_G, "AddToRegrowthManager") then AddToRegrowthManager(inst) end

    -- 存档
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass
    inst.OnEntityWake = OnWake

    -- 幽灵互动（DS 安全跳过）
    if rawget(_G, "MakeHauntableIgnite") then MakeHauntableIgnite(inst) end

    return inst
end

return Prefab("lightflier_flower", fn, assets, prefabs)
