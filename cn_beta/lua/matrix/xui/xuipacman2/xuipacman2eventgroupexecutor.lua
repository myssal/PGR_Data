local XUiPacMan2AtomicEventExecutor = require("XUi/XUiPacMan2/XUiPacMan2AtomicEventExecutor")

---@class XUiPacMan2EventGroupExecutor
---事件组执行器。
---
---职责：
---1. 每次触发创建独立事件组运行实例；
---2. 根据AtomicEventTimes调度原子事件；
---3. 管理事件组和原子事件的输入锁；
---4. 等待全部调度完成和原子事件完成；
---5. 通知事件组完成。
---
---事件组默认允许并发，包括相同EventGroupId的不同运行实例。
local XUiPacMan2EventGroupExecutor = XClass(nil, "XUiPacMan2EventGroupExecutor")

---@param inputManager XUiPacMan2InputManager
---@param eventConfig XUiPacMan2EventConfig
---@param visualController XUiPacMan2VisualController
---@param eventTimerManager XUiPacMan2EventTimerManager
function XUiPacMan2EventGroupExecutor:Ctor(inputManager, eventConfig, visualController, eventTimerManager)
    self._InputManager = inputManager
    self._EventConfig = eventConfig
    self._EventTimerManager = eventTimerManager
    self._AtomicExecutor = XUiPacMan2AtomicEventExecutor.New(visualController, eventTimerManager)

    self._RunningGroups = {}
    self._NextGroupRuntimeId = 0
    self._NextAtomicRuntimeId = 0

    -- 等待队列只保存播放请求，不提前创建运行实例或申请输入锁。
    self._PendingGroups = {}
    self._PendingHead = 1
    self._PendingTail = 0

    self._IsPaused = false
    self._IsFlushingPending = false
    self._IsDisposed = false
end

function XUiPacMan2EventGroupExecutor:BeginStage()
    if self._IsDisposed then
        return
    end

    self._IsPaused = true
    self:_ClearPendingGroups()
    self:_ClearRunningGroups()
    self._IsPaused = false
end

---@param matchedResult table
---@param transactionMessage table
---@param onComplete function|nil
---@return number|nil groupRuntimeId
function XUiPacMan2EventGroupExecutor:Execute(matchedResult, transactionMessage, onComplete)
    if not matchedResult then
        return nil
    end

    return self:ExecuteGroup(matchedResult.EventGroupId, matchedResult, transactionMessage, onComplete)
end

---直接执行指定事件组。
---主流程以后也可以使用这个接口播放开场或结束事件。
---@param eventGroupId number
---@param sourceInfo table|nil
---@param transactionMessage table|nil
---@param onComplete function|nil
---@return number|nil groupRuntimeId
function XUiPacMan2EventGroupExecutor:_ExecuteGroupNow(eventGroupId, sourceInfo, transactionMessage, onComplete)
    local groupConfig = self._EventConfig:GetEventGroupConfig(eventGroupId)

    if not groupConfig then
        XLog.Error("[PacMan2EventGroupExecutor] 找不到事件组配置, eventGroupId=" .. tostring(eventGroupId))

        if onComplete then
            onComplete(nil)
        end

        return nil
    end

    local atomicEventIds = groupConfig.AtomicEventIds or {}
    local atomicEventTimes = groupConfig.AtomicEventTimes or {}

    if #atomicEventIds ~= #atomicEventTimes then
        XLog.Error("[PacMan2EventGroupExecutor] 原子事件Id与时间数量不一致, eventGroupId=" .. tostring(eventGroupId))

        if onComplete then
            onComplete(nil)
        end

        return nil
    end

    if #atomicEventIds == 0 then
        XLog.Error("[PacMan2EventGroupExecutor] 事件组没有原子事件, eventGroupId=" .. tostring(eventGroupId))

        if onComplete then
            onComplete(nil)
        end

        return nil
    end

    -- 每次触发都创建新的运行实例。
    -- 相同EventGroupId也可以存在多个并行实例。
    self._NextGroupRuntimeId = self._NextGroupRuntimeId + 1

    local groupRuntime = {
        RuntimeId = self._NextGroupRuntimeId,
        EventGroupId = eventGroupId,
        SourceInfo = sourceInfo,
        TransactionMessage = transactionMessage,

        -- 尚未到达配置触发时间的原子事件数量。
        PendingScheduleCount = #atomicEventIds,

        -- 已经开始执行，但尚未完成的原子事件数量。
        RunningAtomicCount = 0,

        -- 保存本事件组创建的调度计时器。
        ScheduleTimerIds = {},

        -- 保存当前仍在执行的原子事件运行实例。
        AtomicRuntimes = {},

        InputLockToken = nil,
        OnComplete = onComplete,
    }

    -- 必须先注册运行实例，再启动原子事件。
    -- 因为时间为0的原子事件会在当前调用栈中立即开始和完成。
    self._RunningGroups[groupRuntime.RuntimeId] = groupRuntime

    if groupConfig.BlockControl and self._InputManager then
        groupRuntime.InputLockToken = self._InputManager:AcquireControlLock("PacMan2EventGroup_" .. tostring(groupRuntime.RuntimeId))
    end

    XLog.Debug("[PacMan2EventGroupExecutor] GroupStarted, eventGroupId=" .. tostring(eventGroupId) .. ", runtimeId=" .. tostring(groupRuntime.RuntimeId))

    -- 回调不会同步销毁或重置执行系统，可以连续注册本组的原子事件。
    for index, atomicEventId in ipairs(atomicEventIds) do
        local delay = tonumber(atomicEventTimes[index]) or 0
        self:_ScheduleAtomicEvent(groupRuntime, atomicEventId, math.max(0, delay))
    end

    return groupRuntime.RuntimeId
