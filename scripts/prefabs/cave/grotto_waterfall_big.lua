-- DS 适配版 grotto_waterfall_big.lua
-- 从 DST 源码 scripts/prefabs/grotto_waterfall_big.lua 移植
-- 改动：
--   🔴 移除 AddNetwork / SetPristine / ismastersim
--   🔴 注释 SetDeploySmartRadius（DS 无此方法）

local assets =
{
    Asset("ANIM", "anim/moonisland/moonglass_bigwaterfall.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    -- 🔴 DS 不需要 AddNetwork

    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBuild("moonglass_bigwaterfall")
    inst.AnimState:SetBank("moonglass_bigwaterfall")
    inst.AnimState:PlayAnimation("water_big", true)

    inst:AddTag("NOCLICK")

    inst.no_wet_prefix = true

    -- 🔴 注释 SetDeploySmartRadius（DS 无此方法）
    --inst:SetDeploySmartRadius(3.5)

    -- 🔴 DS 不需要 SetPristine / ismastersim 守卫

    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    -- 🟡 瀑布流水音效
    inst:DoTaskInTime(0, function()
        inst.SoundEmitter:PlaySound("grotto/common/waterfall_LP", "waterfall_loop")
    end)

    return inst
end

return Prefab("grotto_waterfall_big", fn, assets)
