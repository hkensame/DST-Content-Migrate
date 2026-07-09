local assets =
{
    Asset("ANIM", "anim/toadstool/canary.zip"),
    Asset("ANIM", "anim/toadstool/canary_build.zip"),
    Asset("SOUND", "sound/birds.fsb"),
}

local prefabs =
{
    "canary",
    "spoiled_food",
    "feather_canary",
}

local function PreventPickup(inst)
    inst.components.inventoryitem.canbepickedup = false
end

local function AllowPickup(inst)
    if not (inst.sg:HasStateTag("nopickup") and inst.components.health:IsDead()) then
        inst.components.inventoryitem.canbepickedup = true
    end
end

local function OnPutInInventory(inst)
    inst.components.perishable:StartPerishing()
end

local function OnDropped(inst)
    inst.components.perishable:StopPerishing()
    if not inst.components.health:IsDead() then
        inst.sg:GoToState("dropped")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddPhysics()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()

    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD or 192)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES or 8192)
    inst.Physics:CollidesWith(COLLISION.GIANTS or 16384)
    inst.Physics:SetMass(1)
    inst.Physics:SetSphere(1)

    inst:AddTag("bird")
    inst:AddTag("canary")
    inst:AddTag("smallcreature")
    inst:AddTag("small_livestock")
    inst:AddTag("show_spoilage")
    inst:AddTag("sickness")
    inst:AddTag("untrappable")

    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank("canary")
    inst.AnimState:SetBuild("canary_build")
    inst.AnimState:PlayAnimation("struggle_idle_loop1", true)

    inst.DynamicShadow:SetSize(1, .75)

    inst.name = STRINGS.NAMES.CANARY

    inst._task = nil
    inst:SetStateGraph("SGcanarypoisoned")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ "spoiled_food" })

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    --inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BIRD_HEALTH)
    inst.components.health.murdersound = "dontstarve/wilson/hit_animal"

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "crow_body"

    inst:AddComponent("inspectable")

    MakeSmallBurnableCharacter(inst, "crow_body")
    MakeTinyFreezableCharacter(inst, "crow_body")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(2400 / .48) --(TUNING.BIRD_PERISH_TIME / .48)
    inst.components.perishable.onperishreplacement = "spoiled_food"
    inst.components.perishable:SetPercent(.48) --start at yellow
    inst.components.perishable:StopPerishing()

    inst:ListenForEvent("death", PreventPickup)
    inst:ListenForEvent("freeze", PreventPickup)
    inst:ListenForEvent("unfreeze", AllowPickup)
    
    inst:DoTaskInTime(1, function()
      if IsDLCEnabled(CAPY_DLC) and SaveGameIndex:IsModeShipwrecked() then
        inst:Remove()
      end
    end)

    return inst
end

return Prefab("canary_poisoned", fn, assets, prefabs)
