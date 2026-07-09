CommonStates = {}
CommonHandlers = {}

CommonHandlers.OnStep = function()
    return EventHandler("step", function(inst)
        local sound = inst.SoundEmitter
        if sound then
            sound:PlaySound("dontstarve/movement/run_dirt")
            --[[else
                sound:PlaySound("dontstarve/movement/walk_dirt")
            end--]]
        end
    end)

end

CommonHandlers.OnSleep = function()
    return EventHandler("gotosleep", function(inst)
        if inst.components.health and inst.components.health:GetPercent() > 0 then
            if inst.sg:HasStateTag("sleeping") then
                inst.sg:GoToState("sleeping")
            else
                inst.sg:GoToState("sleep")
            end
        end
    end)
end
local function onsleepex(inst)
    inst.sg.mem.sleeping = true
    if not (inst.sg:HasStateTag("nosleep") or inst.sg:HasStateTag("sleeping") or
            (inst.components.health ~= nil and inst.components.health:IsDead())) then
        inst.sg:GoToState("sleep")
    end
end

local function onwakeex(inst)
    inst.sg.mem.sleeping = false
    if inst.sg:HasStateTag("sleeping") and not inst.sg:HasStateTag("nowake") and
        not (inst.components.health ~= nil and inst.components.health:IsDead()) then
        inst.sg.statemem.continuesleeping = true
        inst.sg:GoToState("wake")
    end
end

CommonHandlers.OnSleepEx = function()
    return EventHandler("gotosleep", onsleepex)
end

CommonHandlers.OnWakeEx = function()
    return EventHandler("onwakeup", onwakeex)
end

CommonHandlers.OnNoSleepAnimOver = function(nextstate)
    return EventHandler("animover", function(inst)
        if inst.AnimState:AnimDone() then
            if inst.sg.mem.sleeping then
                inst.sg:GoToState("sleep")
            elseif type(nextstate) == "string" then
                inst.sg:GoToState(nextstate)
            elseif nextstate ~= nil then
                nextstate(inst)
            end
        end
    end)
end

CommonHandlers.OnNoSleepTimeEvent = function(t, fn)
    return TimeEvent(t, function(inst)
        if inst.sg.mem.sleeping and not (inst.components.health ~= nil and inst.components.health:IsDead()) then
            inst.sg:GoToState("sleep")
        elseif fn ~= nil then
            fn(inst)
        end
    end)
end

CommonHandlers.OnFreeze = function()
    return EventHandler("freeze", function(inst)
        if inst.components.health and inst.components.health:GetPercent() > 0 then
            inst.sg:GoToState("frozen")
        end
    end)
end

--天体英雄
--------------------------------------------------------------------------
local function idleonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg:GoToState("idle")
    end
end

CommonStates.AddHitState = function(states, timeline, anim)
    table.insert(states, State{
        name = "hit",
        tags = { "hit", "busy" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end

            local hitanim =
                (anim == nil and "hit") or
                (type(anim) ~= "function" and anim) or
                anim(inst)

            inst.AnimState:PlayAnimation(hitanim)

            if inst.SoundEmitter ~= nil and inst.sounds ~= nil and inst.sounds.hit ~= nil then
                inst.SoundEmitter:PlaySound(inst.sounds.hit)
            end
        end,

        timeline = timeline,

        events =
        {
            EventHandler("animover", idleonanimover),
        },
    })
end

CommonStates.AddDeathState = function(states, timeline, anim)
    table.insert(states, State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            local deathanim =
                (anim == nil and "death") or
                (type(anim) ~= "function" and anim) or
                anim(inst)

            inst.AnimState:PlayAnimation(deathanim)

            if inst.components.locomotor ~= nil then
                inst.components.locomotor:Stop()
            end

            if inst.Physics ~= nil then
                inst.Physics:ClearCollisionMask()
            end

            if inst.components.lootdropper ~= nil then
                inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
            end
        end,

        timeline = timeline,
    })
end

--------------------------------------------------------------------------
--V2C: DST improved to support freezable entities with no health component

local function onfreezeex(inst)
    if not (inst.components.health ~= nil and inst.components.health:IsDead()) then
        inst.sg:GoToState("frozen")
    end
end

