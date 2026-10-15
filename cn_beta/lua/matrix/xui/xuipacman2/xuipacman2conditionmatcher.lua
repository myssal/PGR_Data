local Define = require("XUi/XUiPacMan2/XUiPacMan2ConditionDefine")

local ChangeType = Define.ChangeType
local TriggerMode = Define.TriggerMode
local Logic = Define.Logic
local Operator = Define.Operator

local function IsNumber(value)
    return type(value) == "number"
end

---变化型数字条件必须是ValueChanged，并且存在数字类型的新旧值。
---@param change table|nil
---@return boolean
local function HasNumberChange(change)
    return change ~= nil
        and change.Type == ChangeType.ValueChanged
        and IsNumber(change.OldValue)
        and IsNumber(change.NewValue)
end

---所有Operator的实际判断逻辑。
---
---统一参数：
---currentValue：Context中的当前状态；
---targetValue：条件配置的目标值；
---change：该字段对应的本次变化信息。
---
---Operator自行决定使用currentValue还是change：
---1. Equal到LessEqual使用currentValue；
---2. Changed到DeltaLessEqual使用change；
---3. Triggered使用change。
local OperatorEvaluators = {
    [Operator.Equal] = function(currentValue, targetValue, change)
        return currentValue ~= nil and currentValue == targetValue
    end,

    [Operator.NotEqual] = function(currentValue, targetValue, change)
        return currentValue ~= nil and currentValue ~= targetValue
    end,

    [Operator.Greater] = function(currentValue, targetValue, change)
        return IsNumber(currentValue) and IsNumber(targetValue) and currentValue > targetValue
    end,

    [Operator.GreaterEqual] = function(currentValue, targetValue, change)
        return IsNumber(currentValue) and IsNumber(targetValue) and currentValue >= targetValue
    end,

    [Operator.Less] = function(currentValue, targetValue, change)
        return IsNumber(currentValue) and IsNumber(targetValue) and currentValue < targetValue
    end,

    [Operator.LessEqual] = function(currentValue, targetValue, change)
        return IsNumber(currentValue) and IsNumber(targetValue) and currentValue <= targetValue
    end,

    [Operator.Changed] = function(currentValue, targetValue, change)
        return change ~= nil and change.Type == ChangeType.ValueChanged
    end,

    [Operator.Increased] = function(currentValue, targetValue, change)
        return HasNumberChange(change) and change.NewValue > change.OldValue
    end,

    [Operator.Decreased] = function(currentValue, targetValue, change)
        return HasNumberChange(change) and change.NewValue < change.OldValue
    end,

    [Operator.DeltaEqual] = function(currentValue, targetValue, change)
        return HasNumberChange(change) and IsNumber(targetValue) and change.NewValue - change.OldValue == targetValue
    end,

    [Operator.DeltaGreaterEqual] = function(currentValue, targetValue, change)
        return HasNumberChange(change) and IsNumber(targetValue) and change.NewValue - change.OldValue >= targetValue
    end,

    [Operator.DeltaLessEqual] = function(currentValue, targetValue, change)
        return HasNumberChange(change) and IsNumber(targetValue) and change.NewValue - change.OldValue <= targetValue
    end,

    [Operator.Triggered] = function(currentValue, targetValue, change)
        if not change or change.Type ~= ChangeType.Triggered then
            return false
        end

        -- 没有配置Value时，该Field发生任意Triggered都成立。
        if targetValue == nil then
            return true
        end

        return change.Value == targetValue
    end,
}

---@class XUiPacMan2ConditionMatcher
---条件匹配器。
---
---职责：
---1. 保存本关规则及规则运行状态；
---2. 为所有条件字段建立反向索引；
---3. 字段变化时只检查关注该字段的规则；
---4. 从Context读取字段当前状态；
---5. 从fieldChanges读取该字段的本次变化；
---6. 将当前状态和本次变化同时交给Operator；
---7. 根据Once、OnEnter、EveryMatch决定是否触发事件组。
---
---规则格式：
---{
---    Id = 1,
---    TriggerMode = TriggerMode.EveryMatch,
---    EventGroupId = 1001,
---
---    Condition = {
---        Logic = Logic.All,
---        Items = {
---            {
---                Field = ConditionField.PlayerHp,
---                Operator = Operator.Decreased,
---            },
---            {
---                Field = ConditionField.GameStarted,
---                Operator = Operator.Equal,
---                Value = true,
---            },
---            {
---                Field = ConditionField.PlayerHp,
---                Operator = Operator.LessEqual,
---                Value = 2,
---            },
---        },
---    },
---}
local XUiPacMan2ConditionMatcher = XClass(nil, "XUiPacMan2ConditionMatcher")

