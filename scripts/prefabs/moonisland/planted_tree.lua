
local moonbutterfly_assets =
{
    Asset("ANIM", "anim/moonisland/baby_moon_tree.zip"),
}

local moonbutterfly_prefabs =
{
    "moon_tree_short",
}

local function growtree(inst)
    local tree = SpawnPrefab(inst.growprefab)
    if tree then
        tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tree:growfromseed()
        inst:Remove()
    end
end

local function stopgrowing(inst)
    inst.components.timer:StopTimer("grow")
end

local function startgrowing(inst)
    if not inst.components.timer:TimerExists("grow") then
        local growtime = GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base, TUNING.PINECONE_GROWTIME.random)
        inst.components.timer:StartTimer("grow", growtime)
    end
end

local function ontimerdone(inst, data)
    if data.name == "grow" then
        growtree(inst)
    end
end

local function digup(inst, digger)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function sapling_fn(build, anim, growprefab, tag, fireproof, overrideloot, override_deploy_smart_radius)
    local scrapbook_adddep = growprefab == tag and tag.."_tall" or string.gsub(growprefab, "short", "tall")

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()

		--inst:SetDeploySmartRadius(override_deploy_smart_radius or DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT] / 2)

        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)

        if not fireproof then
            inst:AddTag("plant")
        end

        inst:AddTag(tag)

        inst.scrapbook_anim = anim
        inst.scrapbook_adddeps = {scrapbook_adddep}

        inst.growprefab = growprefab
        inst.StartGrowing = startgrowing

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", ontimerdone)
        startgrowing(inst)

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(overrideloot or {"twigs"})

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnFinishCallback(digup)
        inst.components.workable:SetWorkLeft(1)

            MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
            inst:ListenForEvent("onignite", stopgrowing)
            inst:ListenForEvent("onextinguish", startgrowing)
            MakeSmallPropagator(inst)

        return inst
    end
    return fn
end

return
    Prefab("moonbutterfly_sapling", sapling_fn("baby_moon_tree", "idle", "moon_tree_short", "moon_tree", nil, nil, 3.2 / 2), moonbutterfly_assets, moonbutterfly_prefabs )

