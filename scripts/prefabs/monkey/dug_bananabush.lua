-- 挖起的香蕉丛 (dug_bananabush)
-- 可重新种植

local assets =
{
    Asset("ANIM", "anim/monkey/bananabush.zip"),
    Asset("INV_IMAGE", "dug_bananabush")
}

local notags = { 'NOBLOCK', 'player', 'FX' }
local function test_ground(inst, pt)
	local tiletype = GetGroundTypeAtPosition(pt)
	local ground_OK = tiletype ~= GROUND.ROCKY and tiletype ~= GROUND.ROAD and tiletype ~= GROUND.IMPASSABLE and
						tiletype ~= GROUND.UNDERROCK and tiletype ~= GROUND.WOODFLOOR and 
						tiletype ~= GROUND.CARPET and tiletype ~= GROUND.CHECKER and tiletype < GROUND.UNDERGROUND
	if ground_OK then
	    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 4, nil, notags)
		local min_spacing = inst.components.deployable.min_spacing or 2
	    for k, v in pairs(ents) do
			if v ~= inst and v:IsValid() and v.entity:IsVisible() and not v.components.placer and v.parent == nil then
				if distsq( Vector3(v.Transform:GetWorldPosition()), pt) < min_spacing*min_spacing then
					return false
				end
			end
		end
		return true
	end
	return false
end

local function ondeploy(inst, pt, deployer)
    local plant = SpawnPrefab("bananabush")
    if plant then
        if deployer ~= nil and deployer.SoundEmitter ~= nil then
            deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
        end
        plant.Transform:SetPosition(pt.x, pt.y, pt.z)
        plant.components.pickable:OnTransplant()
        inst.components.stackable:Get():Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bananabush")
    inst.AnimState:SetBuild("bananabush")
    inst.AnimState:PlayAnimation("dead")

    inst:AddTag("plant")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "dug_bananabush"
    inst.components.inventoryitem.atlasname = "images/dug_bananabush.xml"

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable.test = test_ground
    inst.components.deployable.placer = "common/dug_bananabush_placer"
    inst.components.deployable.min_spacing = 1

    MakeSmallBurnable(inst, TUNING.SMALL_FUEL)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("dug_bananabush", fn, assets),
       MakePlacer("common/dug_bananabush_placer", "bananabush", "bananabush", "idle")
