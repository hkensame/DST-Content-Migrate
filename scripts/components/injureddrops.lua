local function loot(a,b)
local k = a.components.injureddrops
if not b then return end
if not b.damage then return end
k.mod["current"] = k.mod["current"] + b.damage
if k.mod["current"] >= k.mod["max"] then
k.mod["current"] = 0
a.components.lootdropper:SpawnLootPrefab(k.mod.loots[math.random(#k.mod.loots)])
 end
end

local injureddrops = Class(function(self, inst)
	self.inst = inst
	self.mod = {current = 0,max = 100,loots = {"ash"}}
	self.inst:ListenForEvent("attacked", loot)
end)

function injureddrops:OnSave()
    return {c = self.mod.current}
end

function injureddrops:OnLoad(data)
	if data and data.c then
		self.mod.current = data.c
	end
end

return injureddrops
