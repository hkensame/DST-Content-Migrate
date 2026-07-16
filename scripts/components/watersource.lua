-- DS 适配桩：DST watersource 组件
-- DST 中该组件管理 watersource tag 动态开关，并提供 Use() 接口
-- DS 无喷壶系统，桩组件仅确保 require 不报错

local WaterSource = Class(function(self, inst)
    self.inst = inst
    self.available = true
end)

function WaterSource:Use()
    -- DS 无调用方，空实现
end

function WaterSource:OnRemoveFromEntity()
    if self.inst:HasTag("watersource") then
        self.inst:RemoveTag("watersource")
    end
end

return WaterSource
