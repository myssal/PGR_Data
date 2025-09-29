local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")

---@class XTheatre5Agency : XFubenActivityAgency
---@field private _Model XTheatre5Model
---@field FlowController XTheatre5FlowController
---@field PVEAgency XTheatre5PVEAgency
local XTheatre5Agency = XClass(XFubenSimulationChallengeAgency, "XTheatre5Agency")

function XTheatre5Agency:OnInit()
    self.EnumConst = require('XModule/XTheatre5/XTheatre5EnumConst')
    self.EventId = require('XModule/XTheatre5/XTheatre5EventId')

    ---@type XTheatre5PVPAgencyCom
    self.PVPCom = require('XModule/XTheatre5/PVP/XTheatre5PVPAgencyCom').New()
    self.PVPCom:Init(self, self._Model)
    self.PVEAgency = require('XModule/XTheatre5/PVE/XTheatre5PVEAgency').New()
    self.PVEAgency:Init(self, self._Model)

    ---@type XTheatre5BattleAgencyCom
    self.BattleCom = require('XModule/XTheatre5/Common/XTheatre5BattleAgencyCom').New()
    self.BattleCom:Init(self, self._Model)

    self:RegisterChapterAgency()
end

function XTheatre5Agency:InitRpc()
    XRpc.NotifyTheatre5ActivityData = handler(self, self.OnNotifyTheatre5ActivityData)
    XRpc.NotifyTheatre5UnlockCharacter = handler(self, self.OnNotifyTheatre5UnlockCharacter)
    XRpc.NotifyTheatre5AdventureData = handler(self, self.OnNotifyTheatre5AdventureData)
    XRpc.NotifyTheatre5ShopUpdate = handler(self, self.OnNotifyTheatre5ShopUpdate)
    XRpc.NotifyTheatre5SkillChoiceUpdate = handler(self, self.OnNotifyTheatre5SkillChoiceUpdate)
    XRpc.NotifyPveStoryLineUnlock = handler(self, self.OnNotifyPveStoryLineUnlock)
    XRpc.NotifyTheatre5AddItem = handler(self, self.OnNotifyTheatre5AddItem)
    XRpc.NotifyTheatre5BagDataUpdate = handler(self, self.OnNotifyTheatre5BagDataUpdate)
end

function XTheatre5Agency:InitEvent()
    XMVCA.XDlcHelper:AddDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.AutoChess, self)
end

function XTheatre5Agency:RemoveEvent()

end

function XTheatre5Agency:OnRelease()
    self.PVPCom:Release()
    self.PVPCom = nil
    self.PVEAgency:Release()
    self.PVEAgency = nil
    self.BattleCom:Release()
    self.BattleCom = nil

    XMVCA.XDlcHelper:RemoveDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.AutoChess, self)

end

--region overrride

function XTheatre5Agency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.Theatre5
end

function XTheatre5Agency:ExOpenMainUi()
    if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.Theatre5) then
        return false
    end

    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true) then
        if self:ExCheckInTime() and self._Model:GetHasActivityData() then
            self:PlayMainVideo(function()
                XLuaUiManager.Open('UiTheatre5Main')
            end)
            return true
        else
            XUiManager.TipText('CommonActivityNotStart')
        end
    end

    return false
end

function XTheatre5Agency:GetMainVideoId()
    return self._Model:GetTheatre5ConfigValByKey('MainVideoId')
end

function XTheatre5Agency:IsNeedPlayMainVideo()
    local videoId = self:GetMainVideoId()
    if not XTool.IsNumberValid(videoId) then
        return false
    end
    local result = XSaveTool.GetData(string.format("Theatre5_MainVideo_%s", XPlayer.Id))
    if result == true then
        return false
    end
    return true
end

function XTheatre5Agency:PlayMainVideo(cb)
    if self:IsNeedPlayMainVideo() then
        XLuaVideoManager.PlayUiVideo(self:GetMainVideoId(), function()
            XSaveTool.SaveData(string.format("Theatre5_MainVideo_%s", XPlayer.Id), true)
            if cb then
                cb()
            end
        end, true, true)
    else
        if cb then
            cb()
        end
    end
