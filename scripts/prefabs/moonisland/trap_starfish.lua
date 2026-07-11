-- 海星陷阱 (地面陷阱，踩到会造成伤害)
-- 移植自 DST，适配 DS 单人生存模式

require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/moonisland/star_trap.zip"),
    Asset("INV_IMAGE", "star_trap_atlas"),
}

local prefabs =
{
}

local function on_anim_over(inst)
    if inst.components.mine and inst.components.mine.issprung then
        return
    end
    local random_value = math.random()
    if random_value < 0.4 then
        inst.AnimState:PushAnimation("idle_2")
        inst.AnimState:PushAnimation("idle", true)
    elseif random_value < 0.8 then
        inst.AnimState:PushAnimation("idle_3")
        inst.AnimState:PushAnimation("idle", true)
    end
end

local mine_test_fn = function(target, inst)
    return not (target.components.health ~= nil and target.components.health:IsDead())
            and (target.components.combat ~= nil and target.components.combat:CanBeAttacked(inst))
end
local mine_test_tags = { "monster", "character", "animal" }
local mine_must_tags = { "_combat" }
local mine_no_tags = { "notraptrigger", "flying", "ghost", "playerghost", "spawnprotection" }

local function do_snap(inst)
    inst.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/trap")

    local x, y, z = inst.Transform:GetWorldPosition()
    local target_ents = TheSim:FindEntities(x, y, z, TUNING.STARFISH_TRAP_RADIUS or 1, mine_must_tags, mine_no_tags, mine_test_tags)
    for i, target in ipairs(target_ents) do
        if target ~= inst and target.entity:IsVisible() and mine_test_fn(target, inst) then
            target.components.combat:GetAttacked(inst, TUNING.STARFISH_TRAP_DAMAGE or 50)
        end
    end

    if inst._snap_task ~= nil then
        inst._snap_task:Cancel()
        inst._snap_task = nil
    end
end

local function reset(inst)
    if inst.components.mine then
        inst.components.mine:Reset()
    end
end

local function start_reset_task(inst)
    if inst._reset_task ~= nil then
        inst._reset_task:Cancel()
    end
    local reset_time = GetRandomWithVariance(
        (TUNING.STARFISH_TRAP_NOTDAY_RESET and TUNING.STARFISH_TRAP_NOTDAY_RESET.BASE) or 60,
        (TUNING.STARFISH_TRAP_NOTDAY_RESET and TUNING.STARFISH_TRAP_NOTDAY_RESET.VARIANCE) or 30
    )
    inst._reset_task = inst:DoTaskInTime(reset_time, reset)
    inst._reset_task_end_time = GetTime() + reset_time
end

local function on_explode(inst, target)
    inst.AnimState:PlayAnimation("trap")
    inst.AnimState:PushAnimation("trap_idle", true)

    inst:RemoveEventCallback("animover", on_anim_over)

    if target ~= nil and inst._snap_task == nil then
        local frames_until_anim_snap = 8
        inst._snap_task = inst:DoTaskInTime(frames_until_anim_snap * FRAMES, do_snap)
    end

    start_reset_task(inst)
end

local function on_reset(inst)
    inst:ListenForEvent("animover", on_anim_over)

    if inst.AnimState:IsCurrentAnimation("trap_idle") then
        inst.AnimState:PlayAnimation("reset")
        inst.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/idle")
        inst.AnimState:PushAnimation("idle", true)
    end
end

local function on_sprung(inst)
    inst.AnimState:PlayAnimation("trap_idle", true)
    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    inst:RemoveEventCallback("animover", on_anim_over)
    start_reset_task(inst)
end

local function on_deactivate(inst)
    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:SpawnLootPrefab("dug_trap_starfish")
    end
    inst:Remove()
end

local function get_status(inst)
    return (inst.components.mine and inst.components.mine.issprung and "CLOSED") or nil
end

local function on_starfish_dug_up(inst, digger)
    on_deactivate(inst)
end

