local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XSkyTowerAgency : XFubenActivityAgency
---@field private _Model XSkyTowerModel
local XSkyTowerAgency = XClass(XFubenActivityAgency, "XSkyTowerAgency", true)

--region 部分类初始化
XClassPartialRequire("XModule/XSkyTower/XAgencyPartial/XSkyTowerAgencyEnum", "XSkyTowerAgency")
XClassPartialRequire("XModule/XSkyTower/XAgencyPartial/XSkyTowerAgencyScene", "XSkyTowerAgency")
--endregion

function XSkyTowerAgency:OnInit()
    self:RegisterActivityAgency()
    self:InitScene()
    self.IsInitOnce = false --只会初始化一次
    self._InActivity = false --是否处于活动玩法中
    self.RichTextImageCallBack = handler(self, self.OnRichTextImageCallBack)
end

function XSkyTowerAgency:OnLoginOut()

end

function XSkyTowerAgency:InitRpc()
    XRpc.NotifySkyTowerData = handler(self, self.NotifySkyTowerData) --仅用于活动重置等服务器主动变更
    XRpc.NotifySkyTowerCharacter = handler(self, self.NotifySkyTowerCharacter)
    XRpc.NotifySkyTowerPerform = handler(self, self.NotifySkyTowerPerform)
    XRpc.NotifySkyTowerLevel = handler(self, self.NotifySkyTowerLevel)
    XRpc.NotifySkyTowerSpeedUpDailyReset = handler(self, self.NotifySkyTowerSpeedUpDailyReset)
end

function XSkyTowerAgency:InitEvent()

end

function XSkyTowerAgency:InitOnce()
    if self.IsInitOnce then
        return
    end
    self:InitEnum()
    self:InitConst()
    self.IsInitOnce = true
end

function XSkyTowerAgency:IsOpen()
    return self._Model:IsOpen()
end

function XSkyTowerAgency:OpenUi()
    --功能未开启
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SkyTower) then
        return false
    end
    --先拉全量数据，再走进入流程
    self:SkyTowerActivityDataRequest(function()
        -- 先播放 Loading 入场动画，资源加载由 Loop 阶段启动
        XLuaUiManager.Open("UiSkyTowerLoading")
    end)
    return true
end

---文本组件获取图片路径接口
function XSkyTowerAgency:OnRichTextImageCallBack(key, image)
    local url = self._Model:GetClientConfigValue(key)
    if string.IsNilOrEmpty(url) then
        XLog.Error("创建图片失败! Theatre6ClientConfig.stab 未配置主键 = " .. key)
        return
    end
    image:SetSprite(url)
end

function XSkyTowerAgency:ExCheckInTime()
    return XFubenActivityAgency.ExCheckInTime(self)
end

function XSkyTowerAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    return self.ExConfig
end

function XSkyTowerAgency:ExGetProgressTip()
    local level = self._Model:GetSkyTowerLv()
    return string.format(self._Model:GetClientConfigValue("SkyTowerLevelText"), level)
end

function XSkyTowerAgency:ExGetRunningTimeStr()
    if not self._Model:IsOpen() then
        return ""
    end
    local endTime = self._Model:GetActivityEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local timeStr = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    return XUiHelper.GetText("RemainingBusinessTime", timeStr)
end

function XSkyTowerAgency:IsMaxLevel()
    return self:GetSkyTowerLv() >= self.MaxLv
end

function XSkyTowerAgency:GetSkyTowerLv()
    return self._Model:GetSkyTowerLv()
end

---编辑器调用
function XSkyTowerAgency.RefreshCameraParamFromEditor(cameraParam)
    ---@type XUiSkyTowerMain
    local ui = XLuaUiManager.GetTopLuaUi("UiSkyTowerMain")
    if ui then
        ui:RefreshCameraParamFromEditor(cameraParam)
    end
end

--region 通用解锁条件
---通天塔是否已建造到指定楼层
---@param floorId number 要求已建造的楼层Id
---@return boolean
function XSkyTowerAgency:CheckConditionFloorBuilt(floorId)
    if not self:CheckConditionDataReady() then
        return false
    end
    local lvConfig = self._Model:GetLvConfig(self:GetSkyTowerLv())
    return lvConfig.FloorId >= floorId
end

---通天塔等级是否达标
---@param needLv number 要求的通天塔等级
function XSkyTowerAgency:CheckConditionTowerLevel(needLv)
    if not self:CheckConditionDataReady() then
        return false
    end
    return self:GetSkyTowerLv() >= needLv
