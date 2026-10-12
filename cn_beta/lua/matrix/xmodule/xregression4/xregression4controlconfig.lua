
---Control 部分类：配置查询转发层
---配置表统一由 Agency 注册（见 XRegression4AgencyConfig），此处仅转发，
---保持方法名/签名不变，Control 主体与 UI 继续用 self:GetXxx。
---@type XRegression4Control
local XRegression4Control = XClassPartial("XRegression4Control")

function XRegression4Control:InitConfig()
    -- 配置表由 Agency 注册，Control 无需注册
end

--region   ------------------活动 start-------------------

---@return XTableRegression4Activity
function XRegression4Control:GetActivityConfig(activityId)
    return self:GetAgency():GetActivityConfig(activityId)
end

function XRegression4Control:GetActivityStartTime(activityId)
    return self:GetAgency():GetActivityStartTime(activityId)
end

function XRegression4Control:GetActivityEndTime(activityId)
    return self:GetAgency():GetActivityEndTime(activityId)
end

function XRegression4Control:GetStoryId(activityId)
    return self:GetAgency():GetStoryId(activityId)
end

function XRegression4Control:GetTriggerRewardId(activityId)
    return self:GetAgency():GetTriggerRewardId(activityId)
end

function XRegression4Control:GetDurationTime(activityId)
    return self:GetAgency():GetDurationTime(activityId)
end

function XRegression4Control:GetHelpKey(activityId)
    return self:GetAgency():GetHelpKey(activityId)
end

function XRegression4Control:GetPackageUiType(activityId)
    return self:GetAgency():GetPackageUiType(activityId)
end

function XRegression4Control:GetContinueDays(activityId)
    return self:GetAgency():GetContinueDays(activityId)
end

---@return XTableRegression4ActivityOverview[]
function XRegression4Control:GetActivityOverViewList(activityId)
    return self:GetAgency():GetActivityOverViewList(activityId)
end

--endregion------------------活动 finish------------------

--region   ------------------签到 start-------------------

---@return XTableRegression4SignIn[]
function XRegression4Control:GetSignInList(activityId)
    return self:GetAgency():GetSignInList(activityId)
end

---@return XTableRegression4SignIn
function XRegression4Control:GetSignTemplate(signId)
    return self:GetAgency():GetSignTemplate(signId)
end

--endregion------------------签到 finish------------------

--region   ------------------战令 start-------------------

function XRegression4Control:GetPassportActivity(activityId)
    return self:GetAgency():GetPassportActivity(activityId)
end

function XRegression4Control:GetBuyPassportEndTime(passportActivityId)
    return self:GetAgency():GetBuyPassportEndTime(passportActivityId)
end

function XRegression4Control:GetPassportName(passportActivityId)
    return self:GetAgency():GetPassportName(passportActivityId)
end

function XRegression4Control:GetPassportTaskGroupId(passportActivityId)
    return self:GetAgency():GetPassportTaskGroupId(passportActivityId)
end

function XRegression4Control:GetPassportActivityId(activityId)
    return self:GetAgency():GetPassportActivityId(activityId)
end

function XRegression4Control:GetPassportTypeInfos(passportActivityId)
    return self:GetAgency():GetPassportTypeInfos(passportActivityId)
end

function XRegression4Control:GetPassportLevelInfos(passportActivityId)
    return self:GetAgency():GetPassportLevelInfos(passportActivityId)
end

function XRegression4Control:GetPassportRewardInfos(passportActivityId)
    return self:GetAgency():GetPassportRewardInfos(passportActivityId)
end

function XRegression4Control:GetPassportRewardInfo(passportActivityId, typeInfoId, level)
    return self:GetAgency():GetPassportRewardInfo(passportActivityId, typeInfoId, level)
end

function XRegression4Control:GetPassportRewardInfoById(rewardId)
    return self:GetAgency():GetPassportRewardInfoById(rewardId)
end

function XRegression4Control:GetPassportTypeInfoTemplate(typeInfoId)
    return self:GetAgency():GetPassportTypeInfoTemplate(typeInfoId)
end

function XRegression4Control:GetPassportTaskGroupTemplateByTaskId(groupId, taskId)
    return self:GetAgency():GetPassportTaskGroupTemplateByTaskId(groupId, taskId)
end

---@return number[]
function XRegression4Control:GetPassportTaskList(taskType, groupId)
    return self:GetAgency():GetPassportTaskList(taskType, groupId)
end

--endregion------------------战令 finish------------------

--region   ------------------客户端配置 start-------------------

function XRegression4Control:GetClientConfigValue(key, index)
    return self:GetAgency():GetClientConfigValue(key, index)
end

--endregion------------------客户端配置 finish------------------

--region   ------------------问卷 start-------------------

function XRegression4Control:GetSurveyCfgIds()
    return self:GetAgency():GetSurveyCfgIds()
end

---@return XTableRegression4Survey
function XRegression4Control:GetSurveyCfgById(id)
    return self:GetAgency():GetSurveyCfgById(id)
end

--endregion------------------问卷 finish------------------

--region------------------双倍奖励 start------------------

---@return XTableRegression4Double[]
function XRegression4Control:GetDoubleList(activityId)
    return self:GetAgency():GetDoubleList(activityId)
end

---@return XTableRegression4Double
function XRegression4Control:GetDoubleCfg(id)
    return self:GetAgency():GetDoubleCfg(id)
end

--endregion------------------双倍奖励 finish------------------

return XRegression4Control
