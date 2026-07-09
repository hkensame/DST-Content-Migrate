
local function canspawn(inst)
  if not inst.startseason and GetSeasonManager():GetSeason() == SEASONS.SUMMER then
  return true
 end
 if inst.startseason and inst.startseason ~= GetSeasonManager():GetSeason() and GetSeasonManager():GetSeason() == SEASONS.SUMMER then 
 inst.startseason = GetSeasonManager():GetSeason()
 return true
 end
end

local function TrySpawn(inst)
    if canspawn(inst) and not inst.antlion then 
        local antlion = SpawnPrefab("antlion")
        antlion.Transform:SetPosition(inst.Transform:GetWorldPosition())
        antlion.sg:GoToState("enterworld")
        inst.antlion = antlion
    end
  inst.startseason = GetSeasonManager():GetSeason()
end

local function OnSave(inst, data)
    local refs = {}
    data.startseason = inst.startseason
    if inst.antlion then
    data.antlion = inst.antlion.GUID
    table.insert(refs, inst.antlion.GUID)
    end
   return refs
end

local function OnLoad(inst,data)
if data and data.startseason then
  inst.startseason = data.startseason 
 end
end

local function OnLoadPass(inst, ents, data)
    if data.antlion and ents[data.antlion] then
        inst.antlion = ents[data.antlion].entity
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("FX")
    inst.startseason = nil
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPass = OnLoadPass
    inst.Remove = function() return end
    inst:DoPeriodicTask(1, function() TrySpawn(inst) end)
    
    return inst
end

return Prefab("antlion_spawner", fn)
