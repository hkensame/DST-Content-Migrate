-- 棕榈锥种子 (palmcone_seed)
-- 移植自 DST，适配 DS 单机模式
-- DS pinecone 风格：种子即树苗，种植后生长为棕榈锥树

local assets = {
    Asset("ANIM", "anim/monkey/palmcone_seed.zip"),
}

local prefabs = {
    "palmconetree_short",
}

local function growtree(inst)
    inst.growtask = nil
    inst.growtime = nil
    local tree = SpawnPrefab("palmconetree_short")
    if tree then
        tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tree:growfromseed()
        inst:Remove()
    end
end

local function digup(inst, digger)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function plant(inst, growtime)
    inst:RemoveComponent("inventoryitem")
    inst.AnimState:PlayAnimation("idle_planted")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
    inst.growtime = GetTime() + growtime
    inst.growtask = inst:DoTaskInTime(growtime, growtree)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ "twigs" })

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(digup)
    inst.components.workable:SetWorkLeft(1)
end

local function ondeploy(inst, pt)
    inst = inst.components.stackable:Get()
    if inst.components.inventoryitem then
        inst.components.inventoryitem:OnRemoved()
    end
    inst.Transform:SetPosition(pt:Get())
    local timeToGrow = GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base, TUNING.PINECONE_GROWTIME.random)
    plant(inst, timeToGrow)
end

local function stopgrowing(inst)
    if inst.growtask then
        inst.growtask:Cancel()
        inst.growtask = nil
    end
    inst.growtime = nil
end

local notags = { "NOBLOCK", "player", "FX" }
local function test_ground(inst, pt)
    local tiletype = GetGroundTypeAtPosition(pt)
    local ground_OK = tiletype ~= GROUND.ROCKY and tiletype ~= GROUND.ROAD and tiletype ~= GROUND.IMPASSABLE and
                        tiletype ~= GROUND.UNDERROCK and tiletype ~= GROUND.WOODFLOOR and
                        tiletype ~= GROUND.CARPET and tiletype ~= GROUND.CHECKER and tiletype < GROUND.UNDERGROUND
    if ground_OK then
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 4, nil, notags)
        local min_spacing = inst.components.deployable.min_spacing or 2
        for k, v in pairs(ents) do
            if v ~= inst and v:IsValid() and v.entity:IsVisible() and not v.components.placer and v.parent == nil then
                if distsq(Vector3(v.Transform:GetWorldPosition()), pt) < min_spacing * min_spacing then
                    return false
                end
            end
        end
        return true
    end
    return false
end

local function describe(inst)
    if inst.growtime then
        return "PLANTED"
    end
end

local function displaynamefn(inst)
    if inst.growtime then
        return STRINGS.NAMES.PALMCONE_SAPLING
    end
    return STRINGS.NAMES.PALMCONE_SEED
end

local function OnSave(inst, data)
    if inst.growtime then
        data.growtime = inst.growtime - GetTime()
    end
end

local function OnLoad(inst, data)
    if data and data.growtime then
        plant(inst, data.growtime)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("palmcone_seed")
    inst.AnimState:SetBuild("monkey/palmcone_seed")
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "WOOD"
    inst.components.edible.woodiness = 2

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = describe

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    inst:ListenForEvent("onignite", stopgrowing)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventoryitem")

    inst:AddComponent("deployable")
    inst.components.deployable.test = test_ground
    inst.components.deployable.ondeploy = ondeploy

    inst.displaynamefn = displaynamefn

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("common/inventory/palmcone_seed", fn, assets, prefabs),
    MakePlacer("common/palmcone_seed_placer", "palmcone_seed", "monkey/palmcone_seed", "idle_planted")
