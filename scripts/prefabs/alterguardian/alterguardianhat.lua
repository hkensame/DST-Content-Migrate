local Assets =
{
 Asset("ANIM", "anim/alterguardian/hat_alterguardian.zip"),
 Asset("ANIM", "anim/alterguardian/ui_alterguardianhat_1x6.zip"),
}

local prefabs =
{
	"alterguardian_hat_equipped",
}

TUNING.SANITY_BECOME_ENLIGHTENED_THRESH = 170/200

local fname = "hat_alterguardian"

	local function onequip(inst, owner, fname_override)
		local build = fname_override or fname
		owner.AnimState:OverrideSymbol("swap_hat", build, "swap_hat")
		owner.AnimState:Show("HAT")
		owner.AnimState:Show("HAIR_HAT")
		owner.AnimState:Hide("HAIR_NOHAT")
		owner.AnimState:Hide("HAIR")
		
		if owner:HasTag("player") then
			owner.AnimState:Hide("HEAD")
			owner.AnimState:Show("HEAD_HAIR")
		end
		
		if inst.components.fueled then
			inst.components.fueled:StartConsuming()        
		end
	end

	local function _onunequip(inst, owner)
		owner.AnimState:Hide("HAT")
		owner.AnimState:Hide("HAIR_HAT")
		owner.AnimState:Show("HAIR_NOHAT")
		owner.AnimState:Show("HAIR")

		if owner:HasTag("player") then
			owner.AnimState:Show("HEAD")
			owner.AnimState:Hide("HEAD_HAIR")
		end

		if inst.components.fueled then
			inst.components.fueled:StopConsuming()        
		end
	end
	
	local function opentop_onequip(inst, owner)
		owner.AnimState:OverrideSymbol("swap_hat", fname, "swap_hat")
		owner.AnimState:Show("HAT")
		owner.AnimState:Hide("HAIR_HAT")
		owner.AnimState:Show("HAIR_NOHAT")
		owner.AnimState:Show("HAIR")
		
		owner.AnimState:Show("HEAD")
		owner.AnimState:Hide("HEAD_HAIR")

		if inst.components.fueled then
			inst.components.fueled:StartConsuming()        
		end
	end

--格子
local slotpos = {}
for i = 0, 4 do
  table.insert(slotpos, Vector3(0, 95 - (i*72), 0))
