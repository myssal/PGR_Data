local XRegression4EnumConst = require("XModule/XRegression4/XRegression4EnumConst")

---Agency 部分类：模块配置表的唯一注册点 + 对外配置查询接口
---表路径 Share/Regression4/ 与 Client/Regression4/。Agency 常驻、生命周期长于 Control，
---故所有表在此注册（Agency scope）；Control 侧只做转发（见 XRegression4ControlConfig）。
---@type XRegression4Agency
local XRegression4Agency = XClassPartial("XRegression4Agency")

local Share = XConfigUtil.DirectoryType.Share
local Client = XConfigUtil.DirectoryType.Client

local TableKey = {
    Regression4Activity           = { DirPath = Share, Identifier = "Id" },
    Regression4SignIn             = { DirPath = Share, Identifier = "Id" },
    Regression4PassportActivity   = { DirPath = Share, Identifier = "Id" },
    Regression4PassportLevel      = { DirPath = Share, Identifier = "Id" },
    Regression4PassportReward     = { DirPath = Share, Identifier = "Id" },
    Regression4PassportTaskGroup  = { DirPath = Share, Identifier = "Id" },
    Regression4PassportTypeInfo   = { DirPath = Share, Identifier = "Id" },
    Regression4Survey             = { DirPath = Share, Identifier = "Id" },
    Regression4Double             = { DirPath = Share, Identifier = "Id" },
    Regression4ActivityOverview   = { DirPath = Client, Identifier = "Id" },
    Regression4ClientConfig       = { DirPath = Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
}

function XRegression4Agency:InitConfig()
    self:InitConfigByTabKey("Regression4", TableKey)
end

--region   ------------------活动 start-------------------

--- 活动配置
---@param activityId 活动Id
---@return XTableRegression4Activity
function XRegression4Agency:GetActivityConfig(activityId)
    local config = self:GetConfigByTabKeyAndIdKey(TableKey.Regression4Activity, activityId)
    return config or table.empty
end

local function GetActivityTimeId(self, activityId)
    return self:GetActivityConfig(activityId).TimeId
end

function XRegression4Agency:GetActivityStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetActivityTimeId(self, activityId))
end

function XRegression4Agency:GetActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetActivityTimeId(self, activityId))
end

function XRegression4Agency:GetStoryId(activityId)
    return self:GetActivityConfig(activityId).StoryId
end

--- 打脸图（AutoWindow）预览奖励Id，实际发奖走服务端协议
---@param activityId 活动Id
---@return number
function XRegression4Agency:GetTriggerRewardId(activityId)
    return self:GetActivityConfig(activityId).TriggerRewardId
end

function XRegression4Agency:GetDurationTime(activityId)
    return self:GetActivityConfig(activityId).ContinueDays
end

function XRegression4Agency:GetHelpKey(activityId)
    local helpId = self:GetActivityConfig(activityId).HelpId
    return XMVCA.XHelpCourse:GetHelpCourseCfgById(helpId).Function
end

function XRegression4Agency:GetPackageUiType(activityId)
    return self:GetActivityConfig(activityId).PackageUiType
end

function XRegression4Agency:GetContinueDays(activityId)
    return self:GetActivityConfig(activityId).ContinueDays
end

--- 回归活动页签配置
---@param activityId 回归活动Id
---@return XTableRegression4ActivityOverview[]
function XRegression4Agency:GetActivityOverViewList(activityId)
    local list = {}
    local overviewCfgs = self:GetAllConfigByTabKey(TableKey.Regression4ActivityOverview)
    for _, cfg in pairs(overviewCfgs) do
        if cfg.ActivityId == activityId then
            table.insert(list, cfg)
        end
    end
    table.sort(list, function(a, b)
        return a.Priority < b.Priority
    end)
    return list
end

--endregion------------------活动 finish------------------

--region   ------------------签到 start-------------------

