
---@class XRegression4Agency : XAgency
---@field private _Model XRegression4Model
local XRegression4Agency = XClass(XAgency, "XRegression4Agency", true)
-- 配置查询部分类
XClassPartialRequire("XModule/XRegression4/XRegression4AgencyConfig", "XRegression4Agency")

local XRegression4EnumConst = require("XModule/XRegression4/XRegression4EnumConst")

local Version = "Version200"

local PassportRedPoint = "PassportRedPoint"
local GiftShopRedPoint = "GiftShopRedPoint"
local ShopRedPoint = "ShopRedPoint"
local TaskRedPoint = "TaskRedPoint"
local SignRedPoint = "SignRedPoint"

local StoryKey = "StoryKey"

local function GetCookiesKey(self, key)
    local activityId = 0
    local viewModel = self._Model:GetMainViewModel()
    if viewModel then
        activityId = viewModel:GetProperty("_Id")
    end
    return string.format("Regression4_%s_%s_%s_%s", XPlayer.Id, activityId, key, Version)
end

function XRegression4Agency:OnInit()
    -- 初始化配置表（Agency 常驻，表与 Agency 生命周期一致）
    self:InitConfig()
end

function XRegression4Agency:InitRpc()
    -- 登录/活动状态改变 下发
    XRpc.NotifyRegression4Data = handler(self, self.OnNotifyData)
    -- 推送签到数据
    XRpc.NotifyRegression4SignInData = handler(self, self.OnNotifySignData)
    -- 通知触发回流立即发放的奖励
    XRpc.NotifyRegression4TriggerReward = handler(self, self.OnNotifyTriggerReward)
    -- 通知双倍次数变化
    XRpc.NotifyRegression4DoubleData = handler(self, self.OnNotifyDoubleData)
    -- 通知通行证自动领取任务奖励列表
    XRpc.NotifyRegression4PassportAutoGetTaskReward = handler(self, self.OnNotifyAutoReward)
    -- 通知战令基础信息
    XRpc.NotifyRegression4PassportBaseInfo = handler(self, self.OnNotifyPassportData)
    -- 推送问卷数据
    XRpc.NotifyRegression4SurveyData = handler(self, self.OnNotifySurveyData)
end

function XRegression4Agency:InitEvent()
    -- 跨 Agency 事件注册（当前无）
end

--region   ------------------RPC Notify start-------------------

--- 登录/活动状态改变 下发
---@param notifyData Server.XRegression4DataDb
function XRegression4Agency:OnNotifyData(notifyData)
    self._Model:UpdateLoginData(notifyData)
    XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION4_ACTIVITY_STATUS_CHANGE)
end

--- 推送签到数据
function XRegression4Agency:OnNotifySignData(signData)
    if not self:IsOpen() then
        return
    end
    local viewModel = self._Model:GetMainViewModel():GetProperty("_SignViewModel")
    viewModel:SetSignTimes(signData.SigninTimes)
    viewModel:ReceiveMultiSign(signData.Rewards)
end

--- 通知触发回流立即发放的奖励
---@param data Server.NotifyRegression4TriggerReward
function XRegression4Agency:OnNotifyTriggerReward(data)
    if not self:IsOpen() then
        return
    end
    self._Model:SetTriggerRewardList(data.RewardList)
end

--- 通知双倍次数变化（增量，只带变化的类型）
---@param data Server.NotifyRegression4DoubleData
function XRegression4Agency:OnNotifyDoubleData(data)
    if not self:IsOpen() then
        return
    end
    self._Model:SetDoubleUsedTimes(data.Type, data.UsedTimes)
end

--- 通知战令基础信息
function XRegression4Agency:OnNotifyPassportData(data)
    if not self:IsOpen() then
        return
    end
    local baseInfo = data.BaseInfo
    if not baseInfo then
        return
    end
    local viewModel = self._Model:GetMainViewModel():GetProperty("_PassportViewModel")
    viewModel:SetProperty("_Level", baseInfo.Level)
    viewModel:SetAccumulated(baseInfo.Exp)
end

