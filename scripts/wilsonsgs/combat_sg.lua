-- ==================== 战斗状态：拳套攻击 ====================

-- 覆写 doattack 事件，支持 toolpunch 标签武器走独立攻击状态
AddStategraphPostInit('wilson', function(sg)
    local event_doattack = sg.events["doattack"]
    local event_doattack_oldfn = event_doattack.fn
    event_doattack.fn = function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") and not inst.sg:HasStateTag("sneeze") then
            local weapon = inst.components.combat and inst.components.combat:GetWeapon()
            if weapon and weapon:HasTag("toolpunch") then
                inst.sg:GoToState("attack_punch")
            else
                return event_doattack_oldfn(inst, data)
            end
        end
    end
end)

-- 拳套攻击状态
AddStategraphState("wilson", State{
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

    timeline = {
        TimeEvent(8*FRAMES, function(inst)
            inst.components.combat:DoAttack(inst.sg.statemem.target)
            inst.sg:RemoveStateTag("abouttoattack")
        end),
        TimeEvent(12*FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
        end),
        TimeEvent(13*FRAMES, function(inst)
            inst.sg:RemoveStateTag("attack")
        end),
    },

    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },
})
