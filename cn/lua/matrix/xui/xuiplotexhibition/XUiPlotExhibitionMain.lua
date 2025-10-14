local XUiPlotExhibitionMainGrid = require("XUi/XUiPlotExhibition/XUiPlotExhibitionMainGrid")
local XUiPlotExhibitionMainFilterGrid = require("XUi/XUiPlotExhibition/XUiPlotExhibitionMainFilterGrid")

---@class XUiPlotExhibitionMain : XLuaUi
---@field _Control XPlotExhibitionControl
local XUiPlotExhibitionMain = XLuaUiManager.Register(XLuaUi, "UiPlotExhibitionMain")

function XUiPlotExhibitionMain:OnAwake()
    self.GridMember.gameObject:SetActiveEx(false)
    self.PanelFilter.gameObject:SetActiveEx(false)
    self.GridPower.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnFilter, self.OnClickFilter)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnClickFilter)
    self:BindExitBtns()
    
    ---@type XDynamicTableNormal
    self.DynamicTableNormal = XUiHelper.DynamicTableNormal(self, self.ListMember, XUiPlotExhibitionMainGrid)

    -- 筛选也用了动态列表, 一个界面做了两个动态列表~
    ---@type XDynamicTableNormal
    self.DynamicTableFilter = XUiHelper.DynamicTableNormalWithDelegate(self, self.ListPower, XUiPlotExhibitionMainFilterGrid, {
        OnDynamicTableEvent = function(table, event, index, grid)
            if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
                grid:Update(self.DynamicTableFilter:GetData(index))
            elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
                --self._Control:OpenUiDetail(self.DynamicTableNormal:GetData(index))
            end
        end
    })
    
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnClickSkip)
    self.BtnFilterClear = self.BtnFilterClear or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelFilter/BtnFilterClear", "XUiButton")
    XUiHelper.RegisterClickEvent(self, self.BtnFilterClear, self.OnClickClearFilter)
end

function XUiPlotExhibitionMain:OnStart()
end

---@param grid XUiPlotExhibitionMainGrid
function XUiPlotExhibitionMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTableNormal:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self._Control:OpenUiDetail(self.DynamicTableNormal:GetData(index))
    end
end

function XUiPlotExhibitionMain:OnEnable()
    self:Update()
end

function XUiPlotExhibitionMain:OnDisable()
end

function XUiPlotExhibitionMain:Update()
    self._Control:UpdateMain()
    local data = self._Control:GetUiData().Main
    self.DynamicTableNormal:SetDataSource(data.FilterRoleList)
    self.DynamicTableNormal:ReloadDataSync()
end

function XUiPlotExhibitionMain:OnClickFilter()
    if self.PanelFilter.gameObject.activeSelf then
        self.PanelFilter.gameObject:SetActiveEx(false)
        -- 手动close，否则在OnEnable时触发XUiNode.gameObject未激活的error
        local grids = self.DynamicTableFilter:GetGrids()
        for i, grid in pairs(grids) do
            grid:Close()
        end
    else
        self.PanelFilter.gameObject:SetActiveEx(true)
        self:UpdateFilter()
    end
end

function XUiPlotExhibitionMain:UpdateFilter()
    self._Control:UpdateFilter()
    self.DynamicTableFilter:SetDataSource(self._Control:GetUiData().Filter.FilterList)
    self.DynamicTableFilter:ReloadDataSync()
end

function XUiPlotExhibitionMain:UpdateByFilter()
    self:Update()
end

function XUiPlotExhibitionMain:OnClickSkip()
    if XLuaUiManager.IsUiLoad("UiNewFuben") then
        self:Close()
    else
        XLuaUiManager.Open("UiNewFuben", XDataCenter.FubenManager.ChapterType.MainLine)
    end
end

function XUiPlotExhibitionMain:OnClickClearFilter()
    self._Control:ClearFilterForceSelected()
    self:Update()
    self:UpdateFilter()
end

return XUiPlotExhibitionMain