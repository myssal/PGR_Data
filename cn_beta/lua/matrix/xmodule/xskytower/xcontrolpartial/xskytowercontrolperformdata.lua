---Control部分类，此处用于演出/订单的数据读取与任务进度
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

local DEFAULT_TIME_FORMAT = "yyyy/MM/dd"

--region 演出状态

--- 活动内的演出/订单信息，包含普通事件与楼层区间事件（只读）
---@return table<number, XSkyTowerPerformInfoProtocol>
function XSkyTowerControl:GetPerformInfos()
    return self._Model:GetPerformInfos() or table.empty
end

---@return number XMVCA.XSkyTower.PerformState
function XSkyTowerControl:GetState(performId)
    return self._Model:GetPerformState(performId)
end

function XSkyTowerControl:IsFinish(performId)
    return self:GetState(performId) == XMVCA.XSkyTower.PerformState.Finish
end

function XSkyTowerControl:IsNotStart(performId)
    return self:GetState(performId) == XMVCA.XSkyTower.PerformState.NotStart
end

function XSkyTowerControl:IsOnGoing(performId)
    return self:GetState(performId) == XMVCA.XSkyTower.PerformState.OnGoing
end

---演出正在进行且打开过才能显示
function XSkyTowerControl:IsPerformShow(performId)
    if not self:IsOnGoing(performId) then
        return false
    end
    local record = self:GetPerformStoryInfo(performId) or table.empty
    for _, talkId in ipairs(self:GetTalkStoryTalkIds(performId)) do
        if self:GetTalkConfig(talkId).Type == XMVCA.XSkyTower.MessageType.Select and not record[talkId] then
            return false
        end
    end
    return true
end

--- 演出是否全部任务完成（可结算）
function XSkyTowerControl:CheckPerformFinish(performId)
    return self._Model.Perform:CheckPerformFinish(performId)
end

---演出是否可领取奖励（正在进行中+任务已全部完成）
function XSkyTowerControl:CheckPerformClaimReward(performId)
    return self._Model.Perform:CheckPerformClaimReward(performId)
end

--- 演出单个任务是否完成
function XSkyTowerControl:CheckPerformTaskFinish(taskId)
    return self._Model.Perform:CheckPerformTaskFinish(taskId)
end

--- 进行中的演出信息
---@param performType number XMVCA.XSkyTower.PerformType
function XSkyTowerControl:GetRunningPerformInfo(performType, floorId)
    return self._Model:GetRunningPerformInfo(performType, floorId)
end

--- 进行中的演出Id
---@return number 无进行中演出返回0
function XSkyTowerControl:GetRunningPerformIdByType(performType, floorId)
    local performInfo = self:GetRunningPerformInfo(performType, floorId)
    return performInfo and performInfo.PerformId or 0
end

--endregion

--region 任务与条件查询

---演出剧情的玩家选项记录
function XSkyTowerControl:GetPerformStoryInfo(performId)
    return self._Model:GetPerformStoryRecord(performId)
end

--- 任务描述（带进度）
function XSkyTowerControl:GetTaskDescWithProgress(taskId)
    local progress = ""
    local taskLocalData = self:GetTaskLocalData(taskId)
    if taskLocalData then
        progress = string.format("(%s/%s)", taskLocalData.Schedule, taskLocalData.Result)
    end
    return string.format("%s %s", XTaskConfig.GetTaskCfgById(taskId).Desc, progress)
end

--- 任务描述（带进度，达成的进度染绿）
---@return string 富文本
function XSkyTowerControl:GetTaskDescWithProgressRich(taskId)
    local finishColor = self:GetClientConfigValue("PerformProgressFinishColor")
    local progress = ""
    local taskLocalData = self:GetTaskLocalData(taskId)
    if taskLocalData then
        local schedule, result = taskLocalData.Schedule, taskLocalData.Result
        if schedule >= result then
            progress = string.format("<color=#%s>(%s/%s)</color>", finishColor, schedule, result)
        else
            progress = string.format("(%s/%s)", schedule, result)
        end
    end
    return string.format("%s %s", XTaskConfig.GetTaskCfgById(taskId).Desc, progress)
