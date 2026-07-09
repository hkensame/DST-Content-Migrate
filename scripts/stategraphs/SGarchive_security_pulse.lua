local function normal_movement(inst)
	inst.AnimState:PlayAnimation("idle", true)
end

local events = {}

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = normal_movement,
	},
}

return StateGraph("archive_security_pulse", states, events, "idle")
