---@class XScheduleManagerPro
---@field private _Listeners table<any, table<function, XScheduleProEntry>> 活跃定时器主映射（handlerObj -> handler -> entry）
---@field private _Pendings table<any, table<function, XScheduleProEntry>> 派发期挂起操作（同键只保留最后一次）
---@field private _OnceList XScheduleProEntry[] 本帧完成的定时器（待移除）
---@field private _Dispatching boolean 是否正在派发
---@field private _CurFrame number 当前调度帧
---@field private _Pool XPool 定时器节点对象池
---@field private _MapPool XPool 二级子表对象池（handler -> entry map）
---@field private _TrackHandelPool XPool 跟踪对象池（XScheduleProTrackHandelObject）
XScheduleManagerPro = XClass(nil, "XScheduleManagerPro")

local XScheduleProEntry = require("XCommon/XScheduleManagerPro/XScheduleProEntry")
local XScheduleProTrackHandelObject = require("XCommon/XScheduleManagerPro/XScheduleProTrackHandelObject")
local STATUS_ACTIVE = XScheduleProEntry.STATUS_ACTIVE
local STATUS_TO_INSERT = XScheduleProEntry.STATUS_TO_INSERT
local STATUS_TO_DELETE = XScheduleProEntry.STATUS_TO_DELETE

function XScheduleManagerPro._GetObjKey(handlerObj)
    if handlerObj == nil then
        return "StaticList"
    end
    return handlerObj
end
local CSXScheduleManager = CS.XScheduleManager
XScheduleManagerPro.SECOND = CSXScheduleManager.SECOND



function XScheduleManagerPro:Ctor()
    self._Listeners = {}
    self._Pendings = {}
    self._OnceList = {}
    self._Dispatching = false
    self._CurFrame = 0
    -- isDebug=false 关闭 XPool 的 Editor 深拷贝检测，避免高频路径上的开销
    self._Pool = XPool.New(XScheduleProEntry.Create, XScheduleProEntry.Release, false)
    self._MapPool = XPool.New( function() return {} end, table.clear, false)
    self._TrackHandelPool = XPool.New(
        function() return XScheduleProTrackHandelObject.New() end,    -- create：新建跟踪对象
        function(trackHandel) trackHandel:Reset(true) end,            -- release：重置并标记入池
        false)
end

