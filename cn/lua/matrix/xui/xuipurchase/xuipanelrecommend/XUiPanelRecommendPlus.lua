---@class XUiPanelRecommendPlus 月卡Plus
local XUiPanelRecommendPlus = XClass(nil, "XUiPanelRecommendPlus")

function XUiPanelRecommendPlus:Ctor(ui, parent)
    ---@type UnityEngine.GameObject
    self.GameObject = ui.gameObject
    ---@type UnityEngine.RectTransform
    self.Transform = ui.transform
    self.RootUi = parent
    XTool.InitUiObject(self)

    if self.BtnBuy then
        self.BtnBuy.CallBack = handler(self, self.OnBtnBuyClick)
    end
    self.BtnHelp.CallBack = handler(self, self.OnBtnHelpClick)
end

function XUiPanelRecommendPlus:Refresh(signId)
    self.SignId = signId

    if self.RootUi and self.RootUi.RefreshBuyButtonStatus then
        self.RootUi:RefreshBuyButtonStatus(true)
    end
end

function XUiPanelRecommendPlus:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", XUiHelper.GetText("PurchaseMonthPlusDesc"))
end

function XUiPanelRecommendPlus:OnBtnBuyClick()
    self.RootUi:OnBtnBuyClick() --self.RootUi is XUiPurchaseBuyTips
end

return XUiPanelRecommendPlus