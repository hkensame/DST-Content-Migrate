-- ===============================
-- DST 兼容补丁合集 (dst_compat_patches)
-- ===============================
-- 统一管理所有 DST→DS 移植的兼容性补丁，按类别分组
-- 通过 modimport("scripts/dst_compat_patches.lua") 从 modmain.lua 加载

-- ==================== 1. DLC 层全局补丁 ====================
-- DLC0003 getworldgenoptions 洞穴安全补丁
-- 洞穴世界中 inst.topology.overrides 为 nil，导致 getworldgenoptions 返回 nil，
-- childspawner/spawner 调用 IsWorldGenOptionNever 时崩溃
-- 注意：不能用 AddSimPostInit，它在 PopulateWorld 之后才触发（gamelogic.lua:893 vs 855）
-- AddPrefabPostInitAny 在 prefab 初始化瞬间执行，远早于世界生成
AddPrefabPostInitAny(function(inst)
    if inst.getworldgenoptions ~= nil then
        local old = inst.getworldgenoptions
        inst.getworldgenoptions = function(...)
            local result = old(...)
            return result or {}
        end
    end
end)

-- ==================== 2. 实体级补丁 (AddPrefabPostInit / AddSimPostInit) ====================

-- 2.1 蚁狮交易暖石
AddPrefabPostInit("heatrock", function(inst)
    inst:AddComponent("tradable")
    inst.components.tradable.rocktribute = 6
end)

-- 2.2 邪天翁生成
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

-- 2.3 LavaePet food sources
local function _LavaePetFoods(inst)
    inst:AddComponent("edible")
    inst.components.edible.foodtype = "BURNT"
    inst.components.edible.hungervalue = 20
    inst.components.edible.healthvalue = 20
    inst:AddComponent("tradable")
end
AddPrefabPostInit("ash", _LavaePetFoods)
AddPrefabPostInit("charcoal", _LavaePetFoods)

-- 2.4 月蛾生成器：在光飞虫花附近生成月蛾
AddSimPostInit(function()
    local theWorld = rawget(GLOBAL, "TheWorld")
    if theWorld and theWorld.ismastersim and not theWorld.components.moonbutterflyspawner then
        theWorld:AddComponent("moonbutterflyspawner")
    end
end)

-- 2.5 金丝雀→中毒金丝雀：鸟笼处理鸟中毒事件
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

-- 2.6 稻草人吸引金丝雀：附近有稻草人时，鸟生成器把乌鸦替换成金丝雀
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

-- 2.7 毒菌蛤蟆重生管理器（仅在洞穴世界）
AddPrefabPostInit("cave", function(inst)
    if not inst.components.worldsettingstimer then
        inst:AddComponent("worldsettingstimer")
    end
    inst:AddComponent("toadstoolspawner")
end)

-- 2.8 鹿群生成器（仅在地表世界）
if GetModConfigData("klaus") == true then
    AddPrefabPostInit("forest", function(inst)
        if not inst.components.deerherding then
            inst:AddComponent("deerherding")
        end
        if not inst.components.deerherdspawner then
            inst:AddComponent("deerherdspawner")
            print("[DEER] deerherdspawner 已挂载到 forest 世界")
            inst.components.deerherdspawner:OnPostInit()
            print("[DEER] deerherdspawner OnPostInit 完成")
        end
    end)
end


-- 2.9 molebat：DS 无 TheWorld.net，事件源为 TheWorld 本身
-- 注入 GetTheWorld 并注册洞穴地震事件
AddPrefabPostInit("molebat", function(inst)
    inst.GetTheWorld = function() return _cave_world end
    inst:DoTaskInTime(0, function()
        local theWorld = _cave_world
        if theWorld == nil then return end
        inst:ListenForEvent("startquake", function()
            inst._quaking = true
            if inst.components.sleeper then inst.components.sleeper:WakeUp() end
        end, theWorld)
        inst:ListenForEvent("endquake", function()
            inst._quaking = nil
        end, theWorld)
    end)
end)

-- 2.10 蝙蝠大脑覆写（洞穴环境下避免蝙蝠错误回家消失）
AddPrefabPostInit("bat", function(inst)
    local DstBatBrain = require("brains/dst_batbrain")
    inst:SetBrain(DstBatBrain)
end)


-- ==================== 3. Widget 层补丁 (AddClassPostConstruct) ====================

-- 3.1 启迪之冠格子缩放
AddClassPostConstruct("widgets/containerwidget",function(self)
    local self_Open=self.Open
    function self:Open(container, doer)
        self_Open(self, container, doer)
        if self.container and self.container.prefab=="alterguardianhat" then
            self:SetScale(0.5, 0.5, 0.5)
            self:MoveToFront()
        end
    end
end)

-- 3.2 精神控制 UI 覆盖层
AddClassPostConstruct("screens/playerhud", function(self)
    local _SetMainCharacter = self.SetMainCharacter
    function self:SetMainCharacter(maincharacter)
        _SetMainCharacter(self, maincharacter)
        if maincharacter then
            local MindControlOver = require "widgets/mindcontrolover"
            self.overlayroot:AddChild(MindControlOver(maincharacter))
        end
    end
end)
