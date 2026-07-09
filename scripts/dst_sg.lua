
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local EN = GetModConfigData("language")
--[[
local dst_build =  --改，不用这个
{
 "wilson",
 "willow",
 "wendy",
 --"wolfgang",
 --"wolfgang_mighty",
 --"wolfgang_skinny",
 "woodie",
 "wickerbottom",
 "wx78",
 "wes",
 "waxwell",
 "wathgrithr",
 "webber",
 "walani",
 "warly",
 --"wilbur",
 "woodlegs",
}
--]]
----------------<克眼相关>----------------
if GLOBAL.PLATFORM == "Android" then 
    GLOBAL.SJ = true 
else 
    GLOBAL.SJ = false 
end --手机判定

--触摸动作
--ACTIONS.ACTIVATE.priority = 2

  --local TOUCH = Action({},2) --电脑版
  local TOUCH = SJ and Action(2) or Action({},2)
  TOUCH.str = EN and "touch" or "触摸"
  TOUCH.id = "TOUCH"
  TOUCH.fn = function(act)
    if act.target.components.activatable_dst then
        act.target.components.activatable_dst:DoActivate(act.doer)
        return true
    end
  end
  TOUCH.strfn = function(act)
    if act.target and act.target:HasTag("moon_device") then
      return "激活"
    end
  end

  AddAction(TOUCH)
  AddStategraphActionHandler("wilson", ActionHandler(TOUCH, "give"))

  --local REPAIR2 = Action({},2) --电脑版
  local REPAIR2 =  SJ and Action(2) or Action({},2)
  REPAIR2.str = EN and "repair" or "修复"
  REPAIR2.id = "REPAIR2"
  REPAIR2.fn = function(act)
    local material = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if act.target and act.target.components.repairable and material and material.components.repairer then
      return act.target.components.repairable:Repair(act.doer, material)
    end
  end
  AddAction(REPAIR2)
  AddStategraphActionHandler("wilson", ActionHandler(REPAIR2, "dolongaction"))

  local BATHBOMB =  SJ and Action(2) or Action({},2)
  BATHBOMB.str = EN and "Toss In" or "投入"
  BATHBOMB.id = "BATHBOMB"
  BATHBOMB.fn = function(act)
    local bathbombable = (act.target ~= nil and act.target.components.bathbombable) or nil
    local bathbomb = (act.invobject ~= nil and act.invobject.components.bathbomb) or nil

	if bathbomb ~= nil and bathbombable ~= nil and bathbombable.can_be_bathbombed then
	    bathbombable:OnBathBombed(act.invobject, act.doer)
		act.doer.components.inventory:RemoveItem(act.invobject):Remove()
		return true
    end
  end

  AddAction(BATHBOMB)
  AddStategraphActionHandler("wilson", ActionHandler(BATHBOMB, "give"))


--给盾牌单独写个sg
AddStategraphPostInit('wilson', function(sg)
	local event_doattack = sg.events["doattack"]
	local event_doattack_oldfn = event_doattack.fn
	event_doattack.fn = function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") and not inst.sg:HasStateTag("sneeze") then
            local weapon = inst.components.combat and inst.components.combat:GetWeapon()
            if weapon and weapon:HasTag("toolpunch") then 
                inst.sg:GoToState("attack_punch") --触发的sg
            else
                return event_doattack_oldfn(inst, data)
            end
        end
	end
end)

AddStategraphState( "wilson",
    State{
        name = "attack_punch",
        tags = {"attack", "notalking", "abouttoattack", "busy"},
        
        onenter = function(inst)

            inst.AnimState:PlayAnimation("toolpunch")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            
            if inst.components.combat.target then
                inst.components.combat:BattleCry()
                if inst.components.combat.target and inst.components.combat.target:IsValid() then
                    inst:FacePoint(Point(inst.components.combat.target.Transform:GetWorldPosition()))
                end
            end

            inst.sg.statemem.target = inst.components.combat.target
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            
        end,
        
        timeline=
        {
            TimeEvent(8*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
            TimeEvent(12*FRAMES, function(inst) 
				inst.sg:RemoveStateTag("busy")
			end),				
            TimeEvent(13*FRAMES, function(inst)
					inst.sg:RemoveStateTag("attack")
            end),
        },
        
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },
    })

----------------<走得慢相关>----------------
local function DoEquipmentFoleySounds(inst)
	for k,v in pairs(inst.components.inventory.equipslots) do
		if v.components.inventoryitem and v.components.inventoryitem.foleysound then
			inst.SoundEmitter:PlaySound(v.components.inventoryitem.foleysound)
		end
	end
end

local function DoFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
    if inst.prefab == "wx78" then
        inst.SoundEmitter:PlaySound("dontstarve/movement/foley/wx78")
    end
end

local DoRunSounds = function(inst)
    if inst.sg.mem.footsteps > 3 then
        PlayFootstep(inst, .6, true)
    else
        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
        PlayFootstep(inst, 1, true)
    end
