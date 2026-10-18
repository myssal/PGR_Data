local XUiPanelSkyTowerWorkBase = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerWorkBase")

---@class XUiPanelSkyTowerWorkMaterials : XUiPanelSkyTowerWorkBase 备材
---@field Parent XUiSkyTowerWork
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerWorkMaterials = XClass(XUiPanelSkyTowerWorkBase, "XUiPanelSkyTowerWorkMaterials")

function XUiPanelSkyTowerWorkMaterials:GetTargetWorkType()
    return XMVCA.XSkyTower.WorkType.Ingredient
end

function XUiPanelSkyTowerWorkMaterials:GetGridProxy()
    return require("XUi/XUiSkyTower/XUiGrid/Work/XUiGridSkyTowerWorkMaterials")
end

return XUiPanelSkyTowerWorkMaterials