end

---员工等级是否达标
---@param characterId number 角色Id，填0表示不限角色，任意已解锁角色达标即满足
---@param needLv number 要求的角色等级
function XSkyTowerAgency:CheckConditionCharacterLevel(characterId, needLv)
    if not self:CheckConditionDataReady() then
        return false
    end
    if characterId == 0 then
        return self._Model:GetGreaterLevelCharacterCount(needLv) > 0
    end
    if not self._Model:IsCharacterUnlocked(characterId) then
        return false
    end
    return self._Model:GetCharacterLv(characterId) >= needLv
end

---事件或订单是否已完成
---@param performId number SkyTowerPerform表Id
function XSkyTowerAgency:CheckConditionPerformFinish(performId)
    if not self:CheckConditionDataReady() then
        return false
    end
    return self._Model:GetPerformState(performId) == self.PerformState.Finish
end

---解锁条件求值前置校验：活动开启且全量数据已到达
---条件可能在活动外（如商店、引导）被调用，此时按不满足处理
function XSkyTowerAgency:CheckConditionDataReady()
    if not self:IsOpen() then
        return false
    end
    return self._Model:IsDataReady()
end

---@return XTableSkyTowerItem
function XSkyTowerAgency:GetItemConfig(itemId)
    return self._Model:GetItemConfig(itemId)
end

function XSkyTowerAgency:GetItemCount(itemId)
    return self._Model:GetItemCount(itemId)
end
--endregion

--region 工具接口
---@param msg string
---@param isPlayEffect boolean 是否播放烟花特效，默认不播放
function XSkyTowerAgency:TipMsg(msg, isPlayEffect)
    if not msg then
        XLog.Error("XSkyTowerAgency:TipMsg error, msg is nil")
        return
    end
    local uiName = "UiSkyTowerRadio"
    if XLuaUiManager.IsUiShow(uiName) or XLuaUiManager.IsUiPushing(uiName) then
        return
    end
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_small)
    XLuaUiManager.Open(uiName, msg, isPlayEffect)
end

---@param key string
function XSkyTowerAgency:TipText(key)
    self:TipMsg(XUiHelper.GetText(key))
end

---@param code number
function XSkyTowerAgency:TipCode(code)
    self:TipMsg(CS.XTextManager.GetCodeText(code))
end

function XSkyTowerAgency:StrPos2Vector3(str, separator)
    if string.IsNilOrEmpty(str) then
        return Vector3.zero
    end
    local tmp = string.Split(str, separator)
    local num = {}
    for i = 1, 3 do
        local value = tmp[i]
        num[i] = str and tonumber(value) or 0
    end
    return Vector3(num[1], num[2], num[3])
end

function XSkyTowerAgency:CheckBaseOpen()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SkyTower) then
        return false
    end
    if not self:IsOpen() then
        return false
    end
    return true
end

--每日任务红点
function XSkyTowerAgency:CheckDailyTaskRedPoint()
    local timeLimitTaskIds = self._Model:GetActivityTimeLimitTaskIds()

    for _, timeLimitTaskId in ipairs(timeLimitTaskIds) do
        if XTaskConfig.IsTimeLimitTaskInTime(timeLimitTaskId) then
            local timeLimitTaskCfg = timeLimitTaskId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(timeLimitTaskId) or {}
            for _, taskId in ipairs(timeLimitTaskCfg.DayTaskId) do
                if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                    return true
                end
            end
        end
    end

    return false
end

--成就任务红点
function XSkyTowerAgency:CheckAchievementTaskRedPoint()
    local timeLimitTaskIds = self._Model:GetActivityTimeLimitTaskIds()

    for _, timeLimitTaskId in ipairs(timeLimitTaskIds) do
        if XTaskConfig.IsTimeLimitTaskInTime(timeLimitTaskId) then
            local timeLimitTaskCfg = timeLimitTaskId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(timeLimitTaskId) or {}
            for _, taskId in ipairs(timeLimitTaskCfg.TaskId) do
                if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                    return true
                end
            end
        end
    end

    return false
end

--任务入口
function XSkyTowerAgency:CheckTaskRedPoint()
    if not self:CheckBaseOpen() then
        return false
    end

    if self:CheckDailyTaskRedPoint() then
        return true
    end

    if self:CheckAchievementTaskRedPoint() then
        return true
    end

    return false
