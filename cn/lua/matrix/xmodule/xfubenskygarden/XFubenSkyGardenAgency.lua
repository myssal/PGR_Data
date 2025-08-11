local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")

---@class XFubenSkyGardenAgency : XFubenSimulationChallengeAgency
---@field private _Model XFubenSkyGardenModel
local XFubenSkyGardenAgency = XClass(XFubenSimulationChallengeAgency, "XFubenSkyGardenAgency")
function XFubenSkyGardenAgency:OnInit()
    
    self:RegisterChapterAgency()

    self.ExChapterType = self:ExGetChapterType()
end

function XFubenSkyGardenAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.SkyGarden
end

function XFubenSkyGardenAgency:ExGetRunningTimeStr()
    local timeId = self:GetTimeId()
    if self:ExGetIsLocked() or not timeId or timeId <= 0 then
        return ""
    end
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    if endTime <= 0 then
        return ""
    end
    
    local nowTime = XTime.GetServerNowTimestamp()
    return XUiHelper.GetText("ActivityEndLeftText", XUiHelper.GetTime(math.max(0, endTime - nowTime), XUiHelper.TimeFormatType.ACTIVITY))
end

function XFubenSkyGardenAgency:ExCheckInTime()
    local timeId = self:GetTimeId()
    if not timeId or timeId <= 0 then
        return true
    end
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local nowTime = XTime.GetServerNowTimestamp()
    
    return endTime <= 0 or endTime > nowTime
end

function XFubenSkyGardenAgency:ExGetIsLocked()
    local timeId = self:GetTimeId()
    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.SkyGarden) then
        return true
    end
    if not XFunctionManager.CheckInTimeByTimeId(timeId, true) then
        return true
    end
    return false
end

function XFubenSkyGardenAgency:ExGetLockTip()
    local timeId = self:GetTimeId()
    if timeId and timeId > 0 then
        local beginTime = XFunctionManager.GetStartTimeByTimeId(timeId)
        local nowTime = XTime.GetServerNowTimestamp()
        if beginTime > nowTime then
            return XUiHelper.GetText("ScheOpenCountdown", XUiHelper.GetTime(math.max(0, beginTime - nowTime), XUiHelper.TimeFormatType.ACTIVITY))
        end
    end
    
    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.SkyGarden) then
        return XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.SkyGarden)
    end
    
    return ""
end

function XFubenSkyGardenAgency:ExCheckIsFinished(cb)
    local functionId = XFunctionManager.FunctionName.SkyGarden
    if not XFunctionManager.JudgeOpen(functionId) then
        if cb then cb(false) end
        return false
    end
    if cb then cb(true) end
    return true
end

function XFubenSkyGardenAgency:ExGetProgressTip()
    if not self._ProgressTip then
        local cur, total = XMVCA.XBigWorldCourse:GetCourseTotalTaskProgress()
        local progress = math.floor(cur / total * 100)
        self._ProgressTip = XUiHelper.GetText("SkyGardenProgressText", progress)
    end
    return self._ProgressTip
end

function XFubenSkyGardenAgency:GetTimeId()
    return XFunctionManager.GetFunctionTimeId(XFunctionManager.FunctionName.SkyGarden)
end

function XFubenSkyGardenAgency:ClearProgressTip()
    self._ProgressTip = false
end


return XFubenSkyGardenAgency