CommonHandlers.OnFreezeEx = function()
    return EventHandler("freeze", onfreezeex)
end

--------------------------------------------------------------------------
--编织者
local function hit_recovery_delay(inst, delay, max_hitreacts, skip_cooldown_fn)
	local on_cooldown = false
	if (inst._last_hitreact_time ~= nil and inst._last_hitreact_time + (delay or inst.hit_recovery or TUNING.DEFAULT_HIT_RECOVERY) >= GetTime()) then	-- is hit react is on cooldown?
		max_hitreacts = max_hitreacts or inst._max_hitreacts
		if max_hitreacts then
			if inst._hitreact_count == nil then
				inst._hitreact_count = 2
				return false
			elseif inst._hitreact_count < max_hitreacts then
				inst._hitreact_count = inst._hitreact_count + 1
				return false
			end
		end

		skip_cooldown_fn = skip_cooldown_fn or inst._hitreact_skip_cooldown_fn
		if skip_cooldown_fn ~= nil then
			on_cooldown = not skip_cooldown_fn(inst, inst._last_hitreact_time, delay)
		elseif inst.components.combat ~= nil then
			on_cooldown = not (inst.components.combat:InCooldown() and inst.sg:HasStateTag("idle"))		-- skip the hit react cooldown if the creature is ready to attack
		else
			on_cooldown = true
		end
	end

	if inst._hitreact_count ~= nil and not on_cooldown then
		inst._hitreact_count = 1
	end
	return on_cooldown
end

CommonHandlers.HitRecoveryDelay = hit_recovery_delay -- returns true if inst is still in a hit reaction cooldown

local function update_hit_recovery_delay(inst)
	inst._last_hitreact_time = GetTime()
end

CommonHandlers.UpdateHitRecoveryDelay = update_hit_recovery_delay
local function onattacked(inst, data, hitreact_cooldown, max_hitreacts, skip_cooldown_fn)
    if inst.components.health ~= nil and not inst.components.health:IsDead()
		and not hit_recovery_delay(inst, hitreact_cooldown, max_hitreacts, skip_cooldown_fn)
        and (not inst.sg:HasStateTag("busy")
            or inst.sg:HasStateTag("caninterrupt")
            or inst.sg:HasStateTag("frozen")) then
        inst.sg:GoToState("hit")
    end
end

--------
CommonHandlers.OnAttacked = function()
    return EventHandler("attacked", function(inst)
        if inst.components.health and not inst.components.health:IsDead()
           and (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("frozen") ) then
            inst.sg:GoToState("hit")
        end
    end)
end

CommonHandlers.OnAttack = function()
    return EventHandler("doattack", function(inst)
        if inst.components.health and not inst.components.health:IsDead()
           and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("attack")
        end
    end)
end

CommonHandlers.OnDeath = function()
    return EventHandler("death", function(inst) inst.sg:GoToState("death") end)
end

CommonHandlers.OnLocomote = function(can_run, can_walk)

    return EventHandler("locomote", function(inst)
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        
        local is_idling = inst.sg:HasStateTag("idle")
        
        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()
        if is_moving and not should_move then
            if is_running then
                inst.sg:GoToState("run_stop")
            else
                inst.sg:GoToState("walk_stop")
            end
        elseif (is_idling and should_move) or (is_moving and should_move and is_running ~= should_run and can_run and can_walk) then
            if can_run and (should_run or not can_walk) then
                inst.sg:GoToState("run_start")
            elseif can_walk then
                inst.sg:GoToState("walk_start")
            end
        end
    end)

end

CommonStates.AddIdle = function(states, funny_idle_state, anim_override, timeline)
    
    table.insert(states, State {
        name = "idle",
        tags = {"idle", "canrotate"},
        timeline = timeline,
        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            local anim = "idle_loop"
            if anim_override then
                if type(anim_override) == "function" then
                    anim = anim_override(inst)
                else
                    anim = anim_override
                end
            end
               
            if pushanim then
                if type(pushanim) == "string" then
                    inst.AnimState:PlayAnimation(pushanim)
                end
                inst.AnimState:PushAnimation(anim, true)
            else
                inst.AnimState:PlayAnimation(anim, true)
            end
            

        end,
        
       events=
        {
            EventHandler("animover", function(inst) 
                if funny_idle_state and math.random() < .1 then
                    inst.sg:GoToState(funny_idle_state)                
                else
                    inst.sg:GoToState("idle")                                    
                end
            end),
        }, 

    })
