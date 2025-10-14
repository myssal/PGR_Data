local XUiPanelRecommendBase = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendBase")
local XUiPanelRecommendComboPackageGrid = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendComboPackage/XUiPanelRecommendComboPackageGrid")

---@class XUiPanelRecommendComboPackage : XUiPanelRecommendBase@捆绑包
local XUiPanelRecommendComboPackage = XClass(XUiPanelRecommendBase, "XUiPanelRecommendComboPackage")

function XUiPanelRecommendComboPackage:SetData(data, skipFunc, buyFinished)
    --XLog.Debug(data)
    --XUiPanelRecommendBase.SetData(self, data, skipFunc, buyFinished)
    ---@type XPurchaseRecommend
    self.Recommend = data
    self.SkipFunc = skipFunc
    self.BuyFinished = buyFinished
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnClickHelp)

    -- 捆绑包
    local uiDataCombo = XDataCenter.PurchaseManager.GetComboPurchaseData(XPurchaseConfigs.UiType.ComboPackage)
    local firstUiData = uiDataCombo[1]
    if not firstUiData then
        XLog.Error("[XUiPanelRecommendComboPackage] ")
        return
    end

    -- 跳转其实是通过BtnBuy，而不是BtnHelp，目前的BtnHelp是无反应的
    ---@type XUiPanelRecommendComboPackageGrid
    self._BtnGiftBuy1 = XUiPanelRecommendComboPackageGrid.New(self.BtnGiftBuy1, self)
    self._BtnGiftBuy1:Update(firstUiData)
    if firstUiData.Discount and firstUiData.Discount > 0 then
        self.TxtDiscount.text = XUiHelper.GetText("PurchaseDiscount", 100 - firstUiData.Discount)
    end

    for i = 2, 4 do
        local subData = firstUiData.SubDatas[i - 1]
        if subData then
            local btnName = "BtnGiftBuy" .. i
            local btn = self[btnName]
            if not XTool.UObjIsNil(btn) then
                local gridName = "_BtnGiftBuy" .. i
                self[gridName] = self[gridName] or XUiPanelRecommendComboPackageGrid.New(btn, self)
                self[gridName]:Update(firstUiData.SubDatas[i - 1])
            else
                -- 美术去掉按钮，但是没有删除引用导致的报错，兼容一下
                XLog.Error("[XUiPanelRecommendBase] 找不到对应的btn:" .. btnName)
            end
        else
            local btnName = "BtnGiftBuy" .. i
            local btn = self[btnName]
            if not XTool.UObjIsNil(btn) then
                btn.gameObject:SetActiveEx(false)
            else
                -- 美术去掉按钮，但是没有删除引用导致的报错，兼容一下
                XLog.Error("[XUiPanelRecommendBase] 找不到对应的btn:" .. btnName)
            end
        end
    end
end

function XUiPanelRecommendComboPackage:OnClickHelp()
    XUiManager.DialogTip(XUiHelper.GetText("PurchaseComboTitle"), XUiHelper.GetText("PurchaseComboContent"), XUiManager.DialogType.NoBtn)
end

return XUiPanelRecommendComboPackage