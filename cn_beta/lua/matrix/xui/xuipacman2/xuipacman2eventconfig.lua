---@class XUiPacMan2EventConfig
---事件系统策划表适配器。
---
---职责：
---1. 从Control获取原始XTable配置；
---2. 将事件规则表的平行数组转换为Matcher使用的Condition.Items；
---3. 将ConditionValues中的字符串转换为Lua值；
---4. 不解释原子事件Params，Params由对应原子事件类型自行解释。
local XUiPacMan2EventConfig = XClass(nil, "XUiPacMan2EventConfig")

local AllStageId = 0
---@param control XPacMan2Control
function XUiPacMan2EventConfig:Ctor(control)
    self._Control = control
end

---将策划表中的字符串转换成条件目标值。
---@param value string|nil
---@return any
function XUiPacMan2EventConfig:_ParseConditionValue(value)
    if value == nil or value == "" then
        return nil
    end

    if value == "true" then
        return true
    end

    if value == "false" then
        return false
    end

    local numberValue = tonumber(value)

    if numberValue ~= nil then
        return numberValue
    end

    return value
end

---获取本关的全部条件规则，并转换为Matcher使用的格式。
---@param stageId number
---@return table
function XUiPacMan2EventConfig:GetRulesByStageId(stageId)
    local rawConfigs = self._Control:GetEventRuleConfigs()
    local rules = {}

    for _, rawConfig in pairs(rawConfigs) do
        if rawConfig.StageId == AllStageId or rawConfig.StageId == stageId then
            local fieldCount = #rawConfig.ConditionFields
            local operatorCount = #rawConfig.ConditionOperators

            if fieldCount ~= operatorCount then
                XLog.Error("[PacMan2EventConfig] 条件字段和运算符数量不一致, ruleId=" .. tostring(rawConfig.Id))
            elseif fieldCount == 0 then
                XLog.Error("[PacMan2EventConfig] 规则没有配置条件, ruleId=" .. tostring(rawConfig.Id))
            else
                local items = {}

                for index = 1, fieldCount do
                    items[#items + 1] = {
                        Field = rawConfig.ConditionFields[index],
                        Operator = rawConfig.ConditionOperators[index],
                        Value = self:_ParseConditionValue(rawConfig.ConditionValues[index]),
                    }
                end

                rules[#rules + 1] = {
                    Id = rawConfig.Id,
                    TriggerMode = rawConfig.TriggerMode,
                    EventGroupId = rawConfig.EventGroupId,

                    Condition = {
                        Logic = rawConfig.Logic,
                        Items = items,
                    },
                }
            end
        end
    end

    -- Matcher按数组顺序检查规则，主动排序保证顺序稳定。
    table.sort(rules, function(left, right)
        return left.Id < right.Id
    end)

    return rules
end

---@param stageId number
---@return XTablePacMan2StageEvent|nil
function XUiPacMan2EventConfig:GetStageEventConfig(stageId)
    return self._Control:GetStageEventConfig(stageId)
end

---@param eventGroupId number
---@return XTablePacMan2EventGroup|nil
function XUiPacMan2EventConfig:GetEventGroupConfig(eventGroupId)
    return self._Control:GetEventGroupConfig(eventGroupId)
end

---@param atomicEventId number
---@return XTablePacMan2AtomicEvent|nil
function XUiPacMan2EventConfig:GetAtomicEventConfig(atomicEventId)
    return self._Control:GetAtomicEventConfig(atomicEventId)
end

function XUiPacMan2EventConfig:Dispose()
    self._Control = nil
end

return XUiPacMan2EventConfig