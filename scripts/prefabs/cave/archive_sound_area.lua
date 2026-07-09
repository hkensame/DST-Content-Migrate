-- DST handles archive_sound_area as a callback in maze_layouts.lua/layouts.lua
-- (50% chance to spawn archive_ambient_sfx). DS has no such callback mechanism,
-- so we create a real prefab that does the same thing then self-destructs.
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("FX")

    inst.persists = false

    if math.random() < 0.5 then
        local sfx = SpawnPrefab("archive_ambient_sfx")
        if sfx then
            sfx.entity:SetParent(inst.entity)
        end
    end

    inst:DoTaskInTime(0, function()
        inst:Remove()
    end)

    return inst
end

return Prefab("archive_sound_area", fn)
