local XUiPacMan2ConditionContext = require("XUi/XUiPacMan2/XUiPacMan2ConditionContext")
local XUiPacMan2ConditionContextUpdater = require("XUi/XUiPacMan2/XUiPacMan2ConditionContextUpdater")
local XUiPacMan2ConditionMatcher = require("XUi/XUiPacMan2/XUiPacMan2ConditionMatcher")
local ConditionDefine = require("XUi/XUiPacMan2/XUiPacMan2ConditionDefine")
local XUiPacMan2EventGroupExecutor = require("XUi/XUiPacMan2/XUiPacMan2EventGroupExecutor")
local XUiPacMan2EventConfig = require("XUi/XUiPacMan2/XUiPacMan2EventConfig")
local XUiPacMan2EventTimerManager = require("XUi/XUiPacMan2/XUiPacMan2EventTimerManager")
local SignalType = CS.XPacMan2.XPacMan2SignalType
local GamePauseReason = CS.XPacMan2.XPacMan2GamePauseReason
local ChangeType = ConditionDefine.ChangeType
---@class XUiPacMan2EventRuntime
---PacMan2事件系统的唯一外部入口。
---
---职责：
---1. 维护Context、Updater、Matcher等事件系统组件；
---2. 初始化时主动从GameManager读取状态快照；
---3. 接收经过Game实例过滤后的完整C#业务事务；
---4. 按顺序处理事务中的全部Signal；
---5. 合并全部FieldChanges，并在Context更新完成后执行一次Matcher；
---6. 将匹配成功的事件组交给执行器。
local XUiPacMan2EventRuntime = XClass(nil, "XUiPacMan2EventRuntime")

---Lua对不同游戏暂停原因的事件执行策略。
---false只表示不新增事件暂停，不会释放其他来源已经申请的暂停。
local PauseEventExecutionByReason = {
    [GamePauseReason.DamageRecovery] = true,
    [GamePauseReason.PauseMenu] = true,
    [GamePauseReason.Opening] = false,
}

---@param gameUi XUiPacMan2Game
---@param inputManager XUiPacMan2InputManager
---@param control XPacMan2Control
---@param visualController XUiPacMan2VisualController
function XUiPacMan2EventRuntime:Ctor(gameUi, inputManager, control, visualController)
    self._GameUi = gameUi
    self._VisualController = visualController
    self._EventConfig = XUiPacMan2EventConfig.New(control)
    self._ConditionContext = XUiPacMan2ConditionContext.New()
    self._ContextUpdater = XUiPacMan2ConditionContextUpdater.New(self._ConditionContext)
    self._ConditionMatcher = XUiPacMan2ConditionMatcher.New(self._ConditionContext)
    self._EventTimerManager = XUiPacMan2EventTimerManager.New()
    self._EventGroupExecutor = XUiPacMan2EventGroupExecutor.New(inputManager, self._EventConfig, visualController, self._EventTimerManager)
    self._PauseSources = {}
    self._IsDisposed = false
    self._IsContextInitialized = false
end

---开始新关卡。
---此时GameManager还没有创建，只清理旧事件并重置规则和Context。
---@param stageId number
function XUiPacMan2EventRuntime:BeginStage(stageId)
    if self._IsDisposed then
        return
    end

    self._IsContextInitialized = false

    -- 直接清理，不通过ReleasePause恢复旧事件。
    self._PauseSources = {}
    self._EventGroupExecutor:BeginStage()
    self._EventTimerManager:Reset()
    self._ContextUpdater:BeginStage()

    local rules = self._EventConfig:GetRulesByStageId(stageId)
    self._ConditionMatcher:BeginStage(rules)
end

---GameManager完成创建和配置后，主动读取一次条件状态快照。
---@param gameManager XPacMan2.XPacMan2GameManager
function XUiPacMan2EventRuntime:InitializeContext(gameManager)
    self._IsContextInitialized = self._ContextUpdater:InitializeFromGameManager(gameManager)

    if not self._IsContextInitialized then
        XLog.Error("[PacMan2EventRuntime] 条件Context初始化失败")
        return
    end

    -- Context完成初始化后，记录各规则的初始匹配状态。
    -- 这里只建立OnEnter基线，不会触发事件组。
    self._ConditionMatcher:RefreshStates()
end

