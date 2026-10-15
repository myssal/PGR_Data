---@type XSkyTowerControl 客户端模拟任务进度变更
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

local TaskType = XMVCA.XSkyTower.PerformTaskType

function XSkyTowerControl:InitTask()
    self._Commands = {}
    self._IsWaitting = false
    self._ForceSettle = false
    ---<任务Id><任务数据>
    ---@type table<number,XSkyTowerTaskSchedule>
    self._TaskDataDict = {}
    ---<楼层Id><演出类型><演出Id>
    ---@type table<number,table<number,number>>
    --self._FloorPerformDict = {}
    --累计类型
    self._AccumulateTaskType = {
        [TaskType.GainGold] = true,
        [TaskType.Production] = true,
        [TaskType.SellOut] = true,
        [TaskType.PerformTimes] = true,
    }
    --状态类型
    self._StateTaskType = {
        [TaskType.RoleLevel] = true,
        [TaskType.Perform] = true,
        [TaskType.GainGoldSpeed] = true,
    }
    --特殊类型
    self._SpecialTaskType = {
        [TaskType.TowerLevel] = true,
    }
    --进度Handler
    self._ScheduleHandlers = {
        [TaskType.GainGold] = handler(self, self._AddGainGoldSchedule),
        [TaskType.Production] = handler(self, self._AddProductionSchedule),
        [TaskType.SellOut] = handler(self, self._AddSellOutSchedule),
        [TaskType.TowerLevel] = handler(self, self._AddTowerLevelSchedule),
        [TaskType.RoleLevel] = handler(self, self._AddRoleLevelSchedule),
        [TaskType.PerformTimes] = handler(self, self._AddPerformTimesSchedule),
        [TaskType.Perform] = handler(self, self._AddPerformSchedule),
        [TaskType.GainGoldSpeed] = handler(self, self._AddGainGoldSpeedSchedule),
    }
    --条件判断Handler
    self._CheckHandlers = {
        [TaskType.GainGold] = handler(self, self._CheckGainGold),
        [TaskType.Production] = handler(self, self._CheckProduction),
        [TaskType.SellOut] = handler(self, self._CheckSellOut),
        [TaskType.TowerLevel] = handler(self, self._CheckTowerLevel),
        [TaskType.RoleLevel] = handler(self, self._CheckRoleLevel),
        [TaskType.PerformTimes] = handler(self, self._CheckPerformTimes),
        [TaskType.Perform] = handler(self, self._CheckPerform),
        [TaskType.GainGoldSpeed] = handler(self, self._CheckGainGoldSpeed),
    }
    --缓存下服务端任务进度
    self._TempTaskSchedule = {}
end

---获取本地任务进度数据
---@return XSkyTowerTaskSchedule
function XSkyTowerControl:GetTaskLocalData(taskId)
    if not self._TaskDataDict[taskId] then
        XLog.Error(string.format("通天塔不存在本地任务进度数据：%s", taskId))
        return nil
    end
    return self._TaskDataDict[taskId]
end

function XSkyTowerControl:UpdateTaskSchedule()
    for floorId = 1, self:GetMaxFloorId() do
        for _, performType in pairs(XMVCA.XSkyTower.PerformType) do
            self:_UpdatePerformSchedule(floorId, performType)
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_UPDATE)
end

function XSkyTowerControl:_UpdatePerformSchedule(floorId, performType)
    local curPerformId = self:GetRunningPerformIdByType(performType, floorId)
    --self._FloorPerformDict[floorId] = self._FloorPerformDict[floorId] or {}
    --self._FloorPerformDict[floorId][performType] = curPerformId
    self:_UpdateSchedule(curPerformId)
end

--function XSkyTowerControl:_GetCurFloorPerformId(floorId, performType)
--    return self._FloorPerformDict[floorId] and self._FloorPerformDict[floorId][performType] or nil
--end

