require "prefabutil"


local function ondeploy(inst, pt, deployer)
	if deployer and deployer.SoundEmitter then
		deployer.SoundEmitter:PlaySound("dontstarve/wilson/dig")
	end

	local ground = GetWorld()
	if ground then
		local original_tile_type = ground.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
		local x, y = ground.Map:GetTileCoordsAtPoint(pt.x, pt.y, pt.z)
		if x and y then
			ground.Map:SetTile(x,y, inst.data.tile)
			ground.Map:RebuildLayer( original_tile_type, x, y )
			ground.Map:RebuildLayer( inst.data.tile, x, y )
		end

		local minimap = TheSim:FindFirstEntityWithTag("minimap")
		if minimap then
			minimap.MiniMap:RebuildLayer( original_tile_type, x, y )
			minimap.MiniMap:RebuildLayer( inst.data.tile, x, y )
		end
	end

	inst.components.stackable:Get():Remove()
end


----------------<地皮配置表>----------------
-- 每个地皮携带完整配置：动画资产、bank/build、背包图集/图标名
-- 同类 prefab 共用 build（如 cave turfs 共用 turf_moon.zip）属正常设计，
-- 资源管理器会自动去重。
local TURF_CONFIG = {

    --------------------<热带三件套>--------------------
    meteor = {
        anim = "meteor",          tile = GROUND.METEOR,
        bank_build = "turf_moon",
        anim_assets = { "anim/moonisland/turf_moon.zip" },
        inv_image = "turf_meteor", inv_atlas = "images/dst_boss.xml",
    },
    shellbeach = {
        anim = "shellbeach",      tile = GROUND.SHELLBEACH,
        bank_build = "turf_shellbeach",
        anim_assets = { "anim/moonisland/turf_shellbeach.zip" },
        inv_image = "turf_shellbeach", inv_atlas = "images/dst_boss.xml",
    },
    pebblebeach = {
        anim = "pebblebeach",     tile = GROUND.PEBBLEBEACH,
        bank_build = "turf_moon",
        anim_assets = { "anim/moonisland/turf_moon.zip" },
        inv_image = "turf_pebblebeach", inv_atlas = "images/dst_boss.xml",
    },

    --------------------<DST 移植地皮>--------------------
    archive = {
        anim = "archive",         tile = GROUND.ARCHIVE,
        bank_build = "turf_archives",
        anim_assets = { "anim/cave/turf_archives.zip" },
        inv_image = "turf_archive", inv_atlas = "images/turf_archive.xml",
    },
    fungus_moon = {
        anim = "fungus_moon",     tile = GROUND.FUNGUSMOON,
        bank_build = "turf_fungus_moon",
        anim_assets = { "anim/cave/turf_fungus_moon.zip" },
        inv_image = "turf_fungus_moon", inv_atlas = "images/turf_fungus_moon.xml",
    },
    monkey_ground = {
        anim = "monkey_ground",   tile = GROUND.MONKEY_GROUND,
        bank_build = "turf_monkey_ground",
        anim_assets = { "anim/monkey/turf_monkey_ground.zip" },
        inv_image = "turf_monkey_ground", inv_atlas = "images/turf_monkey_ground.xml",
    },

    --------------------<DST 洞穴地皮>--------------------
    -- vent/vault 使用 DST 标准 turf.zip 中的 fumarole/vault 动画
    vent = {
        anim = "fumarole",        tile = GROUND.VENT,
        bank_build = "turf",
        anim_assets = { "anim/dst_turf.zip" },
        inv_image = "turf_vent",  inv_atlas = "images/turf_vent.xml",
    },

    vault = {
        anim = "vault",           tile = GROUND.VAULT,
        bank_build = "turf",
        anim_assets = { "anim/dst_turf.zip" },
        inv_image = "turf_vault", inv_atlas = "images/turf_vault.xml",
    },

}


local function make_turf(name)
	local cfg = TURF_CONFIG[name]
	if not cfg then
		print("[turf_meteor] WARNING: unknown turf name: " .. tostring(name))
		return nil
	end

	-- 按需生成动画资产（只加载当前地皮需要的 .zip）
	local assets = {}
	for _, path in ipairs(cfg.anim_assets) do
		table.insert(assets, Asset("ANIM", path))
	end

	local prefabs = { "gridplacer" }

	local function fn(Sim)
		local inst = CreateEntity()
		inst:AddTag("groundtile")
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		MakeInventoryPhysics(inst)

		inst.AnimState:SetBank(cfg.bank_build)
		inst.AnimState:SetBuild(cfg.bank_build)
		inst.AnimState:PlayAnimation(cfg.anim)

		if rawget(_G, 'MakeInventoryFloatable') then
			MakeInventoryFloatable(inst, cfg.anim.."_water", cfg.anim)
		end

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.imagename = cfg.inv_image
		inst.components.inventoryitem.atlasname = cfg.inv_atlas

		inst.data = { tile = cfg.tile }

		inst:AddComponent("bait")
		inst:AddTag("molebait")

		inst:AddComponent("fuel")
		inst.components.fuel.fuelvalue = TUNING.MED_FUEL

		inst:AddComponent("appeasement")
		inst.components.appeasement.appeasementvalue = TUNING.WRATH_SMALL

		MakeMediumBurnable(inst, TUNING.MED_BURNTIME)
		MakeSmallPropagator(inst)
		inst.components.burnable:MakeDragonflyBait(3)

		inst:AddComponent("deployable")
		inst.components.deployable.ondeploy = ondeploy
		inst.components.deployable.min_spacing = 0
		inst.components.deployable.placer = "gridplacer"

		return inst
	end

	return Prefab("turf_"..name, fn, assets, prefabs)
end


local TURF_LIST = {
	"meteor", "shellbeach", "pebblebeach",
	"archive", "fungus_moon", "monkey_ground",
	"vent", "vault",
}

local prefabs = {}
for _, name in ipairs(TURF_LIST) do
	table.insert(prefabs, make_turf(name))
end

return unpack(prefabs)
