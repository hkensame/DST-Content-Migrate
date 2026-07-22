-- ==================== 移动状态：重物 / groggy / 跑步扩展 ====================

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

-- 覆写 locomote 事件：重物 / groggy 时走不同跑步动画
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
            else
                inst.sg:GoToState("walk_start")
            end
        end
    end))

-- 跑步起步（DST 风格）
AddStategraphState("wilson", State{
    name = "run_start_dst",
    tags = {"moving", "running", "canrotate"},

    onenter = function(inst)
        ConfigureRunState(inst)
        inst.components.locomotor:RunForward()
        inst.AnimState:PlayAnimation(GetRunStateAnim(inst).."_pre")
        inst.sg.mem.footsteps = (inst.sg.statemem.goose or inst.sg.statemem.goosegroggy_dst) and 4 or 0
    end,

    onupdate = function(inst)
        inst.components.locomotor:RunForward()
    end,

    events = {
        EventHandler("animover", function(inst) inst.sg:GoToState("run_dst") end),
    },

    timeline = {
        TimeEvent(1 * FRAMES, function(inst)
            if inst.sg.statemem.heavy then
                PlayFootstep(inst, nil, true)
                DoFoleySounds(inst)
            end
        end),

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
                splash.Transform:SetPosition(pos.x, pos.y, pos.z)
                splash.Transform:SetRotation(rot)
            end
        end),
    },

    onexit = function(inst)
    end,
})

-- 跑步循环（DST 风格）
AddStategraphState("wilson", State{
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
        inst.sg.mem.foosteps = 0
    end,

    onupdate = function(inst)
        inst.components.locomotor:RunForward()
        if inst.components.locomotor.timemoving >= TUNING.WILBUR_TIME_TO_RUN and inst:HasTag("monkey") then
            inst.sg:GoToState("run_monkey_start")
        end
    end,

    timeline = {
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
                splash.Transform:SetPosition(pos.x, pos.y, pos.z)
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
                splash.Transform:SetPosition(pos.x, pos.y, pos.z)
                splash.Transform:SetRotation(rot)
            end
            inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
            PlayFootstep(inst, inst.sg.mem.foosteps < 5 and 1 or .6)
            DoFoleySounds(inst)
        end),

        -- heavy lifting
        TimeEvent(11 * FRAMES, function(inst)
            if inst.sg.statemem.heavy then
                DoRunSounds(inst)
                DoFoleySounds(inst)
                if inst.sg.mem.footsteps > 3 then
                    inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                end
            elseif inst.sg.statemem.moose then
                DoMooseRunSounds(inst)
                DoFoleySounds(inst)
            elseif inst.sg.statemem.sandstorm or inst.sg.statemem.careful then
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
                    inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                end
            end
        end),
        -- groggy
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

    events = {
        EventHandler("animover", function(inst) inst.sg:GoToState("run_dst") end),
    },

    onexit = function(inst)
    end,
})
