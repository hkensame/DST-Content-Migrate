-- DS 适配版 SGmushgnome.lua
-- 从 DST 源码 scripts/stategraphs/SGmushgnome.lua 移植
-- 改动：
--   🔴 移除 CommonHandlers.OnElectrocute / OnFallInVoid
--   🔴 移除 CommonStates.AddElectrocuteStates / AddVoidFallStates
--   🔴 HasAnyStateTag(a,b) → HasStateTag(a) or HasStateTag(b)
--   🔴 移除 TryElectrocuteOnAttacked

require("stategraphs/commonstates")

local PI_BY_6 = PI / 6
local ANGLES = {
    PI_BY_6,
    2 * PI_BY_6,
    3 * PI_BY_6,
    4 * PI_BY_6,
    5 * PI_BY_6,
    PI,
    7 * PI_BY_6,
    8 * PI_BY_6,
    9 * PI_BY_6,
    10 * PI_BY_6,
    11 * PI_BY_6,
    TWOPI,
}

local events =
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnFreeze(),
    -- 🔴 移除 CommonHandlers.OnElectrocute()（DS 无此 handler）
    CommonHandlers.OnDeath(),
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),

    EventHandler("attacked", function(inst, data)
        if not inst.components.health:IsDead() then
            -- 🔴 移除 TryElectrocuteOnAttacked（DS 无此函数）
            if not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("waking") or inst.sg:HasStateTag("sleeping")) and
                not CommonHandlers.HitRecoveryDelay(inst) and
                (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("frozen"))
            then
                inst.sg:GoToState("hit")
            end
        end
    end),

    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and
                (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            -- 🔴 移除 electrocute tag 检查（DS 无触电状态）
            inst.sg:GoToState("attack_pre", data.target)
        end
    end),

    EventHandler("spawn", function(inst)
        if not inst.components.health:IsDead() and
                (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            -- 🔴 移除 electrocute tag 检查
            inst.sg:GoToState("spawn")
        end
    end),

    EventHandler("locomote", function(inst)
        local is_moving = inst.sg:HasStateTag("moving")
        local is_idling = inst.sg:HasStateTag("idle")

        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()

        if is_moving and not should_move then
            inst.sg:GoToState("walk_stop")
        elseif is_idling and should_move then
            if inst.components.combat:HasTarget() then
                inst.sg:GoToState("flaunt")
            else
                inst.sg:GoToState("walk_start")
            end
        end
    end),
    -- 🔴 移除 CommonHandlers.OnFallInVoid()（DS 无虚空坠落）
}

local function return_to_idle(inst)
    inst.sg:GoToState("idle")
end

local function spawn_spore(position, angle)
    local radius = math.random() + 1.0
    local offset = Vector3(math.cos(angle), 0, -math.sin(angle)) * radius

    local spore = SpawnPrefab("spore_moon")
    spore.Transform:SetPosition((position + offset):Get())
end

local states =
{
    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/death")

            inst.Physics:Stop()
            RemovePhysicsColliders(inst)

            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
            inst.components.periodicspawner:Stop()
        end,

        timeline =
        {
            TimeEvent(26*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/bodyfall")
            end),
        },
    },

    State{
        name = "tree",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("tree_idle", true)
        end,
    },

    State{
        name = "panic",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("panic_pre")
            inst.AnimState:PushAnimation("panic_loop", true)
        end,
        onexit = function(inst)
        end,

        onupdate = function(inst)
            if inst.components.burnable and not inst.components.burnable:IsBurning() and inst.sg.timeinstate > .3 then
                inst.sg:GoToState("idle", "panic_post")
            end
        end,
    },

    State{
        name = "flaunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline=
        {
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/surpise") end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/surpise") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("walk_start")
            end),
        },
    },

    State{
        name = "attack_pre",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()

            inst.AnimState:PlayAnimation("atk_pre", false)
        end,

        timeline=
        {
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/taunt") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("attack")
            end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_loop", true)

            inst.sg:SetTimeout(2 + math.random() * 0.5)

            inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/attack_LP", "spinning")

            inst.sg.statemem.position = inst:GetPosition()
            inst.sg.statemem.angles = shuffleArray(ANGLES)
        end,

        timeline =
        {
            TimeEvent(23*FRAMES, function(inst)
                local coughout = SpawnPrefab("spore_moon_coughout")
                coughout.Transform:SetPosition(inst.sg.statemem.position:Get())
            end),
            TimeEvent(25*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[1])
            end),
            TimeEvent(26*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[2])
            end),
            TimeEvent(27*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[3])
            end),
            TimeEvent(28*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[4])
            end),
            TimeEvent(29*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[5])
            end),
            TimeEvent(30*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[6])
            end),
            TimeEvent(31*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[7])
            end),
            TimeEvent(32*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[8])
            end),
            TimeEvent(33*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[9])
            end),
            TimeEvent(34*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[10])
            end),
            TimeEvent(35*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[11])
            end),
            TimeEvent(36*FRAMES, function(inst)
                spawn_spore(inst.sg.statemem.position, inst.sg.statemem.angles[12])
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("attack_pst")
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("spinning")
        end,
    },

    State{
        name = "attack_pst",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()

            inst.AnimState:PlayAnimation("atk_pst", false)
        end,

        timeline=
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/taunt") end),
        },

        events =
        {
            EventHandler("animover", return_to_idle),
        },
    },

    State{
        name = "hit",
        tags = {"hit", "busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/hit")
            CommonHandlers.UpdateHitRecoveryDelay(inst)
        end,

        events =
        {
            EventHandler("animover", return_to_idle),
        },
    },

    State{
        name = "spawn",
        tags = { "waking", "busy", "noattack" },
        -- 🔴 移除 noelectrocute tag（DS 无触电状态）

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("spawn")
        end,

        events =
        {
            EventHandler("animover", return_to_idle),
        },

        timeline=
        {
            TimeEvent(16*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/spawn")
            end),
            TimeEvent(24*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/surpise")
                inst.sg:RemoveStateTag("noattack")
                -- 🔴 移除 RemoveStateTag("noelectrocute")
            end),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    starttimeline =
    {
        TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end),
        TimeEvent(11*FRAMES, function(inst) inst.components.locomotor:WalkForward() end),
        TimeEvent(17*FRAMES, function(inst) inst.Physics:Stop() end),
    },
    walktimeline =
    {
        TimeEvent(0*FRAMES, PlayFootstep ),
        TimeEvent(14*FRAMES, PlayFootstep ),
    },
    endtimeline =
    {
        TimeEvent(0*FRAMES, PlayFootstep ),
    },
})

CommonStates.AddIdle(states, nil, nil,
{
    TimeEvent(7*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/idle")
    end),
})
CommonStates.AddFrozenStates(states)
-- 🔴 移除 CommonStates.AddElectrocuteStates(states)（DS 无触电状态）
CommonStates.AddSleepExStates(states,
{
    starttimeline =
    {
    },

    sleeptimeline =
    {
        TimeEvent(0*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/sleep_in")
        end),
        TimeEvent(35*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/sleep_out")
        end),
    },

    waketimeline =
    {
        TimeEvent(7*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("grotto/creatures/mushgnome/surpise")
        end),
    },
})
-- 🔴 移除 CommonStates.AddVoidFallStates(states)（DS 无虚空坠落）

return StateGraph("mushgnome", states, events, "idle")
