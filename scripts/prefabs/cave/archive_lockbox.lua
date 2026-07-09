local assets =
{
    Asset("ANIM", "anim/cave/archive_lockbox.zip"),
    Asset("MINIMAP_IMAGE", "archive_knowledge_dispensary"),
}

local prefabs =
{
    "archive_dispencer_sfx",
    "archive_lockbox",
}

local assetsdispencer =
{
    Asset("ANIM", "anim/cave/archive_knowledge_dispensary.zip"),
    Asset("ANIM", "anim/cave/archive_knowledge_dispensary_b.zip"),
    Asset("ANIM", "anim/cave/archive_knowledge_dispensary_c.zip"),
	Asset("ANIM", "anim/cave/archive_knowledge_dispensary_d.zip"),
	Asset("ANIM", "anim/cave/archive_knowledge_dispensary_e.zip"),
    Asset("MINIMAP_IMAGE", "archive_knowledge_dispensary"),
    Asset("MINIMAP_IMAGE", "archive_knowledge_dispensary_b"),
    Asset("MINIMAP_IMAGE", "archive_knowledge_dispensary_c"),
	Asset("MINIMAP_IMAGE", "archive_knowledge_dispensary_d"),
	Asset("MINIMAP_IMAGE", "archive_knowledge_dispensary_e"),
}

local OCHESTRINA_MAIN_MUST = {"archive_orchestrina_main"}

local function OnSave(inst, data)
    data.puzzle = inst.puzzle
    data.product_orchestrina = inst.product_orchestrina
end

local function OnLoad(inst, data)
    if data ~= nil and data.puzzle ~= nil then
        inst.puzzle = data.puzzle
    end

    if data ~= nil and data.product_orchestrina ~= nil then
        inst.product_orchestrina = data.product_orchestrina
        if inst.product_orchestrina == "archive_resonator" then
            inst.product_orchestrina = "archive_resonator_item"
        end
    end
end

local function teach(inst)
    inst.persists = false
    local recipe = inst.product_orchestrina
    if recipe == "archive_resonator" then
        recipe = "archive_resonator_item"
	elseif recipe == "vaultrelic" then
		recipe = "vaultrelic_bowl"
    end
	local recipe2 =
		(inst.product_orchestrina == "turfcraftingstation" and "turf_archive") or
		(inst.product_orchestrina == "turf_vault" and "turfcraftingstation") or
		(inst.product_orchestrina == "vaultrelic" and "vaultrelic_vase") or
		nil
	local recipe3 = inst.product_orchestrina == "vaultrelic" and "vaultrelic_planter" or nil

    local pos = Vector3(inst.Transform:GetWorldPosition())
    local players = FindPlayersInRange( pos.x, pos.y, pos.z, 20, true )

    for i,player in ipairs(players) do
        if recipe and player.components.builder then
            local fx = SpawnPrefab("archive_lockbox_player_fx")
            if fx ~= nil then
                player:AddChild(fx)
            end

			local got_new_blueprint = false
            if not player.components.builder:KnowsRecipe(recipe) then
				local loot = SpawnPrefab(recipe.."_blueprint")
				if loot then
					got_new_blueprint = true
					player.components.inventory:GiveItem(loot, nil, pos)
				end
			end
            if recipe2 and not player.components.builder:KnowsRecipe(recipe2) then
				local loot = SpawnPrefab(recipe2.."_blueprint")
				if loot then
					got_new_blueprint = true
					player.components.inventory:GiveItem(loot, nil, pos)
				end
			end
			if recipe3 and not player.components.builder:KnowsRecipe(recipe3) then
				local loot = SpawnPrefab(recipe3.."_blueprint")
				if loot then
					got_new_blueprint = true
					player.components.inventory:GiveItem(loot, nil, pos)
				end
			end

            if player.components.talker then
                player.components.talker:Say(GetString(player.prefab, got_new_blueprint and "ANNOUNCE_ARCHIVE_NEW_KNOWLEDGE" or "ANNOUNCE_ARCHIVE_OLD_KNOWLEDGE"), nil, true)
            end
        end
    end
end

local function OnTeach(inst)
    if not inst.AnimState:IsCurrentAnimation("activation") then
        inst:RemoveComponent("inventoryitem")
        inst.AnimState:PlayAnimation("activation")
        inst.SoundEmitter:PlaySound("grotto/common/archive_lockbox/open")
        inst:DoTaskInTime(174/30, function() teach(inst) end)
    end
