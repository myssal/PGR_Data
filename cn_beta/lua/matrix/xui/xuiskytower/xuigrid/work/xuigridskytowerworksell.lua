local XUiGridSkyTowerWorkBase = require("XUi/XUiSkyTower/XUiGrid/Work/XUiGridSkyTowerWorkBase")

---@class XUiGridSkyTowerWorkSell : XUiGridSkyTowerWorkBase 销售列表项
---@field Parent XUiPanelSkyTowerWorkSell
---@field _Control XSkyTowerControl
local XUiGridSkyTowerWorkSell = XClass(XUiGridSkyTowerWorkBase, "XUiGridSkyTowerWorkSell")

function XUiGridSkyTowerWorkSell:GetWorkType()
    return XMVCA.XSkyTower.WorkType.Sale
end

return XUiGridSkyTowerWorkSell
