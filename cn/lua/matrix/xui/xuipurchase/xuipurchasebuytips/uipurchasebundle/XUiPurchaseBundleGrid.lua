---@class XUiPurchaseBundleGrid : XUiNode
---@field _Control
---@field Parent XUiPurchaseBundle
local XUiPurchaseBundleGrid = XClass(XUiNode, "XUiPurchaseBundleGrid")

function XUiPurchaseBundleGrid:OnStart()
    self._Button = XUiHelper.TryGetComponent(self.Transform, "", "XUiButton")
    XUiHelper.RegisterClickEvent(self, self._Button, self.OnClick)
end

---@param data XUiPurchaseComboSubGridData
function XUiPurchaseBundleGrid:Update(data)
    self._Data = data
    local iconPath = XPurchaseConfigs.GetIconPathByIconName(data.Icon)
    if iconPath and iconPath.AssetPath then
        self._Button:SetRawImage(iconPath.AssetPath, function()
            self.RImgIcon:SetNativeSize()
        end)
    end
    self._Button:SetButtonState(data.IsSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiPurchaseBundleGrid:OnClick()
    self.Parent:SetDataSelected(self._Data)
    self.Parent:InitGoodsShow(self._Data)
    ---@type XUiPurchaseBuyTips
    local panelUi = self.Parent.Parent
    panelUi.Data = self._Data
    panelUi:SetList()
    panelUi:CheckLBRewardIsHave()
    panelUi:RefreshBtnBuyPrice()
end

return XUiPurchaseBundleGrid