end

--- 通用跳转接口（SkipId）
---@param skipDatas XTable.XTableSkipFunctional
function XTheatre5Agency:ExOnSkip(skipDatas)
    if self:ExOpenMainUi() then
        return true
    end

    return false
end

--endregion

--region ViewModel

--- 是否有限时显示
function XTheatre5Agency:ExCheckInTimerShow()
    local timeId = self:GetPVPActivityTimeId()

    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

--- 限时显示文本
function XTheatre5Agency:ExGetTimerShowStr()
    local timeId = self:GetPVPActivityTimeId()

    if XTool.IsNumberValid(timeId) then
        local now = XTime.GetServerNowTimestamp()
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        local leftTime = math.max(endTime - now, 0)

        return XUiHelper.FormatText(self._Model:GetTheatre5ClientConfigText('EntranceTimeLabel'), XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    else
        return ''
    end
end

--endregion

--region Network - BattleShop

--- 技能三选一
function XTheatre5Agency:RequestTheatre5SkillChoice(instanceId, isEquipped, targetIndex, cb)
    XNetwork.Call("XTheatre5SkillChoiceRequest", { InstanceId = instanceId, IsEquipped = isEquipped, TargetIndex = targetIndex }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            -- 保底同步状态
            if XTool.IsNumberValid(res.Status) then
                self._Model.CurAdventureData:UpdateCurPlayStatus(res.Status)

                if res.Status == XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping then
                    self._Model.CurAdventureData:UpdateFullSkillChoiceData(nil)
                end
            end

            if cb then
                cb(false)
            end

            return
        end

        local newStatus = XTool.IsNumberValid(res.Status) and res.Status or XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping

        self._Model.CurAdventureData:UpdateCurPlayStatus(newStatus)
        -- 清空技能三选一数据
        self._Model.CurAdventureData:UpdateFullSkillChoiceData(nil)

        if cb then
            cb(true)
        end
    end)
end

--- 购买背包槽位
function XTheatre5Agency:RequestTheatre5ShopUnlockGridRequest(itemType, cb)
    XNetwork.Call("XTheatre5ShopUnlockGridRequest", { GridType = itemType }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateFullBagData(res.BagData)
        self._Model.CurAdventureData:UpdateGoldNum(res.GoldNum)

        if cb then
            cb(true)
        end
    end)
end

--- 请求进入商店
function XTheatre5Agency:RequestTheatre5EnterShop(cb)
    XNetwork.Call("Theatre5EnterShopRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateCurPlayStatus(res.Status)

        if cb then
            cb(true)
        end
    end)
end

--- 请求购买商品
function XTheatre5Agency:RequestTheatre5ShopBuyItem(instanceId, isEquipped, targetIndex, cb)
    XNetwork.Call("XTheatre5ShopBuyItemRequest", { InstanceId = instanceId, IsEquipped = isEquipped, TargetIndex = targetIndex }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateGoldNum(res.GoldNum)
        self._Model.CurAdventureData:UpdateFullBagData(res.BagData)
        self._Model.CurAdventureData:UpdateFullShopData(res.ShopData)

        if cb then
            cb(true)
        end
    end)
end

--- 请求卖出商品
function XTheatre5Agency:RequestTheatre5ShopSellItem(instanceId, itemType, isEquipped, cb)
    XNetwork.Call("XTheatre5ShopSellItemRequest", { InstanceId = instanceId, IsEquipped = isEquipped, ItemType = itemType }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateGoldNum(res.GoldNum)
        self._Model.CurAdventureData:UpdateFullBagData(res.BagData)
        self._Model.CurAdventureData:UpdateFullShopData(res.ShopData)

        if cb then
            cb(true)
        end
    end)
end

--- 请求刷新商店
function XTheatre5Agency:RequestTheatre5ShopRefresh(cb)
    XNetwork.Call("XTheatre5ShopRefreshRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateFullShopData(res.ShopData)
        self._Model.CurAdventureData:UpdateGoldNum(res.GoldNum)

        if cb then
            cb(true)
        end
    end)
end

--- 请求整理背包中物品的位置
function XTheatre5Agency:RequestTheatre5BagItemMove(instanceId, itemType, srcEquipped, srcIndex, srcIsTempItem, targetEquipped, targetIndex, cb)
    local content = {
        InstanceId = instanceId,
        ItemType = itemType,
        SrcEquipped = srcEquipped,
        SrcIndex = srcIndex,
        SrcIsTempItem = srcIsTempItem,
        TargetEquipped = targetEquipped,
        TargetIndex = targetIndex
    }

    XNetwork.Call("XTheatre5BagItemMoveRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateFullBagData(res.BagData)

        if cb then
            cb(true)
        end
    end)
end

--- 请求设置商品冻结状态
function XTheatre5Agency:RequestTheatre5ShopFreeze(instanceId, isFreeze, cb)
    XNetwork.Call("XTheatre5ShopFreezeRequest", { InstanceId = instanceId, IsFreeze = isFreeze }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateFullShopData(res.ShopData)

        if cb then
            cb(true)
        end
    end)
end

function XTheatre5Agency:RequestPveOrPvpChange(cb)
    XNetwork.Call("PveOrPvpChangeRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end
        self._Model:ChangePlayingMode()
        if cb then
            cb(true)
        end
    end)
end

--endregion

--region Network - Fight
function XTheatre5Agency:RequestDlcSingleEnterFight(worldId, levelId, cb)
    XNetwork.Call("DlcSingleEnterFightRequest", { WorldId = worldId, LevelId = levelId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        if cb then
            cb(true, res.WorldData)
        end
    end)
end
--endregion

--region Network - Rpc

function XTheatre5Agency:OnNotifyTheatre5ActivityData(data)
    if XTool.IsTableEmpty(data) then
        self._Model:SetHasActivityData(false)
        return
    end

    local theatre5DataDb = data.Theatre5DataDb

    self._Model:SetHasActivityData(not XTool.IsTableEmpty(data.Theatre5DataDb))
    self._Model:SetActivityId(theatre5DataDb.ActivityId)
    self._Model:SetCurPlayingMode(theatre5DataDb.PvpType)
    self._Model.PVPAdventureData:UpdatePVPAdventureData(theatre5DataDb.PvpAdventureData)
    self._Model.PVPCharacterData:UpdatePVPCharacters(theatre5DataDb.Characters)
    self._Model.PVEAdventureData:UpdatePVEAdventureData(theatre5DataDb.PveAdventureData)

    --rouge
    self._Model.PVERougeData:UpdatePveCharacters(theatre5DataDb.PveCharacters)
    self._Model.PVERougeData:UpdateCurStoryLineId(theatre5DataDb.CurPveStoryLineId)
    self._Model.PVERougeData:UpdateCurStoryEntranceId(theatre5DataDb.CurStoryEntranceId)
    self._Model.PVERougeData:UpdatePveStoryLines(theatre5DataDb.PveStoryLines)
    self._Model.PVERougeData:UpdatePveClues(theatre5DataDb.PveClues)
    self._Model.PVERougeData:UpdatePveScripts(theatre5DataDb.PveScripts)
    self._Model.PVERougeData:UpdateHistoryChapters(theatre5DataDb.HistoryChapters)

    self._Model:SetCharacterWinGameCountData(theatre5DataDb.CommonFightCnt)
end

function XTheatre5Agency:OnNotifyTheatre5UnlockCharacter(data)
    self._Model.PVPCharacterData:UpdatePVPCharacters(data.PvpCharacters)
    self._Model.PVERougeData:UpdatePveCharacters(data.PveCharacters)
end

function XTheatre5Agency:OnNotifyTheatre5AdventureData(data)
    self._Model.PVPAdventureData:UpdatePVPAdventureData(data.PvpAdventureData)
end

function XTheatre5Agency:OnNotifyTheatre5ShopUpdate(data)
    self._Model.CurAdventureData:UpdateGoldNum(data.GoldNum)
    self._Model.CurAdventureData:UpdateFullShopData(data.ShopData)
    self._Model.CurAdventureData:UpdateFullBagData(data.BagData)
end

function XTheatre5Agency:OnNotifyTheatre5SkillChoiceUpdate(data)
    self._Model.CurAdventureData:UpdateGoldNum(data.GoldNum)
    self._Model.CurAdventureData:UpdateFullBagData(data.BagData)
    self._Model.CurAdventureData:UpdateFullSkillChoiceData(data.SkillChoiceData)
end

function XTheatre5Agency:OnNotifyPveStoryLineUnlock(data)
    self._Model.PVERougeData:UpdateUnlockStoryLine(data.PveStoryLines)
end

function XTheatre5Agency:OnNotifyTheatre5AddItem(data)

end

function XTheatre5Agency:OnNotifyTheatre5BagDataUpdate(data)
    self._Model.CurAdventureData:UpdateCurPlayStatus(data.Status)
    self._Model.CurAdventureData:UpdateGoldNum(data.GoldNum)
    self._Model.CurAdventureData:UpdateFullBagData(data.BagData)
end

--endregion

--region Network - Characters

function XTheatre5Agency:RequestTheatre5CharacterSkinSet(characterId, fashionId, cb)
    XNetwork.Call('Theatre5CharacterSkinSetRequest', { CharacterId = characterId, FashionId = fashionId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        --todo 角色定义抽取基类
        if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameModel.PVP then
            self._Model.PVPCharacterData:UpdateCharacterFashionId(characterId, fashionId)
        else

        end

        if cb then
            cb(true)
        end
    end)
end

--endregion

--region Config - Battle

function XTheatre5Agency:GetTheatre5ItemCfgById(id)
    return self._Model:GetTheatre5ItemCfgById(id)
end

function XTheatre5Agency:GetTheatre5ItemTagCfgById(id)
    return self._Model:GetTheatre5ItemTagCfgById(id)
end

function XTheatre5Agency:GetTheatre5ItemRuneAttrCfgById(id)
    return self._Model:GetTheatre5ItemRuneAttrCfgById(id)
end

function XTheatre5Agency:GetTheatre5AttrShowCfgByType(type)
    return self._Model:GetTheatre5AttrShowCfgByType(type)
end

function XTheatre5Agency:GetTheatre5ItemKeyWordCfgById(id)
    return self._Model:GetTheatre5ItemKeyWordCfgById(id)
end

--- 宝珠品质颜色配置
function XTheatre5Agency:GetClientConfigGemQualityColor(quality)
    return self._Model:GetClientConfigGemQualityColor(quality)
end
--endregion

--region getData
function XTheatre5Agency:GetCurPlayingMode()
    return self._Model:GetCurPlayingMode()
end

function XTheatre5Agency:GetPVPActivityTimeId()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetTheatre5ActivityCfgById(activityId)

        if cfg then
            return cfg.TimeId
        end
    end
end

function XTheatre5Agency:CheckInPVPActivityTime()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetTheatre5ActivityCfgById(activityId)

        if cfg then
            return XFunctionManager.CheckInTimeByTimeId(cfg.TimeId)
        end
    end

    return false
end

--- 判断指定角色是否达成指定的段位
function XTheatre5Agency:CheckCharacterIsAchieveAimRank(charaId, rankId)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true, true) then
        return false
    end

    -- PVP未开启时默认未达成
    if not self:CheckInPVPActivityTime() then
        return false
    end

    -- 指定段位对应的下限积分
    ---@type XTableTheatre5Rank
    local rankCfg = self._Model:GetTheatre5RankCfgById(rankId)

    if rankCfg then
        if XTool.IsNumberValid(charaId) then
            ---@type XTheatre5PVPCharacter
            local charaData = self._Model.PVPCharacterData:GetPVPCharacterById(charaId)

            if charaData then
                return charaData.Rating >= rankCfg.Rating
            end
        else
            local charaDataList = self._Model.PVPCharacterData:GetPVPCharacters()

            if not XTool.IsTableEmpty(charaDataList) then
                for i, v in pairs(charaDataList) do
                    if v.Rating >= rankCfg.Rating then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--- 判断指定角色的胜利次数是否达到指定值
function XTheatre5Agency:CheckCharacterIsAchieveAimWinFightCount(charaId, winCount)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true, true) then
        return false
    end

    if XTool.IsNumberValid(charaId) then
        return self._Model:GetCharacterWinGameCountById(charaId) >= winCount
    else
        -- 不指定角色时表示所有角色合计胜利次数
        local totalWinCount = 0
        local data = self._Model:GetCharacterWinGameCountData()

        if not XTool.IsTableEmpty(data) then
            for i, v in pairs(data) do
                totalWinCount = totalWinCount + v
            end

            return totalWinCount >= winCount
        end
    end

    return false
end
--endregion

function XTheatre5Agency:TryPopupDialog(title, content, closeCb, sureCb, cancelCb, needDailyIgnoreCheck, dailyIgnoreKey, hideFullClose)
    if needDailyIgnoreCheck then
        --todo: 暂无具体需求，先不处理
    end

    XLuaUiManager.Open('UiTheatre5PopupCommon', title, content, closeCb, sureCb, cancelCb, dailyIgnoreKey, hideFullClose)
end

function XTheatre5Agency:TryPopupDialogWithOneBtn(title, content, closeCb, sureCb, needDailyIgnoreCheck, dailyIgnoreKey, hideFullClose)
    if needDailyIgnoreCheck then
        --todo: 暂无具体需求，先不处理
    end

    XLuaUiManager.Open('UiTheatre5PopupCommon', title, content, closeCb, sureCb, nil, dailyIgnoreKey, hideFullClose, true)
end

--- 根据玩法自定义的fashionId返回模型Id
function XTheatre5Agency:GetModelIdByFashionId(fashionId)
    local fashionCfg = self._Model:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.DlcModelId
    end
end

--- 根据玩法自定义的fashionId返回头像
function XTheatre5Agency:GetPortraitByFashionId(fashionId)
    local fashionCfg = self._Model:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.Portrait
    end
end

function XTheatre5Agency:ExGetDlcModelIdByCharacterData(characterData)
    local fashionId = characterData.FashionId

    if XTool.IsNumberValid(fashionId) then
        return self:GetModelIdByFashionId(fashionId)
    end
end

function XTheatre5Agency:ExGetDlcPortraitByCharacterIdAndFashionId(templateId, fashionId)
    if not XTool.IsNumberValid(fashionId) then
        local cfg = self._Model:GetTheatre5CharacterCfgById(templateId)

        if cfg then
            fashionId = cfg.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Default]
        end
    end

    if XTool.IsNumberValid(fashionId) then
        return self:GetPortraitByFashionId(fashionId)
    end
