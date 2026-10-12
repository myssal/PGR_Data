
local XRegression4EnumConst = require("XModule/XRegression4/XRegression4EnumConst")
local XUiGridRegression4Tab = require("XUi/XUiRegression4/XUiGrid/XUiGridRegression4Tab")
local XUiRegression4Activity = XLuaUiManager.Register(XLuaUi, "UiRegression4Activity")

local Type2ModulePath = {
    [XRegression4EnumConst.ActivityType.Sign]       = "XUi/XUiRegression4/XUiPanel/XUiPanelRegression4CheckIn",
    [XRegression4EnumConst.ActivityType.Passport]   = "XUi/XUiRegression4/XUiPanel/XUiPanelRegression4Pass",
    [XRegression4EnumConst.ActivityType.Task]       = "XUi/XUiRegression4/XUiPanel/XUiPanelRegression4Task",
    [XRegression4EnumConst.ActivityType.GiftShop]   = "XUi/XUiRegression4/XUiPanel/XUiPanelRegression4GiftShop",
    [XRegression4EnumConst.ActivityType.Boost]      = "XUi/XUiRegression4/XUiPanel/XUiPanelRegression4Boost"
}

local ScheduleMinute = XScheduleManager.SECOND * 60

local DefaultSelectIndex = 1

function XUiRegression4Activity:OnAwake()
    self.ViewModel = self._Control:GetMainViewModel()
    self.PanelDict = {}
    self:InitUi()
    self:InitCb()
end

function XUiRegression4Activity:OnStart()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(
        {
            XRegression4EnumConst.Regression4CoinId,
            XDataCenter.ItemManager.ItemId.HongKa
        },
        self.PanelSpecialTool,
        self)

    -- 更多活动入口：7.0 及之后版本才启用
    self.BtnMoreActivity.gameObject:SetActiveEx(false)

    self:InitView()
end

function XUiRegression4Activity:OnEnable()
    self.Super.OnEnable(self)
    if XTool.IsNumberValid(self.TabIndex) then
        self:RefreshView()
    else
        self.PanelBtnTab:SelectIndex(DefaultSelectIndex)
    end
    self:UpdateTime()
    if not self.Timer then
        self.Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, ScheduleMinute)
    end
end

function XUiRegression4Activity:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiRegression4Activity:InitUi()
    self:InitTab()
end

function XUiRegression4Activity:InitCb()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    local helpKey = self.ViewModel:GetHelpKey()
    self:BindHelpBtn(self.BtnHelp, helpKey)
end

function XUiRegression4Activity:InitTab()
    self.TabData = self.ViewModel:GetActivityOverViewList() or table.empty

    self.TabGrids = {}
    XTool.UpdateDynamicItemByUiCache(self.TabGrids, self.TabData, self.PanelBtnTab.transform, XUiGridRegression4Tab, self)

    self.TabBtn = {}
    for i, grid in ipairs(self.TabGrids) do
        self.TabBtn[i] = grid.Btn
    end
    self.PanelBtnTab:Init(self.TabBtn, function(index) self:OnSelectTab(index) end)
end

function XUiRegression4Activity:InitView()
    local viewModel = self.ViewModel

    self:BindViewModelPropertyToObj(viewModel, function(rewardList)
        if XTool.IsTableEmpty(rewardList) then
            return
        end
        XUiManager.OpenUiObtain(rewardList)
        viewModel:ClearAutoRewardList()
    end, "_AutoRewardList")

    local endTime = viewModel:GetProperty("_ActivityEndTime")
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not self._Control:IsOpen() then
            self._Control:OnActivityEnd()
        end
    end)
end

function XUiRegression4Activity:OnSelectTab(index)
    if self.TabIndex == index then
        return
    end

    local viewData = self.TabData[index]

    local open, desc
    if viewData then
        open, desc = self.ViewModel:CheckOpenByActivityType(viewData.ActivityType)
    end

    if not open then
        XUiManager.TipMsg(desc)
        return
    end
    self.TabIndex = index
    self:RefreshView()
end

function XUiRegression4Activity:SelectTabByActivityType(activityType)
    for index, tabData in ipairs(self.TabData or table.empty) do
        if tabData.ActivityType == activityType then
            self.PanelBtnTab:SelectIndex(index)
            return true
        end
    end
    return false
end

function XUiRegression4Activity:RefreshView()
    self:HideAllPanel()
    local panel = self:GetSubPanel()
    if not panel then
        return
    end
    self:PlayAnimationWithMask("QieHuan")
    local viewData = self.TabData[self.TabIndex]
    panel:Open()
    self:RefreshRedPoint()
end

function XUiRegression4Activity:HideAllPanel()
    for _, panel in pairs(self.PanelDict) do
        if panel and not XTool.UObjIsNil(panel.GameObject) then
            panel:Close()
        end
    end
end

function XUiRegression4Activity:UpdateTime()
    self.TxtTime.text = XUiHelper.GetTime(self.ViewModel:GetLeftTime(), XUiHelper.TimeFormatType.ACTIVITY)

    local panel = self:GetSubPanel()
    if not panel then
        return
    end
    panel:UpdateTime()
end

function XUiRegression4Activity:GetSubPanel()
    local viewData = self.TabData[self.TabIndex]
    if not viewData then
        XLog.Error("select invalid tab index: " .. self.TabIndex .. "tab config: ", self.TabData)
        return
    end

    local prefabPath = viewData.PrefabPath
    local panel = self.PanelDict[prefabPath]
    if not panel then
        local go = self.PanelContainer:LoadPrefabEx(prefabPath)
        
        local modulePath = Type2ModulePath[viewData.ActivityType]
        if string.IsNilOrEmpty(modulePath) then
            XLog.Error("init panel error: module path is empty! activity type = " .. viewData.ActivityType .. "activity overview id = " .. viewData.Id)
            return
        end
        panel = require(modulePath).New(go, self)
        self.PanelDict[prefabPath] = panel
        self.PanelDict[prefabPath]:Close()
    end
    return panel
end

function XUiRegression4Activity:RefreshRedPoint()
    for _, grid in ipairs(self.TabGrids) do
        grid:RefreshRedPoint()
    end
end