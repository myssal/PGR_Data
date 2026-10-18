local XRedPointConditionRegression4Task = {}
local Events = nil

function XRedPointConditionRegression4Task.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION4_TASK_STATUS_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
    }
    return Events
end

function XRedPointConditionRegression4Task.Check()
    return XMVCA.XRegression4:CheckTaskRedPoint()
end 

return XRedPointConditionRegression4Task