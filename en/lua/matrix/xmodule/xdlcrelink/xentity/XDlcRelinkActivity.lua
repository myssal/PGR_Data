---@class XDlcRelinkActivity
local XDlcRelinkActivity = XClass(nil, "XDlcRelinkActivity")

function XDlcRelinkActivity:Ctor()
    -- 活动Id
    self.ActivityId = 0
end

function XDlcRelinkActivity:NotifyActivityData(data)
    self.ActivityId = data.ActivityId or 0
end

-- 获取活动Id
function XDlcRelinkActivity:GetActivityId()
    return self.ActivityId
end

return XDlcRelinkActivity
