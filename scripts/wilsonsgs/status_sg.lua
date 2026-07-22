-- ==================== 状态效果：打哈欠 / 受击扩展 ====================

-- 打哈欠状态（grogginess 系统）
AddStategraphState("wilson", State{
    name = "yawn",
    tags = { "busy", "yawn", "pausepredict" },

    onenter = function(inst, data)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        if data ~= nil and
            data.grogginess ~= nil and
            data.grogginess > 0 and
            inst.components.grogginess_dst ~= nil then
            inst.sg.statemem.groggy = true
            inst.sg.statemem.knockoutduration = data.knockoutduration
            inst.components.grogginess_dst:AddGrogginess(data.grogginess, data.knockoutduration)
        end

        inst.AnimState:PlayAnimation("yawn")
    end,

    timeline = {
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

    events = {
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
            inst.components.grogginess_dst:AddGrogginess(.01, inst.sg.statemem.knockoutduration)
        end
    end,
})

-- 受击事件扩展：昆虫攻击不硬直
AddStategraphEvent("wilson",
    EventHandler("attacked", function(inst, data)
      if not inst.components.health:IsDead() then
        if (data.attacker and (data.attacker:HasTag("insect") or data.attacker:HasTag("twister"))) or inst.sg:HasStateTag("not_hit_stunned") then
                local is_idle = inst.sg:HasStateTag("idle")
                if not is_idle then
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
