
local rock_moon_glass_assets =
{
    Asset("ANIM", "anim/moonisland/moonglass_rock.zip"),
    Asset("ANIM", "anim/moonisland/moonglass_rock2.zip"),
    Asset("ANIM", "anim/moonisland/moonglass_rock3.zip"),
    Asset("ANIM", "anim/moonisland/moonglass_rock4.zip"),
    Asset("MINIMAP_IMAGE", "rock_moonglass"),
}

local rock_moon_shell_assets =
{
    Asset("ANIM", "anim/moonisland/moonrock_shell.zip"),
}

local prefabs =
{
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "moonrocknugget",
    "moonrockseed",
    "moonrockseed_icon",
}    

SetSharedLootTable( 'rock_moon_glass',
{
    {'moonglass',       1.00},
    {'moonglass',       1.00},
    {'moonglass',       0.25},
})

SetSharedLootTable( 'rock_moon_shell',
{
    {'rocks',           1.00},
    {'flint',           1.00},
    {'moonrocknugget',  1.00},
    {'moonrocknugget',  1.00},
    {'moonrocknugget',  1.00},
    {'moonrocknugget',  0.3},
    {'moonrockseed',    1.00},
})

local function OnRockMoonCapsuleWorkFinished(inst)
    RemovePhysicsColliders(inst)

    -- moonrockseed 已在 loot table 中，无需单独 spawn

    inst.persists = false
    inst:AddTag("NOCLICK")

    inst.AnimState:PlayAnimation("break")
    inst:DoTaskInTime(2, function(inst)
        inst:Remove()
    end)
end

local function baserock_fn(bank, build, anim, minimapicon, tag, multcolour)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
	MakeObstaclePhysics(inst, 1.)

    if minimapicon then
        inst.MiniMapEntity:SetIcon(minimapicon)
    end

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)

    if type(anim) == "table" then
        for i, v in ipairs(anim) do
            if i == 1 then
                inst.AnimState:PlayAnimation(v)
                inst.scrapbook_anim = v
            else
                inst.AnimState:PushAnimation(v, false)
            end
        end
    else
        inst.AnimState:PlayAnimation(anim)
        inst.scrapbook_anim = anim
    end

    if tag then
        inst:AddTag(tag)
    end

	inst:AddComponent("lootdropper") 
	
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
	
	inst.components.workable:SetOnWorkCallback(
		function(inst, worker, workleft)
			local pt = Point(inst.Transform:GetWorldPosition())
			if workleft <= 0 then
				inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
				inst.components.lootdropper:DropLoot(pt)
				inst:Remove()
			else
				
				
				if workleft < TUNING.ROCKS_MINE*(1/3) then
					inst.AnimState:PlayAnimation("low")
				elseif workleft < TUNING.ROCKS_MINE*(2/3) then
					inst.AnimState:PlayAnimation("med")
				else
					inst.AnimState:PlayAnimation("full")
				end
			end
		end)     

    multcolour = multcolour or 0.5
    if 0 <= multcolour and multcolour < 1 then
        local colour = multcolour + math.random() * (1.0 - multcolour)
        inst.AnimState:SetMultColour(colour, colour, colour, 1)
    end

	inst:AddComponent("inspectable")
	inst.components.inspectable.nameoverride = "ROCK"
	MakeSnowCovered(inst, .01)        
	return inst
end

---
local function on_save_moonglass(inst, data)
    data.rock_type = inst.rock_type
end

local function set_moonglass_type(inst, new_type)
    inst.rock_type = new_type
    local anim_name = (inst.rock_type == 1 and "moonglass_rock") or ("moonglass_rock"..tostring(new_type))
    inst.AnimState:SetBuild(anim_name)
    inst.AnimState:SetBank(anim_name)
end

local function on_load_moonglass(inst, data)
    if data and data.rock_type then
        set_moonglass_type(inst, data.rock_type)
    end
end

local function rock_moon_glass()
    local inst = baserock_fn("moonglass_rock", "moonglass_rock", "full", "rock_moonglass.tex", "moonglass", 1.0)

    inst:SetPrefabName("moonglass_rock")

    inst.scrapbook_bank  = "moonglass_rock"
    inst.scrapbook_build = "moonglass_rock"

    set_moonglass_type(inst, math.random(4))

    inst.components.inspectable.nameoverride = "MOONGLASS_ROCK"
    inst.components.lootdropper:SetChanceLootTable('rock_moon_glass')

    inst.OnSave = on_save_moonglass
    inst.OnLoad = on_load_moonglass

    return inst
end


local function rock_moon_shell()
    local inst = baserock_fn("moonrock_shell", "moonrock_shell", "full", "rock_moon_shell.tex", "meteor_protection")

    inst.components.inspectable.nameoverride = "ROCK_MOON"
    inst.components.lootdropper:SetChanceLootTable('rock_moon_shell')

    inst.doNotRemoveOnWorkDone = true
    inst:ListenForEvent("workfinished", OnRockMoonCapsuleWorkFinished)

    return inst
end

return 
    Prefab("moonglass_rock", rock_moon_glass, rock_moon_glass_assets, prefabs),
    Prefab("rock_moon_shell", rock_moon_shell, rock_moon_shell_assets, prefabs)

