-- 月辔状态图
-- 移植自 DST，适配 DS
-- 大幅简化：移除碎片系统、portal生成、gestalt捕获、侵蚀动画

require("stategraphs/commonstates")

local events =
{
    EventHandler("doattack", function(inst, data)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("devour", data and data.target)
        end
    end),

    EventHandler("attacked", function(inst, data)
        if not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("caninterrupt") then
            inst.sg:GoToState("hit")
        end
    end),

    EventHandler("minhealth", function(inst)
        if not inst.sg:HasStateTag("debris") then
            inst.sg:GoToState("melt")
        end
    end),

    EventHandler("lunar_grazer_despawn", function(inst, data)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("melt")
        end
    end),
}

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst.AnimState:IsCurrentAnimation("idle") then
                inst.AnimState:PlayAnimation("idle", true)
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,
        ontimeout = function(inst)
            inst.sg.statemem.idle = true
            inst.sg:GoToState("idle")
        end,
        events =
        {
            EventHandler("locomote", function(inst)
                if inst.components.locomotor:WantsToMoveForward() then
                    inst.sg:GoToState("walk_start")
                end
            end),
        },
    },

    State{
        name = "walk_start",
        tags = { "moving", "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_pre")
        end,
        events =
        {
            EventHandler("locomote", function(inst)
                if not inst.components.locomotor:WantsToMoveForward() then
                    inst.sg.statemem.stop = true
                end
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(inst.sg.statemem.stop and "walk_stop" or "walk")
                end
            end),
        },
    },

    State{
        name = "walk",
        tags = { "moving", "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_loop")
        end,
        events =
        {
            EventHandler("locomote", function(inst)
                if not inst.components.locomotor:WantsToMoveForward() then
                    inst.sg.statemem.stop = true
                end
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(inst.sg.statemem.stop and "walk_stop" or "walk")
                end
            end),
        },
    },

    State{
        name = "walk_stop",
        tags = { "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_pst")
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "hit",
        tags = { "hit", "busy" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hit")
        end,
        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst)
                if inst.components.health.currenthealth < (TUNING.LUNAR_GRAZER_MELT_HEALTH or 30) then
                    inst.sg:GoToState("melt")
                end
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "devour",
        tags = { "attack", "busy" },
        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("devour")
            if target ~= nil and target:IsValid() then
                inst.sg.statemem.target = target
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
        end,
        timeline =
        {
            TimeEvent(12 * FRAMES, function(inst)
                inst.components.combat:StartAttack()
            end),
            TimeEvent(32 * FRAMES, function(inst)
                local target = inst.sg.statemem.target or inst.components.combat.target
                if inst.components.combat:CanHitTarget(target) then
                    inst.components.combat:DoAttack(target)
                end
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "melt",
        tags = { "busy", "nointerrupt" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("despawn_fall")
            inst.components.locomotor:StopMoving()
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("dissipated")
                end
            end),
        },
    },

    State{
        name = "dissipated",
        tags = { "busy", "debris" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.Physics:SetActive(false)
            inst.AnimState:PlayAnimation("despawn_fall_pst_ground")
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
            inst.AnimState:SetSortOrder(3)
            -- Start health regen
            inst.components.health:StartRegen(TUNING.LUNAR_GRAZER_HEALTH_REGEN or 2, 1)
            inst.sg:SetTimeout(10) -- respawn after 10 seconds
        end,
        timeline =
        {
            TimeEvent(1 * FRAMES, function(inst)
                inst:AddTag("NOCLICK")
            end),
        },
        events =
        {
            EventHandler("lunar_grazer_respawn", function(inst)
                inst.sg.statemem.spawn = true
                inst.sg:GoToState("respawn")
            end),
        },
        ontimeout = function(inst)
            inst.sg.statemem.spawn = true
            inst.sg:GoToState("respawn")
        end,
        onexit = function(inst)
            if not inst.sg.statemem.spawn then
                inst.components.health:StopRegen()
            end
        end,
    },

    State{
        name = "respawn",
        tags = { "busy", "noattack", "temp_invincible" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("spawn")
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.BillBoard or ANIM_ORIENTATION.Default or 0)
            inst.AnimState:SetLayer(LAYER_WORLD)
            inst.AnimState:SetSortOrder(0)
            inst:RemoveTag("NOCLICK")
            inst.components.health:StopRegen()
            -- 复活时恢复满血（修复复活后只有22血的bug）
            inst.components.health:DoDelta(inst.components.health.maxhealth - inst.components.health.currenthealth)
        end,
        timeline =
        {
            TimeEvent(90 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("noattack")
                inst.sg:RemoveStateTag("temp_invincible")
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
}

return StateGraph("lunar_grazer", states, events, "idle")
