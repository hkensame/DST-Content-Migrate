local assets =
{
	Asset("ANIM", "anim/dst_batcave.zip"),
}

local prefabs =
{
	"bat"
}

local function ReturnChildren(inst)
	for k,child in pairs(inst.components.childspawner.childrenoutside) do
		if child.components.homeseeker then
			child.components.homeseeker:GoHome()
		end
		child:PushEvent("gohome")
	end
end

local function onnear(inst)
    if inst.components.childspawner.childreninside >= inst.components.childspawner.maxchildren then
        local tries = 10
        while inst.components.childspawner:CanSpawn() and tries > 0 do
            local bat = inst.components.childspawner:SpawnChild()
            if bat ~= nil then
                bat:DoTaskInTime(0, function() bat:PushEvent("panic") end)
            end
            tries = tries - 1
        end
        inst.SoundEmitter:PlaySound("dontstarve/cave/bat_cave_explosion")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/taunt")
    end
end

local function OnEntityWake(inst)
    if inst.components.childspawner.childreninside == inst.components.childspawner.maxchildren then
        inst.AnimState:PlayAnimation("eyes",true)
        inst.SoundEmitter:PlaySound("dontstarve/cave/bat_cave_warning", "full")
    end
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("full")
end

local function onisday(inst, isday)
    if isday then
        inst.components.childspawner:StopSpawning()
    else
        inst.components.childspawner:StartSpawning()
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    inst.AnimState:SetBuild("dst_batcave")
    inst.AnimState:SetBank("dst_batcave")
    inst.AnimState:PlayAnimation("idle")

    MakeObstaclePhysics(inst, 1.3)

	inst:AddComponent("childspawner")
	inst.components.childspawner:SetRegenPeriod(TUNING.BATCAVE_REGEN_TIME)
	inst.components.childspawner:SetSpawnPeriod(TUNING.BATCAVE_SPAWN_TIME)
	inst.components.childspawner:SetMaxChildren(TUNING.BATCAVE_MAX_CHILDREN)
    if not TUNING.BATCAVE_ENABLED then
        inst.components.childspawner.childreninside = 0
    end
	inst.components.childspawner.childname = "bat"
    inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StartRegen()
    -- initialize with no children
    inst.components.childspawner.childreninside = 0

    inst:AddComponent("inspectable")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetDist(6, 40)

	return inst
end

-- 改短名，方便 room_defs 中直接用 batcave 引用
return Prefab( "batcave", fn, assets, prefabs)
