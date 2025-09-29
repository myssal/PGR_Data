---@class XUiGridBWQuestItem : XUiNode
---@field Parent XUiBigWorldPanelQuest
local XUiGridBWQuestItem = XClass(XUiNode, "XUiGridBWQuestItem")
local WrapHold = CS.UnityEngine.Playables.DirectorWrapMode.Hold

function XUiGridBWQuestItem:OnStart()
    XUiHelper.RegisterClickEvent(self.Parent, self.Transform, self.Parent.OnQuestClick)
end


function XUiGridBWQuestItem:OnDisable()
    self._Id = false
    self:StopTimer()
end

---@param objective XBigWorldQuestObjective
function XUiGridBWQuestItem:Update(objective, index)
    local id = objective:GetId()
    local progress = XMVCA.XBigWorldQuest:GetObjectiveProgressDesc(id, objective:GetProgress(), objective:GetMaxProgress())
    self.TxtContent.text = progress
    local isFinish = objective:IsFinish()
    self:UpdateFinish(isFinish)
    self._Id = id
end

function XUiGridBWQuestItem:UpdateFinish(isFinish)
    self.Complete.gameObject:SetActiveEx(isFinish)
    self.UnComplete.gameObject:SetActiveEx(not isFinish)
end

function XUiGridBWQuestItem:PlayEnableAnimation(delay, func, beginCb)
    self:PlayTimeAnimation(self.GridQuestEnable, delay, func, beginCb)
end

function XUiGridBWQuestItem:PlayFinishAnimation(delay, func, beginCb)
    self:PlayTimeAnimation(self.GridQuestFinish, delay, func, beginCb)
end

---@param grid UnityEngine.RectTransform
function XUiGridBWQuestItem:PlayTimeAnimation(grid, delay, func, beginCb)
    if not grid then
        XLog.Error("不存在动画节点")
        return
    end
    
    if delay and delay > 0 then
        self:StopTimer()
        self._Timer = XScheduleManager.ScheduleOnce(function()
            self:StopTimer()
            self:_PlayGridTimeAnimation(grid, func, beginCb)
        end, delay)
    else
        self:_PlayGridTimeAnimation(grid, func, beginCb)
    end
end

function XUiGridBWQuestItem:_PlayGridTimeAnimation(grid, finish, beginCb)
    if not grid then
        return
    end

    grid:PlayTimelineAnimation(finish, beginCb, WrapHold, true)
end

function XUiGridBWQuestItem:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

function XUiGridBWQuestItem:GetObjectiveId()
    return self._Id
end

return XUiGridBWQuestItem