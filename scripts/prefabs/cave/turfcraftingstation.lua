require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/cave/turfcraftingstation.zip"),
    Asset("IMAGE", "images/turfcraftingstation.tex"),
    Asset("ATLAS", "images/turfcraftingstation.xml"),
}

local prefabs =
{
    "collapse_small",
}

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onhit(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.SoundEmitter:PlaySound("turf_crafting_station/turf_crafting_station/station_hit")
        if inst.components.prototyper.on then
            inst.AnimState:PushAnimation("proximity_loop", true)
            if not inst.SoundEmitter:PlayingSound("loop_sound") then
                inst.SoundEmitter:PlaySound("turf_crafting_station/turf_crafting_station/station_prox_lp", "loop_sound")
            end
        else
            inst.AnimState:PushAnimation("idle", false)
            inst.SoundEmitter:KillSound("loop_sound")
        end
    end
end

local function onturnoff(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PushAnimation("idle", false)
        inst.SoundEmitter:KillSound("loop_sound")
    end
end

local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function onturnon(inst)
    if not inst:HasTag("burnt") then
        if inst.AnimState:IsCurrentAnimation("proximity_loop") or
            inst.AnimState:IsCurrentAnimation("place") or
            inst.AnimState:IsCurrentAnimation("use") then
            inst.AnimState:PushAnimation("proximity_loop", true)
            if not inst.SoundEmitter:PlayingSound("loop_sound") then
                inst.SoundEmitter:PlaySound("turf_crafting_station/turf_crafting_station/station_prox_lp", "loop_sound")
            end
        else
            inst.AnimState:PlayAnimation("proximity_loop", true)
            if not inst.SoundEmitter:PlayingSound("loop_sound") then
                inst.SoundEmitter:PlaySound("turf_crafting_station/turf_crafting_station/station_prox_lp", "loop_sound")
            end
        end
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("turf_crafting_station/turf_crafting_station/station_place")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()

    MakeObstaclePhysics(inst, .4)

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("turfcraftingstation.tex")

    inst.AnimState:SetBank("turfcraftingstation")
    inst.AnimState:SetBuild("turfcraftingstation")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("structure")
    inst:AddTag("prototyper")

    inst:AddComponent("inspectable")

    inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = onturnon
    inst.components.prototyper.onturnoff = onturnoff
    inst.components.prototyper.onactivate = function()
        if not inst:HasTag("burnt") then
            inst.AnimState:PlayAnimation("use")
            inst.AnimState:PushAnimation("proximity_loop", true)
            inst.SoundEmitter:PlaySound("turf_crafting_station/turf_crafting_station/station_use")
        end
    end
    inst.components.prototyper.trees =
    {
        SCIENCE = 0,
        MAGIC = 0,
        ANCIENT = 0,
        OBSIDIAN = 0,
        WATER = 0,
        HOME = 0,
        CITY = 0,
        LOST = 3,
    }

    inst:ListenForEvent("onbuilt", onbuilt)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    MakeSnowCovered(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload
    return inst
end

return Prefab("turfcraftingstation", fn, assets, prefabs),
    MakePlacer("turfcraftingstation_placer", "turfcraftingstation", "turfcraftingstation", "idle")
