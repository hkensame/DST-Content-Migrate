local assets =
{
    Asset("ANIM", "anim/cave/cave_exit_lightsource.zip"),
}

local function timechange(inst)
    local c = GetClock()
    if c == nil then return end
    local p = c:GetPhase()
    if p == "day" then
        inst.components.lighttweener:StartTween(nil, 5, .9, .3, {180/255, 195/255, 150/255}, 2)
    elseif p == "dusk" then
        inst.components.lighttweener:StartTween(nil, 5, .6, .6, {91/255, 164/255, 255/255}, 4)
    elseif p == "night" then
        inst.components.lighttweener:StartTween(nil, 0, 0, 1, {0, 0, 0}, 6)
    end
end

local function common_fn(widthscale)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("cavelight")
    inst.AnimState:SetBuild("cave_exit_lightsource")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.Transform:SetScale(2*widthscale, 2, 2*widthscale)

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    local world = GetWorld()
    if world ~= nil then
        inst:ListenForEvent("daytime", function() timechange(inst) end, world)
        inst:ListenForEvent("dusktime", function() timechange(inst) end, world)
        inst:ListenForEvent("nighttime", function() timechange(inst) end, world)
    end

    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.entity:AddLight(), 5 * widthscale, .9, .3, {180/255, 195/255, 150/255}, 0)

    return inst
end

local function normalfn()
    return common_fn(1)
end

local function atriumfn()
    local inst = common_fn(.6)
    return inst
end

return Prefab("cavelight", normalfn, assets),
       Prefab("cavelight_atrium", atriumfn, assets)
