require("stategraphs/commonstates")

local events = {
	CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSink(),
    CommonHandlers.OnFallInVoid(),
}

local states = {
	State{ name = "transition", },
	State{ name = "idle",
		tags = { "idle", "canrotate" },
		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("idle", true)
		end,
	},
}

CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states)
CommonStates.AddSinkAndWashAshoreStates(states, {washashore = "idle",})
CommonStates.AddVoidFallStates(states, {voiddrop = "idle",})
CommonStates.AddElectrocuteStates(states)

return StateGraph("daywalker", states, events, "idle")
