local XUiPanelPurchaseItemListBase = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiPanelPurchaseItemListBase')
local XUiPurchaseBundleGrid = require("XUi/XUiPurchase/XUiPurchaseBuyTips/UiPurchaseBundle/XUiPurchaseBundleGrid")

---@class XUiPurchaseBundle : XUiPanelPurchaseItemListBase
---@field _Control
local XUiPurchaseBundle = XClass(XUiPanelPurchaseItemListBase, "XUiPurchaseBundle")

function XUiPurchaseBundle:OnStart()
    self._GridMain = XUiPurchaseBundleGrid.New(self.BtnBigGift, self)
    ---@type XUiPurchaseBundleGrid[]
    self._Grids = {}
    self.BtnGift.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnClickHelp)
end

function XUiPurchaseBundle:OnClickHelp()
    XUiManager.DialogTip(XUiHelper.GetText("PurchaseComboTitle"), XUiHelper.GetText("PurchaseComboContent"), XUiManager.DialogType.NoBtn)
end

---@param data XPurchaseComboData|XUiPurchaseComboSubGridData
function XUiPurchaseBundle:InitGoodsShow(data)
    self._Data = data
    self.TxtName.text = data.Name
    self.TxtSection.text = XUiHelper.GetText('PurchaseBuyTimesProgress', data.BuyTimes, data.BuyLimitTimes)
    --self.ImgTime
    --self.TXtTime
    --self.BtnHelp
    if data.Discount then
        self.Tag.gameObject:SetActiveEx(true)
        self.TxtDiscount.text = XUiHelper.GetDiscountText(data.Discount)
    else
        self.Tag.gameObject:SetActiveEx(false)
    end
    self:SetDataSelected(data)
    if data.MainComboData then
        self._GridMain:Update(data.MainComboData)
        XTool.UpdateDynamicItem(self._Grids, data.MainComboData.SubDatas, self.BtnGift, XUiPurchaseBundleGrid, self)
    else
        self._GridMain:Update(data)
        XTool.UpdateDynamicItem(self._Grids, data.SubDatas, self.BtnGift, XUiPurchaseBundleGrid, self)
    end
    self:UpdateTime()
end

---@param data XPurchaseComboData|XUiPurchaseComboSubGridData
function XUiPurchaseBundle:SetDataSelected(data)
    local subDatas
    if data.MainComboData then
        data.MainComboData.IsSelected = false
        subDatas = data.MainComboData.SubDatas
    else
        subDatas = data.SubDatas
    end
    if subDatas then
        for i = 1, #subDatas do
            subDatas[i].IsSelected = false
        end
    end
    data.IsSelected = true
end

function XUiPurchaseBundle:OnEnable()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, XScheduleManager.SECOND)
    end
end

function XUiPurchaseBundle:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiPurchaseBundle:UpdateTime()
    --有失效时间只显示失效时间。
    -- 失效时间
    if self._Data.Price and self._Data.TimeToInvalid > 0 then
        local remainTime = self._Data.TimeToInvalid - XTime.GetServerNowTimestamp()
        if remainTime > 0 then
            self.ImgTime.gameObject:SetActive(true)
            if self._Data.Discount then
                self.TXtTime.text = XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.PURCHASELB))
            else
                self.TXtTime.text = XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.PURCHASELB))
            end
        else
            self.ImgTime.gameObject:SetActive(false)
            self.TXtTime.text = TextManager.GetText("PurchaseLBSettOff")
            XScheduleManager.UnSchedule(self._Timer)
            self._Timer = false
        end
    end
end

return XUiPurchaseBundle