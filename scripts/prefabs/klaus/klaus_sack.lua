-- DS 无 FindPlayersInRangeSq，单机兼容实现
local function FindPlayersInRangeSq(x, y, z, rangesq, isalive)
    local player = GetPlayer()
    if player == nil then return {} end
    if isalive and player:HasTag("playerghost") then return {} end
    if player:GetDistanceSqToPoint(x, y, z) < rangesq then
        return {player}
    end
    return {}
end

assets = 
{
    Asset("ANIM", "anim/klaus/klaus_bag.zip"),
}

local prefabs = {
  "klaus",
  "klaus_sack_spawner",
    "boneshard",
    "bundle",
}

local function SackTimer(inst)
    inst.components.timer:StartTimer("SackTimer", 480*30)
end

local function OnTimerDone(inst, data)
    if data.name == "SackTimer" then
      local x, y, z = inst.Transform:GetWorldPosition()
      local klaus_sack = SpawnPrefab("klaus_sack")
      klaus_sack.Transform:SetPosition(x, y, z)
      inst.components.timer:StopTimer("SackTimer")
      inst:Remove()
    end
end

local function SackSpawner(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("klaus_sack_spawner").Transform:SetPosition(x, y, z)
end

require("components/klaussackloot") --contains GLOBAL function AddGiantLootPrefabs
AddGiantLootPrefabs(prefabs)

local function DropLootDirect(inst, items)
    for i, v in ipairs(items) do
        local item
        if type(v) == "string" then
            item = SpawnPrefab(v)
        else
            item = SpawnPrefab(v[1])
            if item ~= nil and item.components.stackable ~= nil then
                item.components.stackable.stacksize = v[2]
            end
        end
        if item ~= nil then
            inst.components.lootdropper:FlingItem(item)
        end
    end
end

local function OpenSack(inst)
        inst.AnimState:PlayAnimation("open")
        inst.persists = false
        inst:DoTaskInTime(1, ErodeAway)
        
        SackSpawner(inst)

        for i, items in ipairs(inst.components.klaussackloot:GetLoot()) do
            DropLootDirect(inst, items)
        end
end

local function onuseklauskey(inst)
            inst.unlock = false
            --Find spawn point far away, preferrably not near players
            local pos = inst:GetPosition()
            local minplayers = math.huge
            local spawnx, spawnz
            FindWalkableOffset(pos,
                math.random() * 2 * PI, 33, 16, true, true,
                function(pt)
                    local count = #FindPlayersInRangeSq(pt.x, pt.y, pt.z, 625)
                    if count < minplayers then
                        minplayers = count
                        spawnx, spawnz = pt.x, pt.z
                        return count <= 0
                    end
                    return false
                end)

            if spawnx == nil then
                --No spawn point (with or without players), so try closer
                local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 18, 12, false, true)
                if offset ~= nil then
                    spawnx, spawnz = pos.x + offset.x, pos.z + offset.z
                end
            end

            local klaus = SpawnPrefab("klaus")
            klaus.Transform:SetPosition(spawnx or pos.x, 0, spawnz or pos.z)
            klaus:SpawnDeer()
            -- override the spawn point so klaus comes to his sack
            klaus.components.knownlocations:RememberLocation("spawnpoint", pos, false)
            klaus.components.spawnfader:FadeIn()
end

local function ItemTradeTest(inst, item)
 return inst.unlock and item:HasTag("deer_antler") or (inst.closed and not inst.unlock) and item.prefab == "klaussackkey"
end

local function ItemGet(inst, giver, item)
  if inst.unlock then
    if item:HasTag("deer_antler") then
      onuseklauskey(inst)
    end
  end
  if inst.closed and not inst.unlock then
    if item.prefab == "klaussackkey" then
      OpenSack(inst)
    end
  end
end
local function KlausRemove(inst)
      for i,v in pairs(Ents) do
        if v.prefab == "klaus" then --如果有克劳斯…
          return
        else --如果没有克劳斯，并且已解锁
          if not inst.unlock then
            SackSpawner(inst) --克劳斯包重新计时
            inst:Remove() --移除克劳斯包
          end
        end
      end
end

local function OnLoad(inst, data)
  if data then
    inst.unlock = data.unlock
    inst.closed = data.closed
    inst.time = data.time
  end
  --KlausRemove(inst)
end

local function OnSave(inst, data)
  data.unlock = inst.unlock or nil
  data.closed = inst.closed or nil
  data.time = inst.time
end
 
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("klaus_sack.tex")

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("klaus_bag")
    inst.AnimState:SetBuild("klaus_bag")
    inst.AnimState:PlayAnimation("idle")
    
    if TUNING.WINTERS_FEAST then
        inst.AnimState:OverrideSymbol("swap_chain", "klaus_bag", "swap_chain_winter")
        inst.AnimState:OverrideSymbol("swap_chain_link", "klaus_bag", "swap_chain_link_winter")
        inst.AnimState:OverrideSymbol("swap_chain_lock", "klaus_bag", "swap_chain_lock_winter")
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ItemTradeTest)
    inst.components.trader.onaccept = ItemGet

    inst:AddComponent("klaussackloot")

    inst.unlock = true
    inst.closed = true

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    GetPlayer():ListenForEvent("klaus_remove", function(inst)
      SackSpawner(inst)
      inst:Remove()
    end)

    --inst.KlausRemove = KlausRemove
--[[
--如果地图上没有克劳斯，并且已经解锁。计时开始并移除克劳斯包
    inst:DoTaskInTime(1, function()
      for i,v in pairs(Ents) do
        if v.prefab == "klaus" and inst.unlock then
          return
        else
          SackSpawner(inst)
          inst:Remove()
        end
      end
    end)
--]]
 return inst
end

local function fn2(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()

    inst:AddComponent("timer")

    inst.time = SackTimer
    inst:DoTaskInTime(0, function()
      if not inst.components.timer:TimerExists("SackTimer") then
        inst.time(inst)
      end
    end)

    inst.OnSave = function(inst, data)
      data.time = inst.time
    end
    inst.OnLoad = function(inst, data)
      if data then
        inst.time = data.time
      end
    end
    inst:ListenForEvent("timerdone", OnTimerDone)

	return inst
end

return Prefab("klaus_sack", fn, assets, prefabs),
       Prefab("klaus_sack_spawner", fn2, assets, prefabs)