---处理C#已经收集完成的一次完整业务事务。
---
---执行顺序：
---1. 先扫描流程请求，建立事件暂停约束；
---2. 按C#记录顺序将全部Signal交给Updater，仅转换条件系统关心的信号；
---3. 合并全部FieldChanges；
---4. 全部条件状态更新完毕后只调用一次Matcher；
---5. 将匹配结果交给执行器；暂停期间只入队，不启动。
---@param transaction XPacMan2.XPacMan2GameSignalTransaction
function XUiPacMan2EventRuntime:OnGameSignalTransaction(transaction)
    if self._IsDisposed then
        return
    end
    if not self._IsContextInitialized then
        XLog.Error("[PacMan2EventRuntime] Context尚未初始化，不能处理业务事务")
        return
    end

    if not transaction or not transaction.Signals then
        XLog.Error("[PacMan2EventRuntime] 收到无效的业务事务")
        return
    end

    local signals = transaction.Signals

    if signals.Length <= 0 then
        return
    end

    -- 必须先处理流程请求，再更新条件和提交事件组。
    self:_HandleTransactionFlow(signals)
    
    local transactionFieldChanges = {}

    -- 本对象属于整个业务事务。
    -- 同一事务命中的所有Rule和事件组共享它，但不应修改它。
    local transactionMessage = {
        SourceTransaction = transaction,
        SignalMessages = {},
    }

    -- C#数组使用从0开始的下标。
    for index = 0, signals.Length - 1 do
        local signal = signals[index]

        -- 流程请求已经提前处理。
        -- Updater只转换自己注册的业务信号，其他信号不产生条件变化。
        -- 保留原始消息，供后续执行器读取。
        if signal then
            local fieldChanges, runtimeInfo = self._ContextUpdater:ApplySignal(signal)

            -- 完整原始信号已经保存在SourceTransaction中。
            -- 这里只记录Updater产生了条件变化或运行时信息的消息，避免创建无用记录。
            if fieldChanges or runtimeInfo then
                transactionMessage.SignalMessages[#transactionMessage.SignalMessages + 1] = {
                    Signal = signal,
                    RuntimeInfo = runtimeInfo,
                }
            end

            if fieldChanges then
                self:_MergeTransactionFieldChanges(transactionFieldChanges, fieldChanges)
            end
        end
    end

    -- 所有Signal都已处理，Context此时已经是事务结束后的最终状态。
    self:_MatchAndExecute(transactionFieldChanges, transactionMessage)
end

---使用本次完整变化检查条件，并提交匹配成功的事件组。
---C#完整事务和Lua流程通知共用此方法。
---调用前必须完成本次相关Context更新。
---@param fieldChanges table|nil
---@param transactionMessage table
function XUiPacMan2EventRuntime:_MatchAndExecute(fieldChanges, transactionMessage)
    if not fieldChanges or next(fieldChanges) == nil then
        return
    end

    local matchedResults = self._ConditionMatcher:OnFieldsChanged(fieldChanges)
    local executedEventGroupIds = {}

    for _, matchedResult in ipairs(matchedResults) do
        local eventGroupId = matchedResult.EventGroupId

        -- 一次匹配可能命中多条指向相同事件组的规则。
        -- 同一个事件组在本次提交中最多执行一次。
        if not executedEventGroupIds[eventGroupId] then
            executedEventGroupIds[eventGroupId] = true

            XLog.Debug("[PacMan2EventRuntime] ConditionMatched, ruleId=" .. tostring(matchedResult.Id) .. ", eventGroupId=" .. tostring(eventGroupId))

            -- 执行器负责处理暂停：暂停期间只入队，恢复后再启动。
            self._EventGroupExecutor:Execute(matchedResult, transactionMessage, function(groupRuntime)
                self:_OnEventGroupCompleted(groupRuntime)
            end)
        end
    end
end