end

function XTheatre5Agency:CheckShopConfigCanBuyGoods(shopCfg)
    --商店过期
    if not XFunctionManager.CheckInTimeByTimeId(shopCfg.TimeLimitId) then
        return false
    end
    local currencyCoinId = self:GetActivityCoinInActivity()
    --货币过期
    if not XTool.IsNumberValid(currencyCoinId) then
        return false
    end
    --取消掉打印，防止策划前后端配置不一致，红点每秒检测打印    
    local shopDatas = XShopManager.GetShopGoodsList(shopCfg.ShopId, true)
    if XTool.IsTableEmpty(shopDatas) then
        return false
    end
    for _, shopData in pairs(shopDatas) do
        --还有购买次数
        if shopData.TotalBuyTimes < shopData.BuyTimesLimit then
            --解锁了
            local isLock = false
            for _, v in pairs(shopData.ConditionIds) do
                local ret = XConditionManager.CheckCondition(v)
                if not ret then
                    isLock = true
                    break
                end
            end
            if not isLock then
                for _, priceData in pairs(shopData.ConsumeList) do
                    local itemCount = XDataCenter.ItemManager.GetCount(priceData.Id)
                    --钱够了
                    if itemCount >= priceData.Count then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--限时能对换商品
function XTheatre5Agency:CheckLimitShopCanBuyGoods()
    local limitShopId = self._Model:GetTheatre5ConfigValByKey('Theatre5LimitShop')
    if not XTool.IsNumberValid(limitShopId) then
        return false
    end
    local shopCfg = self._Model:GetTaskOrShopCfg(limitShopId)
    if not shopCfg then
        return false
    end
    return self:CheckShopConfigCanBuyGoods(shopCfg)
