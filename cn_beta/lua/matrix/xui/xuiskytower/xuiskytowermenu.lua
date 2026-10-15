local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridSkyTowerMenu = require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerMenu")

---@class XUiSkyTowerMenu : XLuaUi 图鉴
---@field PanelGroup XUiButtonGroup
---@field _Control XSkyTowerControl
local XUiSkyTowerMenu = XLuaUiManager.Register(XLuaUi, "UiSkyTowerMenu")

local DefaultTabId = 1 --默认选中页签
local MenuTabType = XMVCA.XSkyTower.MenuTabType

local XUiPanelSkyTowerBubbleIngredient = require("XUi/XUiSkyTower/XUiPanel/XUiPanelSkyTowerBubbleIngredient")

function XUiSkyTowerMenu:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyTowerMenu:OnStart(tabId, defaultParam)
    self.DefaultTabId = tabId or DefaultTabId
    self.DefaultParam = defaultParam
    self.PanelGroup:SelectIndex(self.DefaultTabId)
end

function XUiSkyTowerMenu:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateView()
end

function XUiSkyTowerMenu:Close()
    self:CloseIngredientBubble()
    self.Super.Close(self)
end

function XUiSkyTowerMenu:UpdateView()
    self:UpdateTab()
end

--红点
function XUiSkyTowerMenu:UpdateTab()
    for tabId, btn in pairs(self.TabList) do
        local datas = self:GetTabDatas(tabId)
        btn:ShowReddot(self:CheckRedPoint(tabId))
        btn:SetName(string.format("%s/%s", self._Control:GetMenuTabUnlockCount(tabId), #datas))
    end
end

function XUiSkyTowerMenu:InitUi()
    ---@type table<number,XUiComponent.XUiButton>
    self.TabList = {
        [MenuTabType.Perform] = self.BtnStory,
        [MenuTabType.Indent] = self.BtnIndent,
        [MenuTabType.Food] = self.BtnFood
    }
    self:UpdateTab()

    self.PanelGroup:Init(self.TabList, function(tabIndex)
        self:OnSelectTab(tabIndex)
    end)

    --dynamicTab
    self.DynamicFoodTable = XDynamicTableNormal.New(self.PanelFoodList)
    self.DynamicFoodTable:SetProxy(XUiGridSkyTowerMenu, self)
    self.DynamicFoodTable:SetDelegate(self)
    self.DynamicFoodTable:SetDynamicEventDelegate(handler(self, self.OnFoodTableEvent))
    self.GridFoods.gameObject:SetActiveEx(false)

    self.DynamicIndentTable = XDynamicTableNormal.New(self.PanelIndent)
    self.DynamicIndentTable:SetProxy(XUiGridSkyTowerMenu, self)
    self.DynamicIndentTable:SetDelegate(self)
    self.DynamicIndentTable:SetDynamicEventDelegate(handler(self, self.OnMessageTableEvent))
    self.GridIndent.gameObject:SetActiveEx(false)

    self.DynamicStoryTable = XDynamicTableNormal.New(self.PanelStory)
    self.DynamicStoryTable:SetProxy(XUiGridSkyTowerMenu, self)
    self.DynamicStoryTable:SetDelegate(self)
    self.DynamicStoryTable:SetDynamicEventDelegate(handler(self, self.OnStoryTableEvent))
    self.GridStory.gameObject:SetActiveEx(false)

    self.PanelBubbleLeft = XUiPanelSkyTowerBubbleIngredient.New(self.PanelLeft, self)
    self.PanelBubbleRight = XUiPanelSkyTowerBubbleIngredient.New(self.PanelRight, self)

    self.PanelBubbleLeft:Hide()
    self.PanelBubbleRight:Hide()
end

function XUiSkyTowerMenu:InitCb()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnWndClose:AddEventListener(handler(self, self.Close))

    local proxy = self.PanelFoodList.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    proxy:RegisterHandler(handler(self, self.OnDragProxy))

    self:RegisterClickEvent(self.RImgBg, self.CloseIngredientBubble)
end

function XUiSkyTowerMenu:InitView()
    self.PanelGroup:SelectIndex(self.DefaultTabId)
end

function XUiSkyTowerMenu:OnSelectTab(tabIndex)
    if self.TabIndex == tabIndex then
        return
    end

    local btn = self.TabList[tabIndex]
    if btn then
        btn:ShowReddot(false)
    end
    self._Control:MarkMenuRedPoint(tabIndex)

    self.TabIndex = tabIndex
    if tabIndex ~= MenuTabType.Food then
        self:CloseIngredientBubble()
    end
    self:PlayAnimation("QieHuan")
    self:SetupDynamicTab()
end

function XUiSkyTowerMenu:SetupDynamicTab()
    local isPerform = self.TabIndex == MenuTabType.Perform
    local isIndent = self.TabIndex == MenuTabType.Indent
    local isMenu = self.TabIndex == MenuTabType.Food
    self.PanelStory.gameObject:SetActiveEx(isPerform)
    self.PanelIndent.gameObject:SetActiveEx(isIndent)
    self.PanelFoodList.gameObject:SetActiveEx(isMenu)
    self.DataList = self:GetTabDatas(self.TabIndex)

    local dynamic
    if isPerform then
        dynamic = self.DynamicStoryTable
        self._Control:MarkPerformListRedPoint(self.DataList)
    elseif isIndent then
        dynamic = self.DynamicIndentTable
        self._Control:MarkPerformListRedPoint(self.DataList)
    else
        dynamic = self.DynamicFoodTable
    end

    dynamic:SetDataSource(self.DataList)
    local startIndex = 1
    if self.DefaultParam then
        startIndex = self:GetGridIndex(self.DefaultParam)
    end
    dynamic:ReloadDataSync(startIndex)

end

function XUiSkyTowerMenu:OnFoodTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshFood(self.DataList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:CloseIngredientBubble()
        if not grid:IsUnLock() then
            XMVCA.XSkyTower:TipMsg(self._Control:GetCommonUnlockText(3))
            return
        end
        local x = grid.Transform.position.x
        local isLeft = x > 1
        if isLeft then
            self.PanelBubbleLeft:Show(grid.Transform, self.DataList[index], isLeft)
        else
            self.PanelBubbleRight:Show(grid.Transform, self.DataList[index], isLeft)
        end
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlaySelectTip(self.DynamicFoodTable)
        self.DefaultParam = nil
    end
end

function XUiSkyTowerMenu:OnMessageTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshIndent(self.DataList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickPerform(grid)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlaySelectTip(self.DynamicIndentTable)
        self.DefaultParam = nil
    end
end

function XUiSkyTowerMenu:OnStoryTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshPerform(self.DataList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickPerform(grid)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlaySelectTip(self.DynamicStoryTable)
        self.DefaultParam = nil
    end
end

function XUiSkyTowerMenu:PlaySelectTip(dynamic)
    if not self.DefaultParam then
        return
    end
    local grids = dynamic:GetGrids()
    local grid = grids[self:GetGridIndex(self.DefaultParam)]
    if not grid then
        return
    end
    grid:PlayTip()
end

function XUiSkyTowerMenu:GetGridIndex(param)
    for index, value in ipairs(self.DataList) do
        if value == param then
            return index
        end
    end
    return 1
end

---@param grid XUiGridSkyTowerMenu
function XUiSkyTowerMenu:OnClickPerform(grid)
    if not grid then
        return
    end
    local performId = grid:GetId()
    --与锁定样式保持一致，尚未进行对话的事件也不能从图鉴打开
    if not grid:IsUnLock() then
        XMVCA.XSkyTower:TipMsg(self._Control:GetUnlockConditionDesc(performId))
        return
    end
    grid:SetRedPointState(false)
    self._Control:MarkPerformRedPoint(performId)
    self._Control:OpenPerformUi(performId, true)
end

function XUiSkyTowerMenu:OnFoodScroll()
    self:CloseIngredientBubble()
end

function XUiSkyTowerMenu:GetTabDatas(tabId)
    if tabId == MenuTabType.Perform then
        return self:GetPerformList()
    elseif tabId == MenuTabType.Indent then
        return self:GetIndentList()
    elseif tabId == MenuTabType.Food then
        return self:GetFoodIdList()
    end
    return table.empty
end

function XUiSkyTowerMenu:GetFoodIdList()
    if not self.FoodIdList then
        self.FoodIdList = self._Control:GetAllFoodIds()
    end
    return self.FoodIdList
end

function XUiSkyTowerMenu:GetIndentList()
    if not self.IndentList then
        self.IndentList = self:GetSortedPerformList(self._Control:GetAllIndentIds())
    end
    return self.IndentList
end

function XUiSkyTowerMenu:GetPerformList()
    if not self.PerformList then
        self.PerformList = self:GetSortedPerformList(self._Control:GetAllPerformIds())
    end
    return self.PerformList
end

---日志使用独立的排序列表，避免改变其他界面共用的配置Id列表
function XUiSkyTowerMenu:GetSortedPerformList(performIds)
    local list = XTool.Clone(performIds)
    table.sort(list, handler(self, self.SortPerformByPriority))
    return list
end

function XUiSkyTowerMenu:SortPerformByPriority(a, b)
    local priorityA = self._Control:GetPerformConfig(a).Priority
    local priorityB = self._Control:GetPerformConfig(b).Priority
    if priorityA ~= priorityB then
        return priorityA < priorityB
    end
    return a < b
end

function XUiSkyTowerMenu:CheckRedPoint(tabId)
    return self._Control:CheckMenuRedPoint(tabId)
end

function XUiSkyTowerMenu:CloseIngredientBubble()
    self.PanelBubbleLeft:Hide()
    self.PanelBubbleRight:Hide()
end

function XUiSkyTowerMenu:OnDragProxy(int, eventData)
    if int == 0 then
        self:CloseIngredientBubble()
    end
end

return XUiSkyTowerMenu
