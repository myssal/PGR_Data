---@class XQuestBase
local XQuestBase = XClass(nil,"QuestBase")

---@param proxy XDlcCSharpFuncs
function XQuestBase:Ctor(proxy)
    self._proxy = proxy
end

function XQuestBase:SetActiveObjectiveIdList(idList)
    self._activeObjectiveIdList = idList
end

---@return boolean
function XQuestBase:ExtraStepCheck(id)--此处由于step激活逻辑调整到了服务器上，后续使用需要重新设计
    local isActive = true
    if self.StepExtraCheckFuncs[id] ~= nil then
        isActive = self.StepExtraCheckFuncs[id](self)
    end
    return isActive
end

--function XQuestBase:OnEnable(id)
--    if self.StepEnterFuncs[id] ~= nil then
--        self.StepEnterFuncs[id](self)
--    end
--end
--
--function XQuestBase:OnDisable(id)
--    if self.StepExitFuncs[id] ~= nil then
--        self.StepExitFuncs[id](self)
--    end
--end

---@param eventType number
---@param eventArgs userdata
function XQuestBase:HandleEvent(eventType, eventArgs)
    --if self.StepIdList == nil then
    --    return
    --end

    --XTool.LoopCollection(self.StepIdList, function(v)
    --    if self.StepHandleEventFuncs[v] ~= nil then
    --        self.StepHandleEventFuncs[v](self, eventType, eventArgs)
    --    end
    --end)

    --XTool.LoopCollection(self._activeObjectiveIdList, function(id)
    --    local objective = self._objectives[id]
    --    local handleEventFunc = self._objectiveHandleEventFuncs[id]
    --    if handleEventFunc then
    --        handleEventFunc(objective, self._proxy, eventType, eventArgs)
    --    end
    --end)
end

XQuestBase.StepExtraCheckFuncs = {}
XQuestBase.StepEnterFuncs = {}
XQuestBase.StepExitFuncs = {}
XQuestBase.StepHandleEventFuncs = {}

--==========新架构==================================

local CSAddObjectiveArgs = CS.StatusSyncFight.XQuestConfig.AddQuestObjectiveArgs
local emptyFunc = function() end

local function InitQuestObjective(objectiveBaseClass, define)
    --将任务的静态配置传入进行初始化，在服务端启动时初始化阶段
    CSAddObjectiveArgs(define.Id, define.Type, define.Args)

    local id = define.Id
    --构建任务目标的classTable
    local objectiveClass = XDlcScriptManager.RegQuestObjectiveScript(
        id, "QuestObjective"..tostring(id), objectiveBaseClass)
    objectiveClass.Init = define.InitFunc or emptyFunc --这个函数不能为空，会报错
    objectiveClass.Enter = define.EnterFunc
    objectiveClass.HandleEvent = define.HandleEventFunc
    objectiveClass.Exit = define.ExitFunc
    objectiveClass.HasEnterFunc = define.EnterFunc ~= nil
    objectiveClass.HasExitFunc = define.ExitFunc ~= nil
    --objectiveClass.SetQuest = function(self, quest)
    --    self.quest = quest
    --end

    --XLog.Debug("[Script] XQuestBase.InitQuestObjective: " .. tostring(id))
end

function XQuestBase.InitQuestObjectives(objectiveBaseClass, objectivesDefines)
    for _, define in pairs(objectivesDefines) do
        InitQuestObjective(objectiveBaseClass, define)
    end
end

local CSAddStepArgs = CS.StatusSyncFight.XQuestConfig.AddQuestStepArgs

local function InitStep(define)
    CSAddStepArgs(define)
end

function XQuestBase.InitSteps(stepDefines)
    for _, define in pairs(stepDefines) do
        InitStep(define)
    end
end

return XQuestBase
