-- ==================== DST 实体级补丁 ====================
-- 单个 prefab/实体的补丁（AddPrefabPostInit / AddSimPostInit）
-- 通过 modimport("scripts/dst_entity_patches.lua") 从 modmain.lua 加载

--蚁狮交易暖石
AddPrefabPostInit("heatrock", function(inst)
    inst:AddComponent("tradable")
    inst.components.tradable.rocktribute = 6
end)

--邪天翁生成
if GetModConfigData("malbatross") == true then
  AddPrefabPostInit("octopusking", function(inst)
   inst:AddComponent("childspawner")
   inst.components.childspawner.childname = "malbatross"
   inst.components.childspawner:SetRegenPeriod(TUNING.TOTAL_DAY_TIME*20)
   inst.components.childspawner:SetSpawnPeriod(TUNING.TOTAL_DAY_TIME/16)
   inst.components.childspawner:SetMaxChildren(1)
   inst.components.childspawner:StartSpawning()
  end)
end

--LavaePet food sources
local function _LavaePetFoods(inst)
    inst:AddComponent("edible")
    inst.components.edible.foodtype = "BURNT"
    inst.components.edible.hungervalue = 20
    inst.components.edible.healthvalue = 20
    inst:AddComponent("tradable")
end
AddPrefabPostInit("ash", _LavaePetFoods)
AddPrefabPostInit("charcoal", _LavaePetFoods)

-- 无眼鹿自动长角
AddPrefabPostInit("deer", function(inst)
    if not inst.gem then
        inst:DoTaskInTime(0, function()
            inst:PushEvent("queuegrowantler")
        end)
    end
end)

-- 月蛾生成器：在光飞虫花附近生成月蛾
AddSimPostInit(function()
    local theWorld = rawget(GLOBAL, "TheWorld")
    if theWorld and theWorld.ismastersim and not theWorld.components.moonbutterflyspawner then
        theWorld:AddComponent("moonbutterflyspawner")
    end
end)

-- 金丝雀→中毒金丝雀：鸟笼处理鸟中毒事件
AddPrefabPostInit("birdcage", function(inst)
    if inst.components.occupier ~= nil then
        inst:ListenForEvent("birdpoisoned", function(inst, data)
            if inst.components.occupier ~= nil and inst.components.occupier:IsOccupied() then
                local po = data.poisoned_prefab
                if data.bird and data.bird:IsValid() then
                    data.bird:Remove()
                end
                inst.components.occupier:ChangeOccupation(po, po, nil)
            end
        end)
    end
end)

-- 稻草人吸引金丝雀：附近有稻草人时，鸟生成器把乌鸦替换成金丝雀
local SCARECROW_TAGS = { "scarecrow" }
AddComponentPostInit("birdspawner", function(self)
    local _OldPickBird = self.PickBird
    self.PickBird = function(self, spawn_point)
        local bird = _OldPickBird(self, spawn_point)
        if bird == "crow" and spawn_point then
            local x, y, z = spawn_point:Get()
            local targets = TheSim:FindEntities(x, y, z, TUNING.BIRD_CANARY_LURE_DISTANCE, SCARECROW_TAGS)
            if #targets > 0 then
                bird = "canary"
            end
        end
        return bird
    end
end)

-- 毒菌蛤蟆重生管理器（仅在洞穴世界）
AddPrefabPostInit("cave", function(inst)
    if not inst.components.worldsettingstimer then
        inst:AddComponent("worldsettingstimer")
    end
    inst:AddComponent("toadstoolspawner")
end)
