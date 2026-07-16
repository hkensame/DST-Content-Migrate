--[[ archivemanager class definition ]]
-- DS 移植版：移除 assert(TheWorld.ismastersim)

-- DS strict.lua 兼容：在 prefab 沙箱中 GLOBAL 不可用
-- 文档要求：PrefabFiles/组件脚本不能直接引用 GLOBAL/TheWorld
-- 改用 inst:GetTheWorld() 实体注入模式。此文件是组件，
-- 需要通过 modmain.lua 中的 AddPrefabPostInit 注入 GetTheWorld。
-- 当前跳过 WORLDSTATETAGS（DST 专有，DS 不存在）

return Class(function(self, inst)

--[[ Member variables ]]

--Public
self.inst = inst

--Private
local _power_enabled = false

--[[ Public member functions ]]

function self:SwitchPowerOn(setting)
    print("[ARCHIVE] SwitchPowerOn: setting="..tostring(setting).." current_power="..tostring(_power_enabled).." inst="..tostring(self.inst))
    if _power_enabled ~= true and setting == true then
        _power_enabled = true
        print("[ARCHIVE] SwitchPowerOn: POWER ON! Pushing arhivepoweron")
        -- WORLDSTATETAGS 是 DST 专有，DS 中不存在，跳过
        print("[ARCHIVE] SwitchPowerOn: pushing arhivepoweron event to "..tostring(self.inst))
        self.inst:PushEvent("arhivepoweron")
        print("[ARCHIVE] SwitchPowerOn: POWER ON complete")
    elseif _power_enabled ~= false and setting == false then
        _power_enabled = false
        print("[ARCHIVE] SwitchPowerOn: POWER OFF! Pushing arhivepoweroff")
        -- WORLDSTATETAGS 是 DST 专有，DS 中不存在，跳过
        self.inst:PushEvent("arhivepoweroff")
    else
        print("[ARCHIVE] SwitchPowerOn: no change needed (already "..tostring(_power_enabled)..")")
    end
end

function self:GetPowerSetting()
    print("[ARCHIVE] GetPowerSetting: returning "..tostring(_power_enabled))
    return _power_enabled
end

--[[ Debug ]]

function self:GetDebugString()
    return tostring(_power_enabled)
end

--[[ End ]]

end)
