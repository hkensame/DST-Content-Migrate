-- ==================== 镐子反震：SGwilson 状态注入 ====================
-- 向 DS 的 wilson stategraph 注入 tooltooweak 事件处理和 mine_recoil 状态
-- 动画剪辑 pickaxe_recoil 由 player_actions_pickaxe_recoil.zip 提供

-- ==================== 击飞 knockback 状态注入 ====================
-- 动画剪辑 knockback_high 由 player_attacks_recoil.zip 提供
-- 动画剪辑 buck_pst 由 DS 原生提供

-- DS 兼容性：FrameEvent 是 DST 专属，DS 用 TimeEvent 替代
local _TimeEvent = rawget(_G, "TimeEvent")
local _FRAMES = rawget(_G, "FRAMES")
local FrameEvent = rawget(_G, "FrameEvent") or (_TimeEvent ~= nil and _FRAMES ~= nil
    and function(frame, fn) return _TimeEvent(frame * _FRAMES, fn) end)
    or function() end

-- ==================== 镐子反震 ====================

-- 事件监听：收到 "tooltooweak" 后切换到反震状态
AddStategraphEvent("wilson", EventHandler("tooltooweak", function(inst, data)
    if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
        inst.sg:GoToState("mine_recoil", data)
    end
end))

-- 反震状态：工具弹开 + 角色后退
AddStategraphState("wilson", State{
    name = "mine_recoil",
    tags = { "busy" },

    onenter = function(inst, data)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()
        inst.AnimState:PlayAnimation("pickaxe_recoil")
        if data ~= nil and data.target ~= nil and data.target:IsValid() then
            SpawnPrefab("impact").Transform:SetPosition(data.target:GetPosition():Get())
        end
        if inst.components.playercontroller and inst.components.playercontroller.ShakeCamera then
            inst.components.playercontroller:ShakeCamera(inst, "FULL", .4, .02, .15, 20)
        end
        inst.Physics:SetMotorVel(-6, 0, 0)
    end,

    onupdate = function(inst)
        if inst.sg.statemem.speed ~= nil then
            inst.Physics:SetMotorVel(inst.sg.statemem.speed, 0, 0)
            inst.sg.statemem.speed = inst.sg.statemem.speed * 0.75
        end
    end,

    timeline = {
        FrameEvent(4, function(inst)
            inst.sg.statemem.speed = -3
        end),
    },

    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },
})

-- ==================== 击飞 knockback ====================

-- 事件监听：收到 "knockback" 后切换到击飞状态
AddStategraphEvent("wilson", EventHandler("knockback", function(inst, data)
    if not inst.components.health:IsDead() then
        inst.sg:GoToState("knockback", data)
    end
end))

-- 击飞状态：朝击飞源的反方向弹开
AddStategraphState("wilson", State{
    name = "knockback",
    tags = { "knockback", "busy", "nointerrupt", "jumping" },

    onenter = function(inst, data)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()
        inst.AnimState:PlayAnimation("knockback_high")

        if data ~= nil and data.knocker ~= nil and data.knocker:IsValid() then
            local x, y, z = data.knocker.Transform:GetWorldPosition()
            local distsq = inst:GetDistanceSqToInst(data.knocker)
            local rot = inst.Transform:GetRotation()
            local rot1 = inst:GetAngleToPoint(x, y, z)
            local drot = math.abs(rot - rot1)
            while drot > 180 do
                drot = math.abs(drot - 360)
            end
            local rangesq = (data.radius or 10) * (data.radius or 10)
            local k = distsq < rangesq and 0.3 * distsq / rangesq - 1 or -0.7
            local speed = (data.strengthmult or 1) * 12 * k
            inst.sg.statemem.speed = speed
            inst.sg.statemem.dspeed = 0
            if drot > 90 then
                inst.sg.statemem.reverse = true
                inst.Transform:SetRotation(rot1 + 180)
                inst.Physics:SetMotorVel(-speed, 0, 0)
            else
                inst.Transform:SetRotation(rot1)
                inst.Physics:SetMotorVel(speed, 0, 0)
            end
        end
    end,

    onupdate = function(inst)
        if inst.sg.statemem.speed ~= nil then
            inst.sg.statemem.speed = inst.sg.statemem.speed + inst.sg.statemem.dspeed
            if inst.sg.statemem.speed < 0 then
                inst.sg.statemem.dspeed = inst.sg.statemem.dspeed + 0.075
                inst.Physics:SetMotorVel(
                    inst.sg.statemem.reverse and -inst.sg.statemem.speed or inst.sg.statemem.speed, 0, 0)
            else
                inst.sg.statemem.speed = nil
                inst.sg.statemem.dspeed = nil
                inst.Physics:Stop()
            end
        end
    end,

    timeline = {
        FrameEvent(10, function(inst)
            inst.sg:RemoveStateTag("nointerrupt")
            inst.sg:RemoveStateTag("jumping")
        end),
    },

    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("knockback_pst")
            end
        end),
    },

    onexit = function(inst)
        if inst.sg.statemem.speed ~= nil then
            inst.Physics:Stop()
        end
    end,
})

-- 击飞恢复状态：落地缓冲
AddStategraphState("wilson", State{
    name = "knockback_pst",
    tags = { "knockback", "busy", "nomorph", "nodangle" },

    onenter = function(inst)
        inst.AnimState:PlayAnimation("buck_pst")
    end,

    timeline = {
        FrameEvent(8, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end),
    },

    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },
})
