local XUiPacMan2ConditionDefine = {}

---Matcher接收到的变化类型。
XUiPacMan2ConditionDefine.ChangeType = {
    -- 持续状态从OldValue变化为NewValue。
    ValueChanged = 1,

    -- 某件瞬时事件刚刚发生，不会保存到Context。
    Triggered = 2,
}

---规则触发模式。
XUiPacMan2ConditionDefine.TriggerMode = {
    Once = "Once",
    OnEnter = "OnEnter",
    EveryMatch = "EveryMatch",
}

---多个条件的组合方式。
XUiPacMan2ConditionDefine.Logic = {
    All = "All",
    Any = "Any",
}

---条件比较方式。
---
---Operator本身决定从哪里读取数据：
---1. Equal到LessEqual读取Context当前状态；
---2. Changed到DeltaLessEqual读取本次ValueChanged；
---3. Triggered读取本次Triggered事件。
XUiPacMan2ConditionDefine.Operator = {
    Equal = "Equal",
    NotEqual = "NotEqual",
    Greater = "Greater",
    GreaterEqual = "GreaterEqual",
    Less = "Less",
    LessEqual = "LessEqual",

    Changed = "Changed",
    Increased = "Increased",
    Decreased = "Decreased",
    DeltaEqual = "DeltaEqual",
    DeltaGreaterEqual = "DeltaGreaterEqual",
    DeltaLessEqual = "DeltaLessEqual",

    Triggered = "Triggered",
}

return XUiPacMan2ConditionDefine