---@param context XUiPacMan2ConditionContext
function XUiPacMan2ConditionMatcher:Ctor(context)
    self._Context = context

    ---@type table<number, table>
    self._Rules = {}

    ---@type number[]
    self._RuleOrder = {}

    ---@type table<number, table>
    self._RuleStates = {}

    ---@type table<string, table>
    self._FieldRuleIndex = {}
end

---载入本关规则并建立字段反向索引。
---这里只初始化规则运行状态，不会触发事件。
---@param rules table|nil
function XUiPacMan2ConditionMatcher:BeginStage(rules)
    self._Rules = {}
    self._RuleOrder = {}
    self._RuleStates = {}
    self._FieldRuleIndex = {}

    if not rules then
        return
    end

    for _, rule in ipairs(rules) do
        if self:_ValidateRule(rule) then
            self._Rules[rule.Id] = rule
            self._RuleOrder[#self._RuleOrder + 1] = rule.Id
            self._RuleStates[rule.Id] = {
                HasTriggered = false,
                LastMatched = false,
            }

            self:_BuildRuleIndex(rule)
        end
    end
end

---Context完成初始快照后，刷新规则的初始匹配状态。
---这里只记录状态，不会触发事件组。
---
---例如玩家初始HP已经小于等于2：
---OnEnter规则的LastMatched会被正确记录为true，
---避免第一次无关变化到来时被错误识别成false到true。
function XUiPacMan2ConditionMatcher:RefreshStates()
    for _, ruleId in ipairs(self._RuleOrder) do
        local rule = self._Rules[ruleId]
        local state = self._RuleStates[ruleId]
        state.LastMatched = self:_EvaluateRule(rule, nil)
    end
end

---处理本次条件系统变化。
---@param fieldChanges table|nil
---@return table[] matchedResults 命中的规则列表，元素为原规则的只读引用
function XUiPacMan2ConditionMatcher:OnFieldsChanged(fieldChanges)
    local matchedResults = {}

    if not fieldChanges then
        return matchedResults
    end

    local candidateRuleIds = self:_CollectCandidateRules(fieldChanges)

    -- 按配置顺序检查，避免pairs导致事件触发顺序不稳定。
    for _, ruleId in ipairs(self._RuleOrder) do
        if candidateRuleIds[ruleId] then
            local rule = self._Rules[ruleId]
            local state = self._RuleStates[ruleId]
            local currentMatched = self:_EvaluateRule(rule, fieldChanges)
            local shouldTrigger = self:_ShouldTrigger(rule, state, currentMatched)

            if shouldTrigger then
                state.HasTriggered = true

                -- 调用方只读使用，不得修改规则或在其中保存每次执行的状态。
                matchedResults[#matchedResults + 1] = rule
            end

            -- 必须在ShouldTrigger之后更新，否则无法判断false进入true。
            state.LastMatched = currentMatched
        end
    end

    return matchedResults
end

---检查规则基本配置是否合法。
---@param rule table
---@return boolean
function XUiPacMan2ConditionMatcher:_ValidateRule(rule)
    if not rule then
        return false
    end

    if rule.Id == nil then
        XLog.Error("[PacMan2Matcher] Rule.Id为空")
        return false
    end

    if self._Rules[rule.Id] then
        XLog.Error("[PacMan2Matcher] Rule.Id重复=" .. tostring(rule.Id))
        return false
    end

    if rule.EventGroupId == nil then
        XLog.Error("[PacMan2Matcher] EventGroupId为空, ruleId=" .. tostring(rule.Id))
        return false
    end

    if rule.TriggerMode ~= TriggerMode.Once
        and rule.TriggerMode ~= TriggerMode.OnEnter
        and rule.TriggerMode ~= TriggerMode.EveryMatch then
        XLog.Error("[PacMan2Matcher] TriggerMode非法, ruleId=" .. tostring(rule.Id))
        return false
    end

    if not rule.Condition then
        XLog.Error("[PacMan2Matcher] Condition为空, ruleId=" .. tostring(rule.Id))
        return false
    end

    if rule.Condition.Logic ~= Logic.All and rule.Condition.Logic ~= Logic.Any then
        XLog.Error("[PacMan2Matcher] Condition.Logic非法, ruleId=" .. tostring(rule.Id))
        return false
    end

    if not rule.Condition.Items or #rule.Condition.Items == 0 then
        XLog.Error("[PacMan2Matcher] Condition.Items为空, ruleId=" .. tostring(rule.Id))
        return false
    end

    for index, condition in ipairs(rule.Condition.Items) do
        if condition.Field == nil then
            XLog.Error("[PacMan2Matcher] Condition.Field为空, ruleId=" .. tostring(rule.Id) .. ", index=" .. tostring(index))
            return false
        end

        if not OperatorEvaluators[condition.Operator] then
            XLog.Error("[PacMan2Matcher] Condition.Operator非法, ruleId=" .. tostring(rule.Id) .. ", index=" .. tostring(index))
            return false
        end
    end

    return true
end

---为所有条件字段建立反向索引。
---
---结构：
---_FieldRuleIndex = {
---    PlayerHp = {
---        [1] = true,
---        [2] = true,
---    },
---}
---
---表示PlayerHp发生变化时，需要检查规则1和规则2。
---@param rule table
function XUiPacMan2ConditionMatcher:_BuildRuleIndex(rule)
    for _, condition in ipairs(rule.Condition.Items) do
        local field = condition.Field
        local ruleIds = self._FieldRuleIndex[field]

        if not ruleIds then
            ruleIds = {}
            self._FieldRuleIndex[field] = ruleIds
        end

        ruleIds[rule.Id] = true
    end
end

---根据本次事务变化收集候选规则。
---同一条规则同时关注多个字段时会自动去重。
---@param fieldChanges table
---@return table<number, boolean>
function XUiPacMan2ConditionMatcher:_CollectCandidateRules(fieldChanges)
    local candidateRuleIds = {}

    for field in pairs(fieldChanges) do
        local ruleIds = self._FieldRuleIndex[field]

        if ruleIds then
            for ruleId in pairs(ruleIds) do
                candidateRuleIds[ruleId] = true
            end
        end
    end

    return candidateRuleIds
end

---判断整条规则是否成立。
---@param rule table
---@param fieldChanges table|nil
---@return boolean
function XUiPacMan2ConditionMatcher:_EvaluateRule(rule, fieldChanges)
    local conditionGroup = rule.Condition

    if conditionGroup.Logic == Logic.Any then
        for _, condition in ipairs(conditionGroup.Items) do
            if self:_EvaluateCondition(condition, fieldChanges) then
                return true
            end
        end

        return false
    end

    for _, condition in ipairs(conditionGroup.Items) do
        if not self:_EvaluateCondition(condition, fieldChanges) then
            return false
        end
    end

    return true
end

---将Context当前状态和本次变化同时交给Operator。
---由Operator自行决定使用哪一部分数据。
---@param condition table
---@param fieldChanges table|nil
---@return boolean
function XUiPacMan2ConditionMatcher:_EvaluateCondition(condition, fieldChanges)
    local currentValue = self:_GetCurrentValue(condition)
    local change = self:_GetFieldChange(condition, fieldChanges)
    local evaluator = OperatorEvaluators[condition.Operator]

    if not evaluator then
        XLog.Error("[PacMan2Matcher] 未知Operator=" .. tostring(condition.Operator))
        return false
    end

    return evaluator(currentValue, condition.Value, change) == true
end

---读取条件对应的Context当前状态。
---Triggered字段不保存在Context中，因此允许返回nil。
---@param condition table
---@return any
function XUiPacMan2ConditionMatcher:_GetCurrentValue(condition)
    return self._Context:Get(condition.Field)
end

---取得条件字段在本次事务中的变化信息。
---@param condition table
---@param fieldChanges table|nil
---@return table|nil
function XUiPacMan2ConditionMatcher:_GetFieldChange(condition, fieldChanges)
    if not fieldChanges then
        return nil
    end

    return fieldChanges[condition.Field]
end

---根据模式判断本次是否触发事件组。
---@param rule table
---@param state table
---@param currentMatched boolean
---@return boolean
function XUiPacMan2ConditionMatcher:_ShouldTrigger(rule, state, currentMatched)
    if not currentMatched then
        return false
    end

    if rule.TriggerMode == TriggerMode.Once then
        return not state.HasTriggered
    end

    if rule.TriggerMode == TriggerMode.OnEnter then
        return not state.LastMatched
    end

    if rule.TriggerMode == TriggerMode.EveryMatch then
        return true
    end

    XLog.Error("[PacMan2Matcher] 未知TriggerMode=" .. tostring(rule.TriggerMode) .. ", ruleId=" .. tostring(rule.Id))
    return false
end

function XUiPacMan2ConditionMatcher:Dispose()
    self._Context = nil
    self._Rules = nil
    self._RuleOrder = nil
    self._RuleStates = nil
    self._FieldRuleIndex = nil
end

return XUiPacMan2ConditionMatcher