--- 活动签到列表
---@param activityId 回归活动Id
---@return XTableRegression4SignIn[]
function XRegression4Agency:GetSignInList(activityId)
    local list = {}
    local signCfgs = self:GetAllConfigByTabKey(TableKey.Regression4SignIn)
    for _, cfg in pairs(signCfgs) do
        if cfg.ActivityId == activityId then
            table.insert(list, cfg)
        end
    end
    table.sort(list, function(a, b)
        return a.Days < b.Days
    end)
    return list
end

--- 签到配置
---@param signId 签到配置Id
---@return XTableRegression4SignIn
function XRegression4Agency:GetSignTemplate(signId)
    local template = self:GetConfigByTabKeyAndIdKey(TableKey.Regression4SignIn, signId)
    if not template then
        return table.empty
    end
    return template
end

--endregion------------------签到 finish------------------

--region   ------------------战令 start-------------------

--- 当期战令活动配置
local _PassportActivity
--- 当期战令类型配置
local _PassportTypeInfo
--- 当期战令等级信息
local _PassportLevelInfo
--- 当期战令奖励信息
local _PassportRewardInfo
--- 战令任务
local _PassportTaskInfo = {}

--- 战令活动配置
---@param activityId 回归活动Id
---@return XTableRegression4PassportActivity
function XRegression4Agency:GetPassportActivity(activityId)
    if not XTool.IsNumberValid(activityId) then
        XLog.Error("XRegression4Agency:GetPassportActivity: invalid activityId: " .. tostring(activityId))
        return table.empty
    end
    local passportCfgs = self:GetAllConfigByTabKey(TableKey.Regression4PassportActivity)
    if not _PassportActivity or _PassportActivity.ActivityId ~= activityId then
        for _, cfg in pairs(passportCfgs) do
            if cfg.ActivityId == activityId then
                _PassportActivity = cfg
                break
            end
        end
    end
    return _PassportActivity
end

--- 活动结束前x秒，禁止购买战令
---@param passportActivityId 战令活动Id
---@return number
function XRegression4Agency:GetBuyPassportEndTime(passportActivityId)
    return self:GetPassportActivity(passportActivityId).BuyPassPortEarlyEndTime
end

--- 战令活动名
---@param passportActivityId 战令活动Id
---@return string
function XRegression4Agency:GetPassportName(passportActivityId)
    return self:GetPassportActivity(passportActivityId).Name
end

--- 战令任务组id
---@param passportActivityId 战令活动Id
---@return number
function XRegression4Agency:GetPassportTaskGroupId(passportActivityId)
    return self:GetPassportActivity(passportActivityId).TaskGroup
end

--- 根据玩法活动Id获取战令活动Id
---@param activityId 玩法活动Id
---@return number
function XRegression4Agency:GetPassportActivityId(activityId)
    local passportActivityId
    local passportCfgs = self:GetAllConfigByTabKey(TableKey.Regression4PassportActivity)
    for _, passportActivity in pairs(passportCfgs) do
        if passportActivity.ActivityId == activityId then
            passportActivityId = passportActivity.Id
        end
    end
    return passportActivityId
end

--- 初始化战令类型数据
local function InitPassportTypeInfo(self, passportActivityId)
    _PassportTypeInfo = {}
    local typeInfoCfgs = self:GetAllConfigByTabKey(TableKey.Regression4PassportTypeInfo)
    for _, typeInfo in pairs(typeInfoCfgs) do
        if typeInfo.PassportActivityId == passportActivityId then
            table.insert(_PassportTypeInfo, typeInfo)
        end
    end
    table.sort(_PassportTypeInfo, function(a, b)
        return a.Id < b.Id
    end)
end

--- 初始化战令等级数据
local function InitPassportLevelInfo(self, passportActivityId)
    _PassportLevelInfo = {}
    local levelCfgs = self:GetAllConfigByTabKey(TableKey.Regression4PassportLevel)
    for _, levelInfo in pairs(levelCfgs) do
        if levelInfo.PassportActivityId == passportActivityId and levelInfo.Level > 0 then
            table.insert(_PassportLevelInfo, levelInfo)
        end
    end
    table.sort(_PassportLevelInfo, function(a, b)
        return a.Level < b.Level
    end)
