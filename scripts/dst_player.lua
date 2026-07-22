--走得慢组件
local function ShouldKnockout(inst)
    return DefaultKnockoutTest(inst) and not inst.sg:HasStateTag("yawn")
end

AddPlayerPostInit(function(inst)
  table.insert(assets, Asset("ANIM", "anim/player_encumbered.zip")) --背大理石
  table.insert(assets, Asset("ANIM", "anim/player_encumbered_jump.zip"))
  --走得慢: DS 原版 data/anim 已有 player_groggy bank
  inst.AnimState:AddOverrideBuild("player_attackss") --恐怖盾牌

  inst:AddComponent("grogginess_dst") --走得慢组件
  inst.components.grogginess_dst:SetResistance(3)
  inst.components.grogginess_dst:SetKnockOutTest(ShouldKnockout)

  --毒菌蛤蟆
  inst:AddTag("debuffable")
  inst:AddComponent("debuffable")
  inst.components.debuffable:SetFollowSymbol("headbase", 0, -200, 0)
end)


