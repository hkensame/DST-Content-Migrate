-- DS 适配版 grotto_pool_moonglass.lua
-- 从 DST 源码 scripts/prefabs/grotto_pool_moonglass.lua 移植
-- 改动：
--   🔴 移除 AddNetwork / SetPristine / ismastersim
--   🔴 注释 SetDeploySmartRadius（DS 无此方法）
--   🔴 注释 halloween_moonpuff（缺少 fx_moon_tea.zip 动画资源）
--   ⚪ WatchWorldState / SetPhysicsRadiusOverride / SetPrefabNameOverride 保留（DS 可用）

local assets =
{
    Asset("ANIM", "anim/moonisland/moonglass_bigwaterfall.zip"),
}

local prefabs =
{
    -- 🔴 halloween_moonpuff 移除（缺少 fx_moon_tea.zip 动画资源）
}

SetSharedLootTable("moonglass_prop",
{
    {'moonglass', 1.0},
    {'moonglass', 1.0},
    {'moonglass', 0.5},
})

local function set_full(inst)
    inst:SetPhysicsRadiusOverride(2)
    inst:RemoveTag("NOCLICK")

    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)

    -- 🔴 注释 halloween_moonpuff（缺少动画资源）
    --local reset_fx = SpawnPrefab("halloween_moonpuff")
    --reset_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())

    if inst._anim ~= nil then
        inst.AnimState:PlayAnimation(inst._anim, true)
    end
end

local function OnCaveFullMoon(inst, fullmoon)
    -- Assume we only ran this function if we're mined out.
    if TUNING.GROTTO_MOONGLASS_REGROW_CHANCE > math.random() then
        set_full(inst)
        inst:StopWatchingWorldState("iscavefullmoon", OnCaveFullMoon)
    end
end

local function set_mined(inst)
    inst:SetPhysicsRadiusOverride(nil)
    inst:AddTag("NOCLICK")

    if inst._anim ~= nil then
        inst.AnimState:PlayAnimation(inst._anim.."_mined", true)
    end

    inst:WatchWorldState("iscavefullmoon", OnCaveFullMoon)
end

local function on_mined(inst, worker, workleft)
    if workleft <= 0 then
        local glass_pos = inst:GetPosition()

        SpawnPrefab("rock_break_fx").Transform:SetPosition(glass_pos:Get())

        if worker ~= nil then
            local worker_pos = worker:GetPosition()

            inst.components.lootdropper:DropLoot(worker_pos)
        else
            inst.components.lootdropper:DropLoot(glass_pos)
        end

        set_mined(inst)
    end
end

local function on_minable_load(inst, data)
    if data.workleft <= 0 then
        set_mined(inst)
    end
end

local function mineable_glass(name, anim)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        -- 🔴 DS 不需要 AddNetwork

        inst.Transform:SetTwoFaced()

        inst.AnimState:SetBuild("moonglass_bigwaterfall")
        inst.AnimState:SetBank("moonglass_bigwaterfall")
        inst.AnimState:PlayAnimation(anim, true)

        inst.no_wet_prefix = true

        -- 🔴 注释 SetDeploySmartRadius（DS 无此方法）
        --inst:SetDeploySmartRadius(2)

        inst:SetPhysicsRadiusOverride(2)

        inst:AddTag("moonglass")

        inst:SetPrefabNameOverride("moonglass_rock")

        inst.scrapbook_proxy = "grotto_pool_big"

        -- 🔴 DS 不需要 SetPristine / ismastersim 守卫

        inst._anim = anim

        inst:AddComponent("workable")
        inst.components.workable.savestate = true
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
        inst.components.workable:SetOnWorkCallback(on_mined)
        inst.components.workable:SetOnLoadFn(on_minable_load)

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable("moonglass_prop")
        inst.components.lootdropper.max_speed = 1.2
        inst.components.lootdropper.min_speed = 0.3
        inst.components.lootdropper.y_speed = 14
        inst.components.lootdropper.y_speed_variance = 4

        inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return mineable_glass("grotto_moonglass_1", "moonglass_1"),
        mineable_glass("grotto_moonglass_3", "moonglass_3"),
        mineable_glass("grotto_moonglass_4", "moonglass_4")
