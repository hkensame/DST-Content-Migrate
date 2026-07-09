--------------------------------------------------------------------------
--[[ ArchiveManager class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

-- DS: no client/server distinction, remove assert(TheWorld.ismastersim)

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------



--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _power_enabled = false


--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SwitchPowerOn(setting)
	if _power_enabled ~= true and setting == true then
		_power_enabled = true
        -- DS: WORLDSTATETAGS not available
		self.inst:PushEvent("arhivepoweron")
	elseif _power_enabled ~= false and setting  == false then
		_power_enabled = false
        -- DS: WORLDSTATETAGS not available
		self.inst:PushEvent("arhivepoweroff")
	end
end

function self:GetPowerSetting()
	return _power_enabled
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
--inst:ListenForEvent("ms_playerjoined", OnPlayerJoined)

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

--@V2C deleted save/load, typo means it never worked here.
--     power state is loaded from archive_switch instead.

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
