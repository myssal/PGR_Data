---@class XQuestAction
---@field PanelQuest XUiBigWorldPanelQuest
local XQuestAction = XClass(nil, "XQuestAction")

local WrapHold = CS.UnityEngine.Playables.DirectorWrapMode.Hold

function XQuestAction:Ctor(panelQuest)
    self._RefCount = 0
    self._Active = false
    self.PanelQuest = panelQuest
    self:OnInit()
end

function XQuestAction:OnInit()
    self._BeginCb = function() 
        self:AddRefCount()
    end
    
    self._FinishCb = function() 
        self:SubRefCount()
        self:Finish()
    end
end

---@param data XBigWorldQuestOpData
function XQuestAction:SetOperateData(data)
    self._OperateData = data
end

function XQuestAction:Release()
    self._RefCount = 0
    self._Active = false
    self.PanelQuest:RecycleAction(self, self._OperateData)
    self._OperateData = nil
end

function XQuestAction:Begin()
    self._Active = true
    self:AddEvent()
end

function XQuestAction:Finish()
    if self._RefCount > 0 then
        return
    end

    if not self._Active then
        return
    end

    self:RemoveEvent()
    self:Release()
    self.PanelQuest:OperateDequeue()
end

function XQuestAction:AddRefCount()
    self._RefCount = self._RefCount + 1
end

function XQuestAction:SubRefCount()
    self._RefCount = self._RefCount - 1
end

function XQuestAction:ResetRefCount()
    self._RefCount = 0
end

function XQuestAction:AddEvent()
end

function XQuestAction:RemoveEvent()
end

function XQuestAction:IsActive()
    return self._Active
end

function XQuestAction:GetOperateData()
    return self._OperateData
end

--- 刷新整个任务栏
---@param data XBigWorldQuestOpData
function XQuestAction:UpdateByRefreshOperate(data)
    self:RefreshView(data)
    self:UpdateDynamicItem(data and data.ObjectiveList or nil, false, false)
    self:Finish()
end

--- 有新的任务接取
---@param data XBigWorldQuestOpData
function XQuestAction:UpdateByQuestReceiveOperate(data)
    if not data then
        return
    end
    self:RefreshView(data)
    local questId = data.QuestId
    if XMVCA.XBigWorldQuest:IsInstQuest(questId) then
        self:PlayAnimation("TaskEnable")
    else
        if not self._ReceiveFinishCb then
            self._ReceiveFinishCb = function() 
                self.PanelQuest:OnReceiveQuestRefresh(self._BeginCb, self._FinishCb)
            end
        end
        self:PlayAnimation("TaskEnable", self._ReceiveFinishCb)
    end
    self:UpdateDynamicItem(data.ObjectiveList, true, false)
    self:Finish()
end

--- 任务追踪
---@param data XBigWorldQuestOpData
function XQuestAction:UpdateByQuestTrackOperate(data)
    self:RefreshView(data)
    self:PlayAnimation("TaskEnable")
    self:UpdateDynamicItem(data.ObjectiveList)
    self:Finish()
end

--- 任务取消追踪
---@param data XBigWorldQuestOpData
function XQuestAction:UpdateByQuestUnTrackOperate(data)
    self:RefreshView(data)
    self:UpdateDynamicItem(nil, false, false)
    self:Finish()
end

--- 任务完成
---@param data XBigWorldQuestOpData
function XQuestAction:UpdateByQuestFinishOperate(data)
    self:RefreshView(data)
    self:PlayAnimation("TaskDisable")
    self:UpdateDynamicItem(data.ObjectiveList, false, false)
    self:Finish()
end

--- 任务步骤激活
---@param data XBigWorldQuestOpData
function XQuestAction:UpdateByStepActiveOperate(data)
    self:RefreshView(data)
    local stepId = data.StepId
    local playAnimation = false
    if stepId and stepId > 0 and not string.IsNilOrEmpty(XMVCA.XBigWorldQuest:GetQuestStepTextByStepId(stepId)) then
        playAnimation = true
    end
    if playAnimation then
        self:PlayAnimation("StepStart")
    end
    self:UpdateDynamicItem(data.ObjectiveList, true, false)
    self:Finish()
end

--- 任务步骤完成
---@param data XBigWorldQuestOpData
function XQuestAction:UpdateByStepFinishOperate(data)
    self:RefreshView(data)
    local stepId = data.StepId
    local playAnimation = false
    if stepId and stepId > 0 and not string.IsNilOrEmpty(XMVCA.XBigWorldQuest:GetQuestStepTextByStepId(stepId)) then
        playAnimation = true
    end
    if playAnimation then
        self:PlayAnimation("StepFinish")
    end
    self:UpdateDynamicItem(data.ObjectiveList, false, false)
    self:Finish()
end

--- 任务流程激活
---@param data XBigWorldQuestOpData
function XQuestAction:UpdateByObjectiveActiveOperate(data)
    self:RefreshView(data)
    self:UpdateDynamicItem(data.ObjectiveList, false, false)
    self:UpdateGridAnimation(data.OperateObjective, true, false)
    self:Finish()
end

--- 任务流程完成
---@param data XBigWorldQuestOpData
function XQuestAction:UpdateByObjectiveFinishOperate(data)
    self:RefreshView(data)
    self:UpdateDynamicItem(data.ObjectiveList, false, false)
    self:UpdateGridAnimation(data.OperateObjective, false, true)
    self:Finish()
end


function XQuestAction:PlayAnimation(anim, finish)
    self.PanelQuest:PlayAnimation(anim, finish or self._FinishCb, self._BeginCb, WrapHold)
end

---@param data XBigWorldQuestOpData
function XQuestAction:RefreshView(data)
    self.PanelQuest:RefreshView(data)
end

function XQuestAction:UpdateDynamicItem(dataList, isEnable, isFinish)
    self.PanelQuest:UpdateDynamicItem(dataList, isEnable, isFinish, self._BeginCb, self._FinishCb)
end



---@param objective XBigWorldQuestObjective
function XQuestAction:UpdateGridAnimation(objective, isEnable, isFinish)
    self.PanelQuest:UpdateGridAnimation(objective, isEnable, isFinish, self._FinishCb, self._BeginCb)
end

return XQuestAction