--- 推送问卷数据
function XRegression4Agency:OnNotifySurveyData(data)
    if not self:IsOpen() then
        return
    end
    local activeSurveyData = data.SurveyData
    if not activeSurveyData then
        return
    end
    local activeSurveyList = activeSurveyData.ActiveSurveyList
    if not activeSurveyList then
        return
    end
    ---@type XRegression4Survey
    local viewModel = self._Model:GetMainViewModel():GetProperty("_SurveyViewModel")
    for _, v in pairs(activeSurveyList) do
        viewModel:AddSurveyData(v)
    end
end

--- 通知通行证自动领取任务奖励列表
---@param data Server.NotifyRegression4PassportAutoGetTaskReward
function XRegression4Agency:OnNotifyAutoReward(data)
    if not self:IsOpen() then
        return
    end
    local viewModel = self._Model:GetMainViewModel()
    local oldList = viewModel:GetProperty("_AutoRewardList")
    if not XTool.IsTableEmpty(oldList) then
        oldList = appendArray(oldList, data.RewardList)
    else
        oldList = data.RewardList
    end
    viewModel:SetProperty("_AutoRewardList", oldList)
end

--endregion------------------RPC Notify finish------------------

--region   ------------------状态查询 start-------------------

---@return XRegression4
function XRegression4Agency:GetMainViewModel()
    return self._Model:GetMainViewModel()
end

function XRegression4Agency:IsOpen()
    return self._Model:IsOpen()
end

--- 回归活动状态, 1 开放 0 关闭
---@param activityId number 活动Id,可选参数，不填则判断当期
---@return number
function XRegression4Agency:ActivityState(activityId)
    if not XTool.IsNumberValid(activityId) then
        return self:IsOpen() and 1 or 0
    end
    if not self:IsOpen() then
        return 0
    end
    return self._Model:GetMainViewModel():GetProperty("_Id") == tonumber(activityId) and 1 or 0
end

--- 倒计时文本（主界面入口用）
function XRegression4Agency:GetLeftTime()
    local viewModel = self._Model:GetMainViewModel()
    return XUiHelper.GetTime(viewModel:GetLeftTime(), XUiHelper.TimeFormatType.ACTIVITY)
end

--- 复刷关双倍奖励次数：总次数与已消耗次数
---@return number, number 总次数, 已消耗次数
function XRegression4Agency:GetRepeatChallengeDoubleTimes()
    local viewModel = self._Model:GetMainViewModel()
    if not viewModel then
        return 0, 0
    end
    local totalTimes = 0
    for _, cfg in ipairs(self:GetDoubleList(viewModel:GetProperty("_Id")) or table.empty) do
        totalTimes = math.max(totalTimes, cfg.DoubleTimes)
    end
    local usedTimes = viewModel:GetDoubleUsedTimes(XRegression4EnumConst.DoubleType.RepeatChallengeMultiReward)
    return totalTimes, usedTimes
end

--endregion------------------状态查询 finish------------------

--region   ------------------入口/CG start-------------------

--- 播放回归CG，播完回调（已播过则直接回调）
function XRegression4Agency:PlayStory(cb)
    local viewModel = self._Model:GetMainViewModel()
    local storyId = viewModel:GetStoryId()
    local storyKey = GetCookiesKey(self, StoryKey .. tostring(storyId))
    if XSaveTool.GetData(storyKey) then
        if cb then cb() end
        return
    end
    XDataCenter.MovieManager.PlayMovie(storyId, function()
        XSaveTool.SaveData(storyKey, true)
        if cb then cb() end
    end, nil, false, false)
end

--- Ui入口
function XRegression4Agency:EnterUiMain()
    if not self:IsOpen() then
        return
    end
    --活动分包资源检测
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    self:PlayStory(function()
        XLuaUiManager.Open("UiRegression4Activity")
    end)
end

--- 活动结束
function XRegression4Agency:OnActivityEnd()
    if self:IsOpen() then
        return
    end
    local uiNameList = { "UiRegression4Activity", "UiRegression4AutoWindow", "UiRegression4Tips" }
    --处于玩法界面内
    for _, uiName in ipairs(uiNameList) do
        if XLuaUiManager.IsUiShow(uiName) then
            XLuaUiManager.RunMain()
            XUiManager.TipText("CommonActivityEnd")
            return
        end
    end
    --通过玩法跳转到其他界面
    for _, uiName in ipairs(uiNameList) do
        if XLuaUiManager.IsUiLoad(uiName) then
            XLuaUiManager.Remove(uiName)
        end
    end
