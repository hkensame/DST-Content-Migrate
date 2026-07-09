-- DST 风格洞穴入口（测试用）
-- 进入时硬编码 level=3，指向 levellist[LEVELTYPE.CAVE][3] = DST_CAVE

local assets =
{
    Asset("ANIM", "anim/cave/dst_cave_entrance.zip"),
    Asset("IMAGE", "images/cave_open.tex"),
    Asset("ATLAS", "images/cave_open.xml"),
    Asset("IMAGE", "images/cave_closed.tex"),
    Asset("ATLAS", "images/cave_closed.xml"),
}

local function GetVerb(inst)
    return STRINGS.ACTIONS.ACTIVATE.SPELUNK
end

local function OnActivate(inst)
    if not IsGamePurchased() then return end

    SetPause(true)

    local function go_spelunking()
        SaveGameIndex:GetSaveFollowers(GetPlayer())

        local function onsaved()
            SetPause(false)
            StartNextInstance({reset_action=RESET_ACTION.LOAD_SLOT, save_slot = SaveGameIndex:GetCurrentSaveSlot()}, true)
        end

        local function doenter()
            -- 直接进入第3层洞穴模板（DST_CAVE）
            SaveGameIndex:SaveCurrent(function() SaveGameIndex:EnterWorld("cave", onsaved, nil, inst.cavenum, 3) end, "descend", inst.cavenum)
        end

        if not inst.cavenum then
            if GetWorld().prefab == "cave" then
                inst.cavenum = SaveGameIndex:GetCurrentCaveNum()
                doenter()
            else
                inst.cavenum = SaveGameIndex:GetNumCaves() + 1
                SaveGameIndex:AddCave(nil, doenter)
            end
        else
            doenter()
        end
    end

    GetPlayer().HUD:Hide()
    TheFrontEnd:Fade(false, 2, function() go_spelunking() end)
end

local function Open(inst)
    -- DST 原版：挖开后切换到 "no_access" 动画，并设为背景层
    -- 改用 open 循环帧代替 no_access（DST 原版 no_access 贴图异常）
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:PushAnimation("open", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst:RemoveComponent("workable")
    inst.open = true

    inst.MiniMapEntity:SetIcon("cave_open.tex")

    inst:DoTaskInTime(2, function()
        if IsGamePurchased() then
            inst:AddComponent("activatable")
            inst.components.activatable.OnActivate = OnActivate
            inst.components.activatable.inactive = true
            inst.components.activatable.getverb = GetVerb
            inst.components.activatable.quickaction = true
        end
    end)
end

local function OnWork(inst, worker, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(Point(inst.Transform:GetWorldPosition()))
        Open(inst)
    else
        if workleft < TUNING.ROCKS_MINE * (1/3) then
            inst.AnimState:PlayAnimation("low")
        elseif workleft < TUNING.ROCKS_MINE * (2/3) then
            inst.AnimState:PlayAnimation("med")
        else
            inst.AnimState:PlayAnimation("idle_closed")
        end
    end
end

local function Close(inst)
    inst:RemoveComponent("activatable")
    inst.AnimState:PlayAnimation("idle_closed", true)
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
    inst.components.workable:SetOnWorkCallback(OnWork)
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"rocks", "rocks", "flint", "flint", "flint"})
    inst.open = false
end

local function onsave(inst, data)
    data.cavenum = inst.cavenum
    data.open = inst.open
end

local function onload(inst, data)
    inst.cavenum = data and data.cavenum
    if data and data.open then
        Open(inst)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    MakeObstaclePhysics(inst, 1)
    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("cave_closed.tex")

    inst.AnimState:SetBank("dst_cave_entrance")
    inst.AnimState:SetBuild("dst_cave_entrance")

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    Close(inst)
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("dst_cave_entrance", fn, assets)
