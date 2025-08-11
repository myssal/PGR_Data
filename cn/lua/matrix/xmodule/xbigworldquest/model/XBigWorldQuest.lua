---@class XBigWorldQuestObjective
---@field _ObjectiveId number
local XBigWorldQuestObjective = XClass(nil, "XBigWorldQuestObjective")

local ObjectiveState = XMVCA.XBigWorldQuest.ObjectiveState

function XBigWorldQuestObjective:Ctor(processId)
    self._ObjectiveId = processId
    self._Progress = 0
    self._State = 0
    self._MaxProgress = 0
    self._ProgressType = 0
end

function XBigWorldQuestObjective:UpdateData(objective)
    self._Progress = objective.CurProgress
    self._MaxProgress = objective.MaxProgress or self._Progress
    self._ProgressType = objective.ProgressType
    self._State = objective.State
end

function XBigWorldQuestObjective:SetProgress(value)
    self._Progress = value
end

function XBigWorldQuestObjective:SetState(value)
    self._State = value
end

function XBigWorldQuestObjective:GetProgress()
    return self._Progress
end

function XBigWorldQuestObjective:GetMaxProgress()
    return self._MaxProgress
end

function XBigWorldQuestObjective:GetId()
    return self._ObjectiveId
end

function XBigWorldQuestObjective:IsFinish()
    return self._State == ObjectiveState.Finished
end

function XBigWorldQuestObjective:GetObjectiveState()
    return self._State
end


---@class XBigWorldQuestStep
---@field _StepId number 步骤Id
---@field _ObjectiveDict table<number, XBigWorldQuestObjective> 目标数据
local XBigWorldQuestStep = XClass(nil, "XBigWorldQuestStep")

local StepState = XMVCA.XBigWorldQuest.StepState

function XBigWorldQuestStep:Ctor(stepId)
    self._StepId = stepId
    self._ObjectiveDict = false
    self._State = StepState.Inactive
end

function XBigWorldQuestStep:GetCurrentProcessId()
    return self._CurrentProcessId
end

function XBigWorldQuestStep:UpdateData(step)
    self._State = step.State
    local objectives = step.Objectives
    if not XTool.IsTableEmpty(objectives) then
        if not self._ObjectiveDict then
            self._ObjectiveDict = {}
        end
        for _, objective in pairs(objectives) do
            local objectiveId = objective.Id
            local objectiveData = self:TryGetObjective(objectiveId)
            objectiveData:UpdateData(objective)
        end
    end
end

function XBigWorldQuestStep:GetState()
    return self._State
end

function XBigWorldQuestStep:SetState(value)
    self._State = value
end

---@return XBigWorldQuestObjective
function XBigWorldQuestStep:TryGetObjective(objectiveId)
    if not self._ObjectiveDict then
        self._ObjectiveDict = {}
    end
    local objectiveData = self._ObjectiveDict[objectiveId]
    if not objectiveData then
        objectiveData = XBigWorldQuestObjective.New(objectiveId)
        self._ObjectiveDict[objectiveId] = objectiveData
    end
    return objectiveData
end

---@return table<number, XBigWorldQuestObjective>
function XBigWorldQuestStep:GetObjectiveDict()
    return self._ObjectiveDict
end

function XBigWorldQuestStep:IsActive()
    return self._State == StepState.InProgress
end

function XBigWorldQuestStep:IsFinish()
    return self._State == StepState.Finished
end

function XBigWorldQuestStep:GetId()
    return self._StepId
end

function XBigWorldQuestStep:Reset()
    self._StepId = 0
    self._ObjectiveDict = false
    self._State = StepState.Inactive
end

---@return XBigWorldQuestObjective
function XBigWorldQuestStep:GetObjectiveData(objectiveId)
    if not self._ObjectiveDict then
        return
    end
    return self._ObjectiveDict[objectiveId]
end


---@class XBigWorldQuest
---@field _QuestId number 任务Id
---@field _StepDict table<number, XBigWorldQuestStep> 步骤数据
local XBigWorldQuest = XClass(nil, "XBigWorldQuest")

local QuestState = XMVCA.XBigWorldQuest.QuestState

function XBigWorldQuest:Ctor(questId)
    self._QuestId = questId
    self._StepDict = false
    self._State = QuestState.InActive
end

function XBigWorldQuest:UpdateData(quest)
    self._State = quest.State
    local steps = quest.Steps
    if not XTool.IsTableEmpty(steps) then
        for _, step in pairs(steps) do
            local stepId = step.Id
            local stepData = self:TryGetStep(stepId)
            stepData:UpdateData(step)
        end
    end
    local finishObjectiveIds = quest.FinishedObjectiveIds
    if not XTool.IsTableEmpty(finishObjectiveIds) then
        local dict = {}
        for _, objectiveId in pairs(finishObjectiveIds) do
            dict[objectiveId] = true
        end
        self._FinishedObjectiveDict = dict
    end
end

---@return XBigWorldQuestStep
function XBigWorldQuest:TryGetStep(stepId)
    if not self._StepDict then
        self._StepDict = {}
    end

    local stepData = self._StepDict[stepId]
    if not stepData then
        stepData = XBigWorldQuestStep.New(stepId)
        self._StepDict[stepId] = stepData
    end

    return stepData
end

---@return XBigWorldQuestStep
function XBigWorldQuest:GetStep(stepId)
    if not self._StepDict then
        return
    end
    return self._StepDict[stepId]
end

---@return XBigWorldQuestStep
function XBigWorldQuest:GetActiveStepData()
    if not self._StepDict then
        return
    end
    for _, data in pairs(self._StepDict) do
        if data:IsActive() then
            return data
        end
    end
    return nil
end

function XBigWorldQuest:GetState()
    return self._State
end

function XBigWorldQuest:SetState(state)
    self._State = state
end

function XBigWorldQuest:GetId()
    return self._QuestId
end

function XBigWorldQuest:IsFinish()
    return self._State == QuestState.Finished
end

function XBigWorldQuest:IsInProgress()
    return self._State == QuestState.InProgress
end

function XBigWorldQuest:IsShowInList()
    if XMVCA.XBigWorldQuest:IsInstQuest(self._QuestId) then
        return false
    end
    if self._State == QuestState.InProgress then
        return true
    end

    return false
end

function XBigWorldQuest:CheckObjectiveFinish(objectiveId)
    return self._FinishedObjectiveDict and self._FinishedObjectiveDict[objectiveId]
end

return XBigWorldQuest