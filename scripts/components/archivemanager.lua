--------------------------------------------------------------------------
--[[ archivemanager class definition ]]
-- DS 移植版：移除 assert(TheWorld.ismastersim)
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _power_enabled = false

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SwitchPowerOn(setting)
    if _power_enabled ~= true and setting == true then
        _power_enabled = true
        if WORLDSTATETAGS ~= nil and WORLDSTATETAGS.SetTagEnabled ~= nil then
            WORLDSTATETAGS.SetTagEnabled("ARCHIVES_ENERGIZED", true)
        end
        self.inst:PushEvent("arhivepoweron")
    elseif _power_enabled ~= false and setting == false then
        _power_enabled = false
        if WORLDSTATETAGS ~= nil and WORLDSTATETAGS.SetTagEnabled ~= nil then
            WORLDSTATETAGS.SetTagEnabled("ARCHIVES_ENERGIZED", false)
        end
        self.inst:PushEvent("arhivepoweroff")
    end
end

function self:GetPowerSetting()
    return _power_enabled
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    return tostring(_power_enabled)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