-- 每帧驱动：1. 遍历触发（同键有 pending 操作的跳过，完成项记入 _OnceList）
-- 2. 移除完成项 3. 处理 _Pendings 挂起增删 4. 推帧
---@param now number 当前时间（毫秒）
function XScheduleManagerPro:_Update(now)
    self._Dispatching = true

    for objKey, handlerMap in pairs(self._Listeners) do
        for handler, entry in pairs(handlerMap) do
            -- 同键存在 pending 操作（删除、或覆盖式插入）时，旧实例本帧不再触发
            if not self:_GetPending(objKey, handler) then
                if entry:Update(now, self._CurFrame) then
                    self._OnceList[#self._OnceList + 1] = entry
                end
            end
        end
    end

    self._Dispatching = false

    -- 移除本帧完成的定时器
    for i = #self._OnceList, 1, -1 do
        local entry = self._OnceList[i]
        self:_RemoveFromListeners(XScheduleManagerPro._GetObjKey(entry.HandlerObj), entry.Handler)
        self._OnceList[i] = nil
    end

    -- 处理派发期挂起的增删（同键只有最后一次操作，插入即替换旧实例）
    for objKey, handlerMap in pairs(self._Pendings) do
        for handler, entry in pairs(handlerMap) do
            self:_RemoveFromListeners(objKey, handler)
            if entry.Status == STATUS_TO_INSERT then
                entry.Status = STATUS_ACTIVE
                self:_SetListener(objKey, handler, entry)
            else -- STATUS_TO_DELETE
                self._Pool:ReturnItemToPool(entry)
            end
            handlerMap[handler] = nil
        end
        self._Pendings[objKey] = nil
        self._MapPool:ReturnItemToPool(handlerMap)
    end

    self._CurFrame = self._CurFrame + 1
end

-- 添加计划：同键 (handlerObj, handler) 重复注册采用后写覆盖，替换旧实例并重置计时
---@param interval number 触发间隔（毫秒）
---@param handler fun(handlerObj:any) 回调函数
---@param handlerObj any 回调对象
---@param loop number 循环次数，0 为永久
---@param firstInterval number 首次触发间隔（毫秒）
function XScheduleManagerPro:_AddListener(interval, handler, handlerObj, loop, firstInterval)
    if interval == nil or handler == nil then
        XLog.Error("XScheduleManagerPro._AddListener error, interval: " .. tostring(interval)
                .. ", handler: " .. tostring(handler))
        return
    end
    -- handlerObj 非表？？？
    if handlerObj ~= nil and type(handlerObj) ~= "table" then
        XLog.Error("XScheduleManagerPro._AddListener error, handlerObj 必须是 table 或 nil, 实际: "
                .. type(handlerObj) .. " " .. tostring(handlerObj))
        return
    end
    -- 跟踪对象约束：入池后禁止注册；一个跟踪对象只允许绑定一个回调函数（同 handler 覆盖注册除外）
    if handlerObj ~= nil and handlerObj.__class == XScheduleProTrackHandelObject then
        if handlerObj:IsInPool() then
            XLog.Error("XScheduleManagerPro._AddListener error, 跟踪对象已入池，禁止注册定时器。"
                    .. "请检查是否在 ReturnTrackHandelObject 之后仍持有该对象")
            return
        end
        if self:_HasOtherSchedule(handlerObj, handler) then
            XLog.Error("XScheduleManagerPro._AddListener error, 跟踪对象只允许绑定一个回调函数，"
                    .. "检测到已绑定其他回调。请为不同回调分别 BuildTrackHandelObject")
            return
        end
    end

    local entry = self._Pool:GetItemFromPool()
    entry.Handler = handler
    entry.HandlerObj = handlerObj
    entry.Interval = interval
    entry.FirstInterval = firstInterval or interval
    entry.NextTriggerTime = nil
    entry.RegFrame = self._CurFrame
    entry.Loop = loop or 0
    entry.Count = 0
    entry.IsFirstTrigger = true

    local objKey = XScheduleManagerPro._GetObjKey(handlerObj)
    if self._Dispatching then
        entry.Status = STATUS_TO_INSERT
        self:_SetPending(objKey, handler, entry)
    else
        self:_RemoveFromListeners(objKey, handler)
        entry.Status = STATUS_ACTIVE
        self:_SetListener(objKey, handler, entry)
    end
end

---@param handler fun(handlerObj:any) 回调函数
---@param handlerObj any 回调对象
function XScheduleManagerPro:_RemoveListener(handler, handlerObj)
    if handler == nil then
        return
    end

    local objKey = XScheduleManagerPro._GetObjKey(handlerObj)
    if self._Dispatching then
        self:_SetPendingDelete(objKey, handler, handlerObj)
    else
        self:_RemoveFromListeners(objKey, handler)
    end
end

-- 移除对象名下的全部定时器（UI/实体销毁时的整体清理）
---@param handlerObj any 回调对象
function XScheduleManagerPro:_RemoveAllListeners(handlerObj)
    local objKey = XScheduleManagerPro._GetObjKey(handlerObj)

    if not self._Dispatching then
        local handlerMap = self._Listeners[objKey]
        if handlerMap then
            for handler, entry in pairs(handlerMap) do
                self._Pool:ReturnItemToPool(entry)
                handlerMap[handler] = nil
            end
            self._Listeners[objKey] = nil
            self._MapPool:ReturnItemToPool(handlerMap)
        end
        return
    end

    -- 派发期：对象名下已挂起的插入全部改写为删除
    local pendingMap = self._Pendings[objKey]
    if pendingMap then
        for _, entry in pairs(pendingMap) do
            entry.Status = STATUS_TO_DELETE
        end
    end
    -- 主映射中该对象名下的全部 handler 挂删除标记
    local handlerMap = self._Listeners[objKey]
    if handlerMap then
        for handler in pairs(handlerMap) do
            if not self:_GetPending(objKey, handler) then
                self:_SetPendingDelete(objKey, handler, handlerObj)
            end
        end
    end
end

---@param handler fun(handlerObj:any) 回调函数
---@param handlerObj any 回调对象
---@return boolean
function XScheduleManagerPro:_HasListener(handler, handlerObj)
    if handler == nil then
        return false
    end

    local objKey = XScheduleManagerPro._GetObjKey(handlerObj)
    if self._Dispatching then
        -- pending 中的最后一次操作即最终状态
        local pending = self:_GetPending(objKey, handler)
        if pending then
            return pending.Status == STATUS_TO_INSERT
        end
    end

    local handlerMap = self._Listeners[objKey]
    return (handlerMap and handlerMap[handler]) ~= nil
end

function XScheduleManagerPro:_SetListener(objKey, handler, entry)
    local handlerMap = self._Listeners[objKey]
    if not handlerMap then
        handlerMap = self._MapPool:GetItemFromPool()
        self._Listeners[objKey] = handlerMap
    end
    handlerMap[handler] = entry
end

-- 从主映射移除并回收节点；子表清空时一并移除入池，避免 handlerObj 键泄漏
function XScheduleManagerPro:_RemoveFromListeners(objKey, handler)
    local handlerMap = self._Listeners[objKey]
    if not handlerMap then
        return
    end

    local entry = handlerMap[handler]
    if not entry then
        return
    end

    handlerMap[handler] = nil
    if next(handlerMap) == nil then
        self._Listeners[objKey] = nil
        self._MapPool:ReturnItemToPool(handlerMap)
    end
    self._Pool:ReturnItemToPool(entry)
end

-- 写入 pending：同键已有操作则回收旧节点，只保留最后一次
function XScheduleManagerPro:_SetPending(objKey, handler, entry)
    local handlerMap = self._Pendings[objKey]
    if not handlerMap then
        handlerMap = self._MapPool:GetItemFromPool()
        self._Pendings[objKey] = handlerMap
    end

    local old = handlerMap[handler]
    if old then
        self._Pool:ReturnItemToPool(old)
    end
    handlerMap[handler] = entry
end

-- 写入 pending 删除标记
function XScheduleManagerPro:_SetPendingDelete(objKey, handler, handlerObj)
    local entry = self._Pool:GetItemFromPool()
    entry.Handler = handler
    entry.HandlerObj = handlerObj
    entry.Status = STATUS_TO_DELETE
    self:_SetPending(objKey, handler, entry)
end

---@return XScheduleProEntry|nil pending 中同键的挂起操作节点，无则为 nil
function XScheduleManagerPro:_GetPending(objKey, handler)
    local handlerMap = self._Pendings[objKey]
    return handlerMap and handlerMap[handler]
end

function XScheduleManagerPro:Clear()
    for objKey, handlerMap in pairs(self._Listeners) do
        for handler, entry in pairs(handlerMap) do
            self._Pool:ReturnItemToPool(entry)
            handlerMap[handler] = nil
        end
        self._Listeners[objKey] = nil
        self._MapPool:ReturnItemToPool(handlerMap)
    end
    for objKey, handlerMap in pairs(self._Pendings) do
        for handler, entry in pairs(handlerMap) do
            self._Pool:ReturnItemToPool(entry)
            handlerMap[handler] = nil
        end
        self._Pendings[objKey] = nil
        self._MapPool:ReturnItemToPool(handlerMap)
    end

    table.clear(self._OnceList)
    self._Dispatching = false
    self._CurFrame = 0
end





--region 对外 API---------- 对外 API ----------

local ScheduleManagerInstance = XScheduleManagerPro.New()
local XScheduleManagerProDebugUtil = require("XCommon/XScheduleManagerPro/XScheduleManagerProDebugUtil")
XScheduleManagerProDebugUtil.Bind(ScheduleManagerInstance)
---------- 对外API（名称与 XScheduleManager 保持一致，handlerObj 紧跟 handler）----------

---@return XScheduleManagerProDebugUtil
function XScheduleManagerPro.GetDebugUtil()
    return XScheduleManagerProDebugUtil
end

-- 由 XScheduleManager.Update 每帧驱动，共用同一个 C# Update 委托
---@param now number 当前时间（毫秒，Time.timeAsDouble * 1000）
function XScheduleManagerPro.Update(now)
    ScheduleManagerInstance:_Update(now)
end

-- /// <summary>
-- /// 启动定时器（第一次执行在 delay + interval 后）
-- /// </summary>
-- /// <param name="handler">处理函数，handlerObj 作为第一个参数传入</param>
-- /// <param name="handlerObj">回调对象，与 handler 共同构成唯一键</param>
-- /// <param name="interval">间隔毫秒</param>
-- /// <param name="loop">循环次数，0为永久</param>
-- /// <param name="delay">延迟毫秒</param>
function XScheduleManagerPro.Schedule(handler, handlerObj, interval, loop, delay)
    ScheduleManagerInstance:_AddListener(interval, handler, handlerObj, loop, interval + (delay or 0))
end

-- /// <summary>
-- /// 启动单次定时器
-- /// </summary>
function XScheduleManagerPro.ScheduleOnce(handler, handlerObj, delay)
    ScheduleManagerInstance:_AddListener(0, handler, handlerObj, 1, delay or 0)
end

-- /// <summary>
-- /// 下一帧执行一次
-- /// </summary>
function XScheduleManagerPro.ScheduleNextFrame(handler, handlerObj)
    ScheduleManagerInstance:_AddListener(0, handler, handlerObj, 1, 0)
end

-- /// <summary>
-- /// 启动指定时间单次定时器
-- /// </summary>
function XScheduleManagerPro.ScheduleAtTimestamp(handler, handlerObj, timeStamp)
    local nowTime = XTime.GetServerNowTimestamp()
    if timeStamp <= nowTime then
        return
    end

    XScheduleManagerPro.ScheduleOnce(handler,handlerObj,(timeStamp - nowTime) * XScheduleManagerPro.SECOND)
end

-- /// <summary>
-- /// 启动永久定时器（第一次执行在 delay + interval 后）
-- /// </summary>
function XScheduleManagerPro.ScheduleForever(handler, handlerObj, interval, delay)
    ScheduleManagerInstance:_AddListener(interval, handler, handlerObj, 0, interval + (delay or 0))
end

-- /// <summary>
-- /// 启动永久定时器
-- /// </summary>
-- /// PS:去除了ScheduleForever里计算时间自动叠加多一次的Interval，第一次执行在 delay 后
function XScheduleManagerPro.ScheduleForeverEx(handler, handlerObj, interval, delay)
    ScheduleManagerInstance:_AddListener(interval, handler, handlerObj, 0, delay or 0)
end

-- /// <summary>
-- /// 取消定时器
-- /// </summary>
function XScheduleManagerPro.UnSchedule(handler, handlerObj)
    ScheduleManagerInstance:_RemoveListener(handler, handlerObj)
end

-- /// <summary>
-- /// 取消对象名下的全部定时器（UI/实体销毁时的整体清理）
-- /// </summary>
function XScheduleManagerPro.UnScheduleAllByHandlerObject(handlerObj)
    ScheduleManagerInstance:_RemoveAllListeners(handlerObj)
end

-- /// <summary>
-- /// 查询定时器是否存在（派发期间以 pending 最后一次操作为准）
-- /// </summary>
function XScheduleManagerPro.HasSchedule(handler, handlerObj)
    return ScheduleManagerInstance:_HasListener(handler, handlerObj)
end

---@param handelObject any
---@return XScheduleProTrackHandelObject
function XScheduleManagerPro.BuildTrackHandelObject(handelObject)
    local trackHandel = ScheduleManagerInstance._TrackHandelPool:GetItemFromPool()
    trackHandel:Reset(false)
    trackHandel:SetHandelObject(handelObject)
    return trackHandel
end

---@param trackHandel XScheduleProTrackHandelObject
function XScheduleManagerPro.ReturnTrackHandelObject(trackHandel)
    if trackHandel == nil then
        return
    end
    if trackHandel:IsInPool() then
        XLog.Error("XScheduleManagerPro.ReturnTrackHandelObject error, 跟踪对象已在池中，禁止重复归还")
        return
    end
    -- 约束：归还前必须先 UnSchedule/UnScheduleAll 清掉名下全部定时器，带着定时器归还直接报错并拒绝归还
    if ScheduleManagerInstance:_HasOtherSchedule(trackHandel, nil) then
        XLog.Error("XScheduleManagerPro.ReturnTrackHandelObject error, 跟踪对象名下仍有未移除的定时器，"
                .. "必须先 UnSchedule/UnScheduleAll 再归还")
        return
    end
    ScheduleManagerInstance._TrackHandelPool:ReturnItemToPool(trackHandel)
end

-- 检查对象名下是否存在绑定到 exceptHandler 之外的活跃定时器（派发期以 pending 最后一次操作为准）。
-- exceptHandler 传 nil 即检查"名下是否还有任何活跃定时器"
---@param handlerObj any 回调对象
---@param exceptHandler function|nil 排除的回调函数
---@return boolean
function XScheduleManagerPro:_HasOtherSchedule(handlerObj, exceptHandler)
    local objKey = XScheduleManagerPro._GetObjKey(handlerObj)

    -- 主映射：跳过 pending 已挂删除的、有限次数已跑完待帧末移除的
    local handlerMap = self._Listeners[objKey]
    if handlerMap then
        for handler, entry in pairs(handlerMap) do
            if handler ~= exceptHandler then
                local isFinished = entry.Loop > 0 and entry.Count >= entry.Loop
                local pending = self:_GetPending(objKey, handler)
                if not isFinished and (not pending or pending.Status ~= STATUS_TO_DELETE) then
                    return true
                end
            end
        end
    end

    -- pending：挂起的插入即最终活跃
    local pendingMap = self._Pendings[objKey]
    if pendingMap then
        for handler, entry in pairs(pendingMap) do
            if handler ~= exceptHandler and entry.Status == STATUS_TO_INSERT then
                return true
            end
        end
    end
    return false
end


--endregion


local __Private = {}
__Private.__Clear__ = function()
    ScheduleManagerInstance:Clear()
end

return __Private
