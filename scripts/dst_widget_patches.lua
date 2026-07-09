--启迪之冠格子缩放
AddClassPostConstruct("widgets/containerwidget",function(self)
  local self_Open=self.Open
  function self:Open(container, doer)
    self_Open(self, container, doer)
    if self.container and self.container.prefab=="alterguardianhat" then --判断是否为特定的预设
      self:SetScale(0.5, 0.5, 0.5) --动画
      --self.bgimage:SetScale(.5,.5,.5) --贴图
      self:MoveToFront()
    end
  end
end)
