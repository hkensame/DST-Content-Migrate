-- Inlined from DST scenarios/archive_cookpot.lua
-- DS doesn't have chestfunctions module, so we spawn the item directly into the container.
local function OnCreate(inst, scenariorunner)
    local item = SpawnPrefab("refined_dust")
    if item and inst.components.container then
        inst.components.container:GiveItem(item)
    end
end

return
{
    OnCreate = OnCreate,
}
