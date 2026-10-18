
local XRegression4EnumConst = require("XModule/XRegression4/XRegression4EnumConst")
local XRegression4 = XClass(XDataEntityBase, "XRegression4")

local default = {
    _Id = 0, --活动Id
    _State = XRegression4EnumConst.ActivityState.NotInRegression, --活动状态
    _BeginTime = 0,         --活动开始时间
    _ActivityEndTime = 0,   --活动结束时间
    _AutoRewardList = {},   --自动领取奖励
    _SignViewModel = {},    --签到视图数据
    _PassportViewModel = {}, --战令视图数据
    _TaskVideModel = {},    --任务视图数据
    _TriggerRewardSent = false, --本次回归触发回流奖励是否已发放
    _TriggerRewardList = {},    --服务端下发的触发回流奖励
    _DoubleUsedTimes = {},      --双倍已使用次数，key为XRegression4EnumConst.DoubleType
}

function XRegression4:Ctor(activityId)
    self:Init(default, activityId)
end

function XRegression4:InitData(activityId)
    self:SetProperty("_Id", activityId)
    local passportId = XMVCA.XRegression4:GetPassportActivityId(self._Id)
    self._PassportViewModel = require("XModule/XRegression4/Entity/XRegression4Passport").New(passportId)
    self._SignViewModel = require("XModule/XRegression4/Entity/XRegression4Sign").New(self._Id)
    self._TaskVideModel = require("XModule/XRegression4/Entity/XRegression4Task").New(passportId)
    self._SurveyViewModel = require("XModule/XRegression4/Entity/XRegression4Survey").New()
end

--- 服务端数据更新
---@param notifyData Server.XRegression4ActivityData
---@return nil
--------------------------
function XRegression4:UpdateData(notifyData)
    self:SetProperty("_State", notifyData.State)
    self:SetProperty("_BeginTime", notifyData.BeginTime)
    self:SetProperty("_TriggerRewardSent", notifyData.TriggerRewardSent)
    self:SetEndTimeStamp()
end

function XRegression4:IsOpen()
    return self._Id > 0 and self._State == XRegression4EnumConst.ActivityState.InRegression and self:GetLeftTime() > 0
end

function XRegression4:GetSignViewModel()
    return self._SignViewModel
end

function XRegression4:GetPassportViewModel()
    return self._PassportViewModel
end

---@return XRegression4Survey
function XRegression4:GetSurveyViewModel()
    return self._SurveyViewModel
end

function XRegression4:GetActivityOverViewList()
    return XMVCA.XRegression4:GetActivityOverViewList(self._Id)
end

--- 触发回流奖励是否已发放，决定打脸图的奖励领取态
function XRegression4:IsTriggerRewardSent()
    return self._TriggerRewardSent
end

function XRegression4:GetTriggerRewardList()
    if not XTool.IsTableEmpty(self._TriggerRewardList) then
        return self._TriggerRewardList
    end
    return XRewardManager.GetRewardList(XMVCA.XRegression4:GetTriggerRewardId(self._Id)) or table.empty
end

function XRegression4:SetTriggerRewardList(rewardList)
    self:SetProperty("_TriggerRewardList", rewardList)
    self:SetProperty("_TriggerRewardSent", true)
end

function XRegression4:GetDoubleUsedTimes(doubleType)
    return self._DoubleUsedTimes[doubleType] or 0
end

function XRegression4:SetDoubleUsedTimes(doubleType, usedTimes)
    self._DoubleUsedTimes[doubleType] = usedTimes
    self:SetProperty("_DoubleUsedTimes", self._DoubleUsedTimes)
end

function XRegression4:GetStoryId()
    return XMVCA.XRegression4:GetStoryId(self._Id)
end

function XRegression4:GetHelpKey()
    return XMVCA.XRegression4:GetHelpKey(self._Id)
end

function XRegression4:GetPackageUiType()
    return XMVCA.XRegression4:GetPackageUiType(self._Id)
end

--- 检查页签功能是否开启
---@param activityType number 活动类型
---@return boolean, string
--------------------------
function XRegression4:CheckOpenByActivityType(activityType)
    if activityType == XRegression4EnumConst.ActivityType.Shop then
        local functionNameId = XFunctionManager.FunctionName.ShopCommon
        return XFunctionManager.JudgeCanOpen(functionNameId), XFunctionManager.GetFunctionOpenCondition(functionNameId)
    elseif activityType == XRegression4EnumConst.ActivityType.Questionnaire then
        local surveyData = self:GetSurveyViewModel()
        if surveyData then
            return surveyData:CheckHasAnySurvey(), ""
        end
        return false, ""
    else
        return true, ""
    end
end

---@return "剩余时间：xxx天"
function XRegression4:GetLeftTimeDesc(colorStr, format)
    return XUiHelper.GetText("CommonActivityTimeStr", self:GetLeftTimeDescWithoutPrefix(colorStr, format))
end

---@return "xxx天"
function XRegression4:GetLeftTimeDescWithoutPrefix(colorStr, format)
    format = format or XUiHelper.TimeFormatType.ACTIVITY
    colorStr = colorStr or "0f70bc"
    return string.format("<color=#%s>%s</color>", colorStr, XUiHelper.GetTime(self:GetLeftTime(), format))
end

--- 距离活动结束剩余时间
function XRegression4:GetLeftTime()
    local timeOfNow = XTime.GetServerNowTimestamp()
    local timeOfEnd = self._ActivityEndTime
    if timeOfEnd == 0 then
        self:SetEndTimeStamp()
        timeOfEnd = self._ActivityEndTime
    end
    return math.max(0, timeOfEnd - timeOfNow)
end

function XRegression4:SetEndTimeStamp()
    local days = XMVCA.XRegression4:GetContinueDays(self._Id)
    local timeStamp = self._BeginTime + days * 24 * 60 * 60
    self:SetProperty("_ActivityEndTime", XTime.GetTimeDayFreshTime(timeStamp))
end

function XRegression4:ClearAutoRewardList()
    self._AutoRewardList = {}
end

return XRegression4