end

--获取活动时间内的限时货币
function XTheatre5Agency:GetActivityCoinInActivity()
    local activityId = self._Model:GetActivityId()
    if XTool.IsNumberValid(activityId) then
        local activityCfg = self._Model:GetTheatre5ActivityCfgById(activityId)
        if XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId) and XTool.IsNumberValid(activityCfg.ActivityCoin) then
            return activityCfg.ActivityCoin
        end
    end
end

--当前是否是教学故事线
function XTheatre5Agency:IsInTeachingStoryLine()
    local teachingStoryLineId = self._Model:GetTheatre5ConfigValByKey('TeachingPveStoryLineId')
    if not XTool.IsNumberValid(teachingStoryLineId) then
        return false
    end

    local curContentId = self._Model.PVERougeData:GetStoryLineContentId(teachingStoryLineId)
    if not curContentId or curContentId > 0 then
        --教学线完成，初始时contentId是nil
        return true
    end
    return false
end


--region 蓝点相关

--- 活动初见未进入的蓝点
function XTheatre5Agency:CheckHasNoEnterReddot()
    return self._Model:CheckHasNoEnterReddot()
end

--- 新赛季开放蓝点
function XTheatre5Agency:CheckHasNewPVPActivityReddot()
    return self._Model:CheckHasNewPVPActivityReddot()
