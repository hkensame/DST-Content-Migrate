-- ==================== 精神控制：SGwilson 状态注入 ====================
-- 向 DS 的 wilson stategraph 注入 mindcontrolled 事件和状态
-- 动画文件（mindcontrol_pre/loop/pst）若未移植也不会崩溃，
-- 角色只是不会播放特定动画（控制器已被禁用，不影响功能）

-- 事件监听：收到 "mindcontrolled" 后切换到受控状态
AddStategraphEvent("wilson", EventHandler("mindcontrolled", function(inst)
    if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
        inst.sg:GoToState("mindcontrolled")
    end
end))

-- 受控入场
AddStategraphState("wilson", State{
    name = "mindcontrolled",
    tags = { "busy", "nomorph", "nodangle" },

    onenter = function(inst)
        -- 锁定玩家控制
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:Enable(false)
        end
        inst.components.inventory:Hide()
        inst:PushEvent("ms_closepopups")

        -- 停止移动，清除缓存操作
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        -- 播放动画（若有骑乘坐骑先下坐骑）
        if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
            inst.sg:AddStateTag("dismounting")
            inst.AnimState:PlayAnimation("fall_off")
            inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")
        else
            inst.AnimState:PlayAnimation("mindcontrol_pre")
        end
    end,

    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                if inst.sg:HasStateTag("dismounting") then
                    inst.sg:RemoveStateTag("dismounting")
                    if inst.components.rider ~= nil then
                        inst.components.rider:ActualDismount()
                    end
                    inst.AnimState:PlayAnimation("mindcontrol_pre")
                else
                    inst.sg:GoToState("mindcontrolled_loop")
                end
            end
        end),
    },

    onexit = function(inst)
        if inst.sg:HasStateTag("dismounting") then
            if inst.components.rider ~= nil then
                inst.components.rider:ActualDismount()
            end
        end
        -- 若未进入 loop（被打断），恢复控制
        if inst.sg.statemem.mindcontrolled == nil then
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
            inst.components.inventory:Show()
        end
    end,
})

-- 受控循环：保持锁定，等待倒计时
AddStategraphState("wilson", State{
    name = "mindcontrolled_loop",
    tags = { "busy", "nomorph", "nodangle" },

    onenter = function(inst)
        if not inst.AnimState:IsCurrentAnimation("mindcontrol_loop") then
            inst.AnimState:PlayAnimation("mindcontrol_loop", true)
        end
        inst.sg:SetTimeout(3 * FRAMES)
    end,

    events = {
        EventHandler("mindcontrolled", function(inst)
            -- debuff 延长时再次进入循环
            inst.sg.statemem.mindcontrolled = true
            inst.sg:GoToState("mindcontrolled_loop")
        end),
    },

    ontimeout = function(inst)
        inst.sg:GoToState("mindcontrolled_pst")
    end,

    onexit = function(inst)
        if not inst.sg.statemem.mindcontrolled then
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
            inst.components.inventory:Show()
        end
    end,
})

-- 受控退出：恢复控制
AddStategraphState("wilson", State{
    name = "mindcontrolled_pst",
    tags = { "busy", "nomorph", "nodangle" },

    onenter = function(inst)
        inst.AnimState:PlayAnimation("mindcontrol_pst")
        inst.sg:SetTimeout(6 * FRAMES)
    end,

    ontimeout = function(inst)
        -- 恢复控制
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:Enable(true)
        end
        inst.components.inventory:Show()
        inst.sg:GoToState("idle", true)
    end,
})
