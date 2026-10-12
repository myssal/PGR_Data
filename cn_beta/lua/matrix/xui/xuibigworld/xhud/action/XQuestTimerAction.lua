local XQuestBaseAction = require("XUi/XUiBigWorld/XHud/Action/XQuestBaseAction")

---@class XQuestTimerAction : XQuestBaseAction
local XQuestTimerAction = XClass(XQuestBaseAction, "XQuestTimerAction")

function XQuestTimerAction:OnInit(delay)
    self._Delay = delay or 0
end

function XQuestTimerAction:Execute()
    self:StopTimer()
    if self._Delay and self._Delay > 0 then
        XScheduleManagerPro.ScheduleOnce(XQuestTimerAction._OnFinishScheduleCb, self, self._Delay)

    else
        self:Finish()
    end
end

function XQuestTimerAction:OnFinish()
    self:StopTimer()
end

function XQuestTimerAction:OnDestroy()
    self:StopTimer()
end

function XQuestTimerAction:StopTimer()
    XScheduleManagerPro.UnSchedule(XQuestTimerAction._OnFinishScheduleCb, self)
end

function XQuestTimerAction:OnPause()
    self:StopTimer()
    self:Finish()
end

function XQuestTimerAction:GetActionType()
    return XMVCA.XBigWorldQuest.ActionType.Timer
end

function XQuestTimerAction:_OnFinishScheduleCb()
    self:Finish()
end

return XQuestTimerAction