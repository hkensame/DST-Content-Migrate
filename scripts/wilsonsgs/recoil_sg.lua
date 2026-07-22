-- ==================== 镐子反震：SGwilson 状态注入 ====================
-- 向 DS 的 wilson stategraph 注入 tooltooweak 事件处理和 mine_recoil 状态
-- 动画剪辑 pickaxe_recoil 由 player_actions_pickaxe_recoil.zip 提供

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
        if inst.components.playercontroller then
            inst.components.playercontroller:ShakeCamera(inst, "FULL", .4, .02, .15)
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
