local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
---@class XUiTheatre5ShopPanel: XUiNode
local XUiTheatre5ShopPanel = XLuaUiManager.Register(XUiNode, "XUiTheatre5ShopPanel")

function XUiTheatre5ShopPanel:OnStart()
    self:InitDynamicTable()
    self.GridShop.gameObject:SetActiveEx(false)
end

function XUiTheatre5ShopPanel:OnEnable()
    
end

function XUiTheatre5ShopPanel:OnDisable()
    
end

function XUiTheatre5ShopPanel:InitDynamicTable()
    self.DynamicShopTable = XDynamicTableNormal.New(self.Parent.PanelItemList)
    self.DynamicShopTable:SetProxy(XUiGridShop)
    self.DynamicShopTable:SetDelegate(self)
end

function XUiTheatre5ShopPanel:UpdateShopShow(shopId)
    self.ShopItemList = XTool.IsNumberValid(shopId) and XShopManager.GetShopGoodsList(shopId) or {}

    self.DynamicShopTable:SetDataSource(self.ShopItemList)
    self.DynamicShopTable:ReloadDataSync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.ShopItemList))
end

function XUiTheatre5ShopPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopItemList[index]
        if data then
            grid:UpdateData(data)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self.DynamicShopTable:GetGrids()
        local gridCount = XTool.GetTableCount(grids)
        if XTool.IsTableEmpty(grids) then
            return
        end    
        for i,grid in ipairs(grids) do
            grid.GameObject:SetActiveEx(false)
        end
        local index = 0
        XLuaUiManager.SetMask(true)
        for i,grid in ipairs(grids) do
            XScheduleManager.ScheduleOnce(function()
                if not XTool.UObjIsNil(grid.GameObject) then
                    grid.GameObject:SetActiveEx(true)
                    local animTrans = XUiHelper.TryGetComponent(grid.Transform, "Animation/GridShopAnimEnable", nil)
                    if animTrans then
                        animTrans:PlayTimelineAnimation()
                    end
                    index = index + 1
                    if index >= gridCount then
                        XLuaUiManager.SetMask(false)
                    end    
                end        
            end, 100 * i)
        end
    end    
end

return XUiTheatre5ShopPanel