-- 月玻璃钟乳石 (纯装饰，无交互)
-- 移植自 DST，适配 DS 单人生存模式

local assets =
{
    Asset("ANIM", "anim/moonisland/moonglass_bigwaterfall.zip"),
}

local function stalactite(num)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst.AnimState:SetBank("moonglass_bigwaterfall")
        inst.AnimState:SetBuild("moonglass_bigwaterfall")
        inst.AnimState:PlayAnimation("stalactite"..tostring(num), true)

        inst:AddTag("NOBLOCK")

        return inst
    end

    return Prefab("moonglass_stalactite"..tostring(num), fn, assets)
end

local s1 = stalactite(1)
local s2 = stalactite(2)
local s3 = stalactite(3)

return s1, s2, s3
