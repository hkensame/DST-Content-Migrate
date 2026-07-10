-- DS 移植版：删除 AddNetwork/SetPristine/ismastersim/scrapbook
-- 仅保留 3 种枯萎变种，采摘即消失（枯萎概念）

local assets =
{
    Asset("ANIM", "anim/bulb_plant_single_withered_build.zip"),
    Asset("ANIM", "anim/bulb_plant_double_withered_build.zip"),
    Asset("ANIM", "anim/bulb_plant_triple_withered_build.zip"),
    Asset("ANIM", "anim/bulb_plant_springy_withered_build.zip"),
}

local withered_prefabs =
{
    "spoiled_food",
}

local plantnames = { "_single", "_springy" }

local LIGHT_COLOUR = { 201/255, 93/255, 10/255 } -- 暗淡橙光

local function commonfn(bank, build, radius)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()

    inst.MiniMapEntity:SetIcon("bulb_plant.png")

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle", true)

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    -- === Master Simulation ===
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
    inst.components.pickable:SetUp("spoiled_food", TUNING.FLOWER_CAVE_REGROW_TIME)
    inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true

    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

    -- 灯光：简单常亮（参考 DS 原版风格）
    local light = inst.entity:AddLight()
    light:SetFalloff(1.5)
    light:SetIntensity(0.2)
    light:SetRadius(radius)
    light:SetColour(unpack(LIGHT_COLOUR))
    light:Enable(true)

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

-- 单头枯萎
local function withered_single()
    local inst = commonfn("bulb_plant_single", "bulb_plant_single_withered_build", 2)

    inst.plantname = plantnames[math.random(1, #plantnames)]
    if inst.plantname ~= "_single" then
        inst.AnimState:SetBank("bulb_plant" .. inst.plantname)
        inst.AnimState:SetBuild("bulb_plant" .. inst.plantname .. "_withered_build")
    end

    return inst
end

-- 双头枯萎
local function withered_double()
    local inst = commonfn("bulb_plant_double", "bulb_plant_double_withered_build", 2.5)

    inst.components.pickable:SetUp("spoiled_food", TUNING.FLOWER_CAVE_REGROW_TIME * 1.5, 2)

    return inst
end

-- 三头枯萎
local function withered_triple()
    local inst = commonfn("bulb_plant_triple", "bulb_plant_triple_withered_build", 2.5)

    inst.components.pickable:SetUp("spoiled_food", TUNING.FLOWER_CAVE_REGROW_TIME * 2, 3)

    return inst
end

return Prefab("flower_cave_withered", withered_single, assets, withered_prefabs),
    Prefab("flower_cave_double_withered", withered_double, assets, withered_prefabs),
    Prefab("flower_cave_triple_withered", withered_triple, assets, withered_prefabs)
