-- DS 移植版：移除 AddNetwork/SetPristine/ismastersim
-- cave_vent_ground_fx.lua — 喷气孔地面特效

local assets =
{
    Asset("ANIM", "anim/cave_vent_ground.zip"),
}

local POSITIONS = {
    {
        {3.5, 0, -6.5},
        {.25, 0, -7.75},
        {-1.75, 0, -6.75},
    },
    {
        {1.5, 0, -4.25},
        {0, 0, -7.5},
        {-1, 0, -6},
    },
}

local function OnSave(inst, data)
    data.animnum = inst.animnum
end

local function OnLoad(inst, data)
    if data and data.animnum then
        inst.animnum = data.animnum
    end
end

local NUM_ANIM = 2
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBuild("cave_vent_ground")
    inst.AnimState:SetBank("cave_vent_ground")
    inst.AnimState:PlayAnimation("idle1")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetMultColour(1,0.5,0.5,1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    -- === Master Simulation ===
    inst.Transform:SetRotation(math.random()*360)

    inst.animnum = math.random(NUM_ANIM)
    if inst.animnum ~= 1 then
        inst.AnimState:PlayAnimation("idle"..inst.animnum)
    end

    inst:AddComponent("savedrotation")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("cave_vent_ground_fx", fn, assets)
