-- 光蟹状态图
-- 移植自 DST，适配 DS

local WALK_SPEED = 4
local RUN_SPEED = 7

require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events=
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true, true),
    EventHandler("stunbomb", function(inst)
        if inst.components.health == nil or not inst.components.health:IsDead() then
            inst.sg:GoToState("stunned")
        end
    end),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
            else
                local r = math.random(10) - 7
                if r > 1 then
                    inst.sg:GoToState("idle"..r)
                    return
                else
                    inst.AnimState:PlayAnimation("idle")
                end
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "eat",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle3", false)
            inst.AnimState:PushAnimation("eat", false)
        end,

        events=
        {
            EventHandler("animqueueover", function(inst) 
                if math.random() < 0.125 then
                    inst:PerformBufferedAction() 
                    inst.sg:GoToState("idle") 
                else
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle") 
                end
            end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.Light:Enable(false)

            inst.AnimState:PlayAnimation("death")
            inst.components.lootdropper:DropLoot(inst:GetPosition()) -- DS 无 DropDeathLoot
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },

    State{
        name = "stunned",
        tags = {"busy", "stunned"},

        onenter = function(inst, duration)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("stunned_loop", true)
            inst.sg:SetTimeout(duration or GetRandomWithVariance(6, 2))
        end,

        ontimeout = function(inst) inst.sg:GoToState("idle") end,
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },
}

CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states)
CommonStates.AddSleepStates(states)
CommonStates.AddFrozenStates(states)

CommonStates.AddSimpleState(states, "idle2", "idle2", {"canrotate"})
CommonStates.AddSimpleState(states, "idle3", "idle3", {"canrotate"})

-- 初始状态直接设为 idle，与所有稳定 SG 文件一致
--CommonStates.AddInitState(states, "idle") -- DS/mod 无此函数

return StateGraph("lightcrab", states, events, "idle", actionhandlers)
