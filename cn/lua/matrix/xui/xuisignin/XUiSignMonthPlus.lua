---@class XUiSignMonthPlus : XUiNode 月卡Plus
local XUiSignMonthPlus = XClass(XUiNode, "XUiSignMonthPlus")

function XUiSignMonthPlus:OnStart()
    if self.BtnBuy then
        self.BtnBuy.CallBack = handler(self, self.OnBtnBuyClick)
    end
    if self.BtnTanchuangCloseWhite then
        self.BtnTanchuangCloseWhite.CallBack = handler(self.Parent, self.Parent.Close)
    end
    if self.BtnHelp then
        self.BtnHelp.CallBack = handler(self, self.OnBtnHelpClick)
    end
end

function XUiSignMonthPlus:Refresh(purchaseData, buyCallBack)
    self._Cb = buyCallBack
    if self.Parent.RefreshBuyButtonStatus then
        self.Parent:RefreshBuyButtonStatus(true)
    end
end

function XUiSignMonthPlus:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", XUiHelper.GetText("PurchaseMonthPlusDesc"))
end

function XUiSignMonthPlus:OnBtnBuyClick()
    if self._Cb then
        self._Cb()
    end
end

return XUiSignMonthPlus