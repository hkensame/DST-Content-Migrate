-- 光飞虫的花 (lightflier_flower)
-- 移植自 DST，适配 DS 单人生存模式
-- 简化为：摘花 → 生成一只光飞虫 → 花计时再生
-- 不再用 childspawner 追踪光飞虫（DST 专属 API），光飞虫独立活动

local assets =
{
    Asset("ANIM", "anim/moonisland/bulb_plant_single.zip"),
    Asset("ANIM", "anim/moonisland/bulb_plant_springy.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "lightflier",
}

-- 再生逻辑

local REGROW_TIME = 120  -- 被摘后120秒再生

local plantnames = { "_single", "_springy" }

-- 被摘：生成光飞虫 + 进入枯萎状态
local function OnPicked(inst)
    -- 生成一只光飞虫
    local lightflier = SpawnPrefab("lightflier")
    if lightflier then
        lightflier.Transform:SetPosition(inst.Transform:GetWorldPosition())
        lightflier:PushEvent("startled")
    end

    -- 切换动画到枯萎
    inst.AnimState:PlayAnimation("picking")
    inst.AnimState:PushAnimation("picked")

    -- 关闭灯光
    inst.Light:Enable(false)
end

-- 再生完成
local function OnRegen(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)

    -- 如果有光环境，开灯
    if GetClock() ~= nil and (GetClock():IsDay() or GetClock():IsDusk()) then
        inst.Light:Enable(true)
        inst.Light:SetIntensity(.75)
        inst.Light:SetRadius(3)
    end
end

-- 变空状态
local function OnMakeEmpty(inst)
    inst.AnimState:PlayAnimation("picked")
    inst.Light:Enable(false)
end

-- 主 Prefab

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()

    inst:AddTag("plant")
    inst:AddTag("lightflier_home")

    -- 随机选择花的形态变体（与DST一致）
    inst.plantname = plantnames[math.random(1, #plantnames)]
    inst.AnimState:SetBank("bulb_plant"..inst.plantname)
    inst.AnimState:SetBuild("bulb_plant"..inst.plantname)
    inst.AnimState:PlayAnimation("off")
    inst.AnimState:PushAnimation("idle", true)

    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(.75)
    inst.Light:SetRadius(3)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)

    -- 可采摘（用 DS 原生的 regrowth 机制定时再生）
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
    inst.components.pickable.onpickedfn = OnPicked
    inst.components.pickable.onregenfn = OnRegen
    inst.components.pickable.makeemptyfn = OnMakeEmpty
    inst.components.pickable:SetUp(nil, REGROW_TIME)

    -- 掉落
    inst:AddComponent("lootdropper")

    -- 检视
    inst:AddComponent("inspectable")

    -- 可燃
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)

    inst.OnSave = function(inst, data)
        data.plantname = inst.plantname
    end
    inst.OnLoad = function(inst, data)
        if data ~= nil and data.plantname ~= nil then
            inst.plantname = data.plantname
            inst.AnimState:SetBank("bulb_plant"..inst.plantname)
            inst.AnimState:SetBuild("bulb_plant"..inst.plantname)
        end
    end

    return inst
end

return Prefab("lightflier_flower", fn, assets, prefabs)