end


    local function alterguardianhat_IsRed(inst) return inst.prefab == MUSHTREE_SPORE_RED end
    local function alterguardianhat_IsGreen(inst) return inst.prefab == MUSHTREE_SPORE_GREEN end
    local function alterguardianhat_IsBlue(inst) return inst.prefab == MUSHTREE_SPORE_BLUE end
    local alterguardianhat_colourtint = { 0.4, 0.3, 0.25, 0.2, 0.15, 0.1 }
    local alterguardianhat_multtint = { 0.7, 0.6, 0.55, 0.5, 0.45, 0.4 }

    local function alterguardianhat_animstatemult(animstate, r, g, b)
        animstate:SetMultColour(
            alterguardianhat_multtint[1+g+b],
            alterguardianhat_multtint[r+1+b],
            alterguardianhat_multtint[r+g+1],
            1
        )
    end
    local function alterguardianhat_updatelight(inst)
        local num_sources = #inst.components.container:FindItems(function(item)
            return item:HasTag("spore")
        end)

        local r = #inst.components.container:FindItems(alterguardianhat_IsRed)
        local g = #inst.components.container:FindItems(alterguardianhat_IsGreen)
        local b = #inst.components.container:FindItems(alterguardianhat_IsBlue)

        if inst._light ~= nil and inst._light:IsValid() then
            if r > 0 or g > 0 or b > 0 then
                inst._light.Light:SetColour(
                    alterguardianhat_colourtint[1+g+b] + r/11,
                    alterguardianhat_colourtint[r+1+b] + g/11,
                    alterguardianhat_colourtint[r+g+1] + b/11
                )
            else
                -- If no spores are inserted, match the colour of the miner hat light.
                inst._light.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
            end
        end

        alterguardianhat_animstatemult(inst.AnimState, r, g, b)

        if inst._front and inst._front:IsValid() then
            alterguardianhat_animstatemult(inst._front.AnimState, r, g, b)
        end

        if inst._back and inst._back:IsValid() then
            alterguardianhat_animstatemult(inst._back.AnimState, r, g, b)
        end
    end

	local function alterguardian_activate(inst, owner)
		if inst._is_active then
			return
		end
		inst._is_active = true

		if inst._task ~= nil then
			inst._task:Cancel()
			inst._task = nil
		end

		_onunequip(inst, owner) -- hide the swap_hat

		if inst._front == nil then
			inst._front = SpawnPrefab("alterguardian_hat_equipped")
			inst._front:OnActivated(owner, true)
		end
		if inst._back == nil then
			inst._back = SpawnPrefab("alterguardian_hat_equipped")
			inst._back:OnActivated(owner, false)
		end

        if inst._light == nil then
            inst._light = SpawnPrefab("alterguardianhatlight")
	        inst._light.entity:SetParent(owner.entity)
        end
        alterguardianhat_updatelight(inst)
	end

	local function alterguardian_deactivate(inst, owner)
		if not inst._is_active then
			return
		end
		inst._is_active = false

        if inst._light ~= nil then
            inst._light:Remove()
            inst._light = nil
		end

		if inst._front ~= nil then
			inst._front:OnDeactivated()
			inst._front = nil
			inst._task = inst:DoTaskInTime(8*FRAMES, function()
                opentop_onequip(inst, owner)
                inst._task = nil
            end)
		else
			opentop_onequip(inst, owner)
		end

		if inst._back ~= nil then
			inst._back:OnDeactivated()
			inst._back = nil
		end
	end

	local function alterguardian_onsanitydelta(inst, owner)
		local sanity = owner.components.sanity ~= nil and owner.components.sanity:GetPercent() or 0
		if sanity > TUNING.SANITY_BECOME_ENLIGHTENED_THRESH then
			alterguardian_activate(inst, owner)
		else
			alterguardian_deactivate(inst, owner)
		end
	end

	local function alterguardian_spawngestalt_fn(inst, owner, data)
		if not inst._is_active then
			return
		end

		if owner ~= nil and (owner.components.health == nil or not owner.components.health:IsDead()) then
		    local target = data.target
			if target and target ~= owner and target:IsValid() and (target.components.health == nil or not target.components.health:IsDead() and not target:HasTag("structure") and not target:HasTag("wall")) then

                -- In combat, this is when we're just launching a projectile, so don't spawn a gestalt yet
                if data.weapon ~= nil and data.projectile == nil 
                        and (data.weapon.components.projectile ~= nil
                            or data.weapon.components.complexprojectile ~= nil
                            or data.weapon.components.weapon:CanRangedAttack()) then
                    return
                end

				local x, y, z = target.Transform:GetWorldPosition()

				local gestalt = SpawnPrefab("alterguardianhat_projectile")
				local r = GetRandomMinMax(3, 5)
				local delta_angle = GetRandomMinMax(-90, 90)
				local angle = (owner:GetAngleToPoint(x, y, z) + delta_angle) * DEGREES
				gestalt.Transform:SetPosition(x + r * math.cos(angle), y, z + r * -math.sin(angle))
				gestalt:ForceFacePoint(x, y, z)
				gestalt:SetTargetPosition(Vector3(x, y, z))
				gestalt.components.follower:SetLeader(owner)

				if owner.components.sanity ~= nil then
					owner.components.sanity:DoDelta(-1, true) -- using overtime so it doesnt make the sanity sfx every time you attack
				end
			end
		end
	end

    local function alterguardian_onequip(inst, owner)
        opentop_onequip(inst, owner)

		inst.alterguardian_spawngestalt_fn = function(_owner, _data) alterguardian_spawngestalt_fn(inst, _owner, _data) end
		inst:ListenForEvent("onattackother", inst.alterguardian_spawngestalt_fn, owner)

		inst._onsanitydelta = function() alterguardian_onsanitydelta(inst, owner) end
		inst:ListenForEvent("sanitydelta", inst._onsanitydelta, owner)
		
		local sanity = owner.components.sanity ~= nil and owner.components.sanity:GetPercent() or 0
		if sanity > TUNING.SANITY_BECOME_ENLIGHTENED_THRESH then
			alterguardian_activate(inst, owner)
		end

        if inst.components.container ~= nil then
            --inst.components.container:Open(owner)
        end
    end

    local function alterguardian_onunequip(inst, owner)
		inst._is_active = false

		inst:RemoveEventCallback("sanitydelta", inst._onsanitydelta, owner)
		inst:RemoveEventCallback("onattackother", inst.alterguardian_spawngestalt_fn, owner)

        if inst._light ~= nil then
            inst._light:Remove()
            inst._light = nil
		end

        _onunequip(inst, owner)
		if inst._front ~= nil then
			inst._front:Remove()
			inst._front = nil
		end 
		if inst._back ~= nil then
			inst._back:Remove()
			inst._back = nil
		end

        if inst.components.container ~= nil then
            inst.components.container:Close()
        end
    end

    local function alterguardianhat_onremove(inst)
        if inst._front ~= nil and inst._front:IsValid() then
            inst._front:Remove()
        end
        if inst._back ~= nil and inst._back:IsValid() then
            inst._back:Remove()
        end
    end

