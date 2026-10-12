local XUiPanelSkyTowerWorkBase = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerWorkBase")

---@class XUiPanelSkyTowerWorkSell : XUiPanelSkyTowerWorkBase 销售
---@field Parent XUiSkyTowerWork
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerWorkSell = XClass(XUiPanelSkyTowerWorkBase, "XUiPanelSkyTowerWorkSell")

function XUiPanelSkyTowerWorkSell:GetTargetWorkType()
    return XMVCA.XSkyTower.WorkType.Sale
end

function XUiPanelSkyTowerWorkSell:GetGridProxy()
    return require("XUi/XUiSkyTower/XUiGrid/Work/XUiGridSkyTowerWorkSell")
end

return XUiPanelSkyTowerWorkSell