end

---当玩家距离上次进入玩法内过了Config中的MaxSettleTime时间，并且通天塔不处于最高等级时，开始游戏按钮右上方需要显示蓝点
function XSkyTowerAgency:CheckEnterBtnRedPoint()
    if not self:CheckBaseOpen() then
        return false
    end

    if not self:IsMaxLevel() then
        if not self._MaxSettleTime then
            self._MaxSettleTime = tonumber(self._Model:GetConfigValue("MaxSettleTime"))
        end

        if XTime.GetServerNowTimestamp() - self._Model:GetEntranceTime() > self._MaxSettleTime then
            return true
        end
    end

    if self:CheckPerformRedPoint() then
        return true
    end

    return false
end

function XSkyTowerAgency:CheckPerformRedPoint()
    local infos = self._Model:GetPerformInfos()
    if XTool.IsTableEmpty(infos) then
        return false
    end

    for performId in pairs(infos) do
        if self._Model.Perform:CheckPerformClaimReward(performId) then
            return true
        end
    end

    return false
end

function XSkyTowerAgency:CheckLevelUpRedPoint()
    if not self:CheckBaseOpen() then
        return false
    end

    if self:IsMaxLevel() then
        return false
    end

    local targetLv = self._Model:GetSkyTowerLv() + 1
    local template = self._Model:GetLvConfig(targetLv)
    local ownGoldCount = self._Model:GetGoldCount()

    if ownGoldCount < template.NeedGoldCount then
        return false
    end

    if XTool.IsNumberValid(template.ConditionId) and not XConditionManager.CheckCondition(template.ConditionId) then
        return false
    end

    return true
end

function XSkyTowerAgency:CheckEntranceRedPoint()
    if not self:CheckBaseOpen() then
        return false
    end

    if self:CheckTaskRedPoint() then
        return true
    end

    if self:CheckEnterBtnRedPoint() then
        return true
    end

    if self:CheckLevelUpRedPoint() then
        return true
    end

    return false
end

function XSkyTowerAgency:OnActivityEnd()
    --只有处于活动玩法内部，才提出玩家
    if self._InActivity then
        XLuaUiManager.RunMain()
        XUiManager.TipText("CommonActivityEnd")
    end
end

function XSkyTowerAgency:SetInActivity(inActivity)
    self._InActivity = inActivity
end

--endregion

--region 协议
--- 全量数据推送入口（活动重置等服务器主动变更时下发）
function XSkyTowerAgency:NotifySkyTowerData(notifyData)
    if not notifyData then
        return
    end
    self._Model:UpdateNotifyData(notifyData.ActivityData)
end

--- 角色信息增量推送
function XSkyTowerAgency:NotifySkyTowerCharacter(notifyData)
    if not notifyData then
        return
    end
    local changedCharacterInfos = notifyData.ChangedCharacterInfos
    if XTool.IsTableEmpty(changedCharacterInfos) then
        return
    end
    self._Model:UpdateCharacterInfos(changedCharacterInfos)
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE)
end

--- 演出信息增量推送
function XSkyTowerAgency:NotifySkyTowerPerform(notifyData)
    if not notifyData then
        return
    end
    self._Model:UpdatePerformInfos(notifyData.ChangedPerformInfos)
end

function XSkyTowerAgency:NotifySkyTowerLevel(notifyData)
    self._Model:UpdateSkyTowerLvLoginIn(notifyData.Level)
end

--- 每日加速次数重置推送
function XSkyTowerAgency:NotifySkyTowerSpeedUpDailyReset(notifyData)
    if not notifyData then
        return
    end
    self._Model:UpdateSpeedUpDailyUsedCount(notifyData.SpeedUpDailyUsedCount)
    self._Model:UpdateSpeedUpItemCount(notifyData.SpeedUpItemCount)
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_DAILY_RESET)
end

function XSkyTowerAgency:SkyTowerActivityDataRequest(responseCb)
    XNetwork.Call("SkyTowerActivityDataRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            self:TipCode(res.Code)
            return
        end
        self._Model:UpdateNotifyData(res.ActivityData)
        -- 离线收益服务端已直接入账并清零，这里只拿来展示账单
        self._Model:UpdateAccount(res.OfflineBill, res.OfflineTime, res.OfflineCharacterLvUpItemCount)
        if responseCb then
            responseCb()
        end
    end)
end

--endregion

return XSkyTowerAgency