end

    
CommonStates.AddSimpleState = function(states, name, anim, tags, finishstate)
    table.insert(states, State{
        name = name,
        tags = tags or {},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation(anim)
            inst.components.locomotor:StopMoving()            
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState(finishstate or "idle") end ),
        },        
    })    
end

CommonStates.AddSimpleActionState = function(states, name, anim, time, tags, finishstate)
    table.insert(states, State{
        name = name,
        
        tags = tags or {},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation(anim)
            inst.components.locomotor:StopMoving()            
        end,
        
        timeline=
        {
            TimeEvent(time, function(inst) inst:PerformBufferedAction() end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState(finishstate or "idle") end ),
        },        
    } )    
end

CommonStates.AddShortAction = function( states, name, anim, timeout )
    table.insert(states, State{
        name = "name",
        tags = {"doing"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation(anim)
            inst.sg:SetTimeout(timeout or 6*FRAMES)
        end,
        
        ontimeout= function(inst)
            doer:PerformBufferedAction()         
        end,
        
        events=
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end ),
        },
    })
end


local function get_loco_state(inst, override, default)
    local anim = default
    if override then
        anim = type(override) == "function" and override(inst) or override
    end
    return anim
end
local function fastRunTest(inst)
    if inst:HasTag("usefastrun") then
        return "_fast"
    else
        return ""
    end
end

CommonStates.AddRunStates = function(states, timelines, anims, softstop, enterexitfns)
   local startrun = State{
            name = "run_start",
            tags = {"moving", "running", "canrotate"},
            
            onenter = function(inst) 
                inst.components.locomotor:RunForward()
                inst.AnimState:PlayAnimation(get_loco_state(inst, anims and anims.startrun, "run_pre"))
                if enterexitfns and enterexitfns.startenter then
                    enterexitfns.startenter(inst)
                end                
            end,
            onexit = function(inst) 
                if enterexitfns and enterexitfns.startexit then
                    enterexitfns.startexit(inst)
                end
                inst.cleantransition = nil
            end,

            events=
            {   
                EventHandler("animover", function(inst) inst.cleantransition = true inst.sg:GoToState("run") end ),        
            },
            
        }
    

    local run = State{
            
            name = "run",
            tags = {"moving", "running", "canrotate"},
            
            onenter = function(inst)                 
                inst.components.locomotor:RunForward()
                inst.AnimState:PlayAnimation(get_loco_state(inst, anims and anims.run, "run_loop"..fastRunTest(inst) ))
                if enterexitfns and enterexitfns.enter then
                    enterexitfns.enter(inst)
                end                  
            end,
            onexit = function(inst)                 
                if enterexitfns and enterexitfns.loopexit then                    
                    enterexitfns.loopexit(inst)
                end
                inst.cleantransition = nil
            end,            
            
            events=
            {   
                EventHandler("animover", function(inst) inst.cleantransition = true  inst.sg:GoToState("run") end ),        
            },
            
            
        }
        
    local stoprun = State{
        
            name = "run_stop",
            tags = {"idle"},
            
            onenter = function(inst) 
                inst.components.locomotor:StopMoving()

                local should_softstop = (type(softstop) == "function" and softstop(inst)) or softstop

                if should_softstop then
                    inst.AnimState:PushAnimation(get_loco_state(inst, anims and anims.stoprun, "run_pst"))
                else
                    inst.AnimState:PlayAnimation(get_loco_state(inst, anims and anims.stoprun, "run_pst"))
                end
                if enterexitfns and enterexitfns.endenter then
                    enterexitfns.endenter(inst)
                end                   
            end,
            onexit = function(inst) 
                if enterexitfns and enterexitfns.endexit then
                    enterexitfns.endexit(inst)
                end
            end,             
            events=
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),        
            },
        }
        
    if timelines then
        startrun.timeline = timelines.starttimeline
        run.timeline = timelines.runtimeline
        stoprun.timeline = timelines.endtimeline
    end        

    table.insert(states, startrun)
    table.insert(states, run)
    table.insert(states, stoprun)
