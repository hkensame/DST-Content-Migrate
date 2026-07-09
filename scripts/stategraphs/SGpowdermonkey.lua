-- 火药猴状态图 (SGpowdermonkey)
-- 移植自 DST，适配 DS 单机模式
-- 移除：OnElectrocute, OnSink, OnFallInVoid, OnHop, OnCorpseChomped
-- 移除：boat 相关状态 (row, dive, dive_pst_land, empty)
-- 移除：AddElectrocuteStates, AddHopStates, AddCorpseStates

require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "action"),
    ActionHandler(ACTIONS.PICKUP, "action"),
    ActionHandler(ACTIONS.GIVE, "action"),
    ActionHandler(ACTIONS.STEAL, "steal"),
    ActionHandler(ACTIONS.PICK, "action"),
    ActionHandler(ACTIONS.ATTACK, "attack"),
    ActionHandler(ACTIONS.HARVEST, "action"),
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.HAMMER, "hammer"),
}

local events =
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnFreeze(),
    --CommonHandlers.OnElectrocute(), -- DS 不支持
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnDeath(),
    --CommonHandlers.OnHop(), -- DS 无平台跳跃
    --CommonHandlers.OnSink(), -- DS 无海洋
    --CommonHandlers.OnFallInVoid(), -- DS 无虚空
    CommonHandlers.OnSleep(),

    EventHandler("victory", function(inst, data)
        inst.sg:GoToState("victory",data)
    end),

    EventHandler("cheer", function(inst, data)
        inst.sg:GoToState("taunt",data)
    end),

    -- OnCorpseChomped 移除
}

local function go_to_idle(inst)
    inst.sg:GoToState("idle")
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
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
            inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/idle")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.components.combat.target and
                    inst.components.combat.target:HasTag("player") then
                    if math.random() < 0.05 then
                        inst.sg:GoToState("taunt")
                        return
                    end
                end
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "action",
        tags = {"busy", "action", "caninterrupt"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("action_pre")
            inst.AnimState:PushAnimation("action",false)
        end,

        timeline =
        {
            TimeEvent(6*FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animqueueover", go_to_idle),
        }
    },

    State{
        name = "hammer",
        tags = {"busy", "action", "caninterrupt"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(17*FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animover", go_to_idle),
        }
    },

    State{
        name = "victory",
        tags = {"busy", "caninterrupt"},
        onenter = function(inst, data)
            inst.Physics:Stop()

            inst.victory = true

            if data.say then
                inst.sg.statemem.say = data.say
            end

            if data and data.item then
                if data.item.prefab == "cave_banana" then
                    inst.AnimState:OverrideSymbol("swap_item", "cave_banana", "cave_banana01")
                elseif data.item.prefab == "cave_banana_cooked" then
                    inst.AnimState:OverrideSymbol("swap_item", "cave_banana", "cave_banana02")
                end
                inst.AnimState:PlayAnimation("action_victory_pre")
                inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/victory_pre")
            else
                inst.sg:GoToState("victory_pst", data)
            end
        end,

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("victory_pst", {say = inst.sg.statemem.say} )
            end),
        }
    },

    State{
        name = "victory_pst",
        tags = {"busy", "caninterrupt"},
        onenter = function(inst, data)
            inst.Physics:Stop()

            inst.AnimState:PlayAnimation("victory")
            inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/victory")

            local say_script = (data and data.say)
                or (STRINGS["MONKEY_BATTLECRY_VICTORY_CHEER"] and STRINGS["MONKEY_BATTLECRY_VICTORY_CHEER"][math.random(#STRINGS["MONKEY_BATTLECRY_VICTORY_CHEER"])])
                or nil
            if say_script then
                inst.components.talker:Say(say_script)
            end
        end,

        timeline =
        {
            TimeEvent(9*FRAMES, function(inst)
                PlayFootstep(inst)
            end),
            TimeEvent(25*FRAMES, function(inst)
                PlayFootstep(inst)
            end),
            TimeEvent(40*FRAMES, function(inst)
                PlayFootstep(inst)
            end),
            TimeEvent(54*FRAMES, function(inst)
                PlayFootstep(inst)
            end),
        },

        events =
        {
            EventHandler("animover", go_to_idle),
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
                local waittime = FRAMES*8
                for i = 0, 3 do
                    inst:DoTaskInTime((i * waittime), function(inst2)
                        inst2.SoundEmitter:PlaySound("monkeyisland/powdermonkey/eat")
                    end)
                end
            end)
        },

        events =
        {
            EventHandler("animover", go_to_idle),
        }
    },

    State{
        name = "taunt",
        tags = {"busy", "caninterrupt"},

        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.sg.statemem.say = data and data.say
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                local say = inst.sg.statemem.say
                    or (STRINGS["MONKEY_BATTLECRY"] and STRINGS["MONKEY_BATTLECRY"][math.random(#STRINGS["MONKEY_BATTLECRY"])])
                    or nil
                if say then
                    inst.components.talker:Say(say)
                end
                inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/taunt")
            end)
        },

        events =
        {
            EventHandler("animover", go_to_idle),
        },
    },

    State{
        name = "steal",
        tags = {"busy","caninterrupt"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("unequipped_atk")
        end,

        timeline =
        {
            TimeEvent(14*FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/attack_unarmed")
            end),
        },

        events =
        {
            EventHandler("animover", go_to_idle),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    starttimeline =
    {
    },

    walktimeline =
    {
        TimeEvent(5*FRAMES, PlayFootstep),
        TimeEvent(13*FRAMES, PlayFootstep),
    },

    endtimeline =
    {
        TimeEvent(5*FRAMES, PlayFootstep),
    },
})


CommonStates.AddSleepStates(states,
{
    starttimeline =
    {
        TimeEvent(FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/sleep_pre")
        end),
    },

    sleeptimeline =
    {
        TimeEvent(FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/sleep_lp", "sleep_lp")
        end),
    },

    endtimeline =
    {
        TimeEvent(FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/sleep_pst")
        end),
    },
},{
    onsleepexit = function(inst)
        inst.SoundEmitter:KillSound("sleep_lp")
    end,
})

CommonStates.AddCombatStates(states,
{
    attacktimeline =
    {
        TimeEvent(14*FRAMES, function(inst)
            local act = inst:GetBufferedAction()
            if act and act.action.id == ACTIONS.ATTACK.id and act.target then
                inst.components.combat:DoAttack(act.target)
                inst:ClearBufferedAction()
            else
                inst.components.combat:DoAttack()
            end

            inst.SoundEmitter:PlaySound(
                (inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and "monkeyisland/powdermonkey/attack_sword")
                or "monkeyisland/powdermonkey/attack_unarmed"
            )
        end),
    },

    hittimeline =
    {
        TimeEvent(FRAMES, function(inst)
            inst.components.timer:StartTimer("hit",2+(math.random()*2))
            inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/hit")
        end),
    },

    deathtimeline =
    {
        TimeEvent(FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("monkeyisland/powdermonkey/death")
        end),
    },
},
nil,
{
    attackanimfn = function(inst)
        return (inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and "atk")
            or "unequipped_atk"
    end
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

return StateGraph("powdermonkey", states, events, "init", actionhandlers)