end

local function OnPutInInventory(inst)
    inst.removewhenspawned = nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("archive_lockbox")
    inst.AnimState:SetBuild("archive_lockbox")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("archive_lockbox")

    local order = {1,2,3,4,5,6,7,8}
    inst.puzzle = {}

    for i=1,8 do
        local num = math.random(1,#order)
        table.insert(inst.puzzle,order[num])
        table.remove(order,num)
    end

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.product_orchestrina = nil

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.teach = teach

    inst:ListenForEvent("onteach", OnTeach)
    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("activation") then
            local x,y,z = inst.Transform:GetWorldPosition()
            local main = TheSim:FindEntities(x,y,z, 10, OCHESTRINA_MAIN_MUST)
            if main then
                for i,ent in ipairs(main)do
                    ent.busy = false
                end
            end
            inst:Remove()
        end
    end)

    return inst
end

local function movesound(inst, baseangle, pos)
    local sound = {angle = 0, dist=0}
    if inst.soundlist and inst.soundlist[1] then
        sound = inst.soundlist[1]
        table.remove(inst.soundlist,1)
    end
    local radius = sound.dist
    local theta = sound.angle + baseangle
    local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
    inst.Transform:SetPosition(offset.x+pos.x,0,offset.z+pos.z)
    inst.SoundEmitter:PlaySound("grotto/common/archive_lockbox/hit")
end

local function IsArchivePowered(inst)
    local theWorld = inst:GetTheWorld()
    if theWorld ~= nil and theWorld.components.archivemanager ~= nil then
        return theWorld.components.archivemanager:GetPowerSetting()
    end
    return false
end

local function OnActivate(inst, doer)
	local powered
	if inst.vaultpowered then
		powered = true
	else
		powered = IsArchivePowered(inst)
	end
	if powered then
        if not inst.AnimState:IsCurrentAnimation("use_pre") and not inst.AnimState:IsCurrentAnimation("use_loop") and not inst.AnimState:IsCurrentAnimation("use_post") then
            inst.AnimState:PlayAnimation("use_pre",false)

            inst.sfx = SpawnPrefab("archive_dispencer_sfx")
            inst.sfx.SoundEmitter:PlaySound("grotto/common/archive_lockbox/LP", "loopsound")
            local baserotation = math.random()*PI2
            local pos = Vector3(inst.Transform:GetWorldPosition())
            inst.sfx.soundlist = {
                {angle=0,dist=20},
                {angle=PI/6,dist=15},
                {angle=-PI/12,dist=10},
                {angle=-PI/2.3,dist=8},
                {angle=0,dist=4},
            }
            movesound(inst.sfx, baserotation, pos)

            inst.sfx:DoTaskInTime(1,function() movesound(inst.sfx, baserotation, pos) end)
            inst.sfx:DoTaskInTime(1.7,function() movesound(inst.sfx, baserotation, pos) end)
            inst.sfx:DoTaskInTime(2.7,function() movesound(inst.sfx, baserotation, pos) end)
            inst.sfx:DoTaskInTime(3.8,function() movesound(inst.sfx, baserotation, pos) end)
            inst.sfx:DoTaskInTime(4.5,function() movesound(inst.sfx, baserotation, pos) end)
        end
    else
        inst.components.activatable.inactive = true
        if doer and doer.components.talker then
            doer.components.talker:Say(GetString(doer.prefab, "ANNOUNCE_ARCHIVE_NO_POWER"), nil, true)
        end
    end
end

local function OnSaveDispencer(inst, data)
    data.product_orchestrina = inst.product_orchestrina
end

local function updateart(inst)
	if inst.product_orchestrina == "turf_vault" then
		inst.AnimState:AddOverrideBuild("archive_knowledge_dispensary_d")
		inst.MiniMapEntity:SetIcon("archive_knowledge_dispensary_d.tex")
		inst.vaultpowered = true
	elseif inst.product_orchestrina == "vaultrelic" then
		inst.AnimState:AddOverrideBuild("archive_knowledge_dispensary_e")
		inst.MiniMapEntity:SetIcon("archive_knowledge_dispensary_e.tex")
		inst.vaultpowered = true
	else
		inst.vaultpowered = nil
		if inst.product_orchestrina == "archive_resonator_item" then
			inst.AnimState:AddOverrideBuild("archive_knowledge_dispensary_b")
			inst.MiniMapEntity:SetIcon("archive_knowledge_dispensary_b.tex")
		elseif inst.product_orchestrina == "refined_dust" then
			inst.AnimState:AddOverrideBuild("archive_knowledge_dispensary_c")
			inst.MiniMapEntity:SetIcon("archive_knowledge_dispensary_c.tex")
		else
			inst.AnimState:SetBuild("archive_knowledge_dispensary") -- DS: ClearAllOverrideSymbols not available
			inst.MiniMapEntity:SetIcon("archive_knowledge_dispensary.tex")
		end
	end

	if inst.vaultpowered then
		inst.AnimState:Show("moss")
		inst.components.inspectable.getstatus = nil
	else
		inst.AnimState:Hide("moss")
	end