end

CommonStates.AddSimpleRunStates = function(states, anim, timelines)
    CommonStates.AddRunStates(states, timelines, { startrun = anim, run = anim, stoprun = anim } )
end


CommonStates.AddWalkStates = function(states, timelines, anims, softstop, enterexitfns)

    local startwalk = State{
            name = "walk_start",
            tags = {"moving", "canrotate"},

            onenter = function(inst) 

                inst.components.locomotor:WalkForward()
                inst.AnimState:PlayAnimation(get_loco_state(inst, anims and anims.startwalk, "walk_pre"))
                if enterexitfns and enterexitfns.startenter then
                    enterexitfns.startenter(inst)
                end
            end,

            onexit = function(inst) 
                if enterexitfns and enterexitfns.startexit then
                    enterexitfns.startexit(inst)
                end
            end,

            events =
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("walk") end ),        
            },
        }
        
    local walk = State{
            
            name = "walk",
            tags = {"moving", "canrotate"},
            
            onenter = function(inst) 
                local heavy = ""
                if inst:HasTag("heavy_walk") then
                    heavy = "heavy_"
                end            

                local alt = ""
                if inst.altstep then
                    alt = "_alt"
                end

                inst.components.locomotor:WalkForward()
                inst.AnimState:PlayAnimation(get_loco_state(inst, anims and anims.walk, heavy.."walk_loop"..alt))
                if enterexitfns and enterexitfns.loopenter then
                    enterexitfns.loopenter(inst)
                end                
            end,

            onexit = function(inst) 
                if enterexitfns and enterexitfns.loopexit then
                    enterexitfns.loopexit(inst)
                end
            end,

            events=
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("walk") end ),        
            },
        }        
    
    local endwalk = State{
            
            name = "walk_stop",
            tags = {"canrotate"},
            
            onenter = function(inst)            
                inst.components.locomotor:StopMoving()
                
                local should_softstop = (type(softstop) == "function" and softstop(inst)) or softstop

                if should_softstop then
                    inst.AnimState:PushAnimation(get_loco_state(inst, anims and anims.stopwalk, "walk_pst"), false)
				else
                    inst.AnimState:PlayAnimation(get_loco_state(inst, anims and anims.stopwalk, "walk_pst"))
				end
                if enterexitfns and enterexitfns.endenter then
                    enterexitfns.endenter(inst)
                end                  
            end,


            onexit = function(inst) 
                if enterexitfns and enterexitfns.endexit then
                    enterexitfns.endexit(inst)
                end
            end,            

            events=
            {
                EventHandler("animover", function(inst)
                    local should_softstop = (type(softstop) == "function" and softstop(inst)) or softstop

                    if not should_softstop then
                        inst.sg:GoToState("idle")
                    end
                end),
                EventHandler("animqueueover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },
        }
        
    if timelines then
        startwalk.timeline = timelines.starttimeline
        walk.timeline = timelines.walktimeline
        endwalk.timeline = timelines.endtimeline
    end
    
    table.insert(states, startwalk)    
    table.insert(states, walk)
    table.insert(states, endwalk)
end

CommonStates.AddSimpleWalkStates = function(states, anim, timelines)
    CommonStates.AddWalkStates(states, timelines, { startwalk = anim, walk = anim, stopwalk = anim }, true )
end

CommonStates.AddSleepStates = function(states, timelines, fns, anims)
    
    local startsleep = State{
            name = "sleep",
            tags = {"busy", "sleeping"},
            
            onenter = function(inst) 
                inst.components.locomotor:StopMoving()
                inst.AnimState:PlayAnimation((anims and anims.sleep_pre) or "sleep_pre")
                if fns and fns.onsleep then
					fns.onsleep(inst)
                end
            end,

            events=
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("sleeping") end ),        
                EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
            },
        }
        
    local sleep = State{
            
            name = "sleeping",
            tags = {"busy", "sleeping"},
            
            onenter = function(inst) 
                inst.AnimState:PlayAnimation((anims and anims.sleep_loop) or "sleep_loop")
            end,
            
            events=
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("sleeping") end ),        
                EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
            },
        }        
    
    local endsleep = State{
            
            name = "wake",
            tags = {"busy", "waking"},
            
            onenter = function(inst) 
                inst.components.locomotor:StopMoving()
                inst.AnimState:PlayAnimation((anims and anims.sleep_pst) or "sleep_pst")
                if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
                    inst.components.sleeper:WakeUp()
                end
                if fns and fns.onwake then
					fns.onwake(inst)
                end
                
            end,

            events=
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),        
            },
        }


    local forcesleep = State{
            name = "forcesleep",
            tags = {"busy", "sleeping"},

            onenter = function(inst)
                inst.components.locomotor:StopMoving()            
                inst.AnimState:PlayAnimation("sleep_loop", true)
            end
        }
        
    if timelines then
        startsleep.timeline = timelines.starttimeline
        sleep.timeline = timelines.sleeptimeline
        endsleep.timeline = timelines.waketimeline
    end
    
    table.insert(states, startsleep)    
    table.insert(states, sleep)
    table.insert(states, endsleep)
    table.insert(states, forcesleep)
