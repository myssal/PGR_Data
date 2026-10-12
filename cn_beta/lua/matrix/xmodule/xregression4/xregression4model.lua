
---@class XRegression4Model : XModel
---@field private _MainViewModel XRegression4 主视图（服务端数据驱动）
local XRegression4Model = XClass(XModel, "XRegression4Model")

local XRegression4 = require("XModule/XRegression4/Entity/XRegression4")

function XRegression4Model:OnInit()
    self._MainViewModel = nil
end

---Control 生命周期结束时触发；服务端存档不清，只清界面级临时缓存
function XRegression4Model:ClearPrivate()
end

function XRegression4Model:ResetAll()
    self._MainViewModel = nil
end

---@return XRegression4
function XRegression4Model:GetMainViewModel()
    return self._MainViewModel
end

---@return boolean
function XRegression4Model:IsOpen()
    return self._MainViewModel ~= nil and self._MainViewModel:IsOpen()
end

--- 登录/活动状态改变，全量数据落地
---@param notifyData Server.XRegression4DataDb
function XRegression4Model:UpdateLoginData(notifyData)
    local data = notifyData.Data
    local activityData = data.ActivityData
    local activityId = activityData and activityData.Id or 0
    if activityId <= 0 then
        return
    end

    self._MainViewModel = self._MainViewModel or XRegression4.New(activityId)
    self._MainViewModel:UpdateData(activityData)
    self._MainViewModel:GetProperty("_SignViewModel"):UpdateData(data.SignInData)
    self._MainViewModel:GetProperty("_PassportViewModel"):UpdateData(data.PassportData)
    self._MainViewModel:GetProperty("_SurveyViewModel"):UpdateData(data.SurveyData)
    local doubleData = data.DoubleData
    if doubleData and not XTool.IsTableEmpty(doubleData.UsedTimes) then
        for doubleType, usedTimes in pairs(doubleData.UsedTimes) do
            self._MainViewModel:SetDoubleUsedTimes(doubleType, usedTimes)
        end
    end
end

--- 触发回流奖励落地
---@param rewardList table
function XRegression4Model:SetTriggerRewardList(rewardList)
    local vm = self._MainViewModel
    if vm then
        vm:SetTriggerRewardList(rewardList)
    end
end

--- 双倍次数增量落地
function XRegression4Model:SetDoubleUsedTimes(doubleType, usedTimes)
    local vm = self._MainViewModel
    if vm then
        vm:SetDoubleUsedTimes(doubleType, usedTimes)
    end
end

return XRegression4Model
