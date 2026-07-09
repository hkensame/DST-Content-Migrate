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
