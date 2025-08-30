local super = require("XModule/XWheelchairManual/XWheelchairManualControl")
---@type XWheelchairManualControl
local XWheelchairManualControl = XClassPartial('XWheelchairManualControl')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XWheelchairManualControl
end

function XWheelchairManualControl:GetWeekActivityTemplatesAndCount(viewData)
    local rewardCfgId = viewData:GetMainId() * 100 + viewData:GetSubId()
    local cfgSpecial = self._Model:GetWheelchairManualGuideWeekRewardSpecialCfg(rewardCfgId)
    if cfgSpecial and XFunctionManager.CheckInTimeByTimeId(cfgSpecial.TimeId) then
        return cfgSpecial.MainTemplateId, cfgSpecial.MainTemplateCount
    end
end

return XWheelchairManualControl