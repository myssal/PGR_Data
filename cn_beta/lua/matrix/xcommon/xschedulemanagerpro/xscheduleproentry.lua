-- 定时计划最小执行单位（XScheduleManagerPro 内部节点，不对外使用）
-- 生命周期由 XScheduleManagerPro 的对象池管理：Create/Release 对接 XPool

---@class XScheduleProEntry
---@field Handler fun(handlerObj:any) 回调函数
---@field HandlerObj any 回调对象，作为 Handler 的第一个参数传入
---@field Interval number 触发间隔（毫秒）
---@field FirstInterval number 首次触发间隔（毫秒）
---@field NextTriggerTime number|nil 下次触发时间（毫秒），首次参与调度前为 nil
---@field RegFrame number 注册时的调度帧
---@field Status number 状态（STATUS_ACTIVE/STATUS_TO_INSERT/STATUS_TO_DELETE，pending 时使用）
---@field Loop number 循环次数，0 为永久
---@field Count number 已触发次数
---@field IsFirstTrigger boolean 是否尚未触发过
local XScheduleProEntry = XClass(nil, "XScheduleProEntry")

XScheduleProEntry.STATUS_ACTIVE = 1
XScheduleProEntry.STATUS_TO_INSERT = 2
XScheduleProEntry.STATUS_TO_DELETE = 3

function XScheduleProEntry:Ctor()
    self:Reset()
end

function XScheduleProEntry:Reset()
    self.Handler = nil
    self.HandlerObj = nil
    self.Interval = 0
    self.FirstInterval = 0
    self.NextTriggerTime = nil
    self.RegFrame = 0
    self.Status = XScheduleProEntry.STATUS_ACTIVE
    self.Loop = 0
    self.Count = 0
    self.IsFirstTrigger = true
end

-- 单帧最多触发一次；触发时间按 NextTriggerTime 累加，积压时逐帧补触发
---@param now number 当前时间（毫秒）
---@param curFrame number 当前调度帧
---@return boolean 是否已完成（到达循环次数或回调出错），完成后由调度器回收
function XScheduleProEntry:Update(now, curFrame)
    -- 注册当帧不触发，保证 ScheduleNextFrame 必然下一帧执行
    if self.RegFrame >= curFrame then
        return false
    end

    if not self.NextTriggerTime then
        local triggerInterval = self.IsFirstTrigger and self.FirstInterval or self.Interval
        self.NextTriggerTime = now + triggerInterval
    end

    if now < self.NextTriggerTime then
        return false
    end

    self.IsFirstTrigger = false
    self.Count = self.Count + 1

    local ok, err = xpcall(self.Handler, debug.traceback, self.HandlerObj)
    if not ok then
        XLog.Error("XScheduleProEntry.Update error, handler: " .. tostring(self.Handler)
                .. ", handlerObj: " .. tostring(self.HandlerObj)
                .. ", error: " .. tostring(err))
        return true
    end

    self.NextTriggerTime = self.NextTriggerTime + self.Interval

    return self.Loop > 0 and self.Count >= self.Loop
end

-- 对象池 create 回调
function XScheduleProEntry.Create()
    return XScheduleProEntry.New()
end

-- 对象池 reset 回调
function XScheduleProEntry.Release(entry)
    entry:Reset()
end

return XScheduleProEntry