end

local function SetProductOrchestrina(inst, product)
	inst.product_orchestrina = product == "archive_resonator" and "archive_resonator_item" or product
	updateart(inst)
end

local function OnLoadDispencer(inst, data)
    if data ~= nil and data.product_orchestrina ~= nil then
		inst:SetProductOrchestrina(data.product_orchestrina)
    end
end

-- Sequential counter for deterministic product distribution (Yellow → Blue → Green) across room dispensers
local _dispencer_counter = 0

local function dispencerfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("archive_knowledge_dispensary.tex")

    MakeObstaclePhysics(inst, 0.66)

    inst.AnimState:SetBank("knowledge_dispensary")
    inst.AnimState:SetBuild("archive_knowledge_dispensary")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:Hide("moss")

    inst:ListenForEvent("animover", function()

        if inst.AnimState:IsCurrentAnimation("idle") then
            if IsArchivePowered(inst) and math.random()< 1/30 then
                local rand = math.random(1,3)
                inst.AnimState:PlayAnimation("taunt"..rand)
                inst.SoundEmitter:PlaySound("grotto/common/archive_lockbox/taunt")
                inst.AnimState:PushAnimation("idle")
            else
                inst.AnimState:PlayAnimation("idle")
            end
        end

        if inst.AnimState:IsCurrentAnimation("use_pre") then
            inst.AnimState:PlayAnimation("use_loop",true)
            inst:DoTaskInTime((45/30) * 2,function()
                inst.SoundEmitter:PlaySound("grotto/common/archive_lockbox/use")
            end)
            inst:DoTaskInTime((45/30) * 3,function()
                inst.AnimState:PlayAnimation("use_post")
                inst:DoTaskInTime(21/30,function()
                    if inst.sfx then
                        inst.sfx:Remove()
                    end

                    if inst.pastloot and inst.pastloot.removewhenspawned then
                        ErodeAway(inst.pastloot)
                    end
                    local loot = SpawnPrefab("archive_lockbox")
                    local pt = Vector3(inst.Transform:GetWorldPosition())
                    pt.y = 3
                    inst.components.lootdropper:FlingItem(loot, pt)

                    loot.product_orchestrina = inst.product_orchestrina
                    inst.components.activatable.inactive = true
                    inst.pastloot = loot
                    loot.removewhenspawned = true
                end)
            end)
        end

        if inst.AnimState:IsCurrentAnimation("use_post") then
            inst.AnimState:PlayAnimation("idle")
        end
    end)

    inst:AddTag("structure")
    inst:AddTag("dustable")

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.quickaction = true

    -- Sequential product assignment: evenly cycles through Yellow (turfcraftingstation), Blue (archive_resonator_item), Green (refined_dust)
    local products = {"turfcraftingstation", "archive_resonator_item", "refined_dust"}
    _dispencer_counter = (_dispencer_counter % #products) + 1
    inst.product_orchestrina = products[_dispencer_counter]
    inst:DoTaskInTime(0, function()
        updateart(inst)
    end)
	inst.SetProductOrchestrina = SetProductOrchestrina

    inst.OnSave = OnSaveDispencer
    inst.OnLoad = OnLoadDispencer

    inst.updateart = updateart

    return inst
end

local function archive_dispencer_sfxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst.persists = false

    return inst
end

local function worldgenitemfn()
    -- this is just used during world gen and should not stick around.
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst.persists = false

    inst:DoTaskInTime(0,function() inst:Remove() end)
    return inst
end

return Prefab("archive_lockbox", fn, assets),
       Prefab("archive_lockbox_dispencer", dispencerfn, assetsdispencer, prefabs),
       Prefab("archive_dispencer_sfx", archive_dispencer_sfxfn),
       Prefab("archive_lockbox_dispencer_temp",worldgenitemfn)
