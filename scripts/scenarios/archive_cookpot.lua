-- Inlined from DST scenarios/archive_cookpot.lua
-- DS doesn't have chestfunctions module, so we spawn the item directly into the container.
local function OnCreate(inst, scenariorunner)
    local item = SpawnPrefab("refined_dust")
    if item then
        -- 先设置位置，避免实体停留在世界原点
        item.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if inst.components.container then
            if not inst.components.container:GiveItem(item) then
                -- GiveItem 失败时清理实体
                item:Remove()
            end
        else
            item:Remove()
        end
    end
end

return
{
    OnCreate = OnCreate,
}