end

local function ConfigureRunState(inst)
  local equippedBody = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if equippedBody and equippedBody:HasTag("heavy") then
        inst.sg.statemem.heavy = true
    elseif inst:HasTag("groggy_dst") then
        inst.sg.statemem.groggy_dst = true
    else
        inst.sg.statemem.normal = true
    end
end

local function GetRunStateAnim(inst)
    return (inst.sg.statemem.heavy and "heavy_walk")
        or (inst.sg.statemem.groggy_dst and "idle_walk")
        or "run"
end

AddStategraphEvent("wilson", 
    EventHandler("locomote", function(inst)
        ConfigureRunState(inst)
        local is_attacking = inst.sg:HasStateTag("attack")
        local is_busy = inst.sg:HasStateTag("busy")
        if is_attacking or is_busy then return end
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()

        if is_moving and not should_move then
            if is_running then
                inst.sg:GoToState("run_stop")
            else
                inst.sg:GoToState("walk_stop")
            end
        elseif (not is_moving and should_move) or (is_moving and should_move and is_running ~= should_run) then
            if should_run then
                inst.sg:GoToState((inst.sg.statemem.heavy or inst.sg.statemem.groggy_dst) and "run_start_dst" or "run_start")
                --inst.sg:GoToState("run_start_dst")
            else
                inst.sg:GoToState("walk_start")
            end
        end 
    end))

AddStategraphState( "wilson",
    State{
        name = "run_start_dst",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst)
            ConfigureRunState(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation(GetRunStateAnim(inst).."_pre")
            inst.sg.mem.footsteps = (inst.sg.statemem.goose or inst.sg.statemem.goosegroggy_dst) and 4 or 0
            --if table.contains(dst_build, inst.prefab) then
              --inst.AnimState:SetBuild(inst.prefab.."_dst")
            --end
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("run_dst") end ),        
        },
        
        timeline=
        {
        
            --heavy lifting 背大理石
            TimeEvent(1 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    PlayFootstep(inst, nil, true)
                    DoFoleySounds(inst)
                end
            end),
            ----

            TimeEvent(4*FRAMES, function(inst)
                PlayFootstep(inst)
                DoFoleySounds(inst)
                local pos = inst:GetPosition()
                if GetWorld().Flooding and GetWorld().Flooding:OnFlood(pos.x, 0, pos.z) then 
                    local rot = inst.Transform:GetRotation()
                    local splash = SpawnPrefab("splash_footstep")
                    
                    local CameraRight = TheCamera:GetRightVec()
                    local CameraDown = TheCamera:GetDownVec()
                    local displacement = CameraRight:Cross(CameraDown) * .15
                    local pos = pos - displacement 
                    splash.Transform:SetPosition(pos.x,pos.y, pos.z)
                    splash.Transform:SetRotation(rot)
            
                end 
            end),
        },

        onexit = function(inst)
            --if table.contains(dst_build, inst.prefab) then
              --inst.AnimState:SetBuild(inst.prefab)
            --end
        end,
    })

AddStategraphState( "wilson",
    State{
        
        name = "run_dst",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst) 
            ConfigureRunState(inst)
            inst.components.locomotor:RunForward()
            local anim = GetRunStateAnim(inst)
            if anim == "run" then
                anim = "run_loop"
            elseif anim == "run_woby" then
                anim = "run_woby_loop"
            end
            if not inst.AnimState:IsCurrentAnimation(anim) then
                inst.AnimState:PlayAnimation(anim, true)
            end
            --if table.contains(dst_build, inst.prefab) then
              --inst.AnimState:SetBuild(inst.prefab.."_dst")
            --end
            inst.sg.mem.foosteps = 0
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
            if inst.components.locomotor.timemoving >= TUNING.WILBUR_TIME_TO_RUN and inst:HasTag("monkey") then
                inst.sg:GoToState("run_monkey_start")
            end
        end,

        timeline=
        {
            TimeEvent(7*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                DoFoleySounds(inst)
                local pos = inst:GetPosition()
                if GetWorld().Flooding and GetWorld().Flooding:OnFlood(pos.x, 0, pos.z) then 
                    local rot = inst.Transform:GetRotation()
                    local splash = SpawnPrefab("splash_footstep")
                    local CameraRight = TheCamera:GetRightVec()
                    local CameraDown = TheCamera:GetDownVec()
                    local displacement = CameraRight:Cross(CameraDown) * .15
                    local pos = pos - displacement 
                    splash.Transform:SetPosition(pos.x,pos.y, pos.z)
                    splash.Transform:SetRotation(rot)
                end 
            end),
            TimeEvent(15*FRAMES, function(inst)
                local pos = inst:GetPosition()
                if GetWorld().Flooding and GetWorld().Flooding:OnFlood(pos.x, 0, pos.z) then 
                    local rot = inst.Transform:GetRotation()
                    local splash = SpawnPrefab("splash_footstep")
                  local CameraRight = TheCamera:GetRightVec()
                    local CameraDown = TheCamera:GetDownVec()
                    local displacement = CameraRight:Cross(CameraDown) * .15
                    local pos = pos - displacement 
                    splash.Transform:SetPosition(pos.x,pos.y, pos.z)
                    splash.Transform:SetRotation(rot)
                end 
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
                PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
                DoFoleySounds(inst)
            end),
            
            --heavy lifting 背大理石
            TimeEvent(11 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                    if inst.sg.mem.footsteps > 3 then
                        --normally stops at > 3, but heavy needs to keep count
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                    end
                elseif inst.sg.statemem.moose then
                    DoMooseRunSounds(inst)
                    DoFoleySounds(inst)
                elseif inst.sg.statemem.sandstorm
                    or inst.sg.statemem.careful then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),
            TimeEvent(36 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                    if inst.sg.mem.footsteps > 12 then
                        inst.sg.mem.footsteps = math.random(4, 6)
                        inst:PushEvent("encumberedwalking")
                    elseif inst.sg.mem.footsteps > 3 then
                        --normally stops at > 3, but heavy needs to keep count
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                    end
                end
            end),
            ------
            --groggy
            TimeEvent(1 * FRAMES, function(inst)
                if inst.sg.statemem.groggy_dst then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.groggy_dst then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),

        },

        events=
        {   
            EventHandler("animover", function(inst) inst.sg:GoToState("run_dst") end ),        
        },

        onexit = function(inst)
            --if table.contains(dst_build, inst.prefab) then
              --inst.AnimState:SetBuild(inst.prefab)
            --end
        end,

    })

