---@class XSkyTowerPerformModel:XModel 演出任务
---@field _MainModel XSkyTowerModel
local XSkyTowerPerformModel = XClass(XModel, "XSkyTowerPerformModel")

function XSkyTowerPerformModel:OnInit()

end

function XSkyTowerPerformModel:ClearPrivate()

end

function XSkyTowerPerformModel:ResetAll()

end

function XSkyTowerPerformModel:CheckPerformFinish(performId)
    local PerformState = XMVCA.XSkyTower.PerformState
    local state = self._MainModel:GetPerformState(performId)
    if state == PerformState.Finish then
        return true
    end
    if state == PerformState.NotStart then
        return false
    end
    local template = self._MainModel:GetPerformConfig(performId)
    local taskIds = template.TaskIds
    if XTool.IsTableEmpty(taskIds) then
        return true
    end
    for _, taskId in ipairs(taskIds) do
        if not self:CheckPerformTaskFinish(taskId) then
            return false
        end
    end
    return true
end

function XSkyTowerPerformModel:CheckPerformClaimReward(performId)
    local state = self._MainModel:GetPerformState(performId)
    if state ~= XMVCA.XSkyTower.PerformState.OnGoing then
        return false
    end
    local template = self._MainModel:GetPerformConfig(performId)
    local taskIds = template.TaskIds
    if XTool.IsTableEmpty(taskIds) then
        return true
    end
    for _, taskId in ipairs(taskIds) do
        if not self:CheckPerformTaskFinish(taskId) then
            return false
        end
    end
    return true
end

function XSkyTowerPerformModel:CheckPerformTaskFinish(taskId)
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    return taskData.State == XDataCenter.TaskManager.TaskState.Achieved or taskData.State == XDataCenter.TaskManager.TaskState.Finish
end

return XSkyTowerPerformModel