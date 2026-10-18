local XRedPointConditionRegression4Sign = {}
local Events = nil

function XRedPointConditionRegression4Sign.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION4_SIGN_STATUS_CHANGE)
    }
    return Events
end

function XRedPointConditionRegression4Sign.Check()
    return XMVCA.XRegression4:CheckSignRedPoint()
end

return XRedPointConditionRegression4Sign