end

---提交事件组。
---未暂停且没有等待项时立即启动，否则进入FIFO等待队列。
---排队时没有运行实例，返回nil；实际启动后的完成通知仍通过onComplete传递。
---@param eventGroupId number
---@param sourceInfo table|nil
---@param transactionMessage table|nil
---@param onComplete function|nil
---@return number|nil groupRuntimeId
function XUiPacMan2EventGroupExecutor:ExecuteGroup(eventGroupId, sourceInfo, transactionMessage, onComplete)
    if self._IsDisposed then
        return nil
    end

    if self._IsPaused or self._IsFlushingPending or self._PendingHead <= self._PendingTail then
        self._PendingTail = self._PendingTail + 1
        self._PendingGroups[self._PendingTail] = {
            EventGroupId = eventGroupId,
            SourceInfo = sourceInfo,
            TransactionMessage = transactionMessage,
            OnComplete = onComplete,
        }

        XLog.Debug("[PacMan2EventGroupExecutor] GroupQueued, eventGroupId=" .. tostring(eventGroupId))

        -- 如果当前可以执行，就处理队列。
        -- 暂停中或已有排空循环时，该函数会直接返回。
        self:FlushPendingGroups()
        return nil
    end

    return self:_ExecuteGroupNow(eventGroupId, sourceInfo, transactionMessage, onComplete)
end

---只改变事件组启动权限，不负责计时器暂停恢复。
---恢复时由Runtime先恢复已有计时器，再调用FlushPendingGroups。
function XUiPacMan2EventGroupExecutor:SetPaused(isPaused)
    if self._IsDisposed then
        return
    end

    self._IsPaused = isPaused
end

---按FIFO顺序启动等待中的事件组。
---回调允许追加事件组或再次暂停，但不允许同步清理执行器。
function XUiPacMan2EventGroupExecutor:FlushPendingGroups()
    if self._IsDisposed or self._IsPaused or self._IsFlushingPending then
        return
    end

    self._IsFlushingPending = true

    while not self._IsPaused and self._PendingHead <= self._PendingTail do
        local pendingGroup = self._PendingGroups[self._PendingHead]

        -- 先出队，再启动；回调新增的事件组追加到队尾。
        self._PendingGroups[self._PendingHead] = nil
        self._PendingHead = self._PendingHead + 1

        self:_ExecuteGroupNow(pendingGroup.EventGroupId, pendingGroup.SourceInfo, pendingGroup.TransactionMessage, pendingGroup.OnComplete)
    end

    self._IsFlushingPending = false

    if self._PendingHead > self._PendingTail then
        self._PendingHead = 1
        self._PendingTail = 0
    end
