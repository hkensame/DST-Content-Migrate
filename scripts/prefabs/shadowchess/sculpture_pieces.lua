local PHYSICS_RADIUS = .1

local function onunequip(inst, owner)
    owner:RemoveTag("heavylifting")
    owner.AnimState:ClearOverrideSymbol("swap_body")
end
--三个雕像头
local function makepiece(name)
    local assets =
    {
        Asset("ANIM", "anim/shadowchess/sculpture_pieces.zip"),
        Asset("ANIM", "anim/shadowchess/swap_sculpture_"..name..".zip"),
	}
	
	local prefabs =
	{
		"underwater_salvageable",
		"splash_green",
	}

    local function onequip(inst, owner)
        owner:AddTag("heavylifting")
        owner.AnimState:OverrideSymbol("swap_body", "swap_sculpture_"..name, "swap_body")
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()

        --MakeSmallHeavyObstaclePhysics(inst, PHYSICS_RADIUS)
        MakeInventoryPhysics(inst, PHYSICS_RADIUS)
        inst:SetPhysicsRadiusOverride(PHYSICS_RADIUS)

        inst.MiniMapEntity:SetIcon("sculpture_"..name..".tex")

        inst.AnimState:SetBank("sculpture_pieces")
        inst.AnimState:SetBuild("swap_sculpture_"..name)
        inst.AnimState:PlayAnimation("anim")

        inst:AddTag("irreplaceable")
        inst:AddTag("nonpotatable")
        inst:AddTag("heavy")
--[[
        inst:AddComponent("heavyobstaclephysics")
        inst.components.heavyobstaclephysics:SetRadius(PHYSICS_RADIUS)
        inst.components.heavyobstaclephysics:MakeSmallObstacle()
--]]
        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/dst_boss.xml"
        inst.components.inventoryitem.cangoincontainer = false
        inst.components.inventoryitem:SetSinks(true)

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.BODY

        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        --inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT or 0.15
        inst.components.equippable.walkspeedmult = -0.85

        inst:AddComponent("repairer")
        inst.components.repairer.repairmaterial = "sculpture"
		inst.components.repairer.workrepairvalue = TUNING.SCULPTURE_COMPLETE_WORK
		--[[
		inst:AddComponent("submersible")
		inst:AddComponent("symbolswapdata")
		inst.components.symbolswapdata:SetData("swap_sculpture_"..name, "swap_body")
--]]
        return inst
    end

    return Prefab("sculpture_"..name, fn, assets, prefabs)
end

--For searching: "sculpture_knighthead", "sculpture_bishophead", "sculpture_rooknose"
return makepiece("knighthead"),
    makepiece("bishophead"),
    makepiece("rooknose")
