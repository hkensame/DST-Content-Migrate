-- 光飞虫状态图
-- 移植自 DST，适配 DS
-- 移除：OnElectrocute、go_home、startled（编队相关）

require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("walk_loop", true)
            else
                inst.AnimState:PlayAnimation("walk_loop", true)
            end
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
            inst:PerformBufferedAction()
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

local walkanims =
{
    startwalk = "walk_pre",
    walk = "walk_loop",
    stopwalk = "walk_pst",
}

CommonStates.AddWalkStates(states, nil, walkanims, true)

local function Land(inst)
    --LandFlyingCreature(inst) -- DS 无此函数
    if inst.Physics ~= nil then
        inst.Physics:Stop()
    end
end

local function Liftoff(inst)
    --RaiseFlyingCreature(inst) -- DS 无此函数
end

CommonStates.AddSleepExStates(states, {},
{
    onsleeping = Land,
    onexitsleeping = Liftoff,
})

CommonStates.AddCombatStates(states, {},
{
    hit = "hit_2",
})

CommonStates.AddFrozenStates(states)

return StateGraph("lightflier", states, events, "idle")