end

---安排工作弹窗里展示的区间事件/订单进度文本，按整条事件或订单的完成状态排序
---@return string[]
function XSkyTowerControl:GetWorkOrderDescList(maxCount, floorId)
    local groupId = self:GetFloorGroupIdByFloorId(floorId)
    if maxCount <= 0 or not XTool.IsNumberValid(groupId) then
        return table.empty
    end

    local list = {}
    local PerformType = XMVCA.XSkyTower.PerformType
    local typePriority = {
        [PerformType.Event] = 1,
        [PerformType.FloorGroup] = 2,
        [PerformType.Indent] = 3,
    }
    local performs = {}
    for _, info in pairs(self._Model:GetPerformInfos() or table.empty) do
        --只展示已解锁且尚未结算的事件/订单，排除未开始和已结算状态
        if not self:IsPerformShow(info.PerformId) then
            goto continue
        end
        local config = self._Model:GetPerformConfig(info.PerformId)
        local priority = typePriority[config.Type]
        if priority and self:GetFloorGroupIdByFloorId(config.FloorId) == groupId and not XTool.IsTableEmpty(config.TaskIds) then
            performs[#performs + 1] = {
                PerformId = info.PerformId,
                Priority = priority,
                IsFinish = self:CheckPerformFinish(info.PerformId),
                TaskIds = config.TaskIds,
            }
        end
        :: continue ::
    end
    --已完成事件＞已完成订单＞未完成事件＞未完成订单，事件内仍按普通事件＞楼层区间事件排序
    table.sort(performs, function(a, b)
        if a.IsFinish ~= b.IsFinish then
            return a.IsFinish
        end
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        end
        return a.PerformId > b.PerformId
    end)

    for _, perform in ipairs(performs) do
        for _, taskId in ipairs(perform.TaskIds) do
            if #list >= maxCount then
                return list
            end
            list[#list + 1] = self:GetTaskDescWithProgressRich(taskId)
        end
    end
    return list
end

--endregion

--region 演出配置查询

function XSkyTowerControl:IsIndent(performId)
    return self:GetPerformType(performId) == XMVCA.XSkyTower.PerformType.Indent
end

function XSkyTowerControl:IsPerform(performId)
    return self:GetPerformType(performId) == XMVCA.XSkyTower.PerformType.Event
end

function XSkyTowerControl:IsFloorGroupPerform(performId)
    return self:GetPerformType(performId) == XMVCA.XSkyTower.PerformType.FloorGroup
end

--- 演出所在楼层的房间
function XSkyTowerControl:GetPerformRoom(performId)
    return self:GetRoom(self:GetFloorId(performId))
end

--- 演出更新时间文本
function XSkyTowerControl:GetTimeStr(performId, format)
    format = format or DEFAULT_TIME_FORMAT
    local performInfo = self._Model:GetPerformInfo(performId)
    --todo 服务端协议未定，UpdateTime为暂定字段名（演出最后更新时间戳），需要服务端下发
    local updateTime = performInfo and performInfo.UpdateTime or 0
    return XTime.TimestampToGameDateTimeString(updateTime, format)
end

--- 演出解锁条件Id列表
function XSkyTowerControl:GetUnlockConditions(performId)
    local template = self:GetPerformConfig(performId)
    return template and template.UnlockConditionIds or table.empty
end

--- 演出解锁条件描述（返回第一个未达成条件的描述，全部达成返回未开始文本）
function XSkyTowerControl:GetUnlockConditionDesc(performId)
    for _, conditionId in ipairs(self:GetUnlockConditions(performId)) do
        local result, desc = XConditionManager.CheckCondition(conditionId)
        if not result then
            return desc
        end
    end
    local tip = self:GetClientConfigValue("PerformNotStartText", 1)
    return string.format(tip, self:GetPerformTypeTitle(performId))
end

--endregion

return XSkyTowerControl
