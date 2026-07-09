assets = 
{
 Asset("ANIM", "anim/chesspiece.zip"),
 --Asset("ANIM", "anim/swap_chesspiece_guardianphase3_stone.zip"),
 Asset("ANIM", "anim/swap_chesspiece_guardianphase3_moonglass.zip"),
}

local prefabs =
{
 "swap_chesspiece_guardianphase3_stone",
}

local function StoneTimer(inst)
    inst.components.timer:StartTimer("StoneTimer", 480*20)
end
    
local function OnTimerDone(inst, data)
    if data.name == "StoneTimer" then
      local x, y, z = inst.Transform:GetWorldPosition()
      local _moonglass = SpawnPrefab("chesspiece_guardianphase3_moonglass")
      _moonglass.Transform:SetPosition(x, y, z)
      
      inst.components.timer:StopTimer("StoneTimer")
      inst:Remove()
    end
end

local function fn()
 local inst = CreateEntity()
 local trans = inst.entity:AddTransform()
 local anim = inst.entity:AddAnimState()
 inst.entity:AddSoundEmitter()
 --MakeObstaclePhysics(inst, 0)
 
 --inst.AnimState:SetBank("guardianphase3_stone")
 --inst.AnimState:SetBuild("guardianphase3_stone")
 --inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("timer")
    
    inst.time = StoneTimer
    inst:DoTaskInTime(0, function()
      if not inst.components.timer:TimerExists("StoneTimer") then
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

local function fn2()
 local inst = CreateEntity()
 local trans = inst.entity:AddTransform()
 local anim = inst.entity:AddAnimState()
 inst.entity:AddMiniMapEntity()
 inst.entity:AddSoundEmitter()
 MakeObstaclePhysics(inst, 0.2)
    inst.MiniMapEntity:SetIcon("alterguardianhat.tex")
 
 inst.AnimState:SetBank("chesspiece")
 inst.AnimState:SetBuild("swap_chesspiece_guardianphase3_moonglass")
 inst.AnimState:PlayAnimation("idle")

 ---靠近恢复精神
 inst:AddComponent("sanityaura")
 inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL
 --发光
 inst:ListenForEvent( "nighttime", function()
    local light = inst.entity:AddLight()
    light:SetFalloff(0.6)
    light:SetIntensity(.5)
    light:SetRadius(3)
    light:Enable(true)
    light:SetColour(192/255, 192/255, 192/255)
 end, GetWorld() )
    
 inst:AddComponent("inspectable")
 inst.components.inspectable:SetDescription("敲碎它会发生什么…")
 
 inst:AddComponent("workable")
 inst.components.workable:SetWorkAction(ACTIONS.MINE)
 inst.components.workable:SetWorkLeft(8)
 inst.components.workable:SetOnWorkCallback(
  function(inst, worker, workleft)
    inst.AnimState:PlayAnimation("jiggle")
    local x, y, z = inst.Transform:GetWorldPosition()
    if workleft <= 0 then
      --inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
      SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
      inst:Remove()
      
      local meteorwarning = SpawnPrefab("meteorwarning")
      meteorwarning.Transform:SetPosition(x, y, z)
    
      inst:DoTaskInTime(1, function()
        local shadow_meteor = SpawnPrefab("shadow_meteor")
        shadow_meteor.Transform:SetPosition(x, y, z)
      
        if meteorwarning ~= nil then
          meteorwarning:Remove()
          meteorwarning = nil
        end
      end)
    
      inst:DoTaskInTime(0.2, function()
        local _stone = SpawnPrefab("chesspiece_guardianphase3_stone")
        _stone.Transform:SetPosition(x, y, z)
      end)
    end
 end)
 
  return inst
end

return Prefab("chesspiece_guardianphase3_stone", fn, assets, prefabs),
        Prefab("chesspiece_guardianphase3_moonglass", fn2, assets, prefabs)

