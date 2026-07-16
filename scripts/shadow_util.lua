-- shadow_util.lua
-- 暗影生物/暗影阵营标签集
-- 所有与暗影相关的 tag 检测统一放在这里，避免各 prefab 维护重复的 tag 列表

return {
    IsShadow = function(ent)
        return ent ~= nil and ent:IsValid()
            and (   ent:HasTag("shadow")
                 or ent:HasTag("shadowcreature")
                 or ent:HasTag("shadowminion")
                 or ent:HasTag("shadowchesspiece")
                 or ent:HasTag("stalker")
                 or ent:HasTag("stalkerminion")
                 or ent:HasTag("shadow_aligned")
                )
    end,
}