end

--- 初始化战令奖励数据
local function InitPassportRewardInfo(self, typeInfos)
    local typeIdDict = {}
    for _, info in ipairs(typeInfos) do
        typeIdDict[info.Id] = true
    end
    _PassportRewardInfo = {}
    local rewardCfgs = self:GetAllConfigByTabKey(TableKey.Regression4PassportReward)
    for _, info in pairs(rewardCfgs) do
        local passportId = info.PassportId
        --只存当期的奖励数据
        if typeIdDict[passportId] then
            _PassportRewardInfo[passportId] = _PassportRewardInfo[passportId] or {}
            _PassportRewardInfo[passportId][info.Level] = info.Id
        end
    end
end

--- 初始化战令任务数据
local function InitPassportTask(self, taskType, groupId)
    _PassportTaskInfo[groupId] = _PassportTaskInfo[groupId] or {}
    local dict = {}
    local taskGroupCfgs = self:GetAllConfigByTabKey(TableKey.Regression4PassportTaskGroup)
    for id, group in pairs(taskGroupCfgs) do
        local opened = XFunctionManager.CheckInTimeByTimeId(group.TimeId, true)
        if group.Type == taskType and group.Group == groupId and opened then
            for _, taskId in ipairs(group.TaskId) do
                dict[taskId] = id
            end
        end
    end
    _PassportTaskInfo[groupId][taskType] = dict
end

--- 获取任务数据
local function GetPassportTaskDict(self, taskType, groupId)
    if not _PassportTaskInfo[groupId] or not _PassportTaskInfo[groupId][taskType] then
        InitPassportTask(self, taskType, groupId)
    end
    return _PassportTaskInfo[groupId][taskType]
end

function XRegression4Agency:GetPassportTypeInfos(passportActivityId)
    if not _PassportTypeInfo or _PassportTypeInfo[1].PassportActivityId ~= passportActivityId then
        InitPassportTypeInfo(self, passportActivityId)
    end
    return _PassportTypeInfo
end

function XRegression4Agency:GetPassportLevelInfos(passportActivityId)
    if not _PassportLevelInfo or _PassportLevelInfo[1].PassportActivityId ~= passportActivityId then
        InitPassportLevelInfo(self, passportActivityId)
    end
    return _PassportLevelInfo
end

function XRegression4Agency:GetPassportRewardInfos(passportActivityId)
    local typeInfo = self:GetPassportTypeInfos(passportActivityId)
    local id = typeInfo[1].Id
    --兼容在线切换passportActivityId
    if not _PassportRewardInfo or _PassportRewardInfo[id] == nil then
        InitPassportRewardInfo(self, typeInfo)
    end
    return _PassportRewardInfo
end

function XRegression4Agency:GetPassportRewardInfo(passportActivityId, typeInfoId, level)
    local infos = self:GetPassportRewardInfos(passportActivityId)
    local id = infos[typeInfoId][level]
    return self:GetConfigByTabKeyAndIdKey(TableKey.Regression4PassportReward, id, true) or table.empty
end

function XRegression4Agency:GetPassportRewardInfoById(rewardId)
    local template = self:GetConfigByTabKeyAndIdKey(TableKey.Regression4PassportReward, rewardId)
    if not template then
        return table.empty
    end
    return template
end

function XRegression4Agency:GetPassportTypeInfoTemplate(typeInfoId)
    local template = self:GetConfigByTabKeyAndIdKey(TableKey.Regression4PassportTypeInfo, typeInfoId)
    if not template then
        return table.empty
    end
    return template
end

