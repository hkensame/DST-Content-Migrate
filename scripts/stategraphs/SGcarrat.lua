-- 胡萝卜鼠状态图
-- 移植自 DST，适配 DS
-- 移除：OnElectrocute, OnSink, OnFallInVoid, YOTC赛跑状态, 健身房状态

require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events =
{
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),

    EventHandler("locomote", function(inst)
        if inst.components.locomotor ~= nil then
            local is_moving = inst.sg:HasStateTag("moving")
            local is_running = inst.sg:HasStateTag("running")
            local is_idling = inst.sg:HasStateTag("idle")

            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()

            if is_moving and not should_move then
                inst.sg:GoToState(is_running and "run_stop" or "walk_stop")
            elseif (is_idling and should_move) or (is_moving and should_move and is_running ~= should_run) then
                inst.sg:GoToState((should_run and "run_start") or "walk_start")
            end
        end
    end),

    EventHandler("trapped", function(inst) inst.sg:GoToState("trapped") end),

    EventHandler("stunbomb", function(inst)
        inst.sg:GoToState("stunned")
    end),
}

local states =
{
    State {
        name = "idle",
        tags = { "idle", "canrotate" },
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle1", true)
            elseif not inst.AnimState:IsCurrentAnimation("idle1") then
                inst.AnimState:PlayAnimation("idle1", true)
            end
            inst.sg:SetTimeout(1 + math.random() * 1)
        end,

        ontimeout = function(inst)
            if ((inst.sg.mem.emerge_time or 0) + (TUNING.CARRAT_EMERGED_TIME_LIMIT or 120)) < GetTime() then
                inst.sg:GoToState("submerge")
            elseif math.random() > 0.55 then
                inst.sg:GoToState("idle2")
            else
                inst.sg:GoToState("idle")
            end
        end,
    },

    State {
        name = "idle2",
        tags = { "idle", "canrotate" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle2", false)
        end,
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State {
        name = "submerge",
        tags = { "busy", "noattack" },
        onenter = function(inst)
            if not inst:IsOnValidGround() then
                inst.sg:GoToState("idle")
                return
            end
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.Physics:Stop()
            inst.Physics:SetActive(false)
            inst.Transform:SetNoFaced()
            inst.AnimState:PlayAnimation("submerge")
        end,
        timeline =
        {
            TimeEvent(30 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(false)
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("submerged")
            end),
        },
        onexit = function(inst)
            inst.Physics:SetActive(true)
            inst.Transform:SetSixFaced()
        end,
    },

    State {
        name = "submerged",
        tags = { "busy", "noattack" },
        onenter = function(inst)
            inst.Physics:SetActive(false)
            inst.Transform:SetNoFaced()
            inst.AnimState:PlayAnimation("planted")
            if inst.GoToSubmerged ~= nil then
                inst:GoToSubmerged()
            end
        end,
        onexit = function(inst)
            inst.Physics:SetActive(true)
            inst.Transform:SetSixFaced()
        end,
    },

    State {
        name = "emerge_fast",
        tags = { "busy", "noattack" },
        onenter = function(inst)
            inst.Physics:SetActive(false)
            inst.AnimState:PlayAnimation("emerge_fast")
            inst.sg.mem.emerge_time = GetTime()
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(true)
            end),
        },
        onexit = function(inst)
            inst.Physics:SetActive(true)
        end,
    },

    State {
        name = "eat",
        tags = { "busy" },
        onenter = function(inst)
            inst.Physics:SetActive(false)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre", false)
            inst.AnimState:PushAnimation("eat_loop", false)
            inst.AnimState:PushAnimation("eat_pst", false)
        end,
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("submerge")
                end
            end),
        },
        timeline =
        {
            TimeEvent(25 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },
        onexit = function(inst)
            inst.Physics:SetActive(true)
        end,
    },

    State {
        name = "stunned",
        tags = { "busy", "stunned" },
        onenter = function(inst, dont_play_sound)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("stunned_loop", true)
            inst.sg:SetTimeout(GetRandomWithVariance(6, 2))
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = true
            end
        end,
        onexit = function(inst)
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = false
            end
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("idle", "stunned_pst")
        end,
    },

    State {
        name = "trapped",
        tags = { "busy", "trapped" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("stunned_loop", true)
            inst.sg:SetTimeout(1)
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },

    State {
        name = "dug_up",
        tags = { "busy", "stunned" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("stunned_pre")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("stunned", true)
                end
            end),
        },
        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(true)
            end),
        },
    },

    State {
        name = "death",
        tags = { "busy" },
        onenter = function(inst)
            if inst._is_burrowed then
                inst:Remove()
            else
                if inst.components.locomotor ~= nil then
                    inst.components.locomotor:StopMoving()
                end
                inst.AnimState:PlayAnimation("death")
                RemovePhysicsColliders(inst)
                inst.components.lootdropper:DropLoot(inst:GetPosition())
            end
        end,
    },
}

CommonStates.AddSleepExStates(states)
CommonStates.AddFrozenStates(states)
CommonStates.AddHitState(states)
CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states)

return StateGraph("carrat", states, events, "emerge_fast", actionhandlers)
