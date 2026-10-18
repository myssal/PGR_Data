-- 定时器跟踪对象（黑板结构）：作为 XScheduleManagerPro 的 handlerObj 使用，
-- 内部持有真正的宿主对象（如 UI 的 self），回调里通过 GetHandelObject 取回。
-- 生命周期由 XScheduleManagerPro 的对象池管理：
--   获取：XScheduleManagerPro.BuildTrackHandelObject(handelObject)
--   归还：XScheduleManagerPro.ReturnTrackHandelObject(trackHandel)（内部会 UnScheduleAll 清掉名下全部定时器）

---@class XScheduleProTrackHandelObject
---@field private _HandelObject any 宿主对象（通常为业务侧 self）
---@field private _IsInPool boolean 是否已归还入池（入池后禁止读写，用于捕获悬空引用）
---@field private _ParmMap table 参数黑板（key -> value），随对象复用，归还时清空
local XScheduleProTrackHandelObject = XClass(nil, "XScheduleProTrackHandelObject")

function XScheduleProTrackHandelObject:Ctor()
    self._HandelObject = nil
    self._IsInPool = false
    self._ParmMap = nil -- 惰性创建，避免不使用黑板时的额外开销
end

---@param handelObject any 宿主对象
function XScheduleProTrackHandelObject:SetHandelObject(handelObject)
    if self._IsInPool then
        XLog.Error("XScheduleProTrackHandelObject:SetHandelObject error, 跟踪对象已入池，禁止写入。"
                .. "请检查是否在 ReturnTrackHandelObject 之后仍持有该对象")
        return
    end
    self._HandelObject = handelObject
end

---@return any 宿主对象
function XScheduleProTrackHandelObject:GetHandelObject()
    if self._IsInPool then
        XLog.Error("XScheduleProTrackHandelObject:GetHandelObject error, 跟踪对象已入池，禁止读取。"
                .. "请检查是否在 ReturnTrackHandelObject 之后仍持有该对象")
        return nil
    end
    return self._HandelObject
end

-- 黑板写入：设置任意参数，方便回调间共享数据
---@param key any 参数键（不可为 nil）
---@param value any 参数值（传 nil 即移除该键）
function XScheduleProTrackHandelObject:SetParm(key, value)
    if self._IsInPool then
        XLog.Error("XScheduleProTrackHandelObject:SetParm error, 跟踪对象已入池，禁止写入。"
                .. "请检查是否在 ReturnTrackHandelObject 之后仍持有该对象")
        return
    end
    if key == nil then
        XLog.Error("XScheduleProTrackHandelObject:SetParm error, key 不能为 nil")
        return
    end
    if not self._ParmMap then
        self._ParmMap = {}
    end
    self._ParmMap[key] = value
end

-- 黑板读取
---@param key any 参数键
---@return any 参数值（未设置返回 nil）
function XScheduleProTrackHandelObject:GetParm(key)
    if self._IsInPool then
        XLog.Error("XScheduleProTrackHandelObject:GetParm error, 跟踪对象已入池，禁止读取。"
                .. "请检查是否在 ReturnTrackHandelObject 之后仍持有该对象")
        return nil
    end
    if not self._ParmMap then
        return nil
    end
    return self._ParmMap[key]
end

-- 重置接口：清空宿主引用与黑板参数，并设置入池标记。
-- 由 XScheduleManagerPro 在出池（isInPool=false）/入池（isInPool=true）时调用。
---@param isInPool boolean 是否处于入池状态（入池后 Get/Set 报错拦截）
function XScheduleProTrackHandelObject:Reset(isInPool)
    self._HandelObject = nil
    if self._ParmMap then
        table.clear(self._ParmMap) -- 表保留复用，仅清空内容
    end
    self._IsInPool = isInPool and true or false
end

---@return boolean 是否已归还入池
function XScheduleProTrackHandelObject:IsInPool()
    return self._IsInPool
end

return XScheduleProTrackHandelObject