function XSkyTowerControl:_UpdateSchedule(performId)
    if not XTool.IsNumberValid(performId) then
        return
    end
    local TaskState = XDataCenter.TaskManager.TaskState
    local taskIds = self:GetPerformTaskIds(performId)
    for _, taskId in ipairs(taskIds) do
        local taskCfg = XTaskConfig.GetTaskCfgById(taskId)
        local conditionId = taskCfg.Condition[1]
        if not XTool.IsNumberValid(conditionId) then
            goto continue
        end
        local conditionCfg = XTaskConfig.GetTaskCondition(conditionId)
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        local schedule = taskData.Schedule[1].Value
        local isNewTask = self._TaskDataDict[taskId] == nil
        ---@type XSkyTowerTaskSchedule
        local scheduleData = self._TaskDataDict[taskId] or {}
        scheduleData.TaskId = taskId
        scheduleData.Result = taskCfg.Result
        scheduleData.TaskType = conditionCfg.Type
        scheduleData.Params = conditionCfg.Params
        scheduleData.IsAchieved = taskData.State == TaskState.Achieved or taskData.State == TaskState.Finish
        if self._TempTaskSchedule[taskId] ~= schedule then
            scheduleData.Schedule = schedule
            self._TempTaskSchedule[taskId] = schedule
        end
        self._TaskDataDict[taskId] = scheduleData
        --进入场景或新任务加入时，按任务目标分区补算当前金币速度
        if isNewTask and scheduleData.TaskType == TaskType.GainGoldSpeed then
            self:AddTaskCommand(TaskType.GainGoldSpeed, scheduleData.Params[1])
        end
        :: continue ::
    end
end

function XSkyTowerControl:AddTaskCommand(taskType, id, value)
    if self._AccumulateTaskType[taskType] then
        if id then
            self._Commands[taskType] = self._Commands[taskType] or {}
            self._Commands[taskType][id] = (self._Commands[taskType][id] or 0) + value
        else
            self._Commands[taskType] = (self._Commands[taskType] or 0) + value
        end
    elseif self._StateTaskType[taskType] then
        self._Commands[taskType] = self._Commands[taskType] or {}
        table.insert(self._Commands[taskType], id)
    elseif self._SpecialTaskType[taskType] then
        self._Commands[taskType] = true
    end
end

function XSkyTowerControl:OnTaskTick()
    if (XTool.IsTableEmpty(self._Commands) or XTool.IsTableEmpty(self._TaskDataDict)) and not self._ForceSettle then
        return
    end
    local isScheduleChange, isSettle = false, false
    for _, data in pairs(self._TaskDataDict) do
        local value = self._Commands[data.TaskType]
        if value then
            self._ScheduleHandlers[data.TaskType](data, value)
            if not isSettle and not data.IsAchieved then
                if self._CheckHandlers[data.TaskType](data) then
                    isSettle = true
                end
            end
            isScheduleChange = true
        end
    end
    --任务进度有变更
    if isScheduleChange then
        --如果有结算 在NotifyTask下发后再发事件
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_UPDATE)
    end
    --有任务完成，保留结算需求，直到上次请求已回包且发送间隔达到2秒
    if isSettle then
        self._ForceSettle = true
    end
    if self._ForceSettle and not self._IsWaitting then
        self._IsWaitting = true
        self._ForceSettle = false
        local isRequested = self:RequestSettleToNow(function()
            self._IsWaitting = false
        end)
        -- CD拦截不回调，保留结算需求留到后续Tick重试。
        if not isRequested then
            self._IsWaitting = false
            self._ForceSettle = true
        end
    end
    self._Commands = {}
end

