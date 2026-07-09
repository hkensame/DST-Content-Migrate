--走得慢组件
local function ShouldKnockout(inst)
    return DefaultKnockoutTest(inst) and not inst.sg:HasStateTag("yawn")
end

AddPlayerPostInit(function(inst)
  table.insert(assets, Asset("ANIM", "anim/player_encumbered.zip")) --背大理石
  table.insert(assets, Asset("ANIM", "anim/player_encumbered_jump.zip"))
  table.insert(assets, Asset("ANIM", "anim/player_groggy.zip")) --走得慢
  inst.AnimState:AddOverrideBuild("player_attackss") --恐怖盾牌

  inst:AddComponent("grogginess_dst") --走得慢组件
  inst.components.grogginess_dst:SetResistance(3)
  inst.components.grogginess_dst:SetKnockOutTest(ShouldKnockout)

  --毒菌蛤蟆
  inst:AddTag("debuffable")
  inst:AddComponent("debuffable")
  inst.components.debuffable:SetFollowSymbol("headbase", 0, -200, 0)
end)

--添加联机版标签判断
AddComponentPostInit("combat", function(self) if self.inst then self.inst:AddTag("_combat") end end)
AddComponentPostInit("health", function(self) if self.inst then self.inst:AddTag("_health") end end)
AddComponentPostInit("sanity", function(self) if self.inst then self.inst:AddTag("_sanity") end end)

--添加交易组件
local function AddTradable(inst)
  if not inst.components.tradable then
    inst:AddComponent("tradable")
  end
end
AddPrefabPostInit("livinglog", AddTradable)

--改太妃糖的食物属性
AddPrefabPostInit("taffy", function(inst)
  inst.components.edible.foodtype = "GOODIES"
end)
