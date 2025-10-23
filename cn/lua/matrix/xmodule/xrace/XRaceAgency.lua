local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds

---@class XRaceAgency : XFubenActivityAgency
---@field private _Model XRaceModel
local XRaceAgency = XClass(XFubenActivityAgency, "XRaceAgency")

function XRaceAgency:OnInit()
    self._WaitTimers = {}
    self:RegisterActivityAgency()
end

function XRaceAgency:InitRpc()
    XRpc.NotifyRacePlayerDataDb = handler(self, self.NotifyRacePlayerDataDb)
    XRpc.NotifyRaceRoundConfig = handler(self, self.NotifyRaceRoundConfig) --RaceRound表被放到etcd里面（热更） 客户端读不到 由服务端下发
    XRpc.NotifyRaceRoundStart = handler(self, self.NotifyRaceRoundStart)
    XRpc.NotifyRaceRoundEnd = handler(self, self.NotifyRaceRoundEnd)
end

function XRaceAgency:InitEvent()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self.CheckOpenMainTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.CloseMainTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UICHAT_ENABLE, self.CheckOpenChatTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UICHAT_DISABLE, self.CloseChatTip, self)
end

----------public start----------

function XRaceAgency:GetCurrentConfig()
    if not self._Model.ActivityId then
        return nil
    end
    return self._Model:GetActivityById(self._Model.ActivityId)
end

function XRaceAgency:IsInActivity()
    local activity = self:GetCurrentConfig()
    if activity then
        return XFunctionManager.CheckInTimeByTimeId(activity.TimeId) and self._Model:IsExistEtcdConfig()
    end
    return false
end

function XRaceAgency:OpenMain()
    local emptyReq = {}
    XNetwork.CallWithAutoHandleErrorCode("RaceGetMainPlainRequest", emptyReq, function(res)
        self._Model:UpdateBasePlayerData(res.RaceDataDb, res.RoundId)
        XNetwork.CallWithAutoHandleErrorCode("RaceGetAllRoundResultRequest", emptyReq, function(res)
            self._Model:UpdateAllRoundResult(res)
            XLuaUiManager.Open("UiRaceMain")
        end)
    end)
end

--region 场景相关--------------------------------------------------
function XRaceAgency:OpenLoading(maxPercentage, time)
    if self._IsShowLoading then return end
    self._IsShowLoading = true
    XLuaUiManager.Open("UiRaceFightLoading")
end

function XRaceAgency:CloseLoading()
    if not self._IsShowLoading then return end
    XLuaUiManager.Close("UiRaceFightLoading")
    self._IsShowLoading = false
end

-- 进入场景
function XRaceAgency:EnterMatchScene(...)
    self:OpenLoading()
    XMVCA.XScene:LoadScene(SceneIds.XRaceScene, true, nil, nil, ...)
end

-- 离开场景
function XRaceAgency:LeaveMatchScene()
    XMVCA.XScene:ExitScene(SceneIds.XRaceScene)
end

function XRaceAgency:GetRaceStartTime()
    local roundId = self._Model:GetCurRound()
    if roundId == -1 then
        return -1
    end
    local etcd = self._Model:GetEtcdRoundConfig(roundId)
    if not etcd then
        return -1
    end
    return etcd.StartTimeLong
end

--endregion

----------public end----------

----------副本扩展----------

function XRaceAgency:ExOpenMainUi()
    if not self:GetIsOpen() then
        return false
    end
    -- 打开主界面
    self:OpenMain()
    return true
end

function XRaceAgency:ExCheckInTime()
    if not self.Super.ExCheckInTime(self) then
        return false
    end
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XRaceAgency:ExGetProgressTip()
    return ""
end

function XRaceAgency:ExGetRunningTimeStr()
    local isInGameTime = self:CheckActivityIsInGameTime()
    if isInGameTime then
        local timeId = self:GetActivityTimeId()
        local gameEndTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        local gameTime = gameEndTime - XTime.GetServerNowTimestamp()
        local timeStr = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
        return XUiHelper.GetText("RaceResetTime", timeStr)
    else
        return XUiHelper.GetText("RaceActivityEnd")
    end
end

