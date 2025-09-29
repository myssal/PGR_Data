---@class XBigWorldQuestAgency : XAgency
---@field private _Model XBigWorldQuestModel
---@field QuestOpType table
local XBigWorldQuestAgency = XClass(XAgency, "XBigWorldQuestAgency")

local stringFormat = string.format

local DlcEventId = XMVCA.XBigWorldService.DlcEventId

local Pattern = "{(.-)}"

function XBigWorldQuestAgency:OnInit()
    self.PatternKeyToValue = {
        Current = 0,
        Max = 0
    }
    self._TrackQuestIdCache = false
    self:InitEnum()
    self:InitConditionCheck()
    self:InitShieldController()
    XMVCA.XBigWorldUI:AddFightUiCb("UiBigWorldTaskMain", handler(self, self.OpenQuestMainByFight), handler(self, self.CloseQuestMain))
end

function XBigWorldQuestAgency:OnRelease()
    self:ReleaseConditionCheck()
    self:RemoveShieldController()
end

function XBigWorldQuestAgency:InitRpc()
end

function XBigWorldQuestAgency:InitEvent()
end

function XBigWorldQuestAgency:ResetData()
    self._Model:ResetData()
end

-- 条件判断初始化
function XBigWorldQuestAgency:InitConditionCheck()
    XMVCA.XBigWorldService:RegisterConditionFunc(10101001, handler(self, self.ConditionCheckQuestFinish))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101002, handler(self, self.ConditionCheckStepFinish))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101003, handler(self, self.ConditionCheckObjectiveFinish))
end

function XBigWorldQuestAgency:ReleaseConditionCheck()
    if not XMVCA:IsRegisterAgency(ModuleId.XBigWorldService) then
        return
    end
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101001)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101002)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101003)
end

function XBigWorldQuestAgency:InitShieldController()
    XMVCA.XBigWorldFunction:RegisterFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Task, self,
        self.OnChangeControlState)
end

function XBigWorldQuestAgency:RemoveShieldController()
    XMVCA.XBigWorldFunction:RemoveFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Task, self,
        self.OnChangeControlState)
end

--- 初始化枚举
--------------------------
function XBigWorldQuestAgency:InitEnum()
    self.QuestType = {
        All = 0,
        Main = 1,
        Side = 2,
        Normal = 3,
    }

    -- C# EQuestState
    self.QuestState = {
        --不活跃/未激活
        InActive = CS.EQuestState.InActive:GetHashCode(),
        --已激活未接取
        Ready = CS.EQuestState.Ready:GetHashCode(),
        --进行中
        InProgress = CS.EQuestState.InProgress:GetHashCode(),
        --已经完成
        Finished = CS.EQuestState.Finished:GetHashCode()
    }

    -- C# EQuestStepState
    self.StepState = {
        --不活跃/未激活
        Inactive = CS.EQuestStepState.InActive:GetHashCode(),
        --进行中
        InProgress = CS.EQuestStepState.InProgress:GetHashCode(),
        --完成
        Finished = CS.EQuestStepState.Finished:GetHashCode(),
    }
    
    -- C# EQuestObjectiveState
    self.ObjectiveState = {
        --不活跃/未激活
        InActive = 0,
        --内部Enter
        Enter = 1,
        --脚本正在执行进入环节
        ScriptEnter = 2,
        --进行中
        InProgress = 3,
        --内部Exit
        Exit = 4,
        --脚本正在退出进入环节
        ScriptExit = 5,
        --完成
        Finished = 6,
    }
    
    self.StepExecMode = {
        --线性执行下属objective
        Serial = 1, 
        --并行执行下属objective
        Parallel = 2, 
    }
    
    self.QuestOpType = {
        --刷新整个界面
        Refresh = 1,
        --弹窗展示
        PopupBegin = 2,
        --弹窗关闭
        PopupEnd = 3,
        --任务领取
        QuestReceive = 4,
        --任务追踪
        QuestTrack = 5,
        --任务取消追踪
        QuestUnTrack = 6,
        --任务完成
        QuestFinish = 7,
        --步骤激活
        StepActive = 8,
        --步骤完成
        StepFinish = 9,
        --流程激活
        ObjectiveActive = 10,
        --流程完成
        ObjectiveFinish = 11,
    }
    
    self.QuestCategory = {
        NormalQuest = 0,
        InstLevelStoryQuest = 1,
        InstLevelPlayQuest = 2,
        LevelPlayQuest = 3
    }

    local EQuestObjectiveProgressType = CS.StatusSyncFight.EQuestObjectiveProgressType
    
    self.QuestStepObjectiveType = {
        Bool = EQuestObjectiveProgressType.Bool:GetHashCode(),
        Int = EQuestObjectiveProgressType.Int:GetHashCode(),
        Float = EQuestObjectiveProgressType.Float:GetHashCode(),
        Percent = EQuestObjectiveProgressType.Percent:GetHashCode(),
    }
    
    self.QuestShieldState = {
        --进入正常状态
        BackToNormal = 0,
        --进入副本状态
        IntoFuben = 1,
    }
    
    self._ReplaceHandler = function(key)
        local v = self.PatternKeyToValue[key]
        return v and tostring(v) or key
    end
