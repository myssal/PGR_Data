---@class XScheduleManagerProDebugUtil
local XScheduleManagerProDebugUtil = {}

---@class XScheduleManagerProDebugItem
---@field Handler function
---@field HandlerObj any
---@field Interval number
---@field FirstInterval number
---@field NextTriggerTime number
---@field Loop number
---@field Count number

local XScheduleProEntry = require("XCommon/XScheduleManagerPro/XScheduleProEntry")

---@type XScheduleManagerPro
XScheduleManagerProDebugUtil._ScheduleManagerInstance = nil
XScheduleManagerProDebugUtil._FieldSeparator = "\t"
XScheduleManagerProDebugUtil._LineSeparator = "\n"
XScheduleManagerProDebugUtil._MaxObjectFieldCount = 30

---@param scheduleManagerInstance XScheduleManagerPro
function XScheduleManagerProDebugUtil.Bind(scheduleManagerInstance)
    XScheduleManagerProDebugUtil._ScheduleManagerInstance = scheduleManagerInstance
end

---@return XScheduleManagerProDebugItem[]
function XScheduleManagerProDebugUtil._GetDebugSnapshot()
    local scheduleManagerInstance = XScheduleManagerProDebugUtil._ScheduleManagerInstance
    if not scheduleManagerInstance then
        return table.empty
    end

    local listeners = scheduleManagerInstance._Listeners
    local pendings = scheduleManagerInstance._Pendings
    if next(listeners) == nil and next(pendings) == nil then
        return table.empty
    end

    local result = {}
    for objKey, handlerMap in pairs(listeners) do
        for handler, entry in pairs(handlerMap) do
            local pendingMap = pendings[objKey]
            local pending = pendingMap and pendingMap[handler]
            local isFinished = entry.Loop > 0 and entry.Count >= entry.Loop
            if not isFinished and (not pending or pending.Status ~= XScheduleProEntry.STATUS_TO_DELETE) then
                result[#result + 1] = {
                    Handler = entry.Handler,
                    HandlerObj = entry.HandlerObj,
                    Interval = entry.Interval,
                    FirstInterval = entry.FirstInterval,
                    NextTriggerTime = entry.NextTriggerTime,
                    Loop = entry.Loop,
                    Count = entry.Count,
                }
            end
        end
    end
    return result
end

function XScheduleManagerProDebugUtil._EncodeField(value)
    local result = tostring(value or "")
    result = string.gsub(result, "%%", "%%25")
    result = string.gsub(result, "\t", "%%09")
    result = string.gsub(result, "\r", "%%0D")
    result = string.gsub(result, "\n", "%%0A")
    return result
end

function XScheduleManagerProDebugUtil._AppendRecord(sb, key, name, detail, remainCount, loop, interval, delay, count,
                                                    isWarning, objectClass, startTime, objectDetail, isTraceObject,
                                                    traceObjectDetail, parmDetail, aliveMilliseconds)
    sb[#sb + 1] = table.concat({
        XScheduleManagerProDebugUtil._EncodeField(key),
        XScheduleManagerProDebugUtil._EncodeField(name),
        XScheduleManagerProDebugUtil._EncodeField(detail),
        XScheduleManagerProDebugUtil._EncodeField(remainCount),
        XScheduleManagerProDebugUtil._EncodeField(loop),
        XScheduleManagerProDebugUtil._EncodeField(interval),
        XScheduleManagerProDebugUtil._EncodeField(delay),
        XScheduleManagerProDebugUtil._EncodeField(count),
        isWarning and "1" or "0",
        XScheduleManagerProDebugUtil._EncodeField(objectClass),
        XScheduleManagerProDebugUtil._EncodeField(startTime),
        XScheduleManagerProDebugUtil._EncodeField(objectDetail),
        isTraceObject and "1" or "0",
        XScheduleManagerProDebugUtil._EncodeField(traceObjectDetail),
        XScheduleManagerProDebugUtil._EncodeField(parmDetail),
        XScheduleManagerProDebugUtil._EncodeField(aliveMilliseconds),
    }, XScheduleManagerProDebugUtil._FieldSeparator)
end

function XScheduleManagerProDebugUtil._SafeToString(value)
    local success, result = pcall(tostring, value)
    return success and result or "<tostring error>"
end

function XScheduleManagerProDebugUtil._GetObjectClassName(obj)
    if obj == nil then
        return "nil"
    end
    return type(obj) == "table" and rawget(obj, "__cname") or type(obj)
end

