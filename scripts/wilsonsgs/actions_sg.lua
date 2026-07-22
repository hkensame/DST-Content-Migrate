-- ==================== 自定义动作：TOUCH / REPAIR2 / BATHBOMB ====================

local EN = GetModConfigData("language")
if GLOBAL.PLATFORM == "Android" then
    GLOBAL.SJ = true
else
    GLOBAL.SJ = false
end

-- 触摸动作
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

-- 修复动作
local REPAIR2 = SJ and Action(2) or Action({},2)
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

-- 浴弹动作
local BATHBOMB = SJ and Action(2) or Action({},2)
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