---将一条Signal产生的FieldChanges合并到事务级FieldChanges。
---
---同一字段在一个事务中多次变化时：
---1. ValueChanged保留第一次OldValue和最后一次NewValue；
---2. Triggered表示本事务中至少发生过一次，Value以最后一次为准。
---@param transactionFieldChanges table
---@param signalFieldChanges table
function XUiPacMan2EventRuntime:_MergeTransactionFieldChanges(transactionFieldChanges, signalFieldChanges)
    for field, incomingChange in pairs(signalFieldChanges) do
        local existingChange = transactionFieldChanges[field]

        if not existingChange then
            transactionFieldChanges[field] = incomingChange
        elseif existingChange.Type == ChangeType.ValueChanged and incomingChange.Type == ChangeType.ValueChanged then
            if existingChange.NewValue ~= incomingChange.OldValue then
                XLog.Warning("[PacMan2EventRuntime] 同一事务中的字段变化不连续, field=" .. tostring(field) .. ", previousNewValue=" .. tostring(existingChange.NewValue) .. ", nextOldValue=" .. tostring(incomingChange.OldValue))
            end

            existingChange.NewValue = incomingChange.NewValue
        elseif existingChange.Type == ChangeType.Triggered and incomingChange.Type == ChangeType.Triggered then
            if incomingChange.Value ~= nil then
                existingChange.Value = incomingChange.Value
            end
        else
            XLog.Error("[PacMan2EventRuntime] 同一字段在一个事务中出现不同ChangeType, field=" .. tostring(field))
        end
    end
end

---执行指定关卡的开局事件组。
---开局事件属于主流程，不经过ConditionMatcher。
---@param stageId number
---@param onComplete function|nil
---@return number|nil groupRuntimeId
function XUiPacMan2EventRuntime:ExecuteOpeningEvent(stageId, onComplete)
    local stageEventConfig = self._EventConfig:GetStageEventConfig(stageId)

    if not stageEventConfig then
        XLog.Warning("[PacMan2EventRuntime] 本关没有StageEvent配置, stageId=" .. tostring(stageId))

        if onComplete then
            onComplete(nil)
        end

        return nil
    end

    local openingEventGroupId = stageEventConfig.OpeningEventGroupId

    -- 没有配置开局事件时，直接视为开局事件完成。
    -- 这样未配置新系统的旧关卡仍然可以正常进入倒计时。
    if not XTool.IsNumberValid(openingEventGroupId) then
        XLog.Debug("[PacMan2EventRuntime] 本关没有配置开局事件组, stageId=" .. tostring(stageId))

        if onComplete then
            onComplete(nil)
        end

        return nil
    end

    local sourceInfo = {
        SourceType = "Opening",
        StageId = stageId,
    }

    return self:ExecuteEventGroup(openingEventGroupId, sourceInfo, nil, onComplete)
end

---供主流程直接提交指定事件组。
---完成回调不允许同步重置或销毁所属事件系统。
function XUiPacMan2EventRuntime:ExecuteEventGroup(eventGroupId, sourceInfo, transactionMessage, onComplete)
    if self._IsDisposed then
        return nil
    end

    return self._EventGroupExecutor:ExecuteGroup(eventGroupId, sourceInfo, transactionMessage, function(groupRuntime)
        self:_OnEventGroupCompleted(groupRuntime)

        if onComplete then
            onComplete(groupRuntime)
        end
    end)
end

---处理游戏暂停流程请求。
---可由C#事务预处理调用，也可由Lua本地暂停菜单直接调用。
---这里只决定事件系统如何处理，不调用C# Pause，不启动321。
function XUiPacMan2EventRuntime:OnGamePauseRequested(reason)
    if self._IsDisposed then
        return
    end

    if reason == nil then
        XLog.Error("[PacMan2EventRuntime] GamePauseRequested缺少Reason")
        return
    end

    local shouldPauseEvents = PauseEventExecutionByReason[reason]

    if shouldPauseEvents == nil then
        XLog.Error("[PacMan2EventRuntime] 未配置暂停原因的事件策略, reason=" .. tostring(reason))
        return
    end

    if shouldPauseEvents then
        self:AcquirePause(reason)
    end
end

---@return boolean
function XUiPacMan2EventRuntime:IsPaused()
    return next(self._PauseSources) ~= nil
end

---Lua主流程报告一次321倒计时正常完成。
---调用时倒计时画面已经关闭，原有玩法恢复流程已经执行。
---这是一次独立通知，不与此前的扣血事务合并。
---@param source number EventDefine.CountdownSource中的值
function XUiPacMan2EventRuntime:OnCountdownCompleted(source)
    if self._IsDisposed then
        return
    end

    if not self._IsContextInitialized then
        XLog.Error("[PacMan2EventRuntime] Context尚未初始化，不能处理倒计时完成")
        return
    end

    local fieldChanges, runtimeInfo = self._ContextUpdater:ApplyCountdownCompleted(source)

    if not fieldChanges then
        return
    end

    -- Lua流程通知没有SourceTransaction。
    -- 保留本次来源信息，匹配出的所有事件组共享这份运行时消息。
    local transactionMessage = {
        SourceType = "CountdownCompleted",
        SignalMessages = {
            {
                RuntimeInfo = runtimeInfo,
            },
        },
    }

    XLog.Debug("[PacMan2EventRuntime] CountdownCompleted, source=" .. tostring(source))

    self:_MatchAndExecute(fieldChanges, transactionMessage)
