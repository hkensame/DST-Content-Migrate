local assets =
{
    Asset("ANIM", "anim/antlion/antlion_sinkhole.zip"),
}

local prefabs =
{
    "sinkhole_spawn_fx_1",
    "sinkhole_spawn_fx_2",
    "sinkhole_spawn_fx_3",
    "mining_ice_fx",
    "mining_fx",
    "mining_moonglass_fx",
}

local COLLAPSE_STAGE_DURATION = 1

local function SpawnFx(inst, scale)
    local theta = math.random() * TWOPI
    local num = 7
    local radius = 1.6
    local dtheta = TWOPI / num
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("sinkhole_spawn_fx_"..math.random(3)).Transform:SetPosition(x, y, z)
    for i = 1, num do
        local dust = SpawnPrefab("sinkhole_spawn_fx_"..math.random(3))
        dust.Transform:SetPosition(x + math.cos(theta) * radius * (1 + math.random() * .1), 0, z - math.sin(theta) * radius * (1 + math.random() * .1))
        local s = scale + math.random() * .2
        dust.Transform:SetScale(i % 2 == 0 and -s or s, s, s)
        theta = theta + dtheta
    end
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/ground_break")
end

local function OnTimerDone(inst, data)
    if data ~= nil and data.name == "repair" then
        if not inst:IsAsleep() then
            SpawnFx(inst, 0.45)
        end
        inst.persists = false
        ErodeAway(inst)
    end
end

local COLLAPSIBLE_WORK_ACTIONS =
{
    CHOP = true, DIG = true, HAMMER = true, MINE = true,
}
local COLLAPSIBLE_TAGS = { "_combat", "pickable", "NPC_workable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
    table.insert(COLLAPSIBLE_TAGS, k.."_workable")
end
local NON_COLLAPSIBLE_TAGS = { "flying", "bird", "ghost", "locomotor", "FX", "NOCLICK", "DECOR", "INLIMBO" }

local function SmallLaunch(inst, launcher, basespeed)
    local hp = inst:GetPosition()
    local pt = launcher:GetPosition()
    local vel = (hp - pt):GetNormalized()
    local speed = basespeed * .5 + math.random()
    local angle = math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
    inst.Physics:Teleport(hp.x, .1, hp.z)
    inst.Physics:SetVel(math.cos(angle) * speed, 3 * speed + math.random(), math.sin(angle) * speed)
end

local function DoCollapse(inst)
    local pos = inst:GetPosition()
    SpawnFx(inst, 0.8)

    local x, y, z = pos:Get()
    local ents = TheSim:FindEntities(x, 0, z, inst.radius + 1, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)
    for _, v in ipairs(ents) do
        if v:IsValid() then
            local isworkable = false
            if v.components.workable ~= nil then
                local work_action = v.components.workable:GetWorkAction()
                isworkable = (
                    (work_action == nil and v:HasTag("NPC_workable")) or
                    (v.components.workable:CanBeWorked() and work_action ~= nil and COLLAPSIBLE_WORK_ACTIONS[work_action.id])
                )
            end
            if isworkable then
                v.components.workable:Destroy(inst)
                if v:IsValid() and v:HasTag("stump") then
                    v:Remove()
                end
            elseif v.components.combat ~= nil and v.components.health ~= nil and not v.components.health:IsDead() then
                if v.components.locomotor == nil then
                    v.components.health:Kill()
                elseif v.components.combat:CanBeAttacked() then
                    v.components.combat:GetAttacked(inst, TUNING.ANTLION_SINKHOLE.DAMAGE)
                end
            end
        end
    end
    local totoss = TheSim:FindEntities(x, 0, z, inst.radius, { "_inventoryitem" }, { "locomotor", "INLIMBO" })
    for _, v in ipairs(totoss) do
        if not v.components.inventoryitem.nobounce and v.Physics ~= nil and v.Physics:IsActive() then
            SmallLaunch(v, inst, 1.5)
        end
    end

    inst.components.timer:StartTimer("repair", 20)
end

local function onstartcollapse(inst)
    inst:AddTag("scarytoprey")
    DoCollapse(inst)
end

local function OnLoad(inst, data)
    if data ~= nil and data.repairing then
        inst.components.timer:StartTimer("repair", 20)
    end
end

local function OnSave(inst, data)
    if inst.components.timer:TimerExists("repair") then
        data.repairing = true
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("sinkhole")
    inst.AnimState:SetBuild("antlion_sinkhole")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)
    inst.Transform:SetEightFaced()

    inst:AddTag("antlion_sinkhole")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("NOCLICK")

    inst.radius = TUNING.DAYWALKER_SLAM_SINKHOLERADIUS or 3

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("docollapse", DoCollapse)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("daywalker_sinkhole", fn, assets, prefabs)
