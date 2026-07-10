-- SGfruitdragon.lua - 火龙果蜥蜴状态图（全功能版）
require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.GOHOME, "gohome"),
}

local events = {
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true, true),

    EventHandler("doattack", function(inst, data)
        if inst.components.health and not inst.components.health:IsDead() and
            (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit")) then
            if inst._is_ripe and not inst.components.timer:TimerExists("fire_cd") then
                inst.sg:GoToState("attack_fire")
            else
                inst.sg:GoToState("attack")
            end
        end
    end),

    EventHandler("attacked", function(inst, data)
        if inst.components.health and not inst.components.health:IsDead() then
            if not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("caninterrupt") or inst.sg:HasStateTag("frozen") then
                inst.sg:GoToState("hit")
            end
        end
    end),

    EventHandler("wake_up_to_challenge", function(inst)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("wake_up_to_challenge")
        end
    end),
}

local function PlayFootstep(inst)
    inst.SoundEmitter:PlaySound("turnoftides/creatures/together/fruit_dragon/footstep")
end

local function DoFireAttack(inst)
    local T = TUNING.FRUITDRAGON or {}
    local hit_range = T.FIREATTACK_HIT_RANGE or 3
    local damage = T.FIREATTACK_DAMAGE or 30
    local x, y, z = inst.Transform:GetWorldPosition()
    local CANT_TAGS = { "fruitdragon", "INLIMBO", "playerghost", "FX", "DECOR", "notarget", "noattack" }
    local ents = TheSim:FindEntities(x, y, z, hit_range + 6, nil, CANT_TAGS)
    for _, v in ipairs(ents) do
        if v ~= inst and v.components.health and not v.components.health:IsDead() then
            v.components.health:DoFireDamage(damage, inst)
            if v.components.burnable then
                v.components.burnable:Ignite()
            end
        end
    end
    inst.components.timer:StartTimer("fire_cd", T.FIREATTACK_COOLDOWN or 6)
end

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.SoundEmitter:PlaySound(inst.sounds.idle)
            inst.AnimState:PlayAnimation("idle_loop")
        end,
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = { "attack", "busy" },
        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("attack")
            inst.SoundEmitter:PlaySound(inst.sounds.attack)
            inst.components.combat:StartAttack()
            inst.sg.statemem.target = target
        end,
        timeline = {
            TimeEvent(22*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
            TimeEvent(28*FRAMES, function(inst) inst.sg:RemoveStateTag("busy") end),
        },
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack_fire",
        tags = { "attack", "busy" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("attack_fire")
            inst.SoundEmitter:PlaySound(inst.sounds.attack_fire)
            inst.components.combat:StartAttack()
        end,
        timeline = {
            TimeEvent(16*FRAMES, function(inst)
                inst.Light:Enable(true)
                inst.DynamicShadow:Enable(false)
            end),
            TimeEvent(20*FRAMES, function(inst)
                DoFireAttack(inst)
            end),
            TimeEvent(37*FRAMES, function(inst)
                inst.Light:Enable(false)
                inst.DynamicShadow:Enable(true)
            end),
        },
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "gohome",
        tags = {"busy", "canrotate"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("gohome")
        end,
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "do_ripen",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_ripe_pst")
            inst.SoundEmitter:PlaySound(inst.sounds.stretch)
        end,
        events = {
            EventHandler("animover", function(inst)
                MakeRipe(inst, true)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "do_unripen",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_ripe_pre")
            inst.SoundEmitter:PlaySound(inst.sounds.do_unripen)
        end,
        events = {
            EventHandler("animover", function(inst)
                MakeUnripe(inst, true)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "wake_up_to_challenge",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle_loop")
        end,
        timeline = {
            TimeEvent(0, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:GoToState("challenge_attack_pre")
            end),
        },
    },

    State{
        name = "challenge_attack_pre",
        tags = {"busy", "noattack"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("challenge_pre")
            inst.SoundEmitter:PlaySound(inst.sounds.challenge_pre)
        end,
        timeline = {
            TimeEvent(18*FRAMES, function(inst)
                inst.components.combat:StartAttack()
            end),
        },
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("challenge_attack")
            end),
        },
    },

    State{
        name = "challenge_attack",
        tags = {"attack", "busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("challenge_loop")
            inst.SoundEmitter:PlaySound(inst.sounds.challenge)
            inst.sg.statemem.loops = 0
            inst.sg.statemem.max_loops = 1 + math.random(3)
        end,
        timeline = {
            TimeEvent(9*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(21*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },
        onupdate = function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg.statemem.loops = inst.sg.statemem.loops + 1
                if inst.sg.statemem.loops >= inst.sg.statemem.max_loops then
                    inst.sg:GoToState("challenge_attack_pst")
                else
                    inst.AnimState:PlayAnimation("challenge_loop")
                end
            end
        end,
    },

    State{
        name = "challenge_attack_pst",
        tags = {"busy", "noattack"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("challenge_pst")
            inst.SoundEmitter:PlaySound(inst.sounds.challenge_pst)
        end,
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "challenge_win",
        tags = {"busy", "noattack"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("challenge_win")
            inst.SoundEmitter:PlaySound(inst.sounds.challenge_win)
        end,
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "challenge_lose",
        tags = {"busy", "noattack"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("challenge_lose")
            inst.SoundEmitter:PlaySound(inst.sounds.challenge_lose)
        end,
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddHitState(states, {
    TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.onhit) end),
})

CommonStates.AddDeathState(states, {
    TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.death) end),
})

CommonStates.AddWalkStates(states, {
    starttimeline = {},
    walktimeline = {
        TimeEvent(0, PlayFootstep),
        TimeEvent(4*FRAMES, PlayFootstep),
        TimeEvent(12*FRAMES, PlayFootstep),
    },
    endtimeline = {
        TimeEvent(0, PlayFootstep),
    },
}, nil, true)

CommonStates.AddRunStates(states, {
    runtimeline = {
        TimeEvent(6*FRAMES, PlayFootstep),
        TimeEvent(10*FRAMES, PlayFootstep),
    },
    endtimeline = {
        TimeEvent(0, PlayFootstep),
    },
})

CommonStates.AddSleepStates(states, {
    starttimeline = {
        TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.stretch) end),
    },
    sleeptimeline = {
        TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.sleep_loop) end),
        TimeEvent(32*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.sleep_loop) end),
    },
    waketimeline = {
        TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.stretch) end),
    },
})

CommonStates.AddFrozenStates(states)

return StateGraph("fruit_dragon", states, events, "idle", actionhandlers)