end

--- 检查任务是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckQuestFinish(template)
    local params = template.Params
    local questId = params[1]
    return self:CheckQuestFinish(questId), template.Desc
end

--- 检查任务步骤是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckStepFinish(template)
    local params = template.Params
    local stepId = params[1]
    return self:CheckStepFinish(stepId), template.Desc
end

--- 检查到任务目标是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckObjectiveFinish(template)
    local params = template.Params
    local objectiveId = params[1]
    local objTemplate = self._Model:GetQuestStepObjectiveTemplate(objectiveId)
    local stepId = objTemplate.StepId
    if not stepId or stepId <= 0 then
        XLog.Warning("此任务目标配置了无效StepId, ObjectiveId = " .. objectiveId)
        return false, template.Desc
    end
    local stepTemplate = self._Model:GetQuestStepTemplate(stepId)
    local questId = stepTemplate.QuestId
    if not questId or questId <= 0 then
        XLog.Warning(string.format("此任务目标配置了无效QuestId, ObjectiveId = %s StepId = %s" .. objectiveId, stepId))
        return false, template.Desc
    end
    return self:CheckObjectiveFinish(questId, objectiveId), template.Desc
end

function XBigWorldQuestAgency:IsQuestItem(id)
    if not XTool.IsNumberValid(id) then
        return false
    end
    
    return XArrangeConfigs.GetType(id) == XArrangeConfigs.Types.QuestItem
end

--region Quest Data

function XBigWorldQuestAgency:InitQuest(data)
    if not data then
        return
    end
    local quests = data.ActiveQuests
    local trackInstQuest = false --是否追踪了副本任务
    local trackId = self._Model:GetTrackQuestId() 
    for _, quest in pairs(quests) do
        local questData = self._Model:GetQuestData(quest.Id)
        questData:UpdateData(quest)
        if self:IsInstQuest(quest.Id) then
            --更新缓存
            self:UpdateTrackQuestCache(trackId)
            --强制追踪副本任务
            self:TrackQuest(quest.Id)
            trackInstQuest = true
        end
    end
    self._Model:UpdateFinishQuest(data.FinishedQuestIds)
    if trackId and trackId > 0 and not trackInstQuest then
        self:NotifyFightTrackQuest(trackId, true)
    end
    
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.Refresh, trackId, 0, 0)

    --更新红点
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_RED_POINT_REFRESH)
end

function XBigWorldQuestAgency:OnQuestActivated(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.Id)
    questData:UpdateData(data)
    
    XEventManager.DispatchEvent(DlcEventId.EVENT_MESSAGE_QUEST_NOTIFY, data.Id)
end

