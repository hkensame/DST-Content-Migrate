-- DS 适配版 grottopool_sfx.lua
-- 从 DST 源码 scripts/prefabs/grottopool_sfx.lua 移植
-- 改动：无（原文件无网络代码，直接兼容 DS）

local function grottopool_sfx()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst:AddTag("CLASSIFIED")
    --[[Non-networked entity]]

    inst:AddTag("FX")

    --inst.entity:SetCanSleep ??

    inst:AddComponent("fader")

    inst.persists = false

    return inst
end

return Prefab("grottopool_sfx", grottopool_sfx)
