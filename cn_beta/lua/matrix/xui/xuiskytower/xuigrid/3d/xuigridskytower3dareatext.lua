local XUiGridSkyTower3DBase = require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DBase")

---@class XUiGridSkyTower3DAreaText : XUiGridSkyTower3DBase
---@field Parent XUiPanelSkyTowerCommonArea
---@field _Control XSkyTowerControl
local XUiGridSkyTower3DAreaText = XClass(XUiGridSkyTower3DBase, "XUiGridSkyTower3DAreaText")

function XUiGridSkyTower3DAreaText:OnStart()
    self.Super.OnStart(self)
    self._MaxFloorGroup = self._Control:GetIntClientConfigValue("FloorGroupCount")
end

function XUiGridSkyTower3DAreaText:OnRefresh(groupId)
    self.ImgArrow1.gameObject:SetActiveEx(groupId < self._MaxFloorGroup)
    self.ImgArrow2.gameObject:SetActiveEx(groupId > 1)
    self.TxtArea.text = self._Control:GetFloorGroupName(groupId)
end

function XUiGridSkyTower3DAreaText:OnRecycle()
    self:Close()
end

return XUiGridSkyTower3DAreaText