end
local function onunfreeze(inst)
    inst.sg:GoToState(inst.sg.sg.states.hit ~= nil and "hit" or "idle")
end

local function onthaw(inst)
    inst.sg:GoToState("thaw")
end

local function onenterfrozenpre(inst)
    if inst.components.locomotor ~= nil then
        inst.components.locomotor:StopMoving()
    end
    inst.AnimState:PlayAnimation("frozen")
    inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
end

local function onenterfrozenpst(inst)
    --V2C: cuz... freezable component and SG need to match state,
    --     but messages to SG are queued, so it is not great when
    --     when freezable component tries to change state several
    --     times within one frame...
    if inst.components.freezable == nil then
        onunfreeze(inst)
    elseif inst.components.freezable:IsThawing() then
        onthaw(inst)
    elseif not inst.components.freezable:IsFrozen() then
        onunfreeze(inst)
    end
end

local function onenterfrozen(inst)
    onenterfrozenpre(inst)
    onenterfrozenpst(inst)
end

local function onexitfrozen(inst)
    inst.AnimState:ClearOverrideSymbol("swap_frozen")
end
-- new
local function onenterthawpre(inst)
    if inst.components.locomotor ~= nil then
        inst.components.locomotor:StopMoving()
    end
    inst.AnimState:PlayAnimation("frozen_loop_pst", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
end

local function onenterthawpst(inst)
    --V2C: cuz... freezable component and SG need to match state,
    --     but messages to SG are queued, so it is not great when
    --     when freezable component tries to change state several
    --     times within one frame...
    if inst.components.freezable == nil or not inst.components.freezable:IsFrozen() then
        onunfreeze(inst)
    end
end

local function onenterthaw(inst)
    onenterthawpre(inst)
    onenterthawpst(inst)
end

local function onexitthaw(inst)
    inst.SoundEmitter:KillSound("thawing")
    inst.AnimState:ClearOverrideSymbol("swap_frozen")
end

CommonStates.AddFrozenStates2 = function(states, onoverridesymbols, onclearsymbols)
    table.insert(states, State
    {
        name = "frozen",
        tags = { "busy", "frozen" },

        onenter = onoverridesymbols ~= nil and function(inst)
            onenterfrozenpre(inst)
            onoverridesymbols(inst)
            onenterfrozenpst(inst)
        end or onenterfrozen,

        events =
        {
            EventHandler("unfreeze", onunfreeze),
            EventHandler("onthaw", onthaw),
        },

        onexit = onclearsymbols ~= nil and function(inst)
            onexitfrozen(inst)
            onclearsymbols(inst)
        end or onexitfrozen,
    })

    table.insert(states, State
    {
        name = "thaw",
        tags = { "busy", "thawing" },

        onenter = onoverridesymbols ~= nil and function(inst)
            onenterthaw(inst)
            onoverridesymbols(inst)
        end or onenterthaw,

        events =
        {
            EventHandler("unfreeze", onunfreeze),
        },

        onexit = onclearsymbols ~= nil and function(inst)
            onexitthaw(inst)
            onclearsymbols(inst)
        end or onexitthaw,
    })
end

CommonStates.AddFrozenStates = function(states, timelines, anims)

    local frozen = State{
        name = "frozen",
        tags = {"busy", "frozen"},
        
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation((anims and anims.frozen) or "frozen", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
        end,
        
        onexit = function(inst)
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,
        
        events=
        {   
            EventHandler("onthaw", function(inst) inst.sg:GoToState("thaw") end ),        
        },
    }

    local thaw = State{
        name = "thaw",
        tags = {"busy", "thawing"},
        
        onenter = function(inst) 
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation((anims and anims.frozen_pst) or "frozen_loop_pst", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
        end,
        
        onexit = function(inst)
            inst.SoundEmitter:KillSound("thawing")
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,

        events =
        {   
            EventHandler("unfreeze", function(inst)
                if inst.sg.sg.states.hit then
                    inst.sg:GoToState("hit")
                else
                    inst.sg:GoToState("idle")
                end
            end ),
        },
    }

    if timelines then
        frozen.timeline = timelines.frozentimeline
    end
    table.insert(states, frozen)    
    table.insert(states, thaw)    
end

CommonStates.AddCombatStates = function(states, timelines, anims)
    local hit = State{
        name = "hit",
        tags = {"hit", "busy"},
        
        onenter = function(inst, cb)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            local hitanim = "hit"
            if anims and anims.hit then
                if type(anims.hit) == "function" then
                    hitanim = anims.hit(inst)
                else
                    hitanim = anims.hit
                end
            end
            inst.AnimState:PlayAnimation(hitanim)
            if inst.SoundEmitter and inst.sounds then
                if inst.sounds.hit then
                    inst.SoundEmitter:PlaySound(inst.sounds.hit)
                end
            end
        end,
        
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    }

    local attack = State{
        name = "attack",
        tags = {"attack", "busy"},
        
        onenter = function(inst, target)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation(anims and anims.attack or "atk")
            inst.sg.statemem.target = target
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    }

    local death = State{
        name = "death",  
        tags = {"busy"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation(anims and anims.death or "death")
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
			inst.Physics:ClearCollisionMask()
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
        end,
    }

    if timelines then
        hit.timeline = timelines.hittimeline
        attack.timeline = timelines.attacktimeline
        death.timeline = timelines.deathtimeline
    end
    
    table.insert(states, hit)    
    table.insert(states, attack)    
    table.insert(states, death)    
end

local function sleepexonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg.statemem.continuesleeping = true
        inst.sg:GoToState(inst.sg.mem.sleeping and "sleeping" or "wake")
    end
end

local function sleepingexonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg.statemem.continuesleeping = true
        inst.sg:GoToState("sleeping")
    end
end

local function wakeexonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg:GoToState(inst.sg.mem.sleeping and "sleep" or "idle")
    end
end

CommonStates.AddSleepExStates = function(states, timelines, fns)
    table.insert(states, State
    {
        name = "sleep",
        tags = { "busy", "sleeping", "nowake" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pre")
            if fns ~= nil and fns.onsleep ~= nil then
                fns.onsleep(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.starttimeline or nil,

        events =
        {
            EventHandler("animover", sleepexonanimover),
        },

        onexit = function(inst)
            if not inst.sg.statemem.continuesleeping and inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
            if fns ~= nil and fns.onexitsleep ~= nil then
                fns.onexitsleep(inst)
            end
        end,
    })

    table.insert(states, State
    {
        name = "sleeping",
        tags = { "busy", "sleeping" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_loop")
            if fns ~= nil and fns.onsleeping ~= nil then
                fns.onsleeping(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.sleeptimeline or nil,

        events =
        {
            EventHandler("animover", sleepingexonanimover),
        },

        onexit = function(inst)
            if not inst.sg.statemem.continuesleeping and inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
            if fns ~= nil and fns.onexitsleeping ~= nil then
                fns.onexitsleeping(inst)
            end
        end,
    })

    table.insert(states, State
    {
        name = "wake",
        tags = { "busy", "waking", "nosleep" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pst")
            if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
            if fns ~= nil and fns.onwake ~= nil then
                fns.onwake(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.waketimeline or nil,

        events =
        {
            EventHandler("animover", wakeexonanimover),
        },

        onexit = fns ~= nil and fns.onexitwake or nil,
    })
end