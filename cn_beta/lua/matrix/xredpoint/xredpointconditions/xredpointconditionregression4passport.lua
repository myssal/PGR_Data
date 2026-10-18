local XRedPointConditionRegression4Passport = {}
local Events = nil

function XRedPointConditionRegression4Passport.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_REGRESSION4_PASSPORT_STATUS_CHANGE)
    }
    return Events
end

function XRedPointConditionRegression4Passport.Check()
    return XMVCA.XRegression4:CheckPassportRedPoint()
end

return XRedPointConditionRegression4Passport