function XRaceAgency:ExGetRightMidCustomText()
    if not self:GetIsOpen() then
        return nil
    end
    local roundId = self._Model:GetCurRound()
    if roundId == -1 then
        return nil
    end
    local etcd = self._Model:GetEtcdRoundConfig(roundId)
    local leftTime = etcd.StartTimeLong - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        return XUiHelper.GetText("RaceRightMidRunning")
    end
    local leftMinute = math.ceil(leftTime / 60)
    if leftMinute > self._Model:GetMainRightMidShowTime() then
        return nil
    end
    return XUiHelper.GetText("RaceRightMidStartTime", leftMinute)
end

---活动是否开启
function XRaceAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Race, false, noTips) then
        return false
    end
    if not self:IsInActivity() then
        if not noTips then
            XUiManager.TipText("CommonActivityNotStart")
        end
        return false
    end
    return true
end

function XRaceAgency:GetActivityTimeId()
    if not self._Model.ActivityId then
        return 0
    end
    return self._Model:GetActivityById(self._Model.ActivityId).TimeId
end

---检查是否处于活动的游戏时间
function XRaceAgency:CheckActivityIsInGameTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XRaceAgency:FinishFight(settleData)

end

----------副本扩展 end----------

----------private start----------

function XRaceAgency:NotifyRacePlayerDataDb(data)
    self._Model:NotifyRacePlayerDataDb(data)
    if self._Model._EtcdRoundConfigs then
        self:CheckOpenMainTip()
    end
end

function XRaceAgency:NotifyRaceRoundConfig(data)
    self._Model:NotifyRaceRoundConfig(data)
    if self._Model._CurRoundId then
        self:CheckOpenMainTip()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_RACE_TIME_UPDATE)
end

function XRaceAgency:NotifyRaceRoundStart(data)
    self._Model:NotifyRaceRoundStart(data)
    XEventManager.DispatchEvent(XEventId.EVENT_RACE_GAME_START)
end

function XRaceAgency:NotifyRaceRoundEnd(data)
    if XLuaUiManager.IsUiShow("UiRaceFightMain") then
        return --走局内的结算逻辑
    end
    XEventManager.DispatchEvent(XEventId.EVENT_RACE_GAME_END, data.RoundId)
end

--region 飘字

function XRaceAgency:IsTipHasShow(uiType, id)
    return self._Model:IsTipHasShow(uiType, id)
end

function XRaceAgency:SetTipShow(uiType, id)
    self._Model:SetTipShow(uiType, id)
end

function XRaceAgency:GetSortBroadcasts(uiType)
    return self._Model:GetSortBroadcasts(uiType)
end

function XRaceAgency:GetCurRound()
    return self._Model:GetCurRound()
end

function XRaceAgency:GetEtcdRoundConfig(roundId)
    return self._Model:GetEtcdRoundConfig(roundId)
end

function XRaceAgency:ParseToTimestamp(timeStr)
    return self._Model:ParseToTimestamp(timeStr)
end

-- UiMain的OnEnable时机可能比协议下发快
function XRaceAgency:CheckOpenMainTip()
    local inMainUi = XLuaUiManager.IsUiShow("UiMain") and XLuaUiManager.GetTopUiName() == "UiMain"
    if not inMainUi then
        return
    end
    if XLuaUiManager.IsUiLoad("UiChatServeMain") then
        -- 避免从聊天横幅跳转活动主界面，然后点返回按钮时，同时出现2个横幅导致层级出问题
        return
    end
    self:CheckTip(XEnumConst.Race.Tip.Main)
end

function XRaceAgency:CheckOpenChatTip()
    local inMainUi = XLuaUiManager.IsUiShow("UiChatServeMain") and XLuaUiManager.GetTopUiName() == "UiChatServeMain"
    if not inMainUi then
        return
    end
    self:CheckTip(XEnumConst.Race.Tip.Chat)
end