end

function XTheatre5Agency:CheckHasNewPVEActivityReddot()
    return self._Model:CheckHasNewPVEActivityReddot()
end

function XTheatre5Agency:CheckLimitShopReddot()
    return self._Model:CheckLimitShopReddot()
end

function XTheatre5Agency:CheckShopNewGoods()
    local shopConfigs = self._Model:GetTaskOrShopCfgs(XMVCA.XTheatre5.EnumConst.TaskShopType.Shop)
    for i = 1, #shopConfigs do
        local shopConfig = shopConfigs[i]
        if self:CheckShopNewGoodsByShopConfig(shopConfig) then
            return true
        end
    end
    return false
end

-- 有新增的任务
---@param taskCfg XTableTheatre5TaskShop
function XTheatre5Agency:CheckNewTaskByTaskConfig(taskCfg)
    local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(taskCfg.TaskTimeLimitId)
    if taskTimeLimitCfg and taskTimeLimitCfg.TaskId then
        for _, taskId in pairs(taskTimeLimitCfg.TaskId) do
            if self._Model:CheckTaskNewReddot(taskId) then
                return true
            end
        end
    end
    return false
end

-- 有新增的商品
---@param taskCfg XTableTheatre5TaskShop
function XTheatre5Agency:CheckShopNewGoodsByShopConfig(shopCfg)
    --商店过期
    if shopCfg.TimeLimitId ~= 0 then
        if not XFunctionManager.CheckInTimeByTimeId(shopCfg.TimeLimitId) then
            return false
        end
    end
    --local currencyCoinId = self:GetActivityCoinInActivity()
    ----货币过期
    --if not XTool.IsNumberValid(currencyCoinId) then
    --    return false
    --end
    --取消掉打印，防止策划前后端配置不一致，红点每秒检测打印    
    local shopDatas = XShopManager.GetShopGoodsList(shopCfg.ShopId, true)
    if XTool.IsTableEmpty(shopDatas) then
        return false
    end
    for _, shopData in pairs(shopDatas) do
        if self._Model:CheckShopNewReddot(shopData.Id) then
            return true
        end
    end
    return false
end

--endregion

function XTheatre5Agency:GetValidShopOrTaskList(type)
    local validTaskShopCfgs = {}
    local taskShopCfgs = self._Model:GetTaskOrShopCfgs(type)
    if XTool.IsTableEmpty(taskShopCfgs) then
        return validTaskShopCfgs
    end
    for _, taskShopCfg in pairs(taskShopCfgs) do
        if XFunctionManager.CheckInTimeByTimeId(taskShopCfg.TimeLimitId, true) then
            table.insert(validTaskShopCfgs, taskShopCfg)
        end
    end
    return validTaskShopCfgs
end

return XTheatre5Agency