local function fn(Sim)
 local inst = CreateEntity()
 inst.entity:AddTransform()
 inst.entity:AddAnimState()
 
    MakeInventoryPhysics(inst)
 
    inst.AnimState:SetBank("alterguardianhat")
    inst.AnimState:SetBuild("hat_alterguardian")
    inst.AnimState:PlayAnimation("anim")
    
    inst:AddTag("hat")
    inst:AddTag("open_top_hat")
    inst:AddTag("gestaltprotection")
 
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "alterguardianhat"
    inst.components.inventoryitem.atlasname = "images/dst_boss.xml"

        --inst.components.floater:SetSize("med")
        --inst.components.floater:SetScale(0.68)
        if rawget(_G, 'MakeInventoryFloatable') then
            MakeInventoryFloatable(inst, "anim", "anim")
        end

        inst:AddComponent("equippable")
      		inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        inst.components.equippable.dapperness = -TUNING.CRAZINESS_SMALL
        inst.components.equippable:SetOnEquip(alterguardian_onequip)
        inst.components.equippable:SetOnUnequip(alterguardian_onunequip)
	    inst.components.equippable.is_magic_dapperness = true

        inst:AddComponent("preserver")
        inst.components.preserver:SetPerishRateMultiplier(0)

        inst:AddComponent("container")
        --inst.components.container:WidgetSetup("alterguardianhat")
        inst.components.container.acceptsstacks = false
        
        inst.components.container.numslots = #slotpos
        inst.components.container.widgetslotpos = slotpos
        inst.components.container.widgetanimbank = "ui_alterguardianhat_1x6"
        inst.components.container.widgetanimbuild = "ui_alterguardianhat_1x6"
        inst.components.container.side_align_tip = 160
        inst.components.container.type = "hand_inv"
        inst.components.container.widgetpos = Vector3(240, -85, 0)

        inst:ListenForEvent("itemget", alterguardianhat_updatelight)
        inst:ListenForEvent("itemlose", alterguardianhat_updatelight)
        inst:ListenForEvent("onremove", alterguardianhat_onremove)

  return inst
end

local function alterguardianhatlightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()

    inst:AddTag("FX")

    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(.8)
    inst.Light:SetRadius(4)

    inst.persists = false

    return inst
end

return Prefab("common/inventory/alterguardianhat", fn, Assets),
       Prefab("alterguardianhatlight", alterguardianhatlightfn)
