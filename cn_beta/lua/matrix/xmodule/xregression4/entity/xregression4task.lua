

local XRegression4EnumConst = require("XModule/XRegression4/XRegression4EnumConst")
local XRegression4Task = XClass(XDataEntityBase, "XRegression4Task")

local default = {
    _Id = 0, --战令玩法Id
    _TaskGroupId = 0,      --任务组id
    _TaskFinishCount = 0, --任务完成次数（仅用于更新界面）
}

-- 默认排序优先级
local DefaultTaskState = 999
-- 任务类型排序
local TaskTypeSortOrder
-- 任务状态排序
local TaskStateSortOrder
-- 星期一
local Monday = 1

local function InitTaskSortOrder()
    TaskTypeSortOrder = {
        [XRegression4EnumConst.TaskType.Daily] = 1,
        [XRegression4EnumConst.TaskType.Weekly] = 2,
        [XRegression4EnumConst.TaskType.TimeLimit] = 3,
        [XRegression4EnumConst.TaskType.Permanent] = 4,
    }

    TaskStateSortOrder = {
        [XDataCenter.TaskManager.TaskState.Achieved] = 0,
        [DefaultTaskState] = 1,
        [XDataCenter.TaskManager.TaskState.Invalid] = 2,
        [XDataCenter.TaskManager.TaskState.Finish] = 3,
    }
end

function XRegression4Task:Ctor(id)
    self:Init(default, id)
end

function XRegression4Task:InitData(id)
    self:SetProperty("_Id", id)
    self:SetProperty("_TaskGroupId", XMVCA.XRegression4:GetPassportTaskGroupId(id))

    InitTaskSortOrder()
    
    self.EndTimeFunc = {
        [XRegression4EnumConst.TaskType.Daily]  = handler(self, self._GetDailyTaskEndTime),
        [XRegression4EnumConst.TaskType.Weekly] = handler(self, self._GetWeeklyTaskEndTime),
        [XRegression4EnumConst.TaskType.Permanent] = handler(self, self._GetPermanentTaskEndTime),
        [XRegression4EnumConst.TaskType.TimeLimit] = handler(self, self._GetTimeLimitTaskEndTime),
    }
end

--常规任务列表（日常+周常）
function XRegression4Task:GetConventionTaskList(needSort)
    local list = XMVCA.XRegression4:GetPassportTaskList(XRegression4EnumConst.TaskType.Daily, self._TaskGroupId)
    list = appendArray(list, XMVCA.XRegression4:GetPassportTaskList(XRegression4EnumConst.TaskType.Weekly, self._TaskGroupId))
    if needSort ~= false then
        needSort = true
    end
    return self:_GetTaskList(list, needSort)
end

--活动任务（常驻 + 限时常驻）
function XRegression4Task:GetActivityTaskList(needSort)
    local list = XMVCA.XRegression4:GetPassportTaskList(XRegression4EnumConst.TaskType.Permanent, self._TaskGroupId)
    list = appendArray(list, XMVCA.XRegression4:GetPassportTaskList(XRegression4EnumConst.TaskType.TimeLimit, self._TaskGroupId))
    if needSort ~= false then
        needSort = true
    end
    return self:_GetTaskList(list, needSort)
end

function XRegression4Task:GetTaskGroupTemplateByTaskId(taskId)
    return XMVCA.XRegression4:GetPassportTaskGroupTemplateByTaskId(self._TaskGroupId, taskId)
end

function XRegression4Task:GetTaskType(taskId)
    local template = self:GetTaskGroupTemplateByTaskId(taskId)
    return template.Type
end

function XRegression4Task:GetEndTime(taskId)
    local type = self:GetTaskType(taskId)
    local func = self.EndTimeFunc[type]
    if not func then
        return 0
    end
    return func(taskId)
end

function XRegression4Task:GetTaskListByType(taskType)
    if taskType == XRegression4EnumConst.TaskType.Daily 
            or taskType == XRegression4EnumConst.TaskType.Weekly then
        return self:GetConventionTaskList()
    else
        return self:GetActivityTaskList()
    end
