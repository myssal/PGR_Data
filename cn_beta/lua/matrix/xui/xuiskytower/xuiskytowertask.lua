local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridSkyTowerTask = require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerTask")

---@class XUiSkyTowerTask : XLuaUi
---@field _Control XSkyTowerControl
local XUiSkyTowerTask = XLuaUiManager.Register(XLuaUi, "UiSkyTowerTask")

local DefaultTabIndex = 1

function XUiSkyTowerTask:OnAwake()
    self:AddBtnListener()
    self:InitBtnTab()
    self:InitDynamicTable()
end

function XUiSkyTowerTask:OnStart()
    self.PanelType:SelectIndex(DefaultTabIndex)
end

function XUiSkyTowerTask:OnEnable()
    if self.SelectIndex then
        self.PanelType:SelectIndex(self.SelectIndex)
    end
    self:Refresh()
end

function XUiSkyTowerTask:OnDisable()
    self:StopTimer()
end

-- Ui刷新相关
--------------------------------------------------------------------------------

function XUiSkyTowerTask:Refresh()
    self:RefreshTaskTable()
    self:RefreshRedPoint()
end

function XUiSkyTowerTask:RefreshTaskTable()
    self.ShowDataList = self:GetTaskShowDataList()
    if XTool.IsTableEmpty(self.ShowDataList) then
        self.PanelTaskDailyList.gameObject:SetActiveEx(false)
        self.PanelNoneDailyTask.gameObject:SetActiveEx(true)
        if self.TxtNone then
            self.TxtNone.text = self._Control:GetClientConfigValue("SkyTowerTaskNoneTxt", self.SelectIndex)
        end
    else
        self.PanelTaskDailyList.gameObject:SetActiveEx(true)
        self.PanelNoneDailyTask.gameObject:SetActiveEx(false)
        self:UpdateDynamicTable()
    end
    self:UpdateTime()
    self:StartTimer()
end

function XUiSkyTowerTask:RefreshRedPoint()
    self.BtnDaily:ShowReddot(self._Control:CheckDailyTaskRedPoint())
    self.BtnActivity:ShowReddot(self._Control:CheckAchievementTaskRedPoint())
end

function XUiSkyTowerTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:Refresh()
    end
end

function XUiSkyTowerTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK, XEventId.EVENT_TASK_SYNC }
end

--------------------------------------------------------------------------------

-- 任务页签相关
--------------------------------------------------------------------------------

function XUiSkyTowerTask:InitBtnTab()
    self.TabBtns = {
        self.BtnDaily,
        self.BtnRecipe,
        self.BtnActivity,
    }
    self.PanelType:Init(self.TabBtns, function(index) self:OnSelectedTab(index) end)
    local typeEnum = XMVCA.XSkyTower.TaskType
    self.TaskTypeList = { typeEnum.Daily, typeEnum.Recipe, typeEnum.Activity }
end

function XUiSkyTowerTask:OnSelectedTab(selectIndex)
    if self.SelectIndex == selectIndex then
        return
    end
    self.SelectIndex = selectIndex
    self.TaskType = self.TaskTypeList[selectIndex]
    self:PlayAnimation("QieHuan")
    self:Refresh()
end

--------------------------------------------------------------------------------

-- 任务列表相关
--------------------------------------------------------------------------------

function XUiSkyTowerTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList)
    self.DynamicTable:SetProxy(XUiGridSkyTowerTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiSkyTowerTask:UpdateDynamicTable()
    if XTool.IsTableEmpty(self.ShowDataList) then
        return
    end
    self.DynamicTable:SetDataSource(self.ShowDataList)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiGridSkyTowerTask
function XUiSkyTowerTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.ShowDataList[index]
        grid:ResetData(taskData, self.TaskType)
    end
end

-- 刷新任务数据
function XUiSkyTowerTask:GetTaskShowDataList()
    local timeLimitTaskIds = self._Control:GetActivityTimeLimitTaskIds()
    --local recipeId = self._Control:GetActivityRecipeTaskId()
    local showDailyTaskIds = {}
    local showNormalTaskIds = {}
    local showRecipeTaskIds = {}

    local showTaskIdLists = {
        showDailyTaskIds,
        showRecipeTaskIds,
        showNormalTaskIds
    }
    
    --local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(recipeId)
    --
    --for _, taskId in ipairs(taskCfg.TaskId) do
    --    table.insert(showRecipeTaskIds, taskId)
    --end

    for _, timeLimitTaskId in ipairs(timeLimitTaskIds) do
        if XTaskConfig.IsTimeLimitTaskInTime(timeLimitTaskId) then
            local timeLimitTaskCfg = timeLimitTaskId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(timeLimitTaskId) or {}
            for _, taskId in ipairs(timeLimitTaskCfg.DayTaskId) do
                table.insert(showDailyTaskIds, taskId)
            end
            for _, taskId in ipairs(timeLimitTaskCfg.TaskId) do
                table.insert(showNormalTaskIds, taskId)
            end
        end
    end
    return XDataCenter.TaskManager.GetTaskIdListData(showTaskIdLists[self.SelectIndex], true)
end

--------------------------------------------------------------------------------


-- 任务时间相关
--------------------------------------------------------------------------------

function XUiSkyTowerTask:UpdateTime()
    local endTime = self._Control:GetActivityEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local leftTime = endTime - nowTime
    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
        self.TxtTime.text = self._Control:GetShopTimeTxt(timeStr)
        self.TxtTime.gameObject:SetActiveEx(true)
    else
        self.TxtTime.gameObject:SetActiveEx(false)
    end
end

function XUiSkyTowerTask:StartTimer()
    self:StopTimer()
    XScheduleManagerPro.ScheduleForever(self._OnUpdateTimeScheduleCb, self, XScheduleManagerPro.SECOND)
end

function XUiSkyTowerTask:StopTimer()
        XScheduleManagerPro.UnSchedule(self._OnUpdateTimeScheduleCb, self)
end

--------------------------------------------------------------------------------

-- 按钮相关
--------------------------------------------------------------------------------

function XUiSkyTowerTask:AddBtnListener()
    self.BtnClose.CallBack = function ()
        self:Close()
    end
    self.ImgBg = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/ImgBg")
    if self.ImgBg then XUiHelper.RegisterClickEvent(self, self.ImgBg, self.Close) end
end

--------------------------------------------------------------------------------

function XUiSkyTowerTask:_OnUpdateTimeScheduleCb()
    self:UpdateTime()
end
