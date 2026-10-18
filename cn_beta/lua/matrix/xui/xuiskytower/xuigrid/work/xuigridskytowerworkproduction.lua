local XUiGridSkyTowerWorkBase = require("XUi/XUiSkyTower/XUiGrid/Work/XUiGridSkyTowerWorkBase")

---@class XUiGridSkyTowerWorkProduction : XUiGridSkyTowerWorkBase 制作列表项
---@field Parent XUiPanelSkyTowerWorkProduction
---@field _Control XSkyTowerControl
local XUiGridSkyTowerWorkProduction = XClass(XUiGridSkyTowerWorkBase, "XUiGridSkyTowerWorkProduction")

function XUiGridSkyTowerWorkProduction:GetWorkType()
    return XMVCA.XSkyTower.WorkType.Food
end

return XUiGridSkyTowerWorkProduction
