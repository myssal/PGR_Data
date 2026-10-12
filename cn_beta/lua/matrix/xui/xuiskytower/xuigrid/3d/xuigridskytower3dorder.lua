local XUiGridSkyTower3DBase = require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DBase")

---@class XUiGridSkyTower3DOrder : XUiGridSkyTower3DBase
---@field BtnClick XUiComponent.XUiButton
---@field _Control XSkyTowerControl
local XUiGridSkyTower3DOrder = XClass(XUiGridSkyTower3DBase, "XUiGridSkyTower3DOrder")

function XUiGridSkyTower3DOrder:InitUi()
    self.TipAnimation = self.Transform:Find("Animation/TipsEnable")
    if self.TipAnimation then
        self.TipAnimation.gameObject:SetActiveEx(false)
    end
end

function XUiGridSkyTower3DOrder:InitCb()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
end

function XUiGridSkyTower3DOrder:OnBtnClick()
    if not XTool.IsNumberValid(self.PerformId) or self._Control:IsFinish(self.PerformId) then
        self:Hide()
        return
    end
    self._Control:OpenPerformUi(self.PerformId)
end

function XUiGridSkyTower3DOrder:OnRefresh(performId)
    self.PerformId = performId
    local finish = self._Control:CheckPerformFinish(performId)
    local isNotStart = self._Control:IsNotStart(performId)
    local isOnGoing = self._Control:IsOnGoing(performId)
    self.PanelComplete.gameObject:SetActiveEx(finish)
    self.PanelOnGoing.gameObject:SetActiveEx(isOnGoing and not finish)
    self.PanelNotStart.gameObject:SetActiveEx(isNotStart)
end

function XUiGridSkyTower3DOrder:Hide()
    self.PerformId = nil
    XUiGridSkyTower3DBase.Hide(self)
end

function XUiGridSkyTower3DOrder:GetPerformId()
    return self.PerformId
end

function XUiGridSkyTower3DOrder:ShowTip()
    if not self.TipAnimation then
        return
    end
    if not self:IsShow() then
        return
    end
    self.TipAnimation.gameObject:SetActiveEx(false)
    self.TipAnimation.gameObject:SetActiveEx(true)
end

return XUiGridSkyTower3DOrder