function XBigWorldQuestAgency:OnQuestUndertaken(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.Id)
    questData:UpdateData(data)
    if self:IsInstQuest(data.Id) then
        --记录上次追踪的任务
        local tracId = self:GetLastTrackQuestId()
        self:UpdateTrackQuestCache(tracId)
        --强制追踪副本任务
        self:TrackQuest(data.Id)
    else
        self:PopupTaskObtain(data.Id, false)
        if self:IsDefaultTrackQuest(data.Id) and not self._SyncTracking then
            local trackId = self:GetTrackQuestId()
            --是默认追踪任务，且当前没有任务需要追踪
            if not trackId or trackId <= 0 then
                self:TrackQuest(data.Id)
            end
        end
    end
    XEventManager.DispatchEvent(DlcEventId.EVENT_MESSAGE_QUEST_NOTIFY, data.Id)
    if self._Model:IsFirstStatusBarPlay(data.Id) then
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.QuestReceive, data.Id, 0, 0)
    end

    --更新红点
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_RED_POINT_REFRESH)
end

function XBigWorldQuestAgency:OnQuestFinished(data)
    if not data then
        return
    end
    local lastQuestId = 0
    local trackId = self._Model:GetTrackQuestId()
    local untrack = false
    for _, id in pairs(data) do
        local quest = self:GetQuestData(id)
        quest:SetState(XMVCA.XBigWorldQuest.QuestState.Finished)
        lastQuestId = id
        if not untrack and trackId == id  then
            untrack = true
        end
    end
    self._Model:UpdateFinishQuest(data)
    if lastQuestId > 0 then
        self:PopupTaskObtain(lastQuestId, true)
    end
    --刷新界面，推进演出
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.QuestFinish, trackId, 0, 0)
    local tracked = false
    --如果不是在副本内，有任务完成(完成的任务需要是正在追踪的)，看看还有没有领取需要自动追踪的任务
    if untrack and not XMVCA.XBigWorldGamePlay:IsInstLevel() then
        tracked = self:TryTrackDefault()
    end
    --没有追踪到默认任务 且 需要取消追踪上一个任务，则还原追踪
    if not tracked and untrack then
        self:UnTrackQuest(trackId)
    end

    --更新红点
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_RED_POINT_REFRESH)
    --任务完成
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_FINISH)
end

function XBigWorldQuestAgency:OnQuestRemove(data)
    if not data then
        return
    end
    local id = data.Id
    if self:IsInstQuest(id) then
        --如果处于还处于副本内，则不还原追踪，直接取消追踪当前任务
        if XMVCA.XBigWorldGamePlay:IsInstLevel() then
            self:UnTrackQuest(id)
        else
            if self._TrackQuestIdCache and self._TrackQuestIdCache > 0 then
                self:TrackQuest(self._TrackQuestIdCache)
                self:UpdateTrackQuestCache(false)
            else
                self:UnTrackQuest(id)
            end
        end
    end
    self._Model:RemoveQuestRedPoint(id)
end

function XBigWorldQuestAgency:OnQuestRelaunch(data)
    if not data then
        return
    end
    local trackId = 0
    for _, quest in pairs(data) do
        local questData = self._Model:GetQuestData(quest.Id)
        questData:UpdateData(quest)
        if self:IsInstQuest(quest.Id) then
            --更新追踪任务缓存
            local tracId = self:GetLastTrackQuestId()
            self:UpdateTrackQuestCache(tracId)
            --强制追踪副本任务
            self:TrackQuest(quest.Id)
            trackId = quest.Id
        end
    end
    --更新界面
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.QuestReceive, trackId, 0, 0)
    --更新红点
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_RED_POINT_REFRESH)
end

function XBigWorldQuestAgency:OnStepChanged(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.QuestId)
    local stepData = questData:TryGetStep(data.StepId)
    
    local notifyFinish = false
    stepData:SetState(data.State)
    local op = self.QuestOpType.Refresh
    if stepData:IsFinish() then
        op = self.QuestOpType.StepFinish
        notifyFinish = true
    elseif stepData:IsActive() then
        op = self.QuestOpType.StepActive
    end
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, op, data.QuestId, data.StepId, 0)

    if notifyFinish then
        --任务完成
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_FINISH)
    end
