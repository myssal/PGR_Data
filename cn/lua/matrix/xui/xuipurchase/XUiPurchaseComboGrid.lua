local XUiPurchaseComboSubGrid = require("XUi/XUiPurchase/XUiPurchaseComboSubGrid")

---@class XUiPurchaseComboGrid : XUiNode
local XUiPurchaseComboGrid = XClass(XUiNode, "XUiPurchaseComboGrid")

function XUiPurchaseComboGrid:OnStart()
    ---@type XUiPurchaseComboSubGrid
    self._GridMain = XUiPurchaseComboSubGrid.New(self.PanelLbItemMain, self)
    ---@type XUiPurchaseComboSubGrid[]
    self._Grids = {}
    self.PanelLbItemSub.gameObject:SetActiveEx(false)
end

---@param data XPurchaseComboData
function XUiPurchaseComboGrid:Update(data)
    self._GridMain:Update(data)
    XTool.UpdateDynamicItem(self._Grids, data.SubDatas, self.PanelLbItemSub, XUiPurchaseComboSubGrid, self)
end

function XUiPurchaseComboGrid:UpdateAllData()
    self.Parent:OnRefresh()
end

return XUiPurchaseComboGrid