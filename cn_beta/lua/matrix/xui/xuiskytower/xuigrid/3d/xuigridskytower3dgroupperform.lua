local XUiGridSkyTower3DOrder = require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DOrder")

---@class XUiGridSkyTower3DGroupPerform : XUiGridSkyTower3DOrder
---@field Parent XUiSkyTowerCommon
---@field _Control XSkyTowerControl
local XUiGridSkyTower3DGroupPerform = XClass(XUiGridSkyTower3DOrder, "XUiGridSkyTower3DGroupPerform")

function XUiGridSkyTower3DGroupPerform:InitCb()
    self.GridFloorGroupEvent:AddEventListener(handler(self, self.OnGridFloorGroupEventClick))
end

function XUiGridSkyTower3DGroupPerform:OnGridFloorGroupEventClick()
    self._Control:OpenPerformUi(self._PerformId)
end

function XUiGridSkyTower3DGroupPerform:OnRefresh(performId)
    self._PerformId = performId
end

return XUiGridSkyTower3DGroupPerform