AddStategraphState( "wilson",
    State{
        name = "yawn",
        tags = { "busy", "yawn", "pausepredict" },

        onenter = function(inst, data)
            --ForceStopHeavyLifting(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            if data ~= nil and
                data.grogginess ~= nil and
                data.grogginess > 0 and
                inst.components.grogginess_dst ~= nil then
                --Because we have the yawn state tag, we will not get
                --knocked out no matter what our grogginess level is.
                inst.sg.statemem.groggy = true
                inst.sg.statemem.knockoutduration = data.knockoutduration
                inst.components.grogginess_dst:AddGrogginess(data.grogginess, data.knockoutduration)
            end

            inst.AnimState:PlayAnimation("yawn")
        end,

        timeline =
        {
            TimeEvent(.1, function(inst)
              if inst.components.rider then
                local mount = inst.components.rider:GetMount()
                if mount ~= nil and mount.sounds ~= nil and mount.sounds.yell ~= nil then
                    inst.SoundEmitter:PlaySound(mount.sounds.yell)
                end
              end
            end),
            TimeEvent(15 * FRAMES, function(inst)
              if inst.yawnsoundoverride ~= nil then
                inst.SoundEmitter:PlaySound(inst.yawnsoundoverride)
              elseif not inst:HasTag("mime") then
                inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/yawn")
              end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:RemoveStateTag("yawn")
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.groggy and
                not inst.sg:HasStateTag("yawn") and
                inst.components.grogginess_dst ~= nil then
                --Add a little grogginess to see if it triggers
                --knock out now that we don't have the yawn tag
                inst.components.grogginess_dst:AddGrogginess(.01, inst.sg.statemem.knockoutduration)
            end
        end,
    })

--给食物buff加的效果
AddStategraphEvent("wilson", 
    EventHandler("attacked", function(inst, data)
      if not inst.components.health:IsDead() then
        if (data.attacker and (data.attacker:HasTag("insect") or data.attacker:HasTag("twister"))) or inst.sg:HasStateTag("not_hit_stunned") then
                local is_idle = inst.sg:HasStateTag("idle")
                if not is_idle then
                    -- avoid stunlock when attacked by bees/mosquitos
                    -- don't go to full hit state, just play sounds

                    inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")        
                    
                    if inst.prefab ~= "wes" then
                        local sound_name = inst.soundsname or inst.prefab
                        local path = inst.talker_path_override or "dontstarve/characters/"
                        local equippedHat = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                        if equippedHat and equippedHat:HasTag("muffler") then
                            inst.SoundEmitter:PlaySound(path..sound_name.."/gasmask_hurt")
                        else
                            local sound_event = path..sound_name.."/hurt"
                            inst.SoundEmitter:PlaySound(inst.hurtsoundoverride or sound_event)
                        end
                    end
                    return
                end
        end
            if not inst:HasTag("not_hit_stunned") then
                if inst.components.pinnable and inst.sg:HasStateTag("pinned") then
                    inst.sg:GoToState("pinned_hit")            
                elseif inst.sg:HasStateTag("shell") then
                    inst.sg:GoToState("shell_hit")
                else
                    if data.stimuli and data.stimuli == "electric" and not inst.components.inventory:IsInsulated() then
                        inst.sg:GoToState("electrocute")
                    else
                        inst.sg:GoToState("hit")
                    end
                end
            end
      end
 end))
