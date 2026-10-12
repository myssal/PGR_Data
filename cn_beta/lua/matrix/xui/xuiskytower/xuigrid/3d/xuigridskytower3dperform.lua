local XUiGridSkyTower3DBase = require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DBase")

---@class XUiGridSkyTower3DPerform : XUiGridSkyTower3DBase
---@field BtnClick XUiComponent.XUiButton
---@field _Control XSkyTowerControl
local XUiGridSkyTower3DPerform = XClass(XUiGridSkyTower3DBase, "XUiGridSkyTower3DPerform")

function XUiGridSkyTower3DPerform:InitUi()
    self.TipAnimation = self.Transform:Find("Animation/TipsEnable")
    if self.TipAnimation then
        self.TipAnimation.gameObject:SetActiveEx(false)
    end
end

function XUiGridSkyTower3DPerform:InitCb()
    self.GridEvent:AddEventListener(handler(self, self.OnBtnClick))
end

function XUiGridSkyTower3DPerform:OnBtnClick()
    self._Control:OpenPerformUi(self._PerformId)
end

function XUiGridSkyTower3DPerform:OnRefresh(performId)
    self._PerformId = performId
    local finish = self._Control:CheckRunningPerformFinish(self._Control:GetFloorId(performId))
    local isNotStart = self._Control:IsNotStart(performId)
    local isOnGoing = self._Control:IsOnGoing(performId)
    self.PanelComplete.gameObject:SetActiveEx(finish)
    self.PanelOnGoing.gameObject:SetActiveEx(isOnGoing and not finish)
    self.PanelNotStart.gameObject:SetActiveEx(isNotStart)
end

function XUiGridSkyTower3DPerform:Hide()
    self.PerformId = nil
    XUiGridSkyTower3DBase.Hide(self)
end

function XUiGridSkyTower3DPerform:GetPerformId()
    return self.PerformId
end

function XUiGridSkyTower3DPerform:ShowTip()
    if not self.TipAnimation then
        return
    end
    if not self:IsShow() then
        return
    end
    self.TipAnimation.gameObject:SetActiveEx(false)
    self.TipAnimation.gameObject:SetActiveEx(true)
end

return XUiGridSkyTower3DPerform