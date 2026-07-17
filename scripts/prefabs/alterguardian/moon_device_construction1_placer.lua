
require "prefabutil"

local assets = {}

local PLACER_SNAP_DISTANCE = 6
local MOON_ALTAR_LINK_TAGS = { "moon_altar_link" }

local function placer_onupdatetransform(inst)
    local pos = inst:GetPosition()
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, PLACER_SNAP_DISTANCE, MOON_ALTAR_LINK_TAGS)

    if #ents > 0 then
        local targetpos = ents[1]:GetPosition()
        inst.Transform:SetPosition(targetpos.x, 0, targetpos.z)

        inst.accept_placement = ents[1]:HasTag("can_build_moon_device")
    else
        inst.accept_placement = false
    end
end

local function placer_override_build_point(inst)
    return inst:GetPosition()
end

local function placer_override_testfn(inst)
    local can_build, mouse_blocked = true, false

    if inst.components.placer.testfn ~= nil then
        can_build, mouse_blocked = inst.components.placer.testfn(inst:GetPosition(), inst:GetRotation())
    end

    can_build = inst.accept_placement

    return can_build, mouse_blocked
end

local function placer_postinit_fn(inst)
	inst.Transform:SetEightFaced()

    inst.components.placer.onupdatetransform = placer_onupdatetransform
    inst.components.placer.override_build_point_fn = placer_override_build_point
    inst.components.placer.override_testfn = placer_override_testfn

    inst.accept_placement = false
end

return MakePlacer("moon_device_construction1_placer", "moon_device_stages", "moon_device", "stage1_idle", true, nil, nil, nil, nil, nil, placer_postinit_fn)
