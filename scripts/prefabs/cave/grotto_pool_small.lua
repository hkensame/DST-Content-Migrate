-- DS 适配版 grotto_pool_small.lua
-- 从 DST 源码 scripts/prefabs/grotto_pool_small.lua 移植

local assets =
{
    Asset("ANIM", "anim/moonisland/moonglass_bigwaterfall_steam.zip"),
    Asset("ANIM", "anim/moonisland/moonglasspool_tile.zip"),
    Asset("MINIMAP_IMAGE", "grotto_pool_small"),
}

local prefabs =
{
    "grotto_waterfall_small1",
    "grotto_waterfall_small2",
    "grottopool_sfx",
}

local function setup_children(inst)
    if inst._waterfall == nil then
        local wf = SpawnPrefab("grotto_waterfall_small"..math.random(1,2))
        wf.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst._waterfall = wf
    end

    if inst._waterfall ~= nil then
        inst._waterfall:ListenForEvent("onremove", function() inst._waterfall = nil end)
    end
end

local function on_save(inst, data)
    if inst._waterfall ~= nil then
        data.wf_id = inst._waterfall.GUID
        return {data.wf_id}
    end
end

local function on_load_postpass(inst, newents, data)
    if data ~= nil and data.wf_id ~= nil then
        local waterfall = newents[data.wf_id]
        if waterfall ~= nil then
            inst._waterfall = waterfall.entity
        end
    end
end

local function on_removed(inst)
    if inst._waterfall ~= nil then
        inst._waterfall:Remove()
    end
end

local function makesmallmist(proxy)
    if not proxy then
        return nil
    end

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    local parent = proxy.entity:GetParent()
    if parent ~= nil then
        inst.entity:SetParent(parent.entity)
    end

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetCanSleep(false)
    inst.persists = false

    -- DS 无 SetFromProxy，手动复制 proxy 位置
    if inst.Transform.SetFromProxy then
        inst.Transform:SetFromProxy(proxy.GUID)
    elseif proxy and proxy.Transform then
        local x, y, z = proxy.Transform:GetWorldPosition()
        inst.Transform:SetPosition(x, y, z)
    end

    inst.AnimState:SetBuild("moonglass_bigwaterfall_steam")
    inst.AnimState:SetBank("moonglass_bigwaterfall_steam")
    inst.AnimState:PlayAnimation("steam_small"..math.random(1,2), true)
    inst.AnimState:SetLightOverride(0.5)

    proxy:ListenForEvent("onremove", function() inst:Remove() end)

    return inst
end

local COLOUR_R, COLOUR_G, COLOUR_B = 227/255, 227/255, 227/255
local function poolfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    -- 🔴 DS 不需要 AddNetwork

    -- 🟡 DS 无 TheNet:IsDedicated()，始终执行
    inst:DoTaskInTime(0, makesmallmist)

    MakeObstaclePhysics(inst, 1.2) -- 🟡 缩小到 1.2，让小瀑布在交互范围内

    inst.AnimState:SetBuild("moonglasspool_tile")
    inst.AnimState:SetBank("moonglasspool_tile")
    inst.AnimState:PlayAnimation("smallpool_idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetLightOverride(0.25)

    inst.MiniMapEntity:SetIcon("grotto_pool_small.tex")

    inst.Light:SetColour(COLOUR_R, COLOUR_G, COLOUR_B)
    inst.Light:SetIntensity(0.3)
    inst.Light:SetFalloff(0.6)
    inst.Light:SetRadius(0.6)

    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("birdblocker")
    inst:AddTag("watersource")

    inst.no_wet_prefix = true

    -- 🟡 瀑布音效
    inst:DoTaskInTime(0, function()
        inst.SoundEmitter:PlaySound("grotto/common/waterfall_LP", "waterfall_loop")
    end)

    -- 🔴 注释 SetDeploySmartRadius（DS 无此方法）
    --inst:SetDeploySmartRadius(2.5)

    inst.scrapbook_specialinfo = "GROTTOPOOL"
    inst.scrapbook_build = "moonglass_bigwaterfall"
    inst.scrapbook_bank  = "moonglass_bigwaterfall"
    inst.scrapbook_anim   = "water_small1"
    inst.scrapbook_adddeps = { "moonglass" }

    -- 🔴 DS 不需要 SetPristine / ismastersim 守卫

    inst:AddComponent("inspectable")

    -- DS 无 watersource 组件（DST 水源系统）
    local ok, err = pcall(function() inst:AddComponent("watersource") end)
    if not ok then print("[grotto_pool_small] watersource skipped:", err) end

    inst:ListenForEvent("onremove", on_removed)

    inst:DoTaskInTime(0, setup_children)

    inst.OnSave = on_save
    inst.OnLoadPostPass = on_load_postpass

    return inst
end

return Prefab("grotto_pool_small", poolfn, assets, prefabs)