end

---申请一个事件暂停来源。
---同一来源重复申请不叠加。
function XUiPacMan2EventRuntime:AcquirePause(reason)
    if self._IsDisposed or reason == nil or self._PauseSources[reason] then
        return
    end

    local wasPaused = self:IsPaused()
    self._PauseSources[reason] = true

    XLog.Debug("[PacMan2EventRuntime] PauseAcquired, reason=" .. tostring(reason))

    if not wasPaused then
        -- 先禁止启动新组，再冻结已有事件时间。
        self._EventGroupExecutor:SetPaused(true)
        self._EventTimerManager:Pause()
    end
end

---释放事件暂停来源。
---恢复回调可以再次申请暂停，但不能同步重置或销毁事件系统。
function XUiPacMan2EventRuntime:ReleasePause(reason)
    if self._IsDisposed or reason == nil or not self._PauseSources[reason] then
        return
    end

    self._PauseSources[reason] = nil

    XLog.Debug("[PacMan2EventRuntime] PauseReleased, reason=" .. tostring(reason))

    if self:IsPaused() then
        return
    end

    -- 执行器暂时仍禁止新组启动。
    -- 恢复已有计时器期间产生的新组继续入队。
    self._EventTimerManager:Resume()

    -- 回调可能合法地再次申请暂停，这个检查仍然需要。
    if self:IsPaused() then
        return
    end

    self._EventGroupExecutor:SetPaused(false)
    self._EventGroupExecutor:FlushPendingGroups()
end

---取消一个正在执行的事件组实例。
---不触发正常完成通知，不重置条件系统和其他事件。
---@param groupRuntimeId number
---@return boolean
function XUiPacMan2EventRuntime:CancelEventGroup(groupRuntimeId)
    if self._IsDisposed or not groupRuntimeId then
        return false
    end

    return self._EventGroupExecutor:CancelGroup(groupRuntimeId)
end

---先处理完整事务中的流程请求。
---无论暂停请求记录在数组的哪个位置，都先建立事件执行约束。
function XUiPacMan2EventRuntime:_HandleTransactionFlow(signals)
    for index = 0, signals.Length - 1 do
        local signal = signals[index]

        if signal and signal.SignalType == SignalType.GamePauseRequested then
            -- C#构造函数保证Args不为空；C#数组从0开始索引。
            local reason = signal.Args.Length > 0 and signal.Args[0] or nil
            self:OnGamePauseRequested(reason)
        end
    end
end

function XUiPacMan2EventRuntime:_OnEventGroupCompleted(groupRuntime)
    if not groupRuntime then
        return
    end

    if self._GameUi and self._GameUi.OnPacMan2EventGroupCompleted then
        self._GameUi:OnPacMan2EventGroupCompleted(groupRuntime)
    end
end

function XUiPacMan2EventRuntime:Dispose()
    if self._IsDisposed then
        return
    end

    self._IsDisposed = true
    self._PauseSources = {}
    self._IsContextInitialized = false

    if self._EventGroupExecutor then
        self._EventGroupExecutor:Dispose()
        self._EventGroupExecutor = nil
    end

    -- 执行器先取消自身任务、释放输入锁，最后由Runtime销毁共享计时器。
    if self._EventTimerManager then
        self._EventTimerManager:Dispose()
        self._EventTimerManager = nil
    end

    if self._ConditionMatcher then
        self._ConditionMatcher:Dispose()
        self._ConditionMatcher = nil
    end

    if self._ContextUpdater then
        self._ContextUpdater:Dispose()
        self._ContextUpdater = nil
    end

    if self._ConditionContext then
        self._ConditionContext:Dispose()
        self._ConditionContext = nil
    end
    
    if self._EventConfig then
        self._EventConfig:Dispose()
        self._EventConfig = nil
    end
    
    self._GameUi = nil
    self._VisualController = nil
end

return XUiPacMan2EventRuntime