---@class XUiPacMan2EventTimerManager
---事件系统专用的一次性计时器。
---
---职责：
---1. 统一管理事件组调度和原子事件完成计时；
---2. 暂停时取消底层调度，并保存剩余时间；
---3. 恢复时按剩余时间重新调度；
---4. 清理时直接丢弃任务，不调用完成回调。
---
---不负责游戏暂停、暂停来源、输入锁或倒计时动画。
local XUiPacMan2EventTimerManager = XClass(nil, "XUiPacMan2EventTimerManager")

function XUiPacMan2EventTimerManager:Ctor()
    self._Tasks = {}
    self._NextTimerId = 0
    self._IsPaused = false
    self._IsDisposed = false
    self._ResumeTasks = nil
end

---注册一次性任务，时间单位为秒。
---未暂停时，零秒任务立即执行，不创建计时任务。
---暂停时，零秒任务仍需保存，等待恢复。
---@param seconds number
---@param callback function
---@return number|nil timerId 等待中的任务Id；已同步完成或未成功注册时返回nil
function XUiPacMan2EventTimerManager:Schedule(seconds, callback)
    if self._IsDisposed then
        return nil
    end

    if type(callback) ~= "function" then
        XLog.Error("[PacMan2EventTimer] callback不是函数")
        return nil
    end

    seconds = tonumber(seconds) or 0

    if seconds ~= seconds or seconds == math.huge or seconds == -math.huge then
        XLog.Error("[PacMan2EventTimer] 非法计时时间")
        return nil
    end

    seconds = math.max(0, seconds)

    if not self._IsPaused and seconds <= 0 then
        callback()
        return nil
    end

    self._NextTimerId = self._NextTimerId + 1

    local task = {
        Id = self._NextTimerId,
        Callback = callback,
        Remaining = seconds,
        DueTime = nil,
        ScheduleId = nil,
    }

    self._Tasks[task.Id] = task

    if not self._IsPaused then
        self:_StartTask(task)
    end

    return task.Id
end

---启动任务。
---仅由Schedule和Resume调用，调用方保证任务有效且当前未暂停。
function XUiPacMan2EventTimerManager:_StartTask(task)
    if task.Remaining <= 0 then
        self:_CompleteTask(task)
        return
    end

    task.DueTime = CS.UnityEngine.Time.timeAsDouble + task.Remaining

    task.ScheduleId = XScheduleManager.ScheduleOnce(function()
        self:_CompleteTask(task)
    end, task.Remaining * XScheduleManager.SECOND)
end

---完成一个有效任务。
---先移除任务，再执行回调；回调中的Cancel、Pause等操作不会再次处理本任务。
function XUiPacMan2EventTimerManager:_CompleteTask(task)
    self._Tasks[task.Id] = nil

    local callback = task.Callback
    task.Callback = nil
    task.ScheduleId = nil
    task.DueTime = nil

    callback()
end

---@param timerId number|nil
function XUiPacMan2EventTimerManager:Cancel(timerId)
    local task = timerId and self._Tasks[timerId]

    if not task then
        return
    end

    self._Tasks[timerId] = nil

    if task.ScheduleId then
        XScheduleManager.UnSchedule(task.ScheduleId)
    end

    task.ScheduleId = nil
    task.Callback = nil
    task.DueTime = nil
end

---冻结全部事件计时。
function XUiPacMan2EventTimerManager:Pause()
    if self._IsDisposed or self._IsPaused then
        return
    end

    self._IsPaused = true

    -- 如果在恢复回调中再次暂停，让原来的恢复循环立即失效。
    self._ResumeTasks = nil

    local now = CS.UnityEngine.Time.timeAsDouble

    for _, task in pairs(self._Tasks) do
        if task.ScheduleId then
            task.Remaining = math.max(0, task.DueTime - now)
            XScheduleManager.UnSchedule(task.ScheduleId)
            task.ScheduleId = nil
            task.DueTime = nil
        end
    end
end

---恢复已有任务。
---回调允许取消其他任务，或再次调用Pause、Resume。
function XUiPacMan2EventTimerManager:Resume()
    if self._IsDisposed or not self._IsPaused then
        return
    end

    self._IsPaused = false

    local resumeTasks = {}

    for _, task in pairs(self._Tasks) do
        resumeTasks[#resumeTasks + 1] = task
    end

    table.sort(resumeTasks, function(left, right)
        if left.Remaining == right.Remaining then
            return left.Id < right.Id
        end

        return left.Remaining < right.Remaining
    end)

    self._ResumeTasks = resumeTasks

    for _, task in ipairs(resumeTasks) do
        -- 回调再次暂停时停止。
        -- 如果回调中Pause后又Resume，新的恢复过程会替换本列表，
        -- 原来的恢复循环不能继续重复启动任务。
        if self._IsPaused or self._ResumeTasks ~= resumeTasks then
            break
        end

        -- 前一个任务的回调可能通过公开Cancel接口取消后面的任务。
        if self._Tasks[task.Id] == task then
            self:_StartTask(task)
        end
    end

    if self._ResumeTasks == resumeTasks then
        self._ResumeTasks = nil
    end
end

---丢弃全部任务，不执行回调。
---不重置Id计数，避免旧Id与新任务发生碰撞。
function XUiPacMan2EventTimerManager:Reset()
    for _, task in pairs(self._Tasks) do
        if task.ScheduleId then
            XScheduleManager.UnSchedule(task.ScheduleId)
        end

        task.ScheduleId = nil
        task.Callback = nil
        task.DueTime = nil
    end

    self._Tasks = {}
    self._ResumeTasks = nil
    self._IsPaused = false
end

function XUiPacMan2EventTimerManager:Dispose()
    if self._IsDisposed then
        return
    end

    self:Reset()
    self._IsDisposed = true
end

return XUiPacMan2EventTimerManager