function XRaceAgency:CheckTip(tipType)
    local timer = self._WaitTimers[tipType]
    if timer then
        XScheduleManager.UnSchedule(timer)
        self._WaitTimers[tipType] = nil
    end
    if not self:GetIsOpen(true) then
        return
    end
    local configs = self._Model:GetSortBroadcasts(tipType)
    if XTool.IsTableEmpty(configs) then
        return
    end
    local roundId = self._Model:GetCurRound()
    if not roundId or roundId == -1 then
        return
    end
    local etcd = self._Model:GetEtcdRoundConfig(roundId)
    if not etcd then
        XLog.Error(string.format("【赛马】检查播报时找不到RoundId=%s的etcd配置", roundId))
        return
    end
    local nowTime = XTime.GetServerNowTimestamp()
    local startTime = etcd.StartTimeLong
    local leftMinute = math.max(startTime - nowTime, 0) / 60
    for i, v in ipairs(configs) do
        if leftMinute <= v.BeforeTime then
            if not self._Model:IsTipHasShow(tipType, v.Id) then
                self._Model:SetTipShow(tipType, v.Id)
                if not self:IsTipShowing(tipType) then
                    self:SetTipShowing(tipType, true)
                    XLuaUiManager.Open("UiRaceToastHall", v, tipType)
                end
            end
            -- 倒计时显示下一条播报
            if i > 1 then
                local nextTime = startTime - configs[i - 1].BeforeTime * 60
                local waitTime = (nextTime - nowTime) * 1000
                self._WaitTimers[tipType] = XScheduleManager.ScheduleOnce(handler(self, self.CheckOpenMainTip), waitTime)
            end
            break
        end
    end
end

--todo 停服公告出现时隐藏
function XRaceAgency:CloseMainTip()
    self:CloseTip(XEnumConst.Race.Tip.Main)
end

function XRaceAgency:CloseChatTip()
    self:CloseTip(XEnumConst.Race.Tip.Chat)
end

function XRaceAgency:CloseTip(tipType)
    local timer = self._WaitTimers[tipType]
    if timer then
        XScheduleManager.UnSchedule(timer)
        self._WaitTimers[tipType] = nil
    end
end

---横幅是否正在显示
function XRaceAgency:SetTipShowing(tipType, isShowing)
    if not self._TipShowDict then
        self._TipShowDict = {}
    end
    self._TipShowDict[tipType] = isShowing
end

function XRaceAgency:IsTipShowing(tipType)
    return self._TipShowDict and self._TipShowDict[tipType]
end

--endregion

--region 红点
function XRaceAgency:CheckTaskRedPoint()
    if self:GetIsOpen(true) then
        local taskId = self:GetCurrentConfig().TaskTimeLimitId
        local taskDatas = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskId)
        for _, value in pairs(taskDatas) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(value.Id)
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
    end
    return false
end

function XRaceAgency:CheckMatchGuessRedpoint()
    if self:GetIsOpen(true) then
        local activity = self:GetCurrentConfig()
        local nowTime = XTime.GetServerNowTimestamp()
        local matchGuessEndTime = XFunctionManager.GetEndTimeByTimeId(activity.MatchGuessTime)
        if nowTime <= matchGuessEndTime then
            --预测时间是否结束
            local matchGuess = activity.MatchGuess
            local playerData = self._Model:GetBasePlayerData()
            if playerData and playerData.GlobalGuessDict then
                for _, id in ipairs(matchGuess) do
                    local info = playerData.GlobalGuessDict[id]
                    if not (info and (XTool.IsNumberValid(info.CharacterId) or XTool.IsNumberValid(info.OptionId))) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function XRaceAgency:CheckRoundGuessRedPoint()
    if self:GetIsOpen(true) then
        local hasPredicted = {}
        local curRoundId = self._Model:GetCurRound()
        local playerData = self._Model:GetBasePlayerData()
        
        if playerData and playerData.RoundGuessDict then
            for roundId, v in pairs(playerData.RoundGuessDict) do
                local infoDict = v.RaceRoundGuessInfoDict
                if infoDict then
                    for guessId, info in pairs(infoDict) do
                        if info.GuessState == XEnumConst.Race.GuessState.GuessSuccess and not info.IsGain then
                            return true --有奖励未领取
                        end
                        if curRoundId == roundId then
                            if XTool.IsNumberValid(info.CharacterId) or XTool.IsNumberValid(info.OptionId) then
                                --已预测选项
                                hasPredicted[guessId] = true
                            end
                        end
                    end
                end
            end
        end
        
        if curRoundId ~= -1 then
            --当前比赛所有预测选项
            local etcd = self._Model:GetEtcdRoundConfig(curRoundId)
            if etcd then
                for _, guessId in pairs(etcd.Guess) do
                    if not hasPredicted[guessId] then
                        return true
                    end
                end
            end
        end
    end
    return false
end
--endregion

----------private end----------

return XRaceAgency