local function on_save(inst, data)
    if inst._reset_task ~= nil then
        local remaining_task_time = inst._reset_task_end_time - GetTime()
        if remaining_task_time >= 0 then
            data.reset_task_time_remaining = remaining_task_time
        end
    end
end

local function on_load(inst, data)
    if data ~= nil and data.reset_task_time_remaining ~= nil then
        if inst._reset_task ~= nil then
            inst._reset_task:Cancel()
        end
        inst._reset_task = inst:DoTaskInTime(data.reset_task_time_remaining, reset)
        inst._reset_task_end_time = GetTime() + data.reset_task_time_remaining
    end
end

local function trap_starfish()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    inst.AnimState:SetBank("star_trap")
    inst.AnimState:SetBuild("star_trap")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("trap")
    inst:AddTag("trapdamage")
    inst:AddTag("birdblocker")
    inst:AddTag("wet")

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "TRAP_STARFISH"
    inst.components.inspectable.getstatus = get_status

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(on_starfish_dug_up)
    inst.components.workable:SetWorkable(true)

    --inst:AddComponent("hauntable") -- DS 无 hauntable 组件
    --inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY or 1

    inst:AddComponent("mine")
    inst.components.mine:SetRadius(TUNING.STARFISH_TRAP_RADIUS or 1)
    inst.components.mine:SetAlignment(nil) -- 全目标触发，包括角色
    inst.components.mine:SetOnExplodeFn(on_explode)
    inst.components.mine:SetOnResetFn(on_reset)
    inst.components.mine:SetOnSprungFn(on_sprung)
    inst.components.mine:SetOnDeactivateFn(on_deactivate)
    -- DS mine 默认测试间隔 1~2 秒（mine.lua:79），太慢
    -- 用自定义快速测试覆盖，每 0.3 秒检测一次
    local _FastMineTest = function(mine_inst)
        local mine = mine_inst.components.mine
        if not mine or mine.issprung or mine.inactive then return end
        local target = FindEntity(mine_inst, mine.radius, mine_test_fn, nil, mine_no_tags, mine_test_tags)
        if target then
            mine:Explode(target)
        end
    end
    inst.components.mine.StartTesting = function(self)
        self:StopTesting()
        self.testtask = self.inst:DoPeriodicTask(0.3, _FastMineTest, 0)
    end
    inst.components.mine:SetReusable(false)
    reset(inst)

    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    inst:ListenForEvent("animover", on_anim_over)

    inst.OnSave = on_save
    inst.OnLoad = on_load

    return inst
end

local function on_deploy(inst, position, deployer)
    local new_trap_starfish = SpawnPrefab("trap_starfish")
    if new_trap_starfish ~= nil then
        new_trap_starfish.AnimState:PlayAnimation("trap_idle")
        if new_trap_starfish.components.mine then
            -- DS mine 组件无 Spring() 方法，手动设置状态
            new_trap_starfish.components.mine.issprung = true
            new_trap_starfish.components.mine.inactive = false
            new_trap_starfish.components.mine:StopTesting()
            on_sprung(new_trap_starfish)
        end
        new_trap_starfish.SoundEmitter:PlaySound("dontstarve/common/plant")
        new_trap_starfish.Transform:SetPosition(position:Get())
        inst:Remove()
    end
end

local function dug_trap_starfish()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("star_trap")
    inst.AnimState:SetBuild("star_trap")
    inst.AnimState:PlayAnimation("inactive", true)

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "TRAP_STARFISH"

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/star_trap_atlas.xml"
    inst.components.inventoryitem.imagename = "star_trap_atlas"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM or 40

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = on_deploy

    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    return inst
end

local p1 = Prefab("trap_starfish", trap_starfish, assets, prefabs)
local p2 = Prefab("dug_trap_starfish", dug_trap_starfish, assets, prefabs)
local placer = MakePlacer("dug_trap_starfish_placer", "star_trap", "star_trap", "trap_idle")

return p1, p2, placer
