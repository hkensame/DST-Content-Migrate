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
    local cs = inst.components.childspawner
    local player = GetPlayer()
    print("[batcave] onnear - childreninside="..tostring(cs.childreninside).." maxchildren="..tostring(cs.maxchildren).." canspawn="..tostring(cs:CanSpawn()).." player="..tostring(player))
    if cs.childreninside > 0 then
        print("[batcave] onnear - 开始释放蝙蝠")
        local tries = 10
        while cs:CanSpawn() and tries > 0 do
            local bat = cs:SpawnChild()
            if bat ~= nil then
                print("[batcave] 蝙蝠产出 - "..tostring(bat).." GUID="..tostring(bat.GUID))
                bat:DoTaskInTime(0, function()
                    if player and player:IsValid() then
                        print("[batcave] 设置玩家为仇恨目标")
                        bat.components.combat:SetTarget(player)
                    end
                end)
            else
                print("[batcave] SpawnChild 返回 nil")
            end
            tries = tries - 1
        end
        inst.SoundEmitter:PlaySound("dontstarve/cave/bat_cave_explosion")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/taunt")
    else
        print("[batcave] onnear - 洞内无蝙蝠，跳过")
    end
end

local function OnEntityWake(inst)
    if inst.components.childspawner.childreninside == inst.components.childspawner.maxchildren then
        inst.AnimState:PlayAnimation("eyes",true)
        inst.SoundEmitter:PlaySound("dontstarve/cave/bat_cave_warning", "full")
    end
end

local function OnEntitySleep(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.SoundEmitter:KillSound("full")
end

local function onfar(inst)
    local cs = inst.components.childspawner
    print("[batcave] onfar - 回收子代，childreninside="..tostring(cs.childreninside))
    ReturnChildren(inst)
    cs:StopSpawning()
    cs:StartRegen()
end

-- DS childspawner 没有 SetOnAddChildFn（DST only），
-- 改用 SetOccupiedFn / SetVacateFn：
--   occupied（首只蝙蝠再生回来）→ 播 eyes
--   vacate（最后一只飞出）→ 切回 idle
local function onspawnchild(inst, child)
    inst.SoundEmitter:PlaySound("dontstarve/cave/bat_cave_bat_spawn")
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
    -- 初始化时 2 只蝙蝠在洞内
    inst.components.childspawner.childreninside = 2
    print("[batcave] 初始化 - childreninside=2 maxchildren="..tostring(inst.components.childspawner.maxchildren))
    inst.components.childspawner:StartRegen()
    inst.components.childspawner:SetSpawnedFn(onspawnchild)
    -- DS childspawner 兼容：有蝙蝠在里面就播 eyes
    inst.components.childspawner:SetOccupiedFn(function(inst)
        print("[batcave] occupied - childreninside="..tostring(inst.components.childspawner.childreninside))
        inst.AnimState:PlayAnimation("eyes", true)
    end)
    inst.components.childspawner:SetVacateFn(function(inst)
        print("[batcave] vacate - childreninside="..tostring(inst.components.childspawner.childreninside))
        inst.AnimState:PlayAnimation("idle", true)
    end)

    inst:AddComponent("inspectable")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)
    inst.components.playerprox:SetDist(6, 40)

    inst:ListenForEvent("entitywake", OnEntityWake)
    inst:ListenForEvent("entitysleep", OnEntitySleep)

    -- 洞口日夜监听（DST 风格）
    local world = rawget(_G, "TheWorld")
    onisday(inst, world and world.state.iscaveday)
    if inst.WatchWorldState then
        inst:WatchWorldState("iscaveday", onisday)
    else
        -- DS 降级：周期检查代替 WatchWorldState
        inst:DoPeriodicTask(5, function()
            local w = rawget(_G, "TheWorld")
            if w then
                onisday(inst, w.state.iscaveday)
            end
        end)
    end

	return inst
end

-- 唯一注册名，避免与 DS 原版 cave/objects/batcave 冲突
return Prefab("dst_batcave", fn, assets, prefabs)
