-- 月眼 (6色发光可拾取植物，地面放置时显示在地图上)
-- 移植自 DST，适配 DS 单人生存模式
-- 注意：小地图图标需要额外添加 PNG 文件到 minimap 目录

local assets =
{
    Asset("ANIM", "anim/moonisland/mooneyes.zip"),
}

local function Sparkle(inst, colour)
    if not inst.AnimState:IsCurrentAnimation(colour.."gem_sparkle") then
        inst.AnimState:PlayAnimation(colour.."gem_sparkle")
        inst.AnimState:PushAnimation(colour.."gem_idle", false)
    end
    inst:DoTaskInTime(4 + math.random(), Sparkle, colour)
end

local function buildeye(colour)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("mooneyes")
        inst.AnimState:SetBuild("mooneyes")
        inst.AnimState:PlayAnimation(colour.."gem_idle")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddTag("donotautopick")

        inst:AddComponent("tradable")
        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = colour.."mooneye"
        inst.components.inventoryitem.atlasname = "images/mooneye_images.xml"
        --inst.components.inventoryitem:SetSinks(true) -- DS 无 SetSinks 方法（海洋相关）

        -- MakeHauntableLaunch(inst) -- DS 无此函数

        inst:DoTaskInTime(0, Sparkle, colour)

        return inst
    end

    return Prefab(colour.."mooneye", fn, assets)
end

local p1 = buildeye("purple")
local p2 = buildeye("blue")
local p3 = buildeye("red")
local p4 = buildeye("orange")
local p5 = buildeye("yellow")
local p6 = buildeye("green")

return p1, p2, p3, p4, p5, p6
