-- DS 移植版：从 DST 源码复制，未修改
-- 植物再生辅助工具

function CalculateFiveRadius(density)
    -- we don't want even density, clumping is allowed. For that reason, we
    -- want to do density per 5 entities, rather than per 1 -- hence fiveradius
    local searcharea = 2 * 16 * 5 / density
    return math.sqrt(searcharea / math.pi)
end

function GetFiveRadius(x, z, prefab)
    local area = nil
    for i, node in ipairs(TheWorld.topology.nodes) do
        if TheSim:WorldPointInPoly(x, z, node.poly) then
            area = i
            break
        end
    end

    if
        area == nil
        or TheWorld.generated == nil
        or TheWorld.topology.ids[area] == nil or TheWorld.generated.densities[TheWorld.topology.ids[area]] == nil
        then
        return
    end

    local density = TheWorld.generated.densities[TheWorld.topology.ids[area]][prefab]
    if density == nil then
        return
    end
    return CalculateFiveRadius(density)
end
