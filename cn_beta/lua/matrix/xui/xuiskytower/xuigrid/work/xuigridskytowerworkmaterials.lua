local XUiGridSkyTowerWorkBase = require("XUi/XUiSkyTower/XUiGrid/Work/XUiGridSkyTowerWorkBase")

---@class XUiGridSkyTowerWorkMaterials : XUiGridSkyTowerWorkBase 备材列表项
---@field Parent XUiPanelSkyTowerWorkMaterials
---@field _Control XSkyTowerControl
local XUiGridSkyTowerWorkMaterials = XClass(XUiGridSkyTowerWorkBase, "XUiGridSkyTowerWorkMaterials")

function XUiGridSkyTowerWorkMaterials:GetWorkType()
    return XMVCA.XSkyTower.WorkType.Ingredient
end

return XUiGridSkyTowerWorkMaterials