function XRegression4Agency:GetPassportTaskGroupTemplateByTaskId(groupId, taskId)
    if not _PassportTaskInfo[groupId] then
        XLog.Error("XRegression4Agency:GetPassportTaskGroupTemplateByTaskId error: task info uninitialized complete!!")
        return table.empty
    end
    local taskGroupCfgs = self:GetAllConfigByTabKey(TableKey.Regression4PassportTaskGroup)
    for _, taskType in pairs(XRegression4EnumConst.TaskType) do
        local dict = GetPassportTaskDict(self, taskType, groupId)
        if not XTool.IsTableEmpty(dict) then
            local taskGroupId = dict[taskId]
            if XTool.IsNumberValid(taskGroupId) then
                return taskGroupCfgs[taskGroupId]
            end
        end
    end
    XLog.Error("XRegression4Agency:GetPassportTaskGroupTemplateByTaskId error: task id = " .. taskId .. " not found")
    return table.empty
end

--- 获取任务列表
---@param taskType 任务类型
---@param groupId 任务组Id
---@return number[]
function XRegression4Agency:GetPassportTaskList(taskType, groupId)
    local dict = GetPassportTaskDict(self, taskType, groupId)
    local list = {}
    local taskGroupCfgs = self:GetAllConfigByTabKey(TableKey.Regression4PassportTaskGroup)
    local defaultOpen = taskType ~= XRegression4EnumConst.TaskType.TimeLimit and true or false
    for taskId, group in pairs(dict or table.empty) do
        local template = taskGroupCfgs[group]
        local timeId = template and template.TimeId or 0
        local open = XFunctionManager.CheckInTimeByTimeId(timeId, defaultOpen)
        if open then
            table.insert(list, taskId)
        end
    end
    return list
end

--endregion------------------战令 finish------------------

--region   ------------------客户端配置 start-------------------

function XRegression4Agency:GetClientConfig(key)
    local cfg = self:GetConfigByTabKeyAndIdKey(TableKey.Regression4ClientConfig, key)
    if not cfg then
        XLog.ErrorTableDataNotFound("XRegression4Agency:GetClientConfig", "Regression4ClientConfig", "Client/Regression4/Regression4ClientConfig.tab", "Key", tostring(key))
        return table.empty
    end
    return cfg
end

function XRegression4Agency:GetClientConfigValue(key, index)
    local values = self:GetClientConfig(key).Values
    return values and values[index]
end

--endregion------------------客户端配置 finish------------------

--region   ------------------问卷 start-------------------

function XRegression4Agency:GetSurveyCfgIds()
    local ids = {}
    local surveyCfgs = self:GetAllConfigByTabKey(TableKey.Regression4Survey)
    if not XTool.IsTableEmpty(surveyCfgs) then
        for _, v in pairs(surveyCfgs) do
            table.insert(ids, v.Id)
        end
    end
    return ids
end

---@return XTableRegression4Survey
function XRegression4Agency:GetSurveyCfgById(id)
    local cfg = self:GetConfigByTabKeyAndIdKey(TableKey.Regression4Survey, id)
    if not cfg then
        return table.empty
    end
    return cfg
end

--endregion------------------问卷 finish------------------

--region------------------双倍奖励 start------------------

---按活动取双倍配置列表
---@param activityId number
---@return XTableRegression4Double[]
function XRegression4Agency:GetDoubleList(activityId)
    local list = {}
    local doubleCfgs = self:GetAllConfigByTabKey(TableKey.Regression4Double)
    for _, cfg in pairs(doubleCfgs) do
        if cfg.ActivityId == activityId then
            list[#list + 1] = cfg
        end
    end
    return list
end

---按 Id 取单条双倍配置
---@return XTableRegression4Double
function XRegression4Agency:GetDoubleCfg(id)
    local cfg = self:GetConfigByTabKeyAndIdKey(TableKey.Regression4Double, id)
    if not cfg then
        return table.empty
    end
    return cfg
end

--endregion------------------双倍奖励 finish------------------

return XRegression4Agency
