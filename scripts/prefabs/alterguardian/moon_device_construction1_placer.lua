
require "prefabutil"

local assets = {}

local function placer_postinit_fn(inst)
	-- 同原版 moon_device.lua 中的 placer_postinit_fn
	inst.Transform:SetEightFaced()
end

return MakePlacer("moon_device_construction1_placer", "moon_device_stages", "moon_device", "stage1_idle", true, nil, nil, nil, nil, nil, placer_postinit_fn)