end

function XBigWorldQuestAgency:OnObjectiveChanged(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.QuestId)
    local stepData = questData:TryGetStep(data.StepId)
    local objectiveData = stepData:TryGetObjective(data.ObjectiveId)
    objectiveData:SetProgress(data.Progress)
    objectiveData:SetState(data.State)
    
    local op
    local notifyFinish = false
    local ObjectiveState = self.ObjectiveState
    if data.State == ObjectiveState.Finished then
        op = self.QuestOpType.ObjectiveFinish
        notifyFinish = true
    elseif data.State == ObjectiveState.Enter then
        op = self.QuestOpType.ObjectiveActive
    end
    if op then
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, op, data.QuestId, data.StepId, data.ObjectiveId)
    end

    if notifyFinish then
        --任务完成
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_FINISH)
    end
end

function XBigWorldQuestAgency:UpdateTrackQuestCache(questId)
    if questId and questId > 0 then
        --如果已经追踪的任务是副本任务，则不用缓存
        if self:IsInstQuest(questId) then
           return 
        end
        --已经记录了，不用更新
        if self._TrackQuestIdCache and self._TrackQuestIdCache > 0 then
            return
        end
        --记录上次追踪的任务
        self._TrackQuestIdCache = questId
    else
        self._TrackQuestIdCache = questId
    end
end

---@return XBigWorldQuest
function XBigWorldQuestAgency:GetQuestData(questId)
    return self._Model:GetQuestData(questId)
end

--- 追踪任务
---@param questId number 任务Id  
--------------------------
function XBigWorldQuestAgency:TrackQuest(questId, cb)
    local trackId = self._Model:GetTrackQuestId()
    if trackId == questId then
        if trackId ~= 0 then
            self:NotifyFightTrackQuest(questId, false, nil)
            self:NotifyFightTrackQuest(questId, true, cb)
        end
        return
    end
    self._SyncTracking = true
    XNetwork.Call("DlcQuestTraceIdChangeRequest", { ChangeTraceQuestId = questId }, function(res)
        self._SyncTracking = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetTrackQuestId(questId)
        self:NotifyFightTrackQuest(questId, true, cb)
        
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.QuestTrack, questId, 0, 0)
    end)
end

--- 取消追踪
---@param questId number 任务Id    
--------------------------
function XBigWorldQuestAgency:UnTrackQuest(questId, cb)
    local trackId = self._Model:GetTrackQuestId()
    if not trackId or trackId <= 0 then
        return
    end

    if questId ~= trackId then
        return
    end

    XNetwork.Call("DlcQuestTraceIdChangeRequest", { ChangeTraceQuestId = 0 }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetTrackQuestId(0)
        self:NotifyFightTrackQuest(questId, false, cb)
        
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.QuestUnTrack, questId, 0, 0)
    end)
end

function XBigWorldQuestAgency:NotifyFightTrackQuest(questId, enable, cancelCb)
    local data = {
        QuestId = questId,
        Enable = enable,
    }
    local result = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_SET_NAVIGTION_ENABLE, data)
    local cancelId = 0
    if result and result.CanceledQuestId and result.CanceledQuestId > 0 then
        cancelId = result.CanceledQuestId
    elseif not enable then
        cancelId = questId
    end

    if cancelCb then cancelCb(cancelId) end
end

--- 追踪默认的任务
function XBigWorldQuestAgency:TryTrackDefault()
    local list = self._Model:GetReceiveAndDefaultTrackQuestIds()
    if XTool.IsTableEmpty(list) then
        return false
    end
    local questId = list[1]
    self:TrackQuest(questId)
    
    return true
end

function XBigWorldQuestAgency:GetTrackQuestId()
    return self._Model:GetTrackQuestId()
end

function XBigWorldQuestAgency:GetLastTrackQuestId()
    --更新追踪任务缓存
    local tracId = self._Model:GetTrackQuestId()
    if not tracId or tracId <= 0 then
        tracId = self._TrackQuestIdCache
    end
    return tracId
end