end

--- 获取可领取的任务列表
---@return number[]
--------------------------
function XRegression4Task:GetAchievedTaskList()
    local taskIds = {}
    for _, task in ipairs(self:GetConventionTaskList(false)) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, task.Id)
        end
    end

    for _, task in ipairs(self:GetActivityTaskList(false)) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, task.Id)
        end
    end
    
    return taskIds
end

function XRegression4Task:GetAchievedConventionTaskList()
    local taskIds = {}
    for _, task in ipairs(self:GetConventionTaskList(false)) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, task.Id)
        end
    end
    return taskIds
end

function XRegression4Task:GetAchievedActivityTaskList()
    local taskIds = {}
    for _, task in ipairs(self:GetActivityTaskList(false)) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, task.Id)
        end
    end
    return taskIds
end

function XRegression4Task:UpdateFinishCount()
    local count = self._TaskFinishCount
    count = count + 1
    self:SetProperty("_TaskFinishCount", count)
end

--region   ------------------private start-------------------

function XRegression4Task:_GetTaskList(list, needSort)
    local taskList = {}
    for _, taskId in ipairs(list or {}) do
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if taskData then
            table.insert(taskList, taskData)
        end
    end
    return needSort and self:_SortTaskList(taskList) or taskList
end

function XRegression4Task:_SortTaskList(taskList)
    table.sort(taskList, function(taskA, taskB) 
        local orderA = TaskStateSortOrder[taskA.State] or TaskStateSortOrder[DefaultTaskState]
        local orderB = TaskStateSortOrder[taskB.State] or TaskStateSortOrder[DefaultTaskState]
        if orderA ~= orderB then
            return orderA < orderB
        end
        
        local typeA = self:GetTaskType(taskA.Id)
        local typeB = self:GetTaskType(taskB.Id)
        orderA = TaskTypeSortOrder[typeA] or DefaultTaskState
        orderB = TaskTypeSortOrder[typeB] or DefaultTaskState
        if orderA ~= orderB then
            return orderA < orderB
        end

        orderA = XTaskConfig.GetTaskPriority(taskA.Id)
        orderB = XTaskConfig.GetTaskPriority(taskB.Id)
        if orderA ~= orderB then
            return orderA > orderB
        end
        
        return taskA.Id < taskB.Id
    end)
    
    return taskList
end

function XRegression4Task:_GetDailyTaskEndTime(taskId)
    local timeOfNow = XTime.GetServerNowTimestamp()
    local nextRefresh = XTime.GetSeverNextRefreshTime()
    return math.max(0, nextRefresh - timeOfNow)
end

function XRegression4Task:_GetWeeklyTaskEndTime(taskId)
    local timeOfNow = XTime.GetServerNowTimestamp()
    local nextRefresh = XTime.GetSeverNextWeekOfDayRefreshTime(Monday)
    return math.max(0, nextRefresh - timeOfNow)
end

function XRegression4Task:_GetPermanentTaskEndTime(taskId)
    return 0
end

--- 获取限时任务时间，为负数则活动未开启，为0活动结束，正数表示距离活动结束时间
---@param taskId 任务Id
---@return number
--------------------------
function XRegression4Task:_GetTimeLimitTaskEndTime(taskId)
    local template = self:GetTaskGroupTemplateByTaskId(taskId)
    local timeId = template.TimeId or 0
    if not XTool.IsNumberValid(timeId) then
        return 0
    end
    local timeOfNow = XTime.GetServerNowTimestamp()
    local timeOfEnd = XFunctionManager.GetEndTimeByTimeId(timeId)
    local timeOfBgn = XFunctionManager.GetStartTimeByTimeId(timeId)
    --未开始
    if timeOfBgn > timeOfNow then
        return timeOfNow - timeOfBgn
    end
    return math.max(0, timeOfEnd - timeOfNow)
end

--endregion------------------private finish------------------

return XRegression4Task