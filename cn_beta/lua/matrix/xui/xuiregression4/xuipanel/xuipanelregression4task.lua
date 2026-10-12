
local XRegression4EnumConst = require("XModule/XRegression4/XRegression4EnumConst")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridRegression4Task = require("XUi/XUiRegression4/XUiGrid/XUiGridRegression4Task")

---@class XUiPanelRegression4Task: XUiNode
local XUiPanelRegression4Task = XClass(XUiNode, "XUiPanelRegression4Task")

--region   ------------------生命周期 start-------------------
function XUiPanelRegression4Task:OnStart()
    self.RootUi = self.Parent
    self.ViewModel = self._Control:GetMainViewModel()
    self.TaskViewModel = self.ViewModel:GetProperty("_TaskVideModel")
    self:InitUi()
end

function XUiPanelRegression4Task:OnEnable()
    self:RefreshView()
end

function XUiPanelRegression4Task:UpdateTime()
end
--endregion------------------生命周期 finish-------------------

--region   ------------------初始化 start-------------------
function XUiPanelRegression4Task:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList)
    self.DynamicTable:SetProxy(XUiGridRegression4Task, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end
--endregion------------------初始化 finish-------------------

--region   ------------------数据刷新 start-------------------
function XUiPanelRegression4Task:RefreshView()
    if not self._Control:CheckTaskLocalRedPointData() then
        self._Control:MarkTaskLocalRedPointData()
    end
    self.TxtTitle.text = self._Control:GetClientConfigValue("TaskTitle", 1) or ""
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XRegression4EnumConst.Regression4CoinId))

    --拥有BP积分：属性绑定，经验推送到达时自动刷新
    self.RootUi:BindViewModelPropertyToObj(self.ViewModel:GetPassportViewModel(), function(points)
        self.TxtNum.text = XUiHelper.GetText("Regression4TaskOwnNum", tostring(points))
    end, "_Accumulated")

    --领奖后任务状态变化，重刷列表
    self.RootUi:BindViewModelPropertyToObj(self.TaskViewModel, function()
        self:SetupDynamicTable()
    end, "_TaskFinishCount")

    self:SetupDynamicTable()
end

function XUiPanelRegression4Task:SetupDynamicTable()
    --常规任务在前，活动任务在后（各自内部已按状态/类型/优先级排序）
    local taskList = {}
    local conventionList = self.TaskViewModel:GetConventionTaskList() or {}
    local activityList = self.TaskViewModel:GetActivityTaskList() or {}
    for _, taskData in ipairs(conventionList) do
        table.insert(taskList, taskData)
    end
    for _, taskData in ipairs(activityList) do
        table.insert(taskList, taskData)
    end

    local achievedList, normalList, finishedList = {}, {}, {}
    for _, taskData in ipairs(taskList) do
        local state = taskData.State
        if state == XDataCenter.TaskManager.TaskState.Achieved then
            achievedList[#achievedList + 1] = taskData
        elseif state == XDataCenter.TaskManager.TaskState.Finish then
            finishedList[#finishedList + 1] = taskData
        else
            normalList[#normalList + 1] = taskData
        end
    end
    self.TaskList = appendArray(appendArray(achievedList, normalList), finishedList)

    local empty = XTool.IsTableEmpty(self.TaskList)
    self.PanelNoneDailyTask.gameObject:SetActiveEx(empty)
    self.PanelTaskDailyList.gameObject:SetActiveEx(not empty)
    if empty then
        return
    end

    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelRegression4Task:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshTask(self.TaskList[idx], idx)
    end
end
--endregion------------------数据刷新 finish-------------------

return XUiPanelRegression4Task