end

--endregion------------------入口/CG finish------------------

--region   ------------------红点 start-------------------

local function CheckTabActivityLocalRedPoint(self, key)
    return XSaveTool.GetData(GetCookiesKey(self, key))
end

local function MarkabActivityLocalRedPoint(self, key)
    XSaveTool.SaveData(GetCookiesKey(self, key), true)
end

function XRegression4Agency:CheckPassportLocalRedPointData()
    return CheckTabActivityLocalRedPoint(self, PassportRedPoint)
end

function XRegression4Agency:CheckShopLocalRedPointData()
    return CheckTabActivityLocalRedPoint(self, ShopRedPoint)
end

function XRegression4Agency:CheckTaskLocalRedPointData()
    return CheckTabActivityLocalRedPoint(self, TaskRedPoint)
end

function XRegression4Agency:CheckSignLocalRedPointData()
    return CheckTabActivityLocalRedPoint(self, SignRedPoint)
end

function XRegression4Agency:CheckGiftShopRedPointData()
    return CheckTabActivityLocalRedPoint(self, GiftShopRedPoint)
end

function XRegression4Agency:MarkPassportLocalRedPointData()
    MarkabActivityLocalRedPoint(self, PassportRedPoint)
end

function XRegression4Agency:MarkShopLocalRedPointData()
    MarkabActivityLocalRedPoint(self, ShopRedPoint)
end

function XRegression4Agency:MarkTaskLocalRedPointData()
    MarkabActivityLocalRedPoint(self, TaskRedPoint)
end

function XRegression4Agency:MarkSignLocalRedPointData()
    MarkabActivityLocalRedPoint(self, SignRedPoint)
end

function XRegression4Agency:MarkGiftShopRedPointData()
    MarkabActivityLocalRedPoint(self, GiftShopRedPoint)
end

local function CheckRedPointBase(self)
    return self:IsOpen()
end

function XRegression4Agency:CheckMainRedPoint()
    if not CheckRedPointBase(self) then
        return false
    end
    -- v4.5 回归活动中主页红点不再包含礼品商城
    return false
end

function XRegression4Agency:CheckTaskRedPoint()
    if not CheckRedPointBase(self) then
        return false
    end
    if not self:CheckTaskLocalRedPointData() then
        return true
    end
    local taskViewModel = self._Model:GetMainViewModel():GetProperty("_TaskVideModel")
    local taskIds = taskViewModel:GetAchievedTaskList()
    return not XTool.IsTableEmpty(taskIds)
end

function XRegression4Agency:CheckSignRedPoint()
    if not CheckRedPointBase(self) then
        return false
    end
    if not self:CheckSignLocalRedPointData() then
        return true
    end
    local signVideModel = self._Model:GetMainViewModel():GetProperty("_SignViewModel")
    return signVideModel:CheckHasReward()
end

function XRegression4Agency:CheckPassportRedPoint()
    if not CheckRedPointBase(self) then
        return false
    end
    if not self:CheckPassportLocalRedPointData() then
        return true
    end
    local passportViewModel = self._Model:GetMainViewModel():GetProperty("_PassportViewModel")
    return passportViewModel:IsRewardsAvailable()
end

function XRegression4Agency:CheckShopRedPoint()
    if not CheckRedPointBase(self) then
        return false
    end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ShopCommon) then
        return false
    end
    if not self:CheckShopLocalRedPointData() then
        return true
    end
    return false
end

function XRegression4Agency:CheckSurveyRedPoint()
    if not CheckRedPointBase(self) then
        return false
    end
    ---@type XRegression4Survey
    local surveyViewModel = self._Model:GetMainViewModel():GetProperty("_SurveyViewModel")
    if surveyViewModel:CheckHasAnySurvey() and not surveyViewModel:CheckHasFinished() then
        return XMVCA.XDailyReset:CheckDailyRedPoint(self:GetSurveyDailyRedPointKey())
    end
    return false
end

function XRegression4Agency:GetSurveyDailyRedPointKey()
    return 'Regression4Survey' .. XPlayer.Id
end

--endregion------------------红点 finish------------------

return XRegression4Agency
