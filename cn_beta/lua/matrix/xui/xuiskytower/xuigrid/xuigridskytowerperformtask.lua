local ColorStr = {
    Enough = "#FFFFFF",
    NotEnough = "#FB7272"
}

---@class XUiGridSkyTowerPerformTask : XUiNode
---@field _Control XSkyTowerControl
local XUiGridSkyTowerPerformTask = XClass(XUiNode, "XUiGridSkyTowerPerformTask")

function XUiGridSkyTowerPerformTask:OnStart(performId)
    self.PerformId = performId
    self.GridFood.gameObject:SetActiveEx(false)
    self.GridDesc.gameObject:SetActiveEx(false)
    self.GridFoods = {}
    self.GridDescList = {}
end

function XUiGridSkyTowerPerformTask:Refresh(taskIds)
    self.Type1.gameObject:SetActiveEx(true)
    self.Type2.gameObject:SetActiveEx(false)
    self:RefreshText(taskIds)
end

function XUiGridSkyTowerPerformTask:RefreshText(taskIds)
    if XTool.IsTableEmpty(taskIds) then
        return
    end
    for index, taskId in ipairs(taskIds) do
        local grid = self.GridDescList[index]
        if not grid then
            local ui = index == 1 and self.GridDesc or XUiHelper.Instantiate(self.GridDesc, self.Type1)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridDescList[index] = grid
            ui.gameObject:SetActiveEx(true)
            grid.TxtTask.requestImage = XMVCA.XSkyTower.RichTextImageCallBack
        end
        self:RefreshDescGrid(grid, taskId)
    end
end

function XUiGridSkyTowerPerformTask:RefreshFood(taskIds)
    local schedule = {}
    for _, taskId in ipairs(taskIds) do
        local taskCfg = XTaskConfig.GetTaskCfgById(taskId)
        for _, conditionId in ipairs(taskCfg.Condition) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            schedule[conditionId] = taskData.Schedule[1].Value
        end
    end

    if XTool.IsTableEmpty(schedule) then
        return
    end
    local index = 1
    for conditionId, value in pairs(schedule) do
        local params = XTaskConfig.GetTaskCondition(conditionId).Params
        local grid = self.GridFoods[index]
        if not grid then
            local ui = index == 1 and self.GridFood or XUiHelper.Instantiate(self.GridFood, self.Type2)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridFoods[index] = grid
            ui.gameObject:SetActiveEx(true)
        end
        self:RefreshFoodGrid(grid, params[1], params[2], value)
        index = index + 1
    end
end

function XUiGridSkyTowerPerformTask:RefreshFoodGrid(grid, paramId, target, value)
    if not grid then
        return
    end
    local workType = math.floor(paramId / 10000)
    local foodId = paramId % 10000
    grid.TxtName.text = self._Control:GetProductName(workType, foodId)
    local colorStr = target > value and ColorStr.NotEnough or ColorStr.Enough
    grid.TxtNeed.text = string.format("<color=%s>%d</color>/%d", colorStr, value, target)
    grid.RImgFood:SetRawImage(self._Control:GetProductIcon(workType, foodId))
    grid.ImgQuality:SetSprite(self._Control:GetProductQualityIcon(workType, foodId, false))
end

function XUiGridSkyTowerPerformTask:RefreshDescGrid(grid, taskId)
    if not grid then
        return
    end
    grid.TxtTask.text = self._Control:GetTaskDescWithProgress(taskId)
    grid.ImgComplete.gameObject:SetActiveEx(self._Control:CheckPerformTaskFinish(taskId))
end

return XUiGridSkyTowerPerformTask