--- 尝试还原追踪任务，如果在副本内完成了任务，此时不能立即还原，需要等切换到正常场景后才能切换
function XBigWorldQuestAgency:TryRestoreTrackQuest()
    if XMVCA.XBigWorldGamePlay:IsInstLevel() then
        return
    end
    if self._TrackQuestIdCache and self._TrackQuestIdCache > 0 then
        self:TrackQuest(self._TrackQuestIdCache)
        self:UpdateTrackQuestCache(false)
    end
end

function XBigWorldQuestAgency:UpdateData(trackQuestId)
    self._Model:SetTrackQuestId(trackQuestId or 0)
end

function XBigWorldQuestAgency:CheckQuestFinish(questId)
    return self._Model:CheckQuestFinish(questId)
end

function XBigWorldQuestAgency:CheckStepFinish(stepId)
    local t = self._Model:GetQuestStepTemplate(stepId)
    if not t then
        return false
    end
    if self._Model:CheckQuestFinish(t.QuestId) then
        return true
    end
    
    local questData = self:GetQuestData(t.QuestId)
    if not questData then
        return false
    end
    --任务已经完成
    if questData:IsFinish() then
        return true
    end
    local state = questData:GetState()
    --任务刚激活，还未领取
    if state == self.QuestState.Ready then
        return false
    end
    local stepData = questData:GetStep(stepId)
    if not stepData then
        return false
    end
    return stepData:IsFinish()
end

function XBigWorldQuestAgency:CheckObjectiveFinish(questId, objectiveId)
    if self._Model:CheckQuestFinish(questId) then
        return true
    end
    return self:CheckObjectiveFinishOnlyObjective(questId, objectiveId)
end

function XBigWorldQuestAgency:CheckObjectiveFinishOnlyObjective(questId, objectiveId)
    local questData = self:GetQuestData(questId)
    if not questData then
        return false
    end
    if questData:CheckObjectiveFinish(objectiveId) then
        return true
    end
    local tStep = self._Model:GetQuestStepObjectiveTemplate(objectiveId)
    local stepId = tStep and tStep.StepId or 0
    if stepId <= 0 then
        return false
    end
    local step = questData:GetStep(stepId)
    if not step then
        return false
    end

    local objective = step:GetObjectiveData(objectiveId)
    return objective and objective:IsFinish() or false
end

--endregion Quest Data

--region Quest Item Config

