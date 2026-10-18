local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiScoreTowerRank : XLuaUi
---@field private _Control XScoreTowerControl
local XUiScoreTowerRank = XLuaUiManager.Register(XLuaUi, "UiScoreTowerRank")

function XUiScoreTowerRank:OnAwake()
    self:RegisterUiEvents()
    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiScoreTowerRank:OnStart()
    self:SetAutoCloseInfo(XMVCA.XScoreTower:GetActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XScoreTower:HandleActivityEnd()
        end
    end)

    self:InitDynamicTable()
    -- 记录排行榜点击
    self._Control:RecordRankClick()
    -- 动画间隔
    self.AnimInterval = self._Control:GetClientConfig("GridRankAnimInterval", 1, true)
end

function XUiScoreTowerRank:OnEnable()
    self.Super.OnEnable(self)
    self:OpenMyRank()
    self:SetupDynamicTable()
end

function XUiScoreTowerRank:OnDisable()
    self.Super.OnDisable(self)
    self:StopDynamicGridTime()
    self:SetGridRankAlpha(1)
end

function XUiScoreTowerRank:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetProxy(require("XUi/XUiScoreTower/Rank/XUiGridScoreTowerPlayerRank"), self)
    self.DynamicTable:SetDelegate(self)
end

function XUiScoreTowerRank:SetupDynamicTable()
    self.PlayerRankInfo = self._Control:GetQueryRankPlayerInfoList()
    local isEmpty = XTool.IsTableEmpty(self.PlayerRankInfo)
    self.PanelNoRank.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        return
    end
    self.DynamicTable:SetDataSource(self.PlayerRankInfo)
    self.DynamicTable:ReloadDataSync(1)
end

---@param grid XUiGridScoreTowerPlayerRank
function XUiScoreTowerRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PlayerRankInfo[index], index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayGridRankAnim()
    end
end

--- 打开自己的排名
function XUiScoreTowerRank:OpenMyRank()
    if not self.PanelMyRankUi then
        ---@type XUiGridScoreTowerMyRank
        self.PanelMyRankUi = require("XUi/XUiScoreTower/Rank/XUiGridScoreTowerMyRank").New(self.PanelMyRank, self)
    end
    self.PanelMyRankUi:Open()
    self.PanelMyRankUi:Refresh()
end

-- 播放排行榜动画
function XUiScoreTowerRank:PlayGridRankAnim()
    if not self.DynamicTable then
        return
    end
    ---@type XUiGridScoreTowerPlayerRank[]
    local grids = self.DynamicTable:GetGrids()
    if XTool.IsTableEmpty(grids) then
        return
    end
    self:StopDynamicGridTime()
    self:SetGridRankAlpha(0)
    local gridCount = table.nums(grids)
    XLuaUiManager.SetMask(true)
    self._AnimIndex = 1
    XScheduleManagerPro.Schedule(XUiScoreTowerRank._OnGridRankAnimScheduleCb, self, self.AnimInterval, gridCount)
    XScheduleManagerPro.ScheduleOnce(XUiScoreTowerRank._OnGridRankAnimFinishScheduleCb, self, self.AnimInterval * gridCount + 300)
end

--- 定时器回调：逐个播放排行格子动画
function XUiScoreTowerRank:_OnGridRankAnimScheduleCb()
    local grids = self.DynamicTable and self.DynamicTable:GetGrids()
    local grid = grids and grids[self._AnimIndex]
    if grid then
        grid:PlayEnableAnim()
    end
    self._AnimIndex = self._AnimIndex + 1
end

function XUiScoreTowerRank:_OnGridRankAnimFinishScheduleCb()
    self:StopDynamicGridTime()
    self:SetGridRankAlpha(1)
    XLuaUiManager.SetMask(false)
end

-- 停止排行榜动画
function XUiScoreTowerRank:StopDynamicGridTime()
    XScheduleManagerPro.UnSchedule(XUiScoreTowerRank._OnGridRankAnimScheduleCb, self)
    XScheduleManagerPro.UnSchedule(XUiScoreTowerRank._OnGridRankAnimFinishScheduleCb, self)
end

-- 设置排行格子透明度
function XUiScoreTowerRank:SetGridRankAlpha(alpha)
    if not self.DynamicTable then
        return
    end
    ---@type XUiGridScoreTowerPlayerRank[]
    local grids = self.DynamicTable:GetGrids()
    if XTool.IsTableEmpty(grids) then
        return
    end
    for _, grid in pairs(grids) do
        grid:SetCanvasGroupAlpha(alpha)
    end
end

function XUiScoreTowerRank:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiScoreTowerRank:OnBtnBackClick()
    self:Close()
end

function XUiScoreTowerRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiScoreTowerRank
