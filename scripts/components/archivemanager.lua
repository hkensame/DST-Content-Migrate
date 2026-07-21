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
    if _power_enabled ~= true and setting == true then
        _power_enabled = true
        -- POWER ON - pushing arhivepoweron
        self.inst:PushEvent("arhivepoweron")
    elseif _power_enabled ~= false and setting == false then
        _power_enabled = false
        -- POWER OFF - pushing arhivepoweroff
        self.inst:PushEvent("arhivepoweroff")
    end
end

function self:GetPowerSetting()
    return _power_enabled
end

--[[ Debug ]]

function self:GetDebugString()
    return tostring(_power_enabled)
end

--[[ End ]]

end)
