local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XSkyTowerAgency : XFubenActivityAgency
---@field private _Model XSkyTowerModel
local XSkyTowerAgency = XClass(XFubenActivityAgency, "XSkyTowerAgency", true)

local IsShopComplete
local IsEnterActivity
local CsClamp = CS.UnityEngine.Mathf.Clamp

--region 部分类初始化
XClassPartialRequire("XModule/XSkyTower/XAgencyPartial/XSkyTowerAgencyEnum", "XSkyTowerAgency")
XClassPartialRequire("XModule/XSkyTower/XAgencyPartial/XSkyTowerAgencyScene", "XSkyTowerAgency")
--endregion

function XSkyTowerAgency:OnInit()
    self:RegisterActivityAgency()
    self:InitScene()
    self.IsInitOnce = false --只会初始化一次
    self._InActivity = false --是否处于活动玩法中
    IsShopComplete = nil
    IsEnterActivity = nil
    self.RichTextImageCallBack = handler(self, self.OnRichTextImageCallBack)
end

function XSkyTowerAgency:OnLoginOut()
    IsShopComplete = nil
    IsEnterActivity = nil
end

function XSkyTowerAgency:InitRpc()
    XRpc.NotifySkyTowerData = handler(self, self.NotifySkyTowerData) --仅用于活动重置等服务器主动变更
    XRpc.NotifySkyTowerCharacter = handler(self, self.NotifySkyTowerCharacter)
    XRpc.NotifySkyTowerPerform = handler(self, self.NotifySkyTowerPerform)
    XRpc.NotifySkyTowerLevel = handler(self, self.NotifySkyTowerLevel)
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
        self:LoadScene()
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
function XSkyTowerAgency:TipMsg(msg)
    if not msg then
        XLog.Error("XSkyTowerAgency:TipMsg error, msg is nil")
        return
    end
    local uiName = "UiSkyTowerRadio"
    if XLuaUiManager.IsUiShow(uiName) or XLuaUiManager.IsUiPushing(uiName) then
        return
    end
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_small)
    XLuaUiManager.Open(uiName, msg)
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

--- 埋点（XRecord，暂未启用，UI仍有调用故保留空桩）
function XSkyTowerAgency:Burying(btnId, uiName)
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

--- 食谱任务红点（3期通天塔不配置食谱任务，恒false）
function XSkyTowerAgency:CheckRecipeTaskRedPoint()
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
    if self:CheckRecipeTaskRedPoint() then
        return true
    end
    return false
end

function XSkyTowerAgency:CheckIndentRedPoint()
    return false
end

function XSkyTowerAgency:CheckPerformRedPoint()
    return false
end

function XSkyTowerAgency:CheckEntranceRedPoint()
    if not self:CheckBaseOpen() then
        return false
    end

    if IsShopComplete == nil and self:CheckShopOpen() then
        self:CheckShopComplete()
        return false
    end

    --策划要求-商店购买完成后，外部红点全部关闭
    if IsShopComplete then
        return false
    end

    if not self._Model:IsActivityInTime() then
        return false
    end

    if self:CheckIsFirstEnter() then
        return true
    end

    if self:CheckTaskRedPoint() then
        return true
    end

    if self:CheckIndentRedPoint() then
        return true
    end

    if self:CheckPerformRedPoint() then
        return true
    end

    return false
end

function XSkyTowerAgency:CheckIsFirstEnter()
    if IsEnterActivity then
        return false
    end
    if self._Model:IsFirstEnterActivity() then
        return true
    end
    IsEnterActivity = true
    return false
end

function XSkyTowerAgency:MarkFirstEnterActivity()
    if IsEnterActivity then
        return
    end
    if not self._Model:IsFirstEnterActivity() then
        return
    end

    self._Model:MarkFirstEnterActivity()
    IsEnterActivity = true
end

function XSkyTowerAgency:CheckShopOpen()
    local functionId = XFunctionManager.FunctionName.ShopCommon
    return XFunctionManager.JudgeCanOpen(functionId) and XFunctionManager.JudgeOpen(functionId)
end

function XSkyTowerAgency:CheckShopComplete(cb)
    if IsShopComplete ~= nil then
        if cb then
            cb(IsShopComplete)
        end
    end
    if not self:CheckShopOpen() then
        if cb then
            cb(false)
        end
        return
    end
    local shopId = self._Model:GetActivityShopId()
    if not XTool.IsNumberValid(shopId) then
        if cb then
            cb(false)
        end
        return
    end

    IsShopComplete = false
    XShopManager.GetShopInfo(shopId, function()
        local goodsList = XShopManager.GetShopGoodsList(shopId, true, true)
        local complete = true
        for _, goods in ipairs(goodsList) do
            --不限制次数, 商店无法购买完成 || 购买次数小于上限
            if goods.BuyTimesLimit <= 0 or (goods.TotalBuyTimes < goods.BuyTimesLimit) then
                complete = false
                break
            end
        end
        IsShopComplete = complete
        if cb then
            cb(complete)
        end
    end, true)
end

function XSkyTowerAgency:ClearShotComplete()
    --如果已经完成了，就不需要清除了
    if IsShopComplete then
        return
    end
    IsShopComplete = nil
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

function XSkyTowerAgency:SkyTowerActivityDataRequest(responseCb)
    XNetwork.Call("SkyTowerActivityDataRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            self:TipCode(res.Code)
            return
        end
        self._Model:UpdateNotifyData(res.ActivityData)
        -- 离线收益服务端已直接入账并清零，这里只拿来展示账单
        self._Model:UpdateAccount(res.OfflineBill, res.OfflineTime, res.OfflineCharacterLvUpItemCount)
        self:MarkFirstEnterActivity()
        if responseCb then
            responseCb()
        end
    end)
end

--endregion

return XSkyTowerAgency
