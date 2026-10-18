---Control部分类，此处用于演出与订单的进度查询
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

--- 获取进行中的订单Id
---@return number
function XSkyTowerControl:GetRunningIndentId(floorId)
    local performId = self:GetRunningPerformIdByType(XMVCA.XSkyTower.PerformType.Indent, floorId)
    return self:CheckPerformInTime(performId) and performId or nil
end

--- 获取进行中的事件（演出）Id
---@return number
function XSkyTowerControl:GetRunningPerformId(floorId)
    local performId = self:GetRunningPerformIdByType(XMVCA.XSkyTower.PerformType.Event, floorId)
    return self:CheckPerformInTime(performId) and performId or nil
end

--- 获取进行中的楼层区间事件（演出）Id
---@return number
function XSkyTowerControl:GetRunningFloorGroupPerformId(floorId)
    local performId = self:GetRunningPerformIdByType(XMVCA.XSkyTower.PerformType.FloorGroup, floorId)
    return self:CheckPerformInTime(performId) and performId or nil
end

function XSkyTowerControl:CheckRunningPerformFinish(floorId)
    local performId = self:GetRunningPerformId(floorId)
    if not XTool.IsNumberValid(performId) then
        return false
    end
    return self:CheckPerformFinish(performId)
end

function XSkyTowerControl:CheckPerformInTime(performId)
    if not XTool.IsNumberValid(performId) then
        return false
    end
    local timeId = self:GetPerformConfig(performId).TimeId
    return XFunctionManager.CheckInTimeByTimeId(timeId, true)
end

--- 日志全收集
---@return boolean
function XSkyTowerControl:IsAllLogCollect()
    local allFoods = self._Model:GetFoodConfigs()
    for _, food in ipairs(allFoods) do
        --食物还未解锁
        if not self._Model.ClientRun:CheckFoodUnlock(food.Id) then
            return false
        end
    end

    local allIndentIds = self:GetAllIndentIds()
    for _, performId in ipairs(allIndentIds) do
        --订单还未完成
        if not self:IsFinish(performId) then
            return false
        end
    end

    local allPerformIds = self:GetAllPerformIds()
    for _, performId in ipairs(allPerformIds) do
        --事件还未完成
        if not self:IsFinish(performId) then
            return false
        end
    end

    return true
end

return XSkyTowerControl
