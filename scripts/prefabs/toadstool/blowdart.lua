local assets =
{
    Asset("ANIM", "anim/toadstool/new_blow_dart.zip"),
    Asset("ANIM", "anim/toadstool/new_swap_blowdart.zip"),
}

local prefabs =
{
    "impact",
    "electrichitsparks",
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_blowdart", "swap_blowdart")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onhit(inst, attacker, target)
    local impactfx = SpawnPrefab("impact")
    if impactfx ~= nil and target.components.combat then
        local follower = impactfx.entity:AddFollower()
        follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
        if attacker ~= nil and attacker:IsValid() then
            impactfx:FacePoint(attacker.Transform:GetWorldPosition())
        end
    end
    inst:Remove()
end

local function onthrown(inst, data)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.components.inventoryitem.pushlandedevents = false
end

local function common()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("blow_dart")
    inst.AnimState:SetBuild("blow_dart")
    inst.AnimState:PlayAnimation("idle_yellow")

    inst:AddTag("blowdart")
    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("projectile")

    if rawget(_G, 'MakeInventoryFloatable') then
        MakeInventoryFloatable(inst, "idle_yellow", "idle_yellow")
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(8, 10)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(60)
    inst.components.projectile:SetOnHitFn(onhit)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst:ListenForEvent("onthrown", onthrown)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = true

    return inst
end

local function yellowthrown(inst)
    inst.AnimState:PlayAnimation("dart_yellow")
    inst:AddTag("NOCLICK")
    inst.persists = false
end

local function yellowattack(inst, attacker, target)
    if target:IsValid() then
        local fx = SpawnPrefab("electrichitsparks")
        if fx then
            fx.Transform:SetPosition(target.Transform:GetWorldPosition())
        end
    end
end

local function yellow()
    local inst = common()

    inst.components.weapon:SetOnAttack(yellowattack)
    if IsDLCEnabled(REIGN_OF_GIANTS) or IsDLCEnabled(CAPY_DLC) or IsDLCEnabled(PORKLAND_DLC) then
        inst.components.weapon:SetDamage(TUNING.YELLOW_DART_DAMAGE)
        inst.components.weapon:SetElectric()
    else
        inst.components.weapon:SetDamage(TUNING.YELLOW_DART_DAMAGE_DS)
    end
    inst.components.projectile:SetOnThrownFn(yellowthrown)

    inst.components.inventoryitem.imagename = "blowdart_yellow"
    inst.components.inventoryitem.atlasname = "images/blowdart_yellow.xml"

    local swap_data = {sym_build = "swap_blowdart", bank = "blow_dart", anim = "idle_yellow"}
    if inst.components.floater then
        inst.components.floater:SetBankSwapOnFloat(true, -4, swap_data)
    end

    return inst
end

return Prefab("blowdart_yellow", yellow, assets, prefabs)
