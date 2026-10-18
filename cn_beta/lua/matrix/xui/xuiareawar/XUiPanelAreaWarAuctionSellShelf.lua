---@class XUiPanelAreaWarAuctionSellShelf : XUiNode
---@field private _Control XAreaWarControl
local XUiPanelAreaWarAuctionSellShelf = XClass(XUiNode, "XUiPanelAreaWarAuctionSellShelf")

function XUiPanelAreaWarAuctionSellShelf:OnStart()
    self:InitDynamicTable()
end

function XUiPanelAreaWarAuctionSellShelf:OnEnable()
    self:StartTimer()
end

function XUiPanelAreaWarAuctionSellShelf:OnDisable()
    self:StopTimer()
end

function XUiPanelAreaWarAuctionSellShelf:OnGetLuaEvents()
    return {
        XEventId.EVENT_AREA_WAR_ITEM_ROOM_ORDER_CHANGE
    }
end

function XUiPanelAreaWarAuctionSellShelf:OnNotify(evt, ...)
    if evt == XEventId.EVENT_AREA_WAR_ITEM_ROOM_ORDER_CHANGE then
        self:RefreshOrderList()
    end
end

function XUiPanelAreaWarAuctionSellShelf:Refresh()
    self:RefreshOrderList()
end

function XUiPanelAreaWarAuctionSellShelf:InitDynamicTable()
    self.GridSell.gameObject:SetActiveEx(false)
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    local XUiGridAreaWarOrder = require("XUi/XUiAreaWar/XUiGridAreaWarOrder")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelShelfList)
    self.DynamicTable:SetProxy(XUiGridAreaWarOrder, self)
    self.DynamicTable:SetDelegate(self)
end

-- 刷新订单列表
function XUiPanelAreaWarAuctionSellShelf:RefreshOrderList()
    local itemRoom = self._Control:GetItemRoom()
    self.OrderList = itemRoom:GetValidOrders()
    self.DynamicTable:SetDataSource(self.OrderList)
    self.DynamicTable:ReloadDataSync()
    self.TxtShelfEmpty.gameObject:SetActiveEx(#self.OrderList == 0)
end

---@param grid XUiGridAreaWarOrder
function XUiPanelAreaWarAuctionSellShelf:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local order = self.OrderList[index]
        grid:RefreshOrder(order)
    end
end

function XUiPanelAreaWarAuctionSellShelf:StartTimer()
    self:StopTimer()
    XScheduleManagerPro.ScheduleForever(XUiPanelAreaWarAuctionSellShelf._OnRefreshOrderTimeScheduleCb, self, XScheduleManagerPro.SECOND)
end

function XUiPanelAreaWarAuctionSellShelf:StopTimer()
    XScheduleManagerPro.UnSchedule(XUiPanelAreaWarAuctionSellShelf._OnRefreshOrderTimeScheduleCb, self)
end

function XUiPanelAreaWarAuctionSellShelf:RefreshOrderTime()
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:RefreshTime()
    end
    
    XMVCA.XAreaWar:CheckSettleOrders()
end

function XUiPanelAreaWarAuctionSellShelf:_OnRefreshOrderTimeScheduleCb()
    self:RefreshOrderTime()
end

return XUiPanelAreaWarAuctionSellShelf
