---@class XUiPanelRecommendComboPackageGrid
local XUiPanelRecommendComboPackageGrid = XClass(nil, "XUiPanelRecommendComboPackageGrid")

function XUiPanelRecommendComboPackageGrid:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
end

---@param data XPurchaseComboData
function XUiPanelRecommendComboPackageGrid:Update(data)
    self.TxtPrice.text = data.Price
    if self.PanelDiscount then
        if data.Discount and data.Discount > 0 then
            self.PanelDiscount.gameObject:SetActiveEx(true)
            self.TxtPriceOriginal.text = data.OriginalPrice
            self.Text.text = XUiHelper.GetDiscountText(data.Discount)
        else
            self.PanelDiscount.gameObject:SetActiveEx(false)
        end
    end

    local iconPath = XPurchaseConfigs.GetIconPathByIconName(data.Icon)
    if iconPath and iconPath.AssetPath then
        self.Icon:SetRawImage(iconPath.AssetPath, function()
            self.Icon:SetNativeSize()
        end)
    end
    
    local path = XDataCenter.ItemManager.GetItemIcon(data.ConsumeId)
    if path then
        self.RImgIcon:SetRawImage(path)
    end
end

return XUiPanelRecommendComboPackageGrid