function XScheduleManagerProDebugUtil._GetFieldValueDetail(value)
    local valueType = type(value)
    if valueType == "table" then
        return string.format("%s(%s)", XScheduleManagerProDebugUtil._GetObjectClassName(value),
                XScheduleManagerProDebugUtil._SafeToString(value))
    end
    if valueType == "string" then
        return string.format("%q", value)
    end
    return XScheduleManagerProDebugUtil._SafeToString(value)
end

function XScheduleManagerProDebugUtil._GetTableFieldDetail(obj)
    local result = {}
    local key, value = next(obj)
    while key ~= nil and #result < XScheduleManagerProDebugUtil._MaxObjectFieldCount do
        result[#result + 1] = string.format("%s = %s", XScheduleManagerProDebugUtil._SafeToString(key),
                XScheduleManagerProDebugUtil._GetFieldValueDetail(value))
        key, value = next(obj, key)
    end
    table.sort(result)
    if key ~= nil then
        result[#result + 1] = string.format("...（仅显示前%d个字段）", XScheduleManagerProDebugUtil._MaxObjectFieldCount)
    end
    return #result > 0 and table.concat(result, "\n") or "无"
end

function XScheduleManagerProDebugUtil._GetObjectDetail(obj)
    local detail = string.format("类名: %s\n类型: %s\n地址: %s",
            XScheduleManagerProDebugUtil._GetObjectClassName(obj), type(obj),
            XScheduleManagerProDebugUtil._SafeToString(obj))
    if type(obj) == "table" then
        detail = detail .. "\n字段:\n" .. XScheduleManagerProDebugUtil._GetTableFieldDetail(obj)
    end
    return detail
end

function XScheduleManagerProDebugUtil._GetParmDetail(parmMap)
    if not parmMap then
        return "无"
    end

    local result = {}
    for key, value in pairs(parmMap) do
        local valueInfo
        if type(value) == "table" then
            valueInfo = string.format("%s(%s)", XScheduleManagerProDebugUtil._GetObjectClassName(value), tostring(value))
        else
            valueInfo = tostring(value)
        end
        result[#result + 1] = string.format("%s = %s", tostring(key), valueInfo)
    end
    table.sort(result)
    return #result > 0 and table.concat(result, "\n") or "无"
end

function XScheduleManagerProDebugUtil._GetHandlerInfo(item)
    local handlerName = GetFunNameByFunAddress(item.Handler)
    local isNamed = handlerName ~= nil
    if not isNamed then
        handlerName = tostring(item.Handler)
    end

    local handlerObj = item.HandlerObj
    local handlerObjName = XScheduleManagerProDebugUtil._GetObjectClassName(handlerObj)
    local isTraceObject = handlerObjName == "XScheduleProTrackHandelObject"
    local displayClass = handlerObjName
    local traceObjectDetail = "无"
    local parmDetail = "无"
    if isTraceObject then
        local traceObj = rawget(handlerObj, "_HandelObject")
        displayClass = XScheduleManagerProDebugUtil._GetObjectClassName(traceObj)
        traceObjectDetail = XScheduleManagerProDebugUtil._GetObjectDetail(traceObj)
        parmDetail = XScheduleManagerProDebugUtil._GetParmDetail(rawget(handlerObj, "_ParmMap"))
    end

    return handlerName, displayClass, XScheduleManagerProDebugUtil._GetObjectDetail(handlerObj), isTraceObject,
            traceObjectDetail, parmDetail, isNamed
end

-- /// <summary>
-- /// Editor面板数据出口：返回普通Lua定时器的文本快照。
-- /// C#仅解析文本协议，不直接持有LuaTable或定时器Entry。
-- /// </summary>
---@return string
function XScheduleManagerProDebugUtil.DebugGetLuaScheduleInfo()
    if not XMain.IsEditorDebug or not XScheduleManager or not XScheduleManager.GetDebugSnapshot then
        return ""
    end

    local snapshot = XScheduleManager.GetDebugSnapshot()
    local sb = {}
    for i = 1, #snapshot do
        local item = snapshot[i]
        if item.RemainCount > 0 then
            local detail = string.format("Id=%s, TotalCreated=%s, TotalTriggered=%s",
                    tostring(item.LastId), tostring(item.TotalCreated), tostring(item.TotalTriggered))
            XScheduleManagerProDebugUtil._AppendRecord(sb, "Lua:" .. tostring(item.Name), item.Name, detail,
                    item.RemainCount, item.Loop, item.Interval, item.Delay, item.LastCount, item.RemainCount > 1)
        end
    end
    return table.concat(sb, XScheduleManagerProDebugUtil._LineSeparator)
end

-- /// <summary>
-- /// Editor面板数据出口：返回Lua Pro定时器的文本快照。
-- /// </summary>
---@return string
function XScheduleManagerProDebugUtil.DebugGetProScheduleInfo()
    if not XMain.IsEditorDebug then
        return ""
    end

    local snapshot = XScheduleManagerProDebugUtil._GetDebugSnapshot()
    local sb = {}
    for i = 1, #snapshot do
        local item = snapshot[i]
        local handlerName, objectClass, objectDetail, isTraceObject,
        traceObjectDetail, parmDetail, isNamed = XScheduleManagerProDebugUtil._GetHandlerInfo(item)
        local key = string.format("LuaPro:%s:%s", tostring(item.Handler), tostring(item.HandlerObj))
        local detail = string.format("NextTriggerTime=%s", tostring(item.NextTriggerTime))
        XScheduleManagerProDebugUtil._AppendRecord(sb, key, handlerName, detail, 1, item.Loop, item.Interval,
                item.FirstInterval, item.Count, not isNamed, objectClass, nil,
                objectDetail, isTraceObject, traceObjectDetail, parmDetail, nil)
    end
    return table.concat(sb, XScheduleManagerProDebugUtil._LineSeparator)
end

-- /// <summary>
-- /// Editor调试：返回当前活跃定时器的Handler信息，一行一个定时器。
-- /// [Named]表示Handler已被XClass记录；[Unnamed]通常表示闭包或非XClass函数。
-- /// TrackHandelObject会同时展示跟踪对象和其内部持有的真实宿主对象。
-- /// </summary>
---@return string
function XScheduleManagerProDebugUtil.DebugGetHandelInfo()
    if not XMain.IsEditorDebug then
        return ""
    end

    local snapshot = XScheduleManagerProDebugUtil._GetDebugSnapshot()
    local sb = {}
    for i = 1, #snapshot do
        local item = snapshot[i]
        local handlerName, objectClass, objectDetail, isTraceObject,
        traceObjectDetail, parmDetail, isNamed = XScheduleManagerProDebugUtil._GetHandlerInfo(item)
        local prefix = isNamed and "[Named]" or "[Unnamed]"
        sb[#sb + 1] = string.format(
                "%s Handler=%s, ObjectClass=%s, IsTraceObject=%s, Object={%s}, TraceObject={%s}, Parm={%s}, Interval=%s, Loop=%s, Count=%s",
                prefix, handlerName, objectClass, tostring(isTraceObject), objectDetail,
                traceObjectDetail, parmDetail, tostring(item.Interval), tostring(item.Loop), tostring(item.Count))
    end
    table.sort(sb)
    return table.concat(sb, XScheduleManagerProDebugUtil._LineSeparator)
end

-- /// <summary>
-- /// Editor调试：输出当前活跃定时器。
-- /// </summary>
function XScheduleManagerProDebugUtil.DumpDebug()
    if not XMain.IsEditorDebug then
        XLog.Warning("XScheduleManagerProDebugUtil.DumpDebug 仅Editor下可用")
        return
    end

    local scheduleManagerInstance = XScheduleManagerProDebugUtil._ScheduleManagerInstance
    if not scheduleManagerInstance then
        XLog.Warning("XScheduleManagerProDebugUtil.DumpDebug 未初始化")
        return
    end

    local snapshot = XScheduleManagerProDebugUtil._GetDebugSnapshot()
    XLog.Debug("XScheduleManagerProDebugUtil.DumpDebug 当前活跃定时器数量: " .. #snapshot)

    ---@type XPool
    local entryPool = scheduleManagerInstance._Pool
    ---@type XPool
    local mapPool = scheduleManagerInstance._MapPool
    XLog.Debug(string.format(
            "XScheduleManagerPro EntryPool using:%d, left:%d, total:%d | MapPool using:%d, left:%d, total:%d",
            entryPool:UsingCount(), entryPool:LeftCount(), entryPool:TotalCount(),
            mapPool:UsingCount(), mapPool:LeftCount(), mapPool:TotalCount()
    ))

    for i = 1, #snapshot do
        local item = snapshot[i]
        XLog.Debug(string.format(
                "XScheduleManagerPro handler:%s, handlerObj:%s, interval:%s, firstInterval:%s, nextTriggerTime:%s, loop:%s, count:%s",
                tostring(item.Handler),
                tostring(item.HandlerObj),
                tostring(item.Interval),
                tostring(item.FirstInterval),
                tostring(item.NextTriggerTime),
                tostring(item.Loop),
                tostring(item.Count)
        ))
    end
end

return XScheduleManagerProDebugUtil
