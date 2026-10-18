local XGDFBaseEvent = require("XEntity/XGuildDorm/Furniture/Events/XGDFBaseEvent")
---@class XGDFTestEvent : XGDFBaseEvent
local XGDFTestEvent = XClass(XGDFBaseEvent, "XGDFTestEvent")
function XGDFTestEvent:Init()
    self:StartEntryBtnListener()
end

function XGDFTestEvent:CheckOnce()
    self:Trigger(XTime.GetServerNowTimestamp() % 2 == 0)
end

function XGDFTestEvent:StartEntryBtnListener()
    XScheduleManagerPro.ScheduleForever(self._OnCheckOnceScheduleCb, self, 5000)
end

function XGDFTestEvent:Dispose()
    XScheduleManagerPro.UnSchedule(self._OnCheckOnceScheduleCb, self)
end

function XGDFTestEvent:_OnCheckOnceScheduleCb()
    self:CheckOnce()
end

return XGDFTestEvent