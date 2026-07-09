-- 猴子状态图 (SGmonkey)
-- 移植自 DST，适配 DS 单机模式
-- 移除：CommonHandlers.OnElectrocute, AddElectrocuteStates
-- 移除：OnCorpseChomped, AddCorpseStates (mod不支持尸体系统)

require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "action"),
    ActionHandler(ACTIONS.PICKUP, "action"),
    ActionHandler(ACTIONS.STEAL, "action"),
    ActionHandler(ACTIONS.PICK, "action"),
    ActionHandler(ACTIONS.HARVEST, "action"),
    ActionHandler(ACTIONS.ATTACK, "throw"),
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events=
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnFreeze(),
    --CommonHandlers.OnElectrocute(), -- DS 不支持
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnSleep(),
    EventHandler("doattack", function(inst, data)
        if inst.components.health and not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState(
                (not (data.target ~= nil and data.target:IsValid()) and "idle") or
                (inst:GetDistanceSqToInst(data.target) <= (TUNING.MONKEY_MELEE_RANGE*TUNING.MONKEY_MELEE_RANGE) + 1 and
                    "attack"
                ) or
                "throw"
            )
        end
    end),

    -- OnCorpseChomped 移除 (mod不支持)
}

local function go_to_idle(inst)
    inst.sg:GoToState("idle")
end

local function play_eat(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/eat")
end

local function play_chest_pound(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/chest_pound")
end

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
            inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/idle")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                local combat_target = inst.components.combat.target
                inst.sg:GoToState((combat_target and combat_target.isplayer and math.random() < 0.05 and "taunt")
                    or "idle")
            end),
        },
    },

    State{
        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("interact")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
        end,
        onexit = function(inst)
            inst.SoundEmitter:KillSound("make")
        end,
        timeline =
        {
            TimeEvent(25 * FRAMES, function(inst) -- FrameEvent 是 DST-only，等价于 TimeEvent(frame*FRAMES,fn)
                inst:PerformBufferedAction()
            end)
        },
        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "eat",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat", true)
        end,

        onexit = function(inst)
            inst:PerformBufferedAction()
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                local waittime = 8*FRAMES
                for i = 0, 3 do
                    inst:DoTaskInTime((i * waittime), play_eat)
                end
            end)
        },

        events=
        {
            EventHandler("animover", go_to_idle),
        }
    },

    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/taunt")
                local waittime = 2*FRAMES
                for i = 0, 11 do
                    inst:DoTaskInTime((i * waittime), play_chest_pound)
                end
            end)
        },

        events =
        {
            EventHandler("animover", go_to_idle),
        },
    },

    State{
        name = "throw",
        tags = {"attack", "busy", "canrotate", "throwing"},

        onenter = function(inst)
            if not inst.HasAmmo(inst) then
                inst.sg:GoToState("idle")
            end

            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("throw")
        end,

        timeline =
        {
            TimeEvent(14*FRAMES, function(inst)
                inst.components.combat:DoAttack()
                inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/throw")
            end),
        },

        events=
        {
            EventHandler("animover", go_to_idle),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(4*FRAMES, PlayFootstep),
        TimeEvent(5*FRAMES, PlayFootstep),
        TimeEvent(10*FRAMES, function(inst)
            PlayFootstep(inst)
            if math.random() < 0.1 then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/idle")
            end
         end),
        TimeEvent(11*FRAMES, PlayFootstep),
    },
})


CommonStates.AddSleepStates(states,
{
    sleeptimeline =
    {
        TimeEvent(1*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/sleep")
        end),
    },
})

CommonStates.AddCombatStates(states,
{
    attacktimeline =
    {
        TimeEvent(17*FRAMES, function(inst)
            inst.components.combat:DoAttack()
            inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/attack")
        end),
    },

    hittimeline =
    {
        TimeEvent(1*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/hurt")
        end),
    },

    deathtimeline =
    {
        TimeEvent(1*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/death")
        end),
    },
})

CommonStates.AddFrozenStates(states)
--CommonStates.AddElectrocuteStates(states) -- DS 不支持

-- DS 无 CommonStates.AddInitState，内联实现
if CommonStates.AddInitState then
    CommonStates.AddInitState(states, "idle")
else
    table.insert(states, State{
        name = "init",
        onenter = function(inst)
            inst.sg:GoToState(inst.is_corpse and "corpse_idle" or "idle")
        end,
    })
end
--CommonStates.AddCorpseStates(states) -- mod 不支持

return StateGraph("monkey", states, events, "init", actionhandlers)
