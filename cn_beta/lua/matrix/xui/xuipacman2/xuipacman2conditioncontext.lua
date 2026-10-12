local Define = require("XUi/XUiPacMan2/XUiPacMan2ConditionDefine")
local ChangeType = Define.ChangeType

---@class XUiPacMan2ConditionContext
---条件系统内部使用的纯状态容器。
---
---职责：
---1. 保存条件判断需要的最新状态；
---2. 使用Lua初始化时建立状态快照；
---3. 使用C#提供的oldValue校验快照是否同步；
---4. 使用C#提供的newValue更新快照；
---5. 返回包含OldValue和NewValue的变化信息。
local XUiPacMan2ConditionContext = XClass(nil, "XUiPacMan2ConditionContext")

function XUiPacMan2ConditionContext:Ctor()
    self._Values = {}
end

---开始新关卡时清空状态。
---@param initialValues table|nil
function XUiPacMan2ConditionContext:Reset(initialValues)
    self._Values = {}
    self:Initialize(initialValues)
end

---写入初始化快照。
---初始化不是运行期变化，因此不会返回变化信息，也不会触发Matcher。
---@param initialValues table|nil
function XUiPacMan2ConditionContext:Initialize(initialValues)
    if not initialValues then
        return
    end

    for field, value in pairs(initialValues) do
        if field ~= nil and value ~= nil then
            self._Values[field] = value
        end
    end
end

---读取字段当前值。
---只供事件系统内部的Matcher使用。
---@param field string
---@return any
function XUiPacMan2ConditionContext:Get(field)
    return self._Values[field]
end


---应用一条带有明确旧值和新值的状态变化。
---
---Context中的当前值用于检查Lua快照是否与C#同步。
---条件判断使用C#消息携带的oldValue和newValue，
---因为它们描述的是本次业务变化的真实过程。
---@param field string
---@param oldValue any
---@param newValue any
---@return table|nil fieldChange
function XUiPacMan2ConditionContext:Update(field, oldValue, newValue)
    if field == nil then
        XLog.Error("[PacMan2ConditionContext] Update field为空")
        return nil
    end

    if oldValue == nil or newValue == nil then
        XLog.Error("[PacMan2ConditionContext] Update oldValue或newValue为空, field=" .. tostring(field))
        return nil
    end

    local currentValue = self._Values[field]

    if currentValue == nil then
        XLog.Warning("[PacMan2ConditionContext] 字段未初始化, field=" .. tostring(field))
    elseif currentValue ~= oldValue then
        XLog.Warning("[PacMan2ConditionContext] 状态不同步, field=" .. tostring(field) .. ", contextValue=" .. tostring(currentValue) .. ", signalOldValue=" .. tostring(oldValue))
    end

    -- C#业务消息是本次变化的权威来源。
    -- 即使Lua快照不同步，也使用newValue修正快照。
    self._Values[field] = newValue

    if oldValue == newValue then
        return nil
    end

    return {
        Type = ChangeType.ValueChanged,
        OldValue = oldValue,
        NewValue = newValue,
    }
end


function XUiPacMan2ConditionContext:Dispose()
    self._Values = nil
end

return XUiPacMan2ConditionContext