
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

local AnimInterval = 30

---@class XUiGridRegression4Task: XUiNode
local XUiGridRegression4Task = XClass(XUiNode, "XUiGridRegression4Task")

function XUiGridRegression4Task:OnStart()
    self.RootUi = self.Parent.RootUi
    -- 奖励列表容器（TaskGridList > Viewport > Content）
    self.TaskContent = self.GridCommon.transform.parent
    self.RewardItems = {}
    self:InitCb()
end

function XUiGridRegression4Task:OnDisable()
    XScheduleManagerPro.UnSchedule(XUiGridRegression4Task._OnPlayTimelineCb, self)
    if not XTool.UObjIsNil(self.PanelAnimation) then
        self:GetAnimCanvasGroup().alpha = 1
    end
end

function XUiGridRegression4Task:InitCb()
    self.BtnFinish:AddEventListener(handler(self, self.OnBtnFinishClick))
    self.BtnSkip:AddEventListener(handler(self, self.OnBtnSkipClick))
end

---@param taskData table 任务数据
---@param index number 在列表中的序号（1-based），用于错开入场动画
function XUiGridRegression4Task:RefreshTask(taskData, index)
    if not taskData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.Data = taskData

    local taskViewModel = self:GetTaskViewModel()

    local finish = taskData.State == XDataCenter.TaskManager.TaskState.Finish
    local achieved = taskData.State == XDataCenter.TaskManager.TaskState.Achieved

    local template = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id)
    self.TxtTaskName.text = template.Title
    self.TxtTaskDescribe.text = template.Desc

    self:RefreshReward(template.RewardId)

    --进度条（多条件任务不显示）
    local showProgress = #template.Condition < 2
    self.ImgProgress.gameObject:SetActiveEx(showProgress)
    self.TxtTaskNumQian.gameObject:SetActiveEx(showProgress)
    if showProgress then
        local result = template.Result > 0 and template.Result or 1
        XTool.LoopMap(taskData.Schedule, function(_, pair)
            local value = math.min(result, pair.Value)
            self.ImgProgress.fillAmount = XUiHelper.GetFillAmountValue(value, result)
            self.TxtTaskNumQian.text = value .. "/" .. result
        end)
    end

    --剩余时间
    local skipId = template.SkipId
    local time = taskViewModel:GetEndTime(taskData.Id)
    local disable = not XTool.IsNumberValid(skipId) or time < 0
    local showTime = time ~= 0 and not finish
    self.PanelTime.gameObject:SetActiveEx(showTime)
    if showTime then
        local tipsIndex = time > 0 and 1 or 2
        local tips = self._Control:GetClientConfigValue("TaskEndTime", tipsIndex)
        self.TxtTime.text = string.format(tips, XUiHelper.GetTimeAndUnit(math.abs(time),
                XUiHelper.TimeUnit.Hour, XUiHelper.TimeUnit.Day))
    end
    self.SkipId = skipId

    self:RefreshButton(finish, achieved, disable)
    self:PlayEnterAnim(index)
end

function XUiGridRegression4Task:PlayEnterAnim(index)
    if self.HasPlayTimeline then
        return
    end
    if XScheduleManagerPro.HasSchedule(XUiGridRegression4Task._OnPlayTimelineCb, self) then
        return
    end

    self:GetAnimCanvasGroup().alpha = 0

    local delay = (index - 1) * AnimInterval
    if delay <= 0 then
        XScheduleManagerPro.ScheduleNextFrame(XUiGridRegression4Task._OnPlayTimelineCb, self)
    else
        XScheduleManagerPro.ScheduleOnce(XUiGridRegression4Task._OnPlayTimelineCb, self, delay)
    end
end

function XUiGridRegression4Task:_OnPlayTimelineCb()
    self.HasPlayTimeline = true
    if XTool.UObjIsNil(self.TimeLine1) then
        return
    end
    self.TimeLine1:PlayTimelineAnimation(function()
        self:GetAnimCanvasGroup().alpha = 1
    end)
end

function XUiGridRegression4Task:GetAnimCanvasGroup()
    if not self._AnimCanvasGroup then
        self._AnimCanvasGroup = self.PanelAnimation:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
    return self._AnimCanvasGroup
end

function XUiGridRegression4Task:RefreshReward(rewardId)
    self.RewardId = rewardId
    local rewardList = XRewardManager.GetRewardList(rewardId) or table.empty
    self.RewardItems = XUiHelper.RefreshUiObjectList(self.RewardItems, self.TaskContent, self.GridCommon, #rewardList, handler(self, self.OnRewardItemRefresh))
end

function XUiGridRegression4Task:OnRewardItemRefresh(index, item)
    if not item.GridCommon then
        item.GridCommon = XUiGridCommon.New(self.RootUi, item.GameObject)
    end
    local rewardList = XRewardManager.GetRewardList(self.RewardId) or table.empty
    item.GridCommon:Refresh(rewardList[index])
    item.TemplateId = rewardList[index] and rewardList[index].TemplateId
end

--- 刷新按钮状态
---@param finish boolean 已完成且领取
---@param achieved boolean 已完成未领取
---@param disableBtnSkip boolean 禁用跳转按钮
function XUiGridRegression4Task:RefreshButton(finish, achieved, disableBtnSkip)
    self.BtnSkip.gameObject:SetActiveEx(not finish and not achieved)
    self.BtnFinish.gameObject:SetActiveEx(not finish and achieved)
    self.ImgComplete.gameObject:SetActiveEx(finish)

    self.BtnSkip:SetDisable(disableBtnSkip, not disableBtnSkip)
end

--- 领取任务奖励
function XUiGridRegression4Task:OnBtnFinishClick()
    if not self:OnBeforeFinishCheck() then
        return
    end
    local data = self.Data
    XDataCenter.TaskManager.FinishTask(data.Id, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
        self:GetTaskViewModel():UpdateFinishCount()
        XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION4_TASK_STATUS_CHANGE)
    end)
end

--- 跳转
function XUiGridRegression4Task:OnBtnSkipClick()
    if not XTool.IsNumberValid(self.SkipId) then
        return
    end
    XFunctionManager.SkipInterface(self.SkipId)
end

--- 领取前检查武器/意识背包容量
function XUiGridRegression4Task:OnBeforeFinishCheck()
    if not XTool.IsNumberValid(self.RewardId) then
        return false
    end
    local rewards = XRewardManager.GetRewardList(self.RewardId)
    local weaponCount, chipCount = 0, 0
    for i = 1, #rewards do
        local templateId = self.RewardItems[i] and self.RewardItems[i].TemplateId
        if templateId and XMVCA.XEquip:IsClassifyEqualByTemplateId(templateId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
            weaponCount = weaponCount + 1
        elseif templateId and XMVCA.XEquip:IsClassifyEqualByTemplateId(templateId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
            chipCount = chipCount + 1
        end
    end
    if (weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false)
            or (chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false)
    then
        return false
    end
    return true
end

function XUiGridRegression4Task:GetTaskViewModel()
    return self._Control:GetMainViewModel():GetProperty("_TaskVideModel")
end

return XUiGridRegression4Task
