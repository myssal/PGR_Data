
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridRegression4Gift = require("XUi/XUiRegression4/XUiGrid/XUiGridRegression4Gift")

---@class XUiPanelRegression4GiftShop: XUiNode
local XUiPanelRegression4GiftShop = XClass(XUiNode, "XUiPanelRegression4GiftShop")

--region   ------------------生命周期 start-------------------
function XUiPanelRegression4GiftShop:OnStart()
    self.RootUi = self.Parent
    self.ViewModel = self._Control:GetMainViewModel()
    self:InitUi()
end

function XUiPanelRegression4GiftShop:OnEnable()
    self:RefreshView()
end

function XUiPanelRegression4GiftShop:UpdateTime()
end
--endregion------------------生命周期 finish-------------------

--region   ------------------初始化 start-------------------
function XUiPanelRegression4GiftShop:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridRegression4Gift, self)
    self.DynamicTable:SetDelegate(self)
    self.GridShop.gameObject:SetActiveEx(false)
end
--endregion------------------初始化 finish-------------------

--region   ------------------数据刷新 start-------------------
function XUiPanelRegression4GiftShop:RefreshView()
    self._Control:MarkGiftShopRedPointData()

    self.UiType = self.ViewModel:GetPackageUiType()

    local cached = XDataCenter.PurchaseManager.GetDatasByUiType(self.UiType)
    if not XTool.IsTableEmpty(cached) then
        self:SetPurchaseList(cached)
    end

    XDataCenter.PurchaseManager.GetPurchaseListRequest({ self.UiType }, function()
        if not self:IsNodeShow() then
            return
        end
        local purchaseList = XDataCenter.PurchaseManager.GetDatasByUiType(self.UiType) or table.empty
        self:SetPurchaseList(purchaseList)
    end)
end

function XUiPanelRegression4GiftShop:SetPurchaseList(purchaseList)
    table.sort(purchaseList, function(a, b)
        local aSellOut = a.BuyLimitTimes and a.BuyLimitTimes > 0 and a.BuyTimes >= a.BuyLimitTimes
        local bSellOut = b.BuyLimitTimes and b.BuyLimitTimes > 0 and b.BuyTimes >= b.BuyLimitTimes
        if aSellOut ~= bSellOut then
            return bSellOut
        end
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        end
        return a.Id < b.Id
    end)

    self.PurchaseList = purchaseList
    self.DynamicTable:SetDataSource(self.PurchaseList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelRegression4GiftShop:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(handler(self, self.RefreshView))
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PurchaseList[idx])
    end
end
--endregion------------------数据刷新 finish-------------------

return XUiPanelRegression4GiftShop