function XBigWorldQuestAgency:GetQuestItemIcon(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Icon or ""
end

function XBigWorldQuestAgency:GetQuestItemName(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Name or ""
end

function XBigWorldQuestAgency:GetQuestItemPriority(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Priority or ""
end

function XBigWorldQuestAgency:GetQuestItemQuality(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Quality or ""
end

function XBigWorldQuestAgency:GetQuestItemDescription(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Description or ""
end

function XBigWorldQuestAgency:GetQuestItemWorldDescription(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.WorldDescription or ""
end

function XBigWorldQuestAgency:GetGroupIdByQuestId(questId)
    return self._Model:GetGroupIdByQuestId(questId, true)
end

--endregion Quest Item Config

---@param stepData XBigWorldQuestStep
---@return XBigWorldQuestObjective[]
function XBigWorldQuestAgency:GetObjectiveListWithStep(stepData)
    if not stepData then
        return
    end
    local dict = stepData:GetObjectiveDict()
    if XTool.IsTableEmpty(dict) then
        return
    end
    local mode = self._Model:GetQuestStepExecMode(stepData:GetId())
    local isSerial = mode == self.StepExecMode.Serial
    local isParallel = mode == self.StepExecMode.Parallel
    local ObjectiveState = self.ObjectiveState

    local list = {}
    for _, objective in pairs(dict) do
        local title = self._Model:GetObjectiveTitle(objective:GetId())
        if string.IsNilOrEmpty(title) then
            goto continue
        end
        if isSerial then --线性模式
            local state = objective:GetObjectiveState()
            if state ~= ObjectiveState.Finished and state ~= ObjectiveState.InActive then
                list[#list + 1] = objective
            end
        elseif isParallel then --并行模式
            list[#list + 1] = objective
        end
        ::continue::
    end
    return list
end

function XBigWorldQuestAgency:GetObjectiveListWithQuestId(questId)
    local questData = self._Model:GetQuestData(questId)
    local step = questData:GetActiveStepData()
    if not step then
        return
    end
    return self:GetObjectiveListWithStep(step)
end

function XBigWorldQuestAgency:GetQuestDisplayProgress(questId)
    local objectiveList = self:GetObjectiveListWithQuestId(questId)
    if XTool.IsTableEmpty(objectiveList) then
        return
    end
    local list = {}
    for _, objective in pairs(objectiveList) do
        local id = objective:GetId()
        local progress = self:GetObjectiveProgressDesc(id, objective:GetProgress(), objective:GetMaxProgress())
        list[#list + 1] = progress
    end
    return list
end

function XBigWorldQuestAgency:GetObjectiveProgressDesc(objectiveId, current, max)
    --local type = self._Model:GetObjectiveType(objectiveId)
    --local max = self._Model:GetObjectiveMaxProgress(objectiveId)
    --if type == self.QuestStepObjectiveType.Int then
    --    return stringFormat("%d/%d", progress, max)
    --elseif type == self.QuestStepObjectiveType.Float then
    --    return stringFormat("%0.1f/%0.1f", progress / 10000, max / 10000)
    --elseif type == self.QuestStepObjectiveType.Percent then
    --    return stringFormat("%0.1f%%", 100 * progress / max)
    --elseif type == self.QuestStepObjectiveType.Bool then
    --    return stringFormat("%d/%d", progress > 0 and 0 or 1, 1)
    --end
    local txt = self._Model:GetObjectiveTitle(objectiveId)
    self.PatternKeyToValue.Current = current
    self.PatternKeyToValue.Max = max
    return txt:gsub(Pattern, self._ReplaceHandler)
end

function XBigWorldQuestAgency:GetReceiveQuestIds()
    return self._Model:GetReceiveQuestIds()
end

function XBigWorldQuestAgency:GetQuestStepText(questId)
    local questData = self._Model:GetQuestData(questId)
    local step = questData:GetActiveStepData()
    if not step then
        return
    end
    return self._Model:GetQuestStepText(step:GetId())
end

function XBigWorldQuestAgency:GetQuestTypeColorWithQuestId(questId)
    local t = self._Model:GetQuestTemplate(questId)
    if not t then
        return ""
    end
    
    local template = self._Model:GetQuestTypeTemplate(t.Type)
    return template and template.Color or ""
end

function XBigWorldQuestAgency:GetQuestTypeMessageColorWithQuestId(questId)
    local t = self._Model:GetQuestTemplate(questId)
    if not t then
        return ""
    end
    
    local template = self._Model:GetQuestTypeTemplate(t.Type)
    return template and template.MessageColor or ""
end

function XBigWorldQuestAgency:GetQuestIdByObjectiveId(objectiveId)
    if not XTool.IsNumberValid(objectiveId) then
        return 0
    end

    local stepId = self._Model:GetObjectiveStepId(objectiveId)

    if not XTool.IsNumberValid(stepId) then
        return 0
    end

    return self._Model:GetQuestStepQuestId(stepId)
end

--region Quest Config

function XBigWorldQuestAgency:GetQuestIcon(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.QuestIcon or ""
end

function XBigWorldQuestAgency:GetQuestBanner(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.QuestBanner or ""
end

function XBigWorldQuestAgency:GetQuestText(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.QuestText or ""
end

function XBigWorldQuestAgency:GetQuestDesc(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.QuestDesc or ""
end

function XBigWorldQuestAgency:GetQuestRewardId(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.RewardId or 0
end

function XBigWorldQuestAgency:IsFavorableQuestType(questId)
    return self._Model:IsFavorableQuestType(questId)
end

function XBigWorldQuestAgency:IsDefaultTrackQuest(questId)
    return self._Model:IsDefaultTrackQuest(questId)
end

function XBigWorldQuestAgency:IsTrackQuest(questId)
    return self._Model:IsTrackQuest(questId)
end

function XBigWorldQuestAgency:GetQuestStepExecMode(stepId)
    return self._Model:GetQuestStepExecMode(stepId)
end

function XBigWorldQuestAgency:IsSerialStep(stepId)
    local mode = self:GetQuestStepExecMode(stepId)
    return mode == self.StepExecMode.Serial
end

function XBigWorldQuestAgency:IsParallelStep(stepId)
    local mode = self:GetQuestStepExecMode(stepId)
    return mode == self.StepExecMode.Parallel
end

function XBigWorldQuestAgency:IsInstQuest(questId)
    if not questId or questId <= 0 then
        return false
    end
    local category = self._Model:GetQuestCategory(questId)
    return category == self.QuestCategory.InstLevelPlayQuest or category == self.QuestCategory.InstLevelStoryQuest
end

function XBigWorldQuestAgency:GetObjectiveTitle(objectiveId)
    return self._Model:GetObjectiveTitle(objectiveId)
end

function XBigWorldQuestAgency:GetObjectiveDesc(objectiveId)
    return self._Model:GetObjectiveDesc(objectiveId)
end

function XBigWorldQuestAgency:GetObjectiveMaxProgress(objectiveId)
    return self._Model:GetObjectiveMaxProgress(objectiveId)
end

function XBigWorldQuestAgency:IsBoolObjective(objectiveId)
    return self._Model:GetObjectiveType(objectiveId) == self.QuestStepObjectiveType.Bool
end

function XBigWorldQuestAgency:GetQuestStepTextByStepId(stepId)
    return self._Model:GetQuestStepText(stepId)
end

-- endregion

--region Ui Open

function XBigWorldQuestAgency:PopupTaskObtain(questId, isFinish)
    self._Model:PopupTaskObtain(questId, isFinish)
end

function XBigWorldQuestAgency:OpenPopupDelivery(luaTable)
    if not luaTable then
        XLog.Error("打开交付界面异常, 参数为空")
        return
    end
    XLuaUiManager.Open("UiBigWorldPopupDelivery", luaTable.ObjectiveId)
end

function XBigWorldQuestAgency:OpenQuestMain(index, questId)
    if self:IsSkipToMainShield() then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldTaskMain", index, questId)
end

function XBigWorldQuestAgency:CloseQuestMain()
    XMVCA.XBigWorldUI:Close("UiBigWorldTaskMain")
end

function XBigWorldQuestAgency:OpenQuestMainByFight(data)
    self:OpenQuestMain(nil, nil)
end

function XBigWorldQuestAgency:IsSkipToMainShield()
    return self._IsSkipToMainShield
end

---@param controlData XBWFunctionControlData
function XBigWorldQuestAgency:OnChangeControlState(controlData)
    local shieldState = controlData:GetArgByIndex(1)
    if not shieldState then
        XLog.Error("屏蔽任务失败，参数异常!")
        return
    end

    if shieldState == self.QuestShieldState.BackToNormal then --返回正常状态
        self._IsSkipToMainShield = false
    elseif shieldState == self.QuestShieldState.IntoFuben then --进入副本，任务的表现
        self._IsSkipToMainShield = true
    end
end

--endregion Ui Open


--region 红点
function XBigWorldQuestAgency:CheckQuestRed()
    return self._Model:CheckQuestRed()
end

function XBigWorldQuestAgency:CheckQuestRedWithQuestType(type)
    return self._Model:CheckQuestRedWithQuestType(type)
end

function XBigWorldQuestAgency:CheckQuestRedWithQuestId(questId)
    return self._Model:CheckQuestRedWithQuestId(questId)
end

function XBigWorldQuestAgency:MarkQuestRedPoint(questId)
    self._Model:MarkQuestRedPoint(questId)
end

function XBigWorldQuestAgency:SaveQuestRed()
    self._Model:SaveQuestRed()
end
--endregion



return XBigWorldQuestAgency