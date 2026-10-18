
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiGridRegression4Quest: XUiNode
---@field _Cfg XTableRegression4Survey
---@field Parent XUiPanelRegression4Boost
local XUiGridRegression4Quest = XClass(XUiNode, "XUiGridRegression4Quest")

local Day = 3600 * 24

function XUiGridRegression4Quest:OnStart(cfg)
    self._Cfg = cfg
    self.BtnTongBlack:AddEventListener(handler(self, self.OnBtnTongBlackClick))
end

function XUiGridRegression4Quest:OnEnable()
    self:Refresh()
end

function XUiGridRegression4Quest:Refresh()
    local beginTime = self.Parent.ViewModel:GetProperty("_BeginTime")
    self._IsUnLock = XTime.GetServerNowTimestamp() >= beginTime + self._Cfg.OpenDay * Day
    self._IsAchieve = self:CheckIsFinished()

    self.TxtName.text = self._Cfg.Name
    self.TxtTips.text = self._Cfg.LockTips
    -- 未到可填写日期：上锁遮罩；已完成：置灰【已完成】
    self.ImgMask.gameObject:SetActiveEx(not self._IsUnLock)
    self.BtnTongBlack:SetDisable(self._IsAchieve, not self._IsAchieve)
    self:RefreshRewards()
end

function XUiGridRegression4Quest:RefreshRewards()
    local taskId = self:GetTaskId()
    if not XTool.IsNumberValid(taskId) then
        return
    end
    local rewardId = XTaskConfig.GetTaskRewardId(taskId)
    local rewardGoods = XRewardManager.GetRewardList(rewardId)
    if XTool.IsTableEmpty(rewardGoods) then
        return
    end
    if not self.GridCommon then
        self.GridCommon = XUiGridCommon.New(nil, self.Grid256New)
    end
    self.GridCommon:Refresh(rewardGoods[1])
    self.GridCommon:SetReceived(self._IsAchieve)
end

function XUiGridRegression4Quest:CheckIsFinished()
    local taskId = self:GetTaskId()
    if not XTool.IsNumberValid(taskId) then
        return false
    end
    return XDataCenter.TaskManager.CheckTaskFinished(taskId)
end

function XUiGridRegression4Quest:OnBtnTongBlackClick()
    if not self._IsUnLock then
        XUiManager.TipMsg(self._Cfg.LockTips)
        return
    end
    if self._IsAchieve then
        XUiManager.TipMsg(self._Control:GetClientConfigValue("SurveyAchievedTips", 1))
        return
    end

    local taskId = self:GetTaskId()
    if XTool.IsNumberValid(taskId) then
        XDataCenter.TaskManager.RequestClientTaskFinish(taskId, function()
            XDataCenter.TaskManager.FinishTask(taskId, function(rewards)
                XUiManager.OpenUiObtain(rewards, nil, function()
                    self:Refresh()
                end, nil)
            end)
        end)
    else
        XLog.Error("回归问卷服务器数据中不存在有效的任务Id, 与当前配置不符:", "SurveyId:" .. tostring(self._Cfg.Id), "TaskId:" .. tostring(self._Cfg.TaskId))
    end
    XMVCA.XUrl:SkipByUrlId(self._Cfg.UrlId)
end

function XUiGridRegression4Quest:GetTaskId()
    local surveyViewModel = self.Parent.ViewModel:GetProperty("_SurveyViewModel")
    return surveyViewModel:GetSurveyTaskIdBySurveyId(self._Cfg.Id) or self._Cfg.TaskId
end

return XUiGridRegression4Quest
