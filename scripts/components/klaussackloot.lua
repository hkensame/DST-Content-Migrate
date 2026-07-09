local giant_loot1 =
{
    "deerclops_eyeball",
    "dragon_scales",
    "mandrake",
}

local giant_loot2 =
{
    "dragonflyfurnace_blueprint",
    "townportal_blueprint",
    "bundlewrap_blueprint",
	"trident_blueprint",
}

local giant_loot3 =
{
    "bearger_fur",
    "goose_feather",
    "lavae_egg",
    "spiderhat",
    "steelwool",
    "townportaltalisman",
	"malbatross_beak",
}

function AddGiantLootPrefabs(prefabs)
    for i, v in ipairs(giant_loot1) do
        table.insert(prefabs, v)
    end

    for i, v in ipairs(giant_loot2) do
        table.insert(prefabs, v)
    end

    for i, v in ipairs(giant_loot3) do
        table.insert(prefabs, v)
    end
end

local KlausSackLoot = Class(function(self, inst)
    self.inst = inst

    self:RollKlausLoot()
end)

local function FillItems(items, prefab)
    for i = 1 + #items, math.random(3, 4) do
        table.insert(items, prefab)
    end
end

function KlausSackLoot:RollKlausLoot()
    self.loot = {}

    local items = {}
    table.insert(items, "amulet")
    table.insert(items, "goldnugget")
    FillItems(items, "charcoal")
    table.insert(self.loot, items)

    items = {}
    if math.random() < .5 then
        table.insert(items, "amulet")
    end
    table.insert(items, "goldnugget")
    FillItems(items, "charcoal")
    table.insert(self.loot, items)

    items = {}
    if math.random() < .1 then
        table.insert(items, "krampus_sack")
    end
    table.insert(items, "goldnugget")
    FillItems(items, "charcoal")
    table.insert(self.loot, items)

    items = {}
    local i1 = math.random(#giant_loot3)
    local i2 = math.random(#giant_loot3 - 1)
    table.insert(items, giant_loot1[math.random(#giant_loot1)])
    if math.random() < .5 then
        table.insert(items, giant_loot2[math.random(#giant_loot2)])
    end
    table.insert(items, giant_loot3[i1])
    table.insert(items, giant_loot3[i2 == i1 and i2 + 1 or i2])
    table.insert(self.loot, items)
end

function KlausSackLoot:GetLoot()
    local loot = {}
    for i, v in ipairs(self.loot) do
        table.insert(loot, v)
    end

    self:RollKlausLoot()

    return loot
end

function KlausSackLoot:OnSave()
    return
    {
        loot = self.loot,
    }
end

function KlausSackLoot:OnLoad(data)
	if data ~= nil then
        self.loot = data.loot
	end
end

return KlausSackLoot