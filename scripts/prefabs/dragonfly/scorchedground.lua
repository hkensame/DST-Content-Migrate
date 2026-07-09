local assets =
{
	Asset("ANIM", "anim/dragonfly/scorched_ground.zip")
}

local anim_names =
{
	"idle"
}

for i = 2, 10 do
	table.insert(anim_names, "idle"..tostring(i))
end

local function OnSave(inst, data)
	data.anim = inst.anim
	data.rotation = inst.Transform:GetRotation()
end

local function OnLoad(inst, data)
	if data ~= nil then
		if data.anim ~= nil then
			inst.anim = data.anim
			inst.AnimState:PlayAnimation(inst.anim)
		end
		if data.rotation ~= nil then
			inst.Transform:SetRotation(data.rotation)
		end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst.AnimState:SetBuild("scorched_ground")
	inst.AnimState:SetBank("scorched_ground")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")

	inst.anim = anim_names[math.random(#anim_names)]
	inst.AnimState:PlayAnimation(inst.anim)

	inst.Transform:SetRotation(math.random() * 360)
	
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("scorchedground", fn, assets)
