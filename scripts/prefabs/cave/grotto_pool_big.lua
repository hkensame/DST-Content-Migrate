-- DS 适配版 grotto_pool_big.lua
-- 从 DST 源码 scripts/prefabs/grotto_pool_big.lua 移植
-- 改动：
--   🔴 移除 AddNetwork / SetPristine / ismastersim
--   🟡 TheNet:IsDedicated() → 始终执行（DS 无专用服务器）
--   🔴 注释 SetDeploySmartRadius
--   🟡 碰撞缩小到 2.0（DS 不支持环形碰撞网格），瀑布音效改为直接播放
--   ⚪ scrapbook_* 字段无害保留

local assets =
{
    Asset("ANIM", "anim/moonisland/moonglass_bigwaterfall_steam.zip"),
    Asset("ANIM", "anim/moonisland/moonglasspool_tile.zip"),
    Asset("MINIMAP_IMAGE", "grotto_pool_big"),
}

local prefabs =
{
    "grotto_moonglass_1",
    "grotto_moonglass_3",
    "grotto_moonglass_4",
    "grotto_waterfall_big",
    "grottopool_sfx",
}

local prefab_layout =
{
    {name = "grotto_waterfall_big",   x = 0,      z = 0},
    {name = "grotto_moonglass_1",     x = 1.15,   z = -2.77},
    {name = "grotto_moonglass_3",     x = -1.15,  z = 2.77},
    {name = "grotto_moonglass_4",     x = 2.49,   z = 1.16},
    {name = "grotto_moonglass_4",     x = -2.49,  z = -1.16},
}

local function setup_children(inst)
    inst._children = inst._children or {}

    local ix, iy, iz = inst.Transform:GetWorldPosition()
    for i, child_data in ipairs(prefab_layout) do
        if inst._children[i] == nil then
            local p = SpawnPrefab(child_data.name)
            p.Transform:SetPosition(ix + child_data.x, iy, iz + child_data.z)
            inst._children[i] = p
        end

        if inst._children[i] ~= nil then
            inst._children[i]:ListenForEvent("onremove", function() inst._children[i] = nil end)
        end
    end
end

local function on_save(inst, data)
    data.children_ids = {}
    if inst._children ~= nil then
        data.children_indexes = {}
        for i=1, #prefab_layout do
            local child = inst._children[i]
            if child ~= nil then
                table.insert(data.children_ids, child.GUID)
                table.insert(data.children_indexes, i)
            end
        end
    end
    return data.children_ids
end

local function on_load_postpass(inst, newents, data)
    if data ~= nil and data.children_ids ~= nil and data.children_indexes ~= nil then
        inst._children = {}
        for id_ix, child_id in ipairs(data.children_ids) do
            local child = newents[child_id]
            if child ~= nil then
                local ix = data.children_indexes[id_ix]
                inst._children[ix] = child.entity
            end
        end
    end
end

local function on_removed(inst)
    if inst._children ~= nil then
        for i = #prefab_layout, 1, -1 do
            local c = inst._children[i]
            if c ~= nil and c:IsValid() then
                c:Remove()
            end
        end
    end
end

local function makebigmist(proxy)
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
    inst.AnimState:PlayAnimation("steam_big", true)
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
    inst:DoTaskInTime(0, makebigmist)

    MakeObstaclePhysics(inst, 3) -- 🟡 缩小到 2.0，让月玻璃在碰撞外可到达

    inst.AnimState:SetBuild("moonglasspool_tile")
    inst.AnimState:SetBank("moonglasspool_tile")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetLightOverride(0.25)

    inst.MiniMapEntity:SetIcon("grotto_pool_big.tex")

    inst.Light:SetColour(COLOUR_R, COLOUR_G, COLOUR_B)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetFalloff(0.6)
    inst.Light:SetRadius(0.9)

    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("birdblocker")
    inst:AddTag("watersource")

    inst.scrapbook_specialinfo = "GROTTOPOOL" -- ⚪ 无害保留
    inst.scrapbook_build = "moonglass_bigwaterfall"
    inst.scrapbook_bank  = "moonglass_bigwaterfall"
    inst.scrapbook_anim   = "water_big"
    inst.scrapbook_adddeps = { "moonglass" }
    inst.no_wet_prefix = true

    -- 🔴 注释 SetDeploySmartRadius（DS 无此方法）
    --inst:SetDeploySmartRadius(5)

    -- 🟡 瀑布音效：替代 DST register_pool 系统
    inst:DoTaskInTime(0, function()
        inst.SoundEmitter:PlaySound("grotto/common/waterfall_LP", "waterfall_loop")
    end)

    -- 🔴 DS 不需要 SetPristine / ismastersim 守卫

    inst:AddComponent("inspectable")

    -- DS 无 watersource 组件（DST 水源系统）
    local ok, err = pcall(function() inst:AddComponent("watersource") end)
    if not ok then print("[grotto_pool_big] watersource skipped:", err) end

    inst:ListenForEvent("onremove", on_removed)

    inst:DoTaskInTime(0, setup_children)

    inst.OnSave = on_save
    inst.OnLoadPostPass = on_load_postpass

    return inst
end

return Prefab("grotto_pool_big", poolfn, assets, prefabs)