function XSkyTowerControl:_ClearTaskData(performId)
    local taskIds = self:GetPerformTaskIds(performId)
    for _, taskId in ipairs(taskIds) do
        self._TaskDataDict[taskId] = nil
        self._TempTaskSchedule[taskId] = nil
    end
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_CheckGainGold(scheduleData)
    return scheduleData.Schedule >= scheduleData.Params[1]
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_AddGainGoldSchedule(scheduleData, value)
    scheduleData.Schedule = scheduleData.Schedule + value
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_CheckProduction(scheduleData)
    return scheduleData.Schedule >= scheduleData.Params[2]
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_AddProductionSchedule(scheduleData, value)
    local count = value[scheduleData.Params[1]]
    if XTool.IsNumberValid(count) then
        scheduleData.Schedule = scheduleData.Schedule + count
    end
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_CheckSellOut(scheduleData)
    return scheduleData.Schedule >= scheduleData.Params[2]
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_AddSellOutSchedule(scheduleData, value)
    local count = value[scheduleData.Params[1]]
    if XTool.IsNumberValid(count) then
        scheduleData.Schedule = scheduleData.Schedule + count
    end
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_CheckTowerLevel(scheduleData)
    return scheduleData.Schedule >= scheduleData.Params[1]
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_AddTowerLevelSchedule(scheduleData)
    scheduleData.Schedule = self:GetSkyTowerLv()
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_CheckRoleLevel(scheduleData)
    return scheduleData.Schedule >= scheduleData.Params[1]
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_AddRoleLevelSchedule(scheduleData, value)
    local targetCharacterId = scheduleData.Params[2]
    if not XTool.IsNumberValid(targetCharacterId) then
        local infos = self._Model:GetCharacterInfos()
        if not infos then
            return
        end
        local maxLv = 0
        for _, info in pairs(infos) do
            maxLv = math.max(maxLv, info.CharacterLv)
        end
        scheduleData.Schedule = maxLv
    elseif table.contains(value, targetCharacterId) then
        scheduleData.Schedule = self:GetCurCharacterLevel(targetCharacterId)
    end
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_CheckPerformTimes(scheduleData)
    return scheduleData.Schedule >= scheduleData.Params[1]
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_AddPerformTimesSchedule(scheduleData, value)
    local targetType = scheduleData.Params[2]
    if not XTool.IsNumberValid(targetType) then
        for _, count in pairs(value) do
            scheduleData.Schedule = scheduleData.Schedule + count
        end
        return
    end
    local count = value[targetType]
    if XTool.IsNumberValid(count) then
        scheduleData.Schedule = scheduleData.Schedule + count
    end
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_CheckPerform(scheduleData)
    return scheduleData.Schedule >= 1
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_AddPerformSchedule(scheduleData, value)
    if not table.contains(value, scheduleData.Params[1]) then
        return
    end
    scheduleData.Schedule = 1
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_CheckGainGoldSpeed(scheduleData)
    return scheduleData.Schedule >= scheduleData.Params[2]
end

---@param scheduleData XSkyTowerTaskSchedule
function XSkyTowerControl:_AddGainGoldSpeedSchedule(scheduleData, value)
    local floorGroupId = scheduleData.Params[1]
    if not table.contains(value, floorGroupId) then
        return
    end
    --判断是否满足工作数量限制
    local workLimit = scheduleData.Params[3]
    local saleWorkCount = 0
    if XTool.IsNumberValid(workLimit) then
        for _, floorId in ipairs(self:GetFloorIdsByGroupId(floorGroupId)) do
            for index = 1, self:GetFloorWorkNum(floorId) do
                local info = self._Model:GetFloorWorkPosInfo(floorId, index)
                if info and info.WorkType == XMVCA.XSkyTower.WorkType.Sale then
                    saleWorkCount = saleWorkCount + 1
                    if saleWorkCount > workLimit then
                        return
                    end
                end
            end
        end
    end
    --进度记录最大值
    local profitData = self:GetProductionStatistics()
    local goldSpeed = math.floor(profitData[floorGroupId].GoldSpeed)
    if scheduleData.Schedule then
        scheduleData.Schedule = math.max(scheduleData.Schedule, goldSpeed)
    else
        scheduleData.Schedule = goldSpeed
    end
end

return XSkyTowerControl

---@class XSkyTowerTaskSchedule
---@field TaskId number 任务Id
---@field Params number[] 任务条件参数
---@field TaskType number 任务类型 对应[XMVCA.XSkyTower.TaskType]
---@field Schedule number 进度值
---@field Result number 目标值
---@field IsAchieved boolean 任务是否已完成（已完成的任务，进度变更将不会发送结算协议）