end

---直接丢弃等待请求。
---不调用完成回调，避免清理时误触发开局倒计时等后续流程。
function XUiPacMan2EventGroupExecutor:_ClearPendingGroups()
    self._PendingGroups = {}
    self._PendingHead = 1
    self._PendingTail = 0
    self._IsFlushingPending = false
end

function XUiPacMan2EventGroupExecutor:_ScheduleAtomicEvent(groupRuntime, atomicEventId, delay)
    local timerId

    -- 所有原子事件，包括零秒事件，都经过统一计时器。
    timerId = self._EventTimerManager:Schedule(delay, function()
        if timerId then
            groupRuntime.ScheduleTimerIds[timerId] = nil
        end

        self:_StartAtomicEvent(groupRuntime.RuntimeId, atomicEventId)
    end)

    -- 已同步执行的零秒任务返回nil，不会被重新登记。
    if timerId then
        groupRuntime.ScheduleTimerIds[timerId] = true
    end
end

function XUiPacMan2EventGroupExecutor:_StartAtomicEvent(groupRuntimeId, atomicEventId)
    local groupRuntime = self._RunningGroups[groupRuntimeId]

    if not groupRuntime then
        return
    end

    groupRuntime.PendingScheduleCount = math.max(0, groupRuntime.PendingScheduleCount - 1)

    local atomicConfig = self._EventConfig:GetAtomicEventConfig(atomicEventId)

    if not atomicConfig then
        XLog.Error("[PacMan2EventGroupExecutor] 找不到原子事件配置, atomicEventId=" .. tostring(atomicEventId))
        self:_TryCompleteGroup(groupRuntime)
        return
    end

    self._NextAtomicRuntimeId = self._NextAtomicRuntimeId + 1

    local atomicRuntime = {
        RuntimeId = self._NextAtomicRuntimeId,
        GroupRuntimeId = groupRuntime.RuntimeId,
        EventGroupId = groupRuntime.EventGroupId,
        AtomicEventId = atomicEventId,
        SourceInfo = groupRuntime.SourceInfo,
        TransactionMessage = groupRuntime.TransactionMessage,
        InputLockToken = nil,

        -- 取消后忽略晚到的异步完成通知。
        IsCancelled = false,

        -- 页面操作结束后，可能仍需等待事件计时器通知完成。
        CompletionTimerId = nil,
    }

    groupRuntime.AtomicRuntimes[atomicRuntime.RuntimeId] = atomicRuntime
    groupRuntime.RunningAtomicCount = groupRuntime.RunningAtomicCount + 1

    if atomicConfig.BlockControl and self._InputManager then
        atomicRuntime.InputLockToken = self._InputManager:AcquireControlLock("PacMan2AtomicEvent_" .. tostring(atomicRuntime.RuntimeId))
    end

    XLog.Debug("[PacMan2EventGroupExecutor] AtomicStarted, atomicEventId=" .. tostring(atomicEventId) .. ", runtimeId=" .. tostring(atomicRuntime.RuntimeId))

    self._AtomicExecutor:Execute(atomicConfig, atomicRuntime, function()
        self:_OnAtomicEventCompleted(groupRuntime.RuntimeId, atomicRuntime.RuntimeId)
    end)
end

function XUiPacMan2EventGroupExecutor:_OnAtomicEventCompleted(groupRuntimeId, atomicRuntimeId)
    local groupRuntime = self._RunningGroups[groupRuntimeId]

    if not groupRuntime then
        return
    end

    local atomicRuntime = groupRuntime.AtomicRuntimes[atomicRuntimeId]

    -- 防止原子事件重复通知完成。
    if not atomicRuntime then
        return
    end

    if atomicRuntime.InputLockToken and self._InputManager then
        self._InputManager:ReleaseLock(atomicRuntime.InputLockToken)
        atomicRuntime.InputLockToken = nil
    end

    groupRuntime.AtomicRuntimes[atomicRuntimeId] = nil
    groupRuntime.RunningAtomicCount = math.max(0, groupRuntime.RunningAtomicCount - 1)

    XLog.Debug("[PacMan2EventGroupExecutor] AtomicCompleted, atomicEventId=" .. tostring(atomicRuntime.AtomicEventId) .. ", runtimeId=" .. tostring(atomicRuntimeId))

    self:_TryCompleteGroup(groupRuntime)
end

function XUiPacMan2EventGroupExecutor:_TryCompleteGroup(groupRuntime)
    if not self._RunningGroups[groupRuntime.RuntimeId] then
        return
    end

    if groupRuntime.PendingScheduleCount > 0 or groupRuntime.RunningAtomicCount > 0 then
        return
    end

    self._RunningGroups[groupRuntime.RuntimeId] = nil

    if groupRuntime.InputLockToken and self._InputManager then
        self._InputManager:ReleaseLock(groupRuntime.InputLockToken)
        groupRuntime.InputLockToken = nil
    end

    XLog.Debug("[PacMan2EventGroupExecutor] GroupCompleted, eventGroupId=" .. tostring(groupRuntime.EventGroupId) .. ", runtimeId=" .. tostring(groupRuntime.RuntimeId))

    if groupRuntime.OnComplete then
        groupRuntime.OnComplete(groupRuntime)
    end
end

function XUiPacMan2EventGroupExecutor:_ClearRunningGroups()
    if self._AtomicExecutor then
        self._AtomicExecutor:Reset()
    end

    for _, groupRuntime in pairs(self._RunningGroups) do
        for timerId in pairs(groupRuntime.ScheduleTimerIds) do
            self._EventTimerManager:Cancel(timerId)
        end

        for _, atomicRuntime in pairs(groupRuntime.AtomicRuntimes) do
            if atomicRuntime.InputLockToken and self._InputManager then
                self._InputManager:ReleaseLock(atomicRuntime.InputLockToken)
            end
        end

        if groupRuntime.InputLockToken and self._InputManager then
            self._InputManager:ReleaseLock(groupRuntime.InputLockToken)
        end
    end

    self._RunningGroups = {}
end

---取消一个正在执行的事件组实例。
---使用RuntimeId定位具体的一次执行，不影响同配置Id的其他实例。
---取消不通知正常完成，后续流程由调用方负责。
---@param groupRuntimeId number
---@return boolean 是否取消成功
function XUiPacMan2EventGroupExecutor:CancelGroup(groupRuntimeId)
    local groupRuntime = groupRuntimeId and self._RunningGroups[groupRuntimeId]

    if not groupRuntime then
        return false
    end

    -- 先移除实例，使晚到的调度和完成回调失效。
    self._RunningGroups[groupRuntimeId] = nil
    groupRuntime.OnComplete = nil

    -- 取消尚未到达播放时间的原子事件。
    for timerId in pairs(groupRuntime.ScheduleTimerIds) do
        self._EventTimerManager:Cancel(timerId)
    end

    -- 停止本组仍在执行的原子事件，并释放它们的输入锁。
    for _, atomicRuntime in pairs(groupRuntime.AtomicRuntimes) do
        self._AtomicExecutor:Cancel(atomicRuntime)

        if atomicRuntime.InputLockToken and self._InputManager then
            self._InputManager:ReleaseLock(atomicRuntime.InputLockToken)
            atomicRuntime.InputLockToken = nil
        end
    end

    if groupRuntime.InputLockToken and self._InputManager then
        self._InputManager:ReleaseLock(groupRuntime.InputLockToken)
        groupRuntime.InputLockToken = nil
    end

    XLog.Debug("[PacMan2EventGroupExecutor] GroupCancelled, eventGroupId=" .. tostring(groupRuntime.EventGroupId) .. ", runtimeId=" .. tostring(groupRuntimeId))
    return true
end

function XUiPacMan2EventGroupExecutor:Dispose()
    if self._IsDisposed then
        return
    end

    self._IsDisposed = true
    self._IsPaused = true

    self:_ClearPendingGroups()
    self:_ClearRunningGroups()

    if self._AtomicExecutor then
        self._AtomicExecutor:Dispose()
        self._AtomicExecutor = nil
    end

    self._InputManager = nil
    self._EventConfig = nil
    self._EventTimerManager = nil
end

return XUiPacMan2EventGroupExecutor