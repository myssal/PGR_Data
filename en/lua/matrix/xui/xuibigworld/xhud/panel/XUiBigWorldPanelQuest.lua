---@class XUiBigWorldPanelQuest : XUiNode
---@field Parent XUiBigWorldHud
---@field _ObjectiveGrids table<number, XUiGridBWQuestItem>
---@field _RunningAction XQuestAction
---@field _ActionQueue XQuestAction[]
---@field _ActionPool XQuestAction[]
local XUiBigWorldPanelQuest = XClass(XUiNode, "XUiBigWorldPanelQuest")

local BWEventId = XMVCA.XBigWorldService.DlcEventId
local QuestOpType = XMVCA.XBigWorldQuest.QuestOpType

local Delay = 200
local WrapHold = CS.UnityEngine.Playables.DirectorWrapMode.Hold

local tableRemove = table.remove

local XUiGridBWQuestItem = require("XUi/XUiBigWorld/XHud/Grid/XUiGridBWQuestItem")

local XQuestAction = require("XUi/XUiBigWorld/XHud/Action/XQuestAction")

local PrimaryKey = 17
local SecondaryKey = 31

function XUiBigWorldPanelQuest:OnStart()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldPanelQuest:OnEnable()
    if XTool.IsTableEmpty(self._ActionQueue) then
        self:SafeEnqueue(self:GetOperateData(QuestOpType.Refresh, XMVCA.XBigWorldQuest:GetTrackQuestId(), 0, 0))
        if XTool.IsTableEmpty(self._ActionQueue) then
            self:RefreshView(nil)
        end
    end
    self:OperateDequeue()
end

function XUiBigWorldPanelQuest:OnDisable()
    self._PopupCount = 0
end

function XUiBigWorldPanelQuest:OnDestroy()
    self:StopQuestActiveTimer()
    XEventManager.RemoveEventListener(BWEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.OperateEnqueue, self)
    XEventManager.RemoveEventListener(BWEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.OnLevelChanged, self)
    XEventManager.RemoveEventListener(BWEventId.EVENT_MAP_PIN_ADD, self.OnMapPinAdd, self)
end


--region 界面刷新

---@param data XBigWorldQuestOpData
function XUiBigWorldPanelQuest:RefreshView(data)
    if not data or not data.QuestId or data.QuestId <= 0 
            or not data.StepId or data.StepId <= 0 then
        
        self.PanelTitle.gameObject:SetActiveEx(false)
        self.PanelQuest.gameObject:SetActiveEx(false)
        return
    end
    local questId = data.QuestId
    self._DisplayId = questId
    local isTrack = questId == XMVCA.XBigWorldQuest:GetTrackQuestId()
    local levelName = XMVCA.XBigWorldMap:GetQuestPinTargetLevelName(questId)
    if isTrack and not string.IsNilOrEmpty(levelName) then
        self.BtnGo.gameObject:SetActiveEx(true)
        levelName = XMVCA.XBigWorldService:GetText("BigWorldTrackText", levelName)
        self.BtnGo:SetNameByGroup(0, levelName)
    else
        self.BtnGo.gameObject:SetActiveEx(false)
    end
    self.PanelTitle.gameObject:SetActiveEx(true)
    self.TxtTitle.text = XMVCA.XBigWorldQuest:GetQuestText(questId)
    self.ImgTitle:SetSprite(XMVCA.XBigWorldQuest:GetQuestIcon(questId))
    local stepId = data.StepId
    local stepTxt = XMVCA.XBigWorldQuest:GetQuestStepTextByStepId(stepId)
    local isEmpty = string.IsNilOrEmpty(stepTxt) 
    self.TxtStep.gameObject:SetActiveEx(not isEmpty)
    if not isEmpty then
        self.TxtStep.text = stepTxt
    end
    isEmpty = XTool.IsTableEmpty(data.ObjectiveList)
    self.PanelQuest.gameObject:SetActiveEx(not isEmpty)
end

--- 刷新整个任务栏
---@param data XBigWorldQuestOpData
function XUiBigWorldPanelQuest:UpdateByRefreshOperate(data)
    self._RunningAction:UpdateByRefreshOperate(data)
end

--- 有新的任务接取
---@param data XBigWorldQuestOpData
function XUiBigWorldPanelQuest:UpdateByQuestReceiveOperate(data)
    self._RunningAction:UpdateByQuestReceiveOperate(data)
end

--- 任务追踪
---@param data XBigWorldQuestOpData
function XUiBigWorldPanelQuest:UpdateByQuestTrackOperate(data)
    self._RunningAction:UpdateByQuestTrackOperate(data)
end

--- 任务取消追踪
---@param data XBigWorldQuestOpData
function XUiBigWorldPanelQuest:UpdateByQuestUnTrackOperate(data)
    self._RunningAction:UpdateByQuestUnTrackOperate(data)
end

--- 任务完成
---@param data XBigWorldQuestOpData
function XUiBigWorldPanelQuest:UpdateByQuestFinishOperate(data)
    self._RunningAction:UpdateByQuestFinishOperate(data)
end

--- 任务步骤激活
---@param data XBigWorldQuestOpData
function XUiBigWorldPanelQuest:UpdateByStepActiveOperate(data)
    self._RunningAction:UpdateByStepActiveOperate(data)
end

--- 任务步骤完成
---@param data XBigWorldQuestOpData
function XUiBigWorldPanelQuest:UpdateByStepFinishOperate(data)
    self._RunningAction:UpdateByStepFinishOperate(data)
end

--- 任务流程激活
---@param data XBigWorldQuestOpData
function XUiBigWorldPanelQuest:UpdateByObjectiveActiveOperate(data)
    self._RunningAction:UpdateByObjectiveActiveOperate(data)
end

--- 任务流程完成
---@param data XBigWorldQuestOpData
function XUiBigWorldPanelQuest:UpdateByObjectiveFinishOperate(data)
    self._RunningAction:UpdateByObjectiveFinishOperate(data)
end

function XUiBigWorldPanelQuest:UpdateDynamicItem(dataList, isEnable, isFinish, finishCb, beginCb)
    local closeIndex = 0
    if not XTool.IsTableEmpty(dataList) then
        for i = 1, #dataList do
            local grid = self._ObjectiveGrids[i]
            if not grid then
                local ui = i == 1 and self.GridQuest or XUiHelper.Instantiate(self.GridQuest, self.GridQuest.transform.parent)
                grid = XUiGridBWQuestItem.New(ui, self)
                self._ObjectiveGrids[i] = grid
            end
            grid:Open()
            grid:Update(dataList[i], i)
            if isEnable then
                grid:PlayEnableAnimation(Delay * (i - 1), finishCb, beginCb)
            elseif isFinish then
                grid:PlayFinishAnimation(Delay * (i - 1), finishCb, beginCb)
            end
        end
        closeIndex = #dataList
    end

    for i = closeIndex + 1, #self._ObjectiveGrids do
        local grid = self._ObjectiveGrids[i]
        grid:Close()
    end
end

function XUiBigWorldPanelQuest:UpdateGridAnimation(objective, isEnable, isFinish, finishCb, beginCb)
    if not objective then
        return
    end
    for _, grid in pairs(self._ObjectiveGrids) do
        if grid and grid:IsNodeShow() and grid:GetObjectiveId() == objective:GetId() then
            if isEnable then
                grid:PlayEnableAnimation(0, beginCb, finishCb)
            elseif isFinish then
                grid:PlayFinishAnimation(0, beginCb, finishCb)
            end
        end
    end
end

--endregion


--region 队列操作


--- 安全入队，会移除掉无用的数据
---@param operateData XBigWorldQuestOpData
---@return boolean
function XUiBigWorldPanelQuest:SafeEnqueue(operateData)
    if not operateData then
        return false
    end
    local hashCode = self:CalcQuestOpDataHashCode(operateData)
    local hasSame = false
    local isUnTrack = operateData.Op == QuestOpType.QuestUnTrack
    for i = #self._ActionQueue, 1, -1 do
        local action = self._ActionQueue[i]
        local data = action:GetOperateData()
        if not hasSame and hashCode == self:CalcQuestOpDataHashCode(data) then
            hasSame = true
        end
        if isUnTrack and operateData.QuestId == data.QuestId then --如果是取消追踪，移除掉队列中当前任务的所有操作
            tableRemove(self._ActionQueue, i)
        end
    end
    if hasSame then
        return
    end
    self._ActionQueue[#self._ActionPool + 1] = self:GetOrCreateAction(operateData)
end

function XUiBigWorldPanelQuest:OperateEnqueue(operate, questId, stepId, objectiveId)
    if operate == QuestOpType.PopupBegin then
        self._PopupCount = self._PopupCount + 1
    elseif operate == QuestOpType.PopupEnd then
        self._PopupCount = self._PopupCount - 1
    else
        self:SafeEnqueue(self:GetOperateData(operate, questId, stepId, objectiveId))
    end
    self:OperateDequeue()
end

function XUiBigWorldPanelQuest:OperateDequeue()
    --还有弹窗覆盖着
    if self._PopupCount > 0 then
        return
    end
    --节点被隐藏了
    if not self.GameObject.activeInHierarchy then
        return
    end
    --有正在运行的行为
    if self._RunningAction and self._RunningAction:IsActive() then
        return
    end
    --队列为空
    if XTool.IsTableEmpty(self._ActionQueue) then
        return
    end
    ---@type XQuestAction
    local action = tableRemove(self._ActionQueue, 1)
    self._RunningAction = action

    local data = action:GetOperateData()
    local handler = self._OperateHandler[data.Op]
    if handler then
        handler(data)
    end
end

--- 回收进池
---@param action XQuestAction
---@param operateData XBigWorldQuestOpData
function XUiBigWorldPanelQuest:RecycleAction(action, operateData)
    self._ActionPool[#self._ActionPool + 1] = action
    self._OpDataPool[#self._OpDataPool + 1] = operateData
    self._RunningAction = nil
end

--endregion


--region 行为数据

function XUiBigWorldPanelQuest:GetQuestOperateData(operate, questId, stepId, objectiveId)
    if not questId or questId <= 0 then
        return self:GetDefaultOperateData(operate, 0, 0, 0)
    end
    local quest = XMVCA.XBigWorldQuest:GetQuestData(questId)
    if not quest:IsInProgress() then
        return self:GetDefaultOperateData(operate, 0, 0, 0)
    end
    ---@type XBigWorldQuestStep
    local step = quest:GetActiveStepData()
    local objectiveList, opObjective
    if step then
        objectiveList = XMVCA.XBigWorldQuest:GetObjectiveListWithStep(step)
        if objectiveId and objectiveId > 0 then
            opObjective = step:GetObjectiveData(objectiveId)
        end
        stepId = step:GetId()
    else
        stepId = 0
    end
    
    local data = self:GetOrCreateOperateData()
    data.Op = operate
    data.QuestId = questId
    data.StepId = stepId
    data.ObjectiveList = objectiveList
    data.OperateObjective = opObjective
    
    return data
end

function XUiBigWorldPanelQuest:GetTrackOperateData(operate, questId, stepId, objectiveId)
    local trackQuestId = XMVCA.XBigWorldQuest:GetTrackQuestId()
    --不是当前追踪的任务，并且没有追踪的任务
    if trackQuestId ~= questId and trackQuestId <= 0 then
        return self:GetDefaultOperateData(operate, 0, 0, 0)
    end
    questId = trackQuestId
    return self:GetQuestOperateData(operate, questId, stepId, objectiveId)
end

function XUiBigWorldPanelQuest:GetReceiveOperateData(operate, questId, stepId, objectiveId)
    return self:GetQuestOperateData(operate, questId, stepId, objectiveId)
end

function XUiBigWorldPanelQuest:GetDefaultOperateData(operate, questId, stepId, objectiveId)
    local data = self:GetOrCreateOperateData()
    data.Op = operate
    data.QuestId = questId
    data.StepId = stepId
    data.ObjectiveList = false
    data.OperateObjective = false
    
    return data
end

---@return XBigWorldQuestOpData
function XUiBigWorldPanelQuest:GetOperateData(operate, questId, stepId, objectiveId)
    local func = self._GetOperateData[operate]
    if func then
        return func(operate, questId, stepId, objectiveId)
    end
    return nil
end

---@return XBigWorldQuestOpData
function XUiBigWorldPanelQuest:GetOrCreateOperateData()
    local opData
    if not XTool.IsTableEmpty(self._OpDataPool) then
        opData = tableRemove(self._OpDataPool)
    else
        opData = {
            Op = 0,
            QuestId = 0,
            StepId = 0,
            ObjectiveList = false,
            OperateObjective = false
        }
    end
    
    return opData
end

--- 获取或者创建一个行为
---@param data XBigWorldQuestOpData
---@return XQuestAction
function XUiBigWorldPanelQuest:GetOrCreateAction(data)
    local action
    if not XTool.IsTableEmpty(self._OpDataPool) then
        action = tableRemove(self._OpDataPool)
    else
        action = XQuestAction.New(self)
    end
    action:SetOperateData(data)
    
    return action
end

--endregion

function XUiBigWorldPanelQuest:InitUi()
    --操作数据池
    self._OpDataPool = {}
    self._ObjectiveGrids = {}
    --操作池
    self._ActionPool = {}
    --操作队列
    self._ActionQueue = {}
    self._OperateHandler = {
        [QuestOpType.Refresh]           = handler(self, self.UpdateByRefreshOperate),
        [QuestOpType.QuestReceive]      = handler(self, self.UpdateByQuestReceiveOperate),
        [QuestOpType.QuestTrack]        = handler(self, self.UpdateByQuestTrackOperate),
        [QuestOpType.QuestUnTrack]      = handler(self, self.UpdateByQuestUnTrackOperate),
        [QuestOpType.QuestFinish]       = handler(self, self.UpdateByQuestFinishOperate),
        [QuestOpType.StepActive]        = handler(self, self.UpdateByStepActiveOperate),
        [QuestOpType.StepFinish]        = handler(self, self.UpdateByStepFinishOperate),
        [QuestOpType.ObjectiveActive]   = handler(self, self.UpdateByObjectiveActiveOperate),
        [QuestOpType.ObjectiveFinish]   = handler(self, self.UpdateByObjectiveFinishOperate),
    }
    self._GetOperateData = {
        [QuestOpType.Refresh]           = handler(self, self.GetTrackOperateData),
        [QuestOpType.QuestReceive]      = handler(self, self.GetReceiveOperateData),
        [QuestOpType.QuestTrack]        = handler(self, self.GetTrackOperateData),
        [QuestOpType.QuestUnTrack]      = handler(self, self.GetDefaultOperateData),
        [QuestOpType.QuestFinish]       = handler(self, self.GetDefaultOperateData),
        [QuestOpType.StepActive]        = handler(self, self.GetTrackOperateData),
        [QuestOpType.StepFinish]        = handler(self, self.GetTrackOperateData),
        [QuestOpType.ObjectiveActive]   = handler(self, self.GetTrackOperateData),
        [QuestOpType.ObjectiveFinish]   = handler(self, self.GetTrackOperateData),
    }
    self._PopupCount = 0
    self.BtnTrack.gameObject:SetActiveEx(false)
end

function XUiBigWorldPanelQuest:InitCb()
    XUiHelper.RegisterClickEvent(self, self.PanelTitle, self.OnQuestClick)

    self.BtnTrack.CallBack = function()
        self:OnBtnTrackClick()
    end

    self.BtnGo.CallBack = function()
        self:OnBtnGoClick()
    end
    
    XEventManager.AddEventListener(BWEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.OperateEnqueue, self)
    XEventManager.AddEventListener(BWEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.OnLevelChanged, self)
    XEventManager.AddEventListener(BWEventId.EVENT_MAP_PIN_ADD, self.OnMapPinAdd, self)
end

function XUiBigWorldPanelQuest:OnReceiveQuestRefresh(beginCb, finishCb)
    if self.BtnTrack then
        self.BtnTrack.gameObject:SetActiveEx(true)
    end
    if beginCb then beginCb() end
    
    self:StopQuestActiveTimer()
    --开启一个定时器，等待按钮隐藏
    self._QuestActiveTimer = XScheduleManager.ScheduleOnce(function()
        if self.BtnTrack then
            self.BtnTrack.gameObject:SetActiveEx(false)
        end
        --添加一个刷新操作
        XEventManager.DispatchEvent(BWEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, QuestOpType.Refresh, XMVCA.XBigWorldQuest:GetTrackQuestId(), 0, 0)
        
        --当前操作完成
        if finishCb then finishCb() end
    end, 5000)
    
    --当前操作完成
    if finishCb then finishCb() end
end

function XUiBigWorldPanelQuest:OnLevelChanged(levelId)
    self:OperateEnqueue(QuestOpType.Refresh, XMVCA.XBigWorldQuest:GetTrackQuestId(), 0, 0)
end

function XUiBigWorldPanelQuest:OnMapPinAdd()
    self:OperateEnqueue(QuestOpType.Refresh, XMVCA.XBigWorldQuest:GetTrackQuestId(), 0, 0)
end

function XUiBigWorldPanelQuest:PlayAnimation(animeName, finCb, beginCb, wrapMode)
    ---@type UnityEngine.RectTransform
    local transform = self[animeName]
    if not transform then
        transform = self.Animation.transform:Find(animeName)
        if not transform then
            XLog.Error("不存在节点!!!!", animeName)
            return
        end
        self[animeName] = transform
    end
    transform:PlayTimelineAnimation(finCb, beginCb, wrapMode or WrapHold, true)
end

function XUiBigWorldPanelQuest:StopQuestActiveTimer()
    if not self._QuestActiveTimer then
        return
    end
    XScheduleManager.UnSchedule(self._QuestActiveTimer)
    self._QuestActiveTimer = false
end

function XUiBigWorldPanelQuest:OnBtnTrackClick()
    local questId = self._DisplayId
    if not questId or questId <= 0 then
        return
    end
    if not self.BtnTrack.gameObject.activeInHierarchy then
        return
    end
    self:StopQuestActiveTimer()
    if self._RunningAction then
        self._RunningAction:ResetRefCount()
        self._RunningAction:Finish()
    end
    XMVCA.XBigWorldQuest:TrackQuest(questId, function()
        self.BtnTrack.gameObject:SetActiveEx(false)
    end)
end

function XUiBigWorldPanelQuest:OnBtnGoClick()
    local questId = self._DisplayId
    if not questId or questId <= 0 then
        return
    end
    XMVCA.XBigWorldMap:OpenBigWorldMapUiAnchorQuest(questId)
end

function XUiBigWorldPanelQuest:OnQuestClick()
    local questId = self._DisplayId
    if not questId or questId <= 0 then
        return
    end
    self.Parent:RecordQuestClick()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenQuest(1, questId)
end

--- 计算任务数据的唯一值
---@param operateData XBigWorldQuestOpData
---@return number
function XUiBigWorldPanelQuest:CalcQuestOpDataHashCode(operateData)
    if not operateData then
        return -1
    end
    local k = PrimaryKey
    k = k * SecondaryKey + operateData.QuestId or 0
    k = k * SecondaryKey + operateData.StepId or 0
    if not XTool.IsTableEmpty(operateData.ObjectiveList) then
        for _, objective in pairs(operateData.ObjectiveList) do
            k = k * SecondaryKey + objective:GetId()
        end
    end
    return k * operateData.Op
end

return XUiBigWorldPanelQuest


---@class XBigWorldQuestOpData
---@field Op number
---@field QuestId number
---@field StepId number
---@field ObjectiveList XBigWorldQuestObjective[]
---@field OperateObjective XBigWorldQuestObjective