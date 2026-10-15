local XUiReformBalanceInfoDesc = require("XUi/XUiReform2nd/Balance/XUiReformBalanceInfoDesc")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceInfoGrid : XUiNode
---@field private _Control XReformControl
---@field PanelTargetTips UnityEngine.RectTransform
---@field TxtTarget UnityEngine.UI.Text
---@field TxtWeight UnityEngine.UI.Text
---@field PanelDesc UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- 4.9 天平详情·单侧汇总（愿望/代价各一份）
local XUiReformBalanceInfoGrid = XClass(XUiNode, "XUiReformBalanceInfoGrid")

function XUiReformBalanceInfoGrid:OnStart()
    ---@type XUiReformBalanceInfoDesc[]
    self._DescList = {}
end

--- 由 XTool.UpdateDynamicItem 驱动
---@param side number XReformBalanceControl.Side
function XUiReformBalanceInfoGrid:Update(side)
    local balanceControl = self._Control:GetBalanceControl()
    local viewModelData = balanceControl:GetBalanceViewModel().Data
    local isWishSide = side == balanceControl.Side.Wish

    local titleKey = "ReformBalanceCostMassTitle"
    local totalMass = viewModelData.CostTotal
    if isWishSide then
        totalMass = viewModelData.WishTotal.."/"..balanceControl:GetMinQuality()
    end
    self.TxtTarget.text = XUiHelper.GetText(titleKey)
    self.TxtWeight.text = totalMass

    local massIds = balanceControl:GetSelectedMassIds(side)
    self.PanelNone.gameObject:SetActiveEx(#massIds == 0)
    XTool.UpdateDynamicItem(self._DescList, massIds, self.PanelDesc, XUiReformBalanceInfoDesc, self)
    XUiHelper.RebuildLayoutRecursive(self.Transform.parent)
end

return XUiReformBalanceInfoGrid
