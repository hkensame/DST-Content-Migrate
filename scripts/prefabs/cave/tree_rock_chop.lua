-- DS 移植版：树石砍伐特效
local assets =
{
    Asset("ANIM", "anim/tree_rock_fx.zip"),
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("tree_rock_fx")
    inst.AnimState:SetBuild("tree_rock_fx")
    inst.AnimState:PlayAnimation("chop")
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    return inst
end

return Prefab("tree_rock_chop", fn, assets)
