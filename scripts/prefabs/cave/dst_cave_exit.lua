-- DST 洞穴自定义出口（测试用）
-- 不管当前在哪个层级，直接回到地表

local assets =
{
    Asset("ANIM", "anim/cave/dst_cave_exit_rope.zip"),
}

local function GetVerb(inst)
    return STRINGS.ACTIONS.ACTIVATE.CLIMB
end

local function onnear(inst)
    inst.AnimState:PlayAnimation("down")
    inst.AnimState:PushAnimation("idle_loop", true)
    inst.SoundEmitter:PlaySound("dontstarve/cave/rope_down")
end

local function onfar(inst)
    inst.AnimState:PlayAnimation("up")
    inst.SoundEmitter:PlaySound("dontstarve/cave/rope_up")
end

local function OnActivate(inst)
    SetPause(true)

    local function head_upwards()
        SaveGameIndex:GetSaveFollowers(GetPlayer())

        local function onsaved()
            SetPause(false)
            StartNextInstance({reset_action=RESET_ACTION.LOAD_SLOT, save_slot = SaveGameIndex:GetCurrentSaveSlot()}, true)
        end

        -- 直接回到地表（不检查层级）
        SaveGameIndex:SaveCurrent(function() SaveGameIndex:EnterWorld("survival", onsaved) end, "ascend", SaveGameIndex:GetCurrentCaveNum())
    end

    GetPlayer().HUD:Hide()
    TheFrontEnd:Fade(false, 2, function() head_upwards() end)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("cave_open2.tex")

    inst.AnimState:SetBank("dst_cave_exit_rope")
    inst.AnimState:SetBuild("dst_cave_exit_rope")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(5, 7)
    inst.components.playerprox:SetOnPlayerFar(onfar)
    inst.components.playerprox:SetOnPlayerNear(onnear)

    inst:AddComponent("inspectable")

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.inactive = true
    inst.components.activatable.getverb = GetVerb
    inst.components.activatable.quickaction = true

    return inst
end

return Prefab("dst_cave_exit", fn, assets)
