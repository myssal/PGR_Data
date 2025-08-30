---@class XTheatre5Control : XControl
---@field private _Model XTheatre5Model
local XTheatre5Control = XClass(XControl, "XTheatre5Control")
---@type XGameEventManager
local CsGameEventManager = CS.XGameEventManager.Instance

function XTheatre5Control:OnInit()
    ---@type XTheatre5PVPControl
    self.PVPControl = self:AddSubControl(require('XModule/XTheatre5/PVP/XTheatre5PVPControl'))
    ---@type XTheatre5ShopControl
    self.ShopControl = self:AddSubControl(require('XModule/XTheatre5/Common/XTheatre5ShopControl'))
    ---@type XTheatre5PVEControl
    self.PVEControl = self:AddSubControl(require('XModule/XTheatre5/PVE/XTheatre5PVEControl'))
    ---@type XTheatre5CharacterControl
    self.CharacterControl = self:AddSubControl(require('XModule/XTheatre5/Common/XTheatre5CharacterControl'))
    ---@type XTheatre5FlowController
    self.FlowControl = self:AddSubControl(require('XModule/XTheatre5/XTheatre5FlowController'))
    ---@type XTheatre5GameEntityControl
    self.GameEntityControl = self:AddSubControl(require('XModule/XTheatre5/Common/XTheatre5GameEntityControl'))

    self._EnterFightHandler = handler(self, self.OnFightEnterEvent)
    self._ExitFightHandler = handler(self, self.OnFightExitEvent)

    CsGameEventManager:RegisterEvent(XEventId.EVENT_DLC_FIGHT_ENTER, self._EnterFightHandler)
    CsGameEventManager:RegisterEvent(XEventId.EVENT_DLC_FIGHT_EXIT, self._ExitFightHandler)
    -- 开发过程中，关闭界面后立即热更代码，会出错，故zlb开发过程中，不做延迟
    if not XMain.IsZlbDebug then
        self:SetDelayReleaseTime(10) --战斗、剧情之后，栈中的界面被Release, 后续当PopThenOpen关闭瞬间会释放control，故做延迟
    end

    XEventManager.AddEventListener(XEventId.EVENT_THEATRE5_SET_BATTLE_PAUSEORCONTINUE, self.OnFightPauseOrResumeEvent, self)
end

function XTheatre5Control:AddAgencyEvent()

end

function XTheatre5Control:RemoveAgencyEvent()

end

function XTheatre5Control:OnRelease()
    self:ClearUiLogicData()

    CsGameEventManager:RemoveEvent(XEventId.EVENT_DLC_FIGHT_ENTER, self._EnterFightHandler)
    CsGameEventManager:RemoveEvent(XEventId.EVENT_DLC_FIGHT_EXIT, self._ExitFightHandler)

    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE5_SET_BATTLE_PAUSEORCONTINUE, self.OnFightPauseOrResumeEvent, self)

    -- 保底逻辑，因为在UI界面中存在对铭牌弹窗的锁定设置，为防止漏解锁，当退出该玩法时手动解锁
    XDataCenter.MedalManager.SetNewNameplateAutoWinLock(false)
end

--region ActivityData

function XTheatre5Control:RefreshCharacterStatusAdds()
    if not self._Model.CurAdventureData then
        return
    end

    if not self._Model.CurAdventureData:GetIsNeedUpdateAdds() then
        return
    end

    -- 记录各个属性加成值的字典
    local runeDict = self._Model.CurAdventureData:GetRuneDict()

    local attrAddsMap = nil

    if not XTool.IsTableEmpty(runeDict) then
        attrAddsMap = {}

        for i, v in pairs(runeDict) do
            ---@type XTableTheatre5ItemRune
            local runeCfg = self._Model:GetTheatre5RuneCfgById(v.ItemId)

            if runeCfg and XTool.IsNumberValid(runeCfg.RuneAttrId) then
                ---@type XTableTheatre5ItemRuneAttr
                local runeAttrCfg = self._Model:GetTheatre5ItemRuneAttrCfgById(runeCfg.RuneAttrId)

                if runeAttrCfg then
                    for i, v in ipairs(runeAttrCfg.AttrTypes) do
                        if XTool.IsNumberValid(runeAttrCfg.AttrValues[i]) then
                            attrAddsMap[v] = attrAddsMap[v] and (attrAddsMap[v] + runeAttrCfg.AttrValues[i]) or runeAttrCfg.AttrValues[i]
                        end
                    end
                end
            end
        end
    end

    self._Model.CurAdventureData:UpdateCharacterStatusAdds(attrAddsMap)

end

--- 判断是否有局内数据
function XTheatre5Control:CheckIsInPVPAdventure()
    return self._Model.PVPAdventureData.HasData
end

function XTheatre5Control:GetGoldNum()
    return self._Model.CurAdventureData:GetGoldNum()
end

function XTheatre5Control:GetTrophyNum()
    return self._Model.CurAdventureData:GetTrophyNum()
end

function XTheatre5Control:GetHealth()
    return self._Model.CurAdventureData:GetHealth()
end

--- 获取宝珠栏解锁格子数
function XTheatre5Control:GetGemUnlockSlotCount()
    return self._Model.CurAdventureData:GetBagRuneGridsNum()
end

--- 获取宝珠栏指定位置的宝珠数据
function XTheatre5Control:GetItemInRuneListByIndex(index)
    return self._Model.CurAdventureData:GetItemInRuneListByIndex(index)
end

function XTheatre5Control:GetCurPlayStatus()
    return self._Model.CurAdventureData:GetCurPlayStatus()
end

--清空战斗数据
function XTheatre5Control:ClearAdventureData()
    self._Model.CurAdventureData:ClearData()
end

--- 获取玩家的技能列表（不包含普攻）
function XTheatre5Control:GetCurSelfSkillIdList()
    return self._Model.CurAdventureData:GetSkillIdsInSkillList()
end

--- 获取玩家的技能列表（包含普攻）
function XTheatre5Control:GetCurSelfSkillIdListWithNormalATK()
    local skillIds = self._Model.CurAdventureData:GetSkillIdsInSkillList()

    ---@type XTableTheatre5Character
    local charaCfg = self:GetCurCharacterCfg()

    if charaCfg and XTool.IsNumberValid(charaCfg.NormalAttack) then
        table.insert(skillIds, 1, charaCfg.NormalAttack)
    end

    return skillIds
end

--- 获取玩家的普攻Id
function XTheatre5Control:GetCurSelfNormalAttackSkillId()
    ---@type XTableTheatre5Character
    local charaCfg = self:GetCurCharacterCfg()

    if charaCfg then
        return charaCfg.NormalAttack
    end
end

--- 获取敌人的技能列表（包含普攻）
function XTheatre5Control:GetCurEnemySkillIdListWithNormalATK()
    local skillIds = self._Model.CurAdventureData:GetEnemySkillIds()

    local charaId = self._Model.CurAdventureData:GetEnemyCharacterId()

    if XTool.IsNumberValid(charaId) then
        ---@type XTableTheatre5Character
        local charaCfg = self:GetTheatre5CharacterCfgById(charaId)

        if charaCfg and XTool.IsNumberValid(charaCfg.NormalAttack) then
            table.insert(skillIds, 1, charaCfg.NormalAttack)
        end
    end

    return skillIds
end

--- 获取敌人的普攻Id
function XTheatre5Control:GetCurEnemyNormalAttackSkillId()
    local charaId = self._Model.CurAdventureData:GetEnemyCharacterId()

    if XTool.IsNumberValid(charaId) then
        ---@type XTableTheatre5Character
        local charaCfg = self:GetTheatre5CharacterCfgById(charaId)

        if charaCfg then
            return charaCfg.NormalAttack
        end
    end
end

--- 获取玩家的宝珠列表(合并同id）
function XTheatre5Control:GetCurSelfGemIdList(ignoreSame)
    return self._Model.CurAdventureData:GetRuneIdsInSkillList(ignoreSame)
end

--- 获取敌人的宝珠列表(合并同id）
function XTheatre5Control:GetCurEnemyGemIdList()
    return self._Model.CurAdventureData:GetEnemyRuneIds()
end

--- 获取角色指定属性的加成
function XTheatre5Control:GetCharacterAttrAddsByAttrType(attrType)
    -- 检查并刷新加成
    self:RefreshCharacterStatusAdds()
    return self._Model.CurAdventureData:GetAttrAddsByAttrType(attrType)
end

--- 判断玩家是否有宝珠
function XTheatre5Control:CheckHasEquipGem()
    return self._Model.CurAdventureData:CheckHasEquipGem()
end

--- 判断玩家是否穿戴技能
function XTheatre5Control:CheckHasEquipSkill()
    return self._Model.CurAdventureData:CheckHasEquipSkill()
end

--endregion

--- 设置当前正在游玩的模式, 用于玩法内各界面差异化逻辑判断
function XTheatre5Control:SetCurPlayingMode(mode)
    self._Model:SetCurPlayingMode(mode)
end

function XTheatre5Control:GetCurPlayingMode()
    return self._Model:GetCurPlayingMode()
end

function XTheatre5Control:OnFightEnterEvent()
    self:LockRef()
    self:ClearUiLogicData()
end

function XTheatre5Control:OnFightExitEvent()
    self:UnLockRef()
end

function XTheatre5Control:OnFightPauseOrResumeEvent(eventType)
    if not CS.StatusSyncFight.XFightClient.FightInstance then
        return
    end

    if type(eventType) == 'string' then
        if not string.IsNilOrEmpty(eventType) and string.IsNumeric(eventType) then
            eventType = tonumber(eventType)
        else
            XLog.Error('战斗暂停控制事件传入了的type不是数值格式:' .. tostring(eventType))
            return
        end
    end

    if eventType == XMVCA.XTheatre5.EnumConst.FightPauseOrResumeType.Pause then
        CS.StatusSyncFight.XFightClient.FightInstance:OnPauseForClient()
    elseif eventType == XMVCA.XTheatre5.EnumConst.FightPauseOrResumeType.Resume then
        CS.StatusSyncFight.XFightClient.FightInstance:OnResumeForClient()
    else
        XLog.Error('战斗暂停控制事件传入了错误的type:' .. tostring(eventType))
    end

end

function XTheatre5Control:ReturnTheatre5Main()
    local uiTheatre5Main = "UiTheatre5Main"
    local isOpen = XLuaUiManager.IsStackUiOpen(uiTheatre5Main)
    if isOpen then
        XLuaUiManager.CloseAllUpperUi(uiTheatre5Main)
    else
        XLuaUiManager.Open(uiTheatre5Main)
        XLog.Debug("theatre5:打开主界面异常,主界面不应该被关闭")
    end
    self.FlowControl:ExitModel()
end

--region Configs 

--region 角色相关

function XTheatre5Control:GetTheatre5CharacterCfgs()
    local allCfgs = self._Model:GetTheatre5CharacterCfgs()
    if XTool.IsTableEmpty(allCfgs) then
        return
    end
    local characterCfgs = {}
    for _, cfg in pairs(allCfgs) do
        if XTool.IsNumberValid(cfg.Priority) then
            table.insert(characterCfgs, cfg)
        end
    end
    table.sort(characterCfgs, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        else
            return a.Id < b.Id
        end
    end)
    return characterCfgs
end

function XTheatre5Control:GetTheatre5CharacterCfgById(id, notips)
    return self._Model:GetTheatre5CharacterCfgById(id, notips)
end

function XTheatre5Control:GetTheatre5SkillCfgById(id, notips)
    return self._Model:GetTheatre5SkillCfgById(id, notips)
end

--- 获取当前选择的角色的配置
function XTheatre5Control:GetCurCharacterCfg()
    local characterId = self._Model.CurAdventureData:GetCharacterId()

    if XTool.IsNumberValid(characterId) then
        return self._Model:GetTheatre5CharacterCfgById(characterId)
    end
end
--endregion

--region 属性相关

function XTheatre5Control:GetTheatre5AttrShowCfgByType(type)
    return self._Model:GetTheatre5AttrShowCfgByType(type)
end

function XTheatre5Control:GetTheatre5AttrShowCfgs()
    return self._Model:GetTheatre5AttrShowCfgs()
end

--endregion

--region 道具物品相关

function XTheatre5Control:GetTheatre5ItemCfgById(id, notips)
    return self._Model:GetTheatre5ItemCfgById(id, notips)
end

function XTheatre5Control:GetTheatre5ItemRuneCfgById(id, notips)
    return self._Model:GetTheatre5RuneCfgById(id, notips)
end

function XTheatre5Control:GetTheatre5ItemTagCfgById(id, notips)
    return self._Model:GetTheatre5ItemTagCfgById(id, notips)
end

function XTheatre5Control:GetTheatre5ItemKeyWordCfgById(id, notips)
    return self._Model:GetTheatre5ItemKeyWordCfgById(id, notips)
end

function XTheatre5Control:GetTheatre5ItemRuneAttrCfgById(id, notips)
    return self._Model:GetTheatre5ItemRuneAttrCfgById(id, notips)
end

function XTheatre5Control:CheckHasEquipOrSkill(itemType, itemId)
    return self._Model.CurAdventureData:CheckHasEquipOrSkill(itemType, itemId)
end
--endregion

--region 商店相关

function XTheatre5Control:GetRouge5CurrencyCfg(currencyId)
    return self._Model:GetRouge5CurrencyCfg(currencyId)
end
--endregion

--region 杂项表

--- 获取宝珠触发次数文本
function XTheatre5Control:GetClientConfigGemTriggerTimesLabel()
    return self._Model:GetTheatre5ClientConfigText('GemTriggerTimesLabel')
end

--- 获取回合结算切换显示按钮的文本
function XTheatre5Control:GetClientConfigRoundSettleSummaryChangeLabel(isSelf)
    return self._Model:GetTheatre5ClientConfigText('RoundSettleSummaryChangeLabel', isSelf and 1 or 2)
end

--- 排行榜-未上榜文本
function XTheatre5Control:GetClientConfigNoRankTips()
    return self._Model:GetTheatre5ClientConfigText('NoRankTips')
end

--- 排行榜刷新提示文本
function XTheatre5Control:GetClientConfigRankRefreshTips()
    return self._Model:GetTheatre5ClientConfigText('RankRefreshTips')
end

--- 页签文本“全部”
function XTheatre5Control:GetClientConfigRankAllTabLabel()
    return self._Model:GetTheatre5ClientConfigText('RankAllTabLabel')
end

--- 放弃对局提示文本
function XTheatre5Control:GetClientConfigGameGiveUpContent()
    return self._Model:GetTheatre5ClientConfigText('GameGiveUpContent')
end

--- 最终结算积分插值动画时长
function XTheatre5Control:GetClientConfigSettleRatingChangedAnimaTotalTime()
    return self._Model:GetTheatre5ClientConfigNum('SettleRatingChangedAnimaTotalTime')
end

--关卡未解锁时的文本
function XTheatre5Control:GetClientConfigPveChapterLevelLockText()
    return self._Model:GetTheatre5ClientConfigText('PveChapterLevelLockText')
end

function XTheatre5Control:GetTaskShopTagName(taskShopType)
    return self._Model:GetTheatre5ClientConfigText('TaskShopTagName', taskShopType)
end

function XTheatre5Control:GetCharacterLock()
    return self._Model:GetTheatre5ClientConfigText('CharacterLock')
end

--- 宝珠品质颜色配置
function XTheatre5Control:GetClientConfigGemQualityColor(quality)
    return self._Model:GetClientConfigGemQualityColor(quality)
end

--- 角色属性加成文本
function XTheatre5Control:GetClientConfigCharacterAttribAddsShow()
    local content = self._Model:GetTheatre5ClientConfigText('CharacterAttribAddsShow')
    return string.gsub(content, '\\', '')
end

--- 兑换商店货币id
function XTheatre5Control:GetTheatre5ShopCurrencyId()
    return self._Model:GetTheatre5ConfigValByKey('Theatre5ShopCurrencyId')
end

--- 获取匹配界面延时配置
function XTheatre5Control:GetClientConfigMatchLoadingDelay(afterEnterFight)
    return self._Model:GetTheatre5ClientConfigNum('MatchLoadingDelay', afterEnterFight and 2 or 1)
end

--- 回合结算时被动宝珠显示的文本
function XTheatre5Control:GetClientConfigRoundSettlePassiveGemLabel()
    return self._Model:GetTheatre5ClientConfigText('RoundSettlePassiveGemLabel')
end

--- 界面内进玩法入口的时间文本格式
function XTheatre5Control:GetClientConfigPVPTimeLabel()
    return self._Model:GetTheatre5ClientConfigText('PVPTimeLabel')
end

--- 奖励、商店界面的时间文本格式
function XTheatre5Control:GetClientConfigRewardTimeLabel()
    return self._Model:GetTheatre5ClientConfigText('RewardTimeLabel')
end

--- PVP玩法不在时间内时的提示
function XTheatre5Control:GetClientConfigPVPNotOpenTips()
    return self._Model:GetTheatre5ClientConfigText('PVPNotOpenTips')
end

--任务商店剩余时间
function XTheatre5Control:GetClientConfigTaskShopTimeLabel()
    return self._Model:GetTheatre5ClientConfigText('TaskShopTimeLabel')
end

--video
function XTheatre5Control:GetMainVideoId()
    return self._Model:GetTheatre5ConfigValByKey('MainVideoId')
end

--- 获取战斗失败后生命数变化延时时长
function XTheatre5Control:GetClientConfigBattleLoseLifeChangeDelay()
    return self._Model:GetTheatre5ClientConfigNum('BattleLoseLifeChangeDelay')
end

--endregion

--endregion

--region 界面数据 - 通用

function XTheatre5Control:ClearUiLogicData()
    self._SelectedUiItem = nil
end

---@param uiItem XUiGridTheatre5Item
function XTheatre5Control:SetItemSelected(uiItem)
    if self._SelectedUiItem then
        self._SelectedUiItem:UnSelect()
    end

    self._SelectedUiItem = uiItem
end

function XTheatre5Control:TryCloseItemDetail()
    self:SetItemSelected(nil)
    self:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
end

--endregion

function XTheatre5Control:GetValidShopIdlist()
    local validTaskShopCfgs = self:GetValidShopOrTaskList(XMVCA.XTheatre5.EnumConst.TaskShopType.Shop)
    local shopIdList = {}
    if not XTool.IsTableEmpty(validTaskShopCfgs) then
        for _, taskShopCfg in pairs(validTaskShopCfgs) do
            table.insert(shopIdList, taskShopCfg.ShopId)
        end
    end
    return shopIdList
end

function XTheatre5Control:GetValidShopOrTaskList(type)
    return XMVCA.XTheatre5:GetValidShopOrTaskList(type)
end

--商店按钮旁边需要展示的奖励
function XTheatre5Control:GetShopShowRewards()
    local values = self._Model:GetTheatre5ConfigValListByKey("ShopShowRewards")
    if XTool.IsTableEmpty(values) then
        return
    end
    local rewards = {}
    for i = 1, #values, 2 do
        local value = values[i]
        table.insert(rewards, XRewardManager.CreateRewardGoods(value, values[i + 1]))
    end
    return rewards
end

function XTheatre5Control:GetTheatre5CoinIds()
    local resourceBarCoins = { XDataCenter.ItemManager.ItemId.Theatre5Coin }
    local activityId = self._Model:GetActivityId()
    if XTool.IsNumberValid(activityId) then
        local activityCfg = self._Model:GetTheatre5ActivityCfgById(activityId)
        if XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId) and XTool.IsNumberValid(activityCfg.ActivityCoin) then
            table.insert(resourceBarCoins, activityCfg.ActivityCoin)
        end
    end
    return resourceBarCoins
end

--region 蓝点相关

--- 消除活动初见未进入的蓝点
function XTheatre5Control:MarkHasNoEnterReddot()
    self._Model:MarkHasNoEnterReddot()
end

--- 消除新赛季开放蓝点
function XTheatre5Control:MarkNewPVPActivityReddot()
    self._Model:MarkNewPVPActivityReddot()
end

function XTheatre5Control:MarkNewPVEActivityReddot()
    self._Model:MarkNewPVEActivityReddot()
end

function XTheatre5Control:MarkLimitShopReddot()
    self._Model:MarkLimitShopReddot()
end

--endregion

function XTheatre5Control:RemoveTaskNewReddot(taskCfg)
    local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(taskCfg.TaskTimeLimitId)
    if taskTimeLimitCfg and taskTimeLimitCfg.TaskId then
        for _, taskId in pairs(taskTimeLimitCfg.TaskId) do
            self._Model:MarkTaskNewReddot(taskId)
        end
    end
end

function XTheatre5Control:RemoveShopNewReddot(shopCfg)
    local shopDatas = XShopManager.GetShopGoodsList(shopCfg.ShopId, true)
    if XTool.IsTableEmpty(shopDatas) then
        return
    end
    for _, shopData in pairs(shopDatas) do
        self._Model:MarkShopNewReddot(shopData.Id)
    end
end

function XTheatre5Control:GetDataHandBook(itemType)
    if itemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        -- 技能按照characterId区分
        local tab = {}
        local itemConfigs = self._Model:GetTheatre5ItemCfgs()
        for id, config in pairs(itemConfigs) do
            -- 配置了IsShow的才显示
            if config.IsShow then
                if config.Type == itemType then
                    -- 技能按角色区分
                    local characterId = config.CharacterId
                    if characterId and characterId > 0 then
                        ---@class XUiTheatre5SkillHandbookTabGridData
                        ---@field TagName string
                        ---@field Items XUiTheatre5SkillHandbookItemGridData[]
                        tab[characterId] = tab[characterId] or {
                            Items = {},
                            TagName = nil,
                            Order = characterId
                        }
                        ---@class XUiTheatre5SkillHandbookItemGridData
                        local data = {
                            Id = id,
                            Order = config.Order,
                            Name = config.Name,
                            Quality = 0,
                            Icon = config.IconRes,
                            Desc = self:GetItemDesc(config),
                            Tags = config.Tags,
                        }
                        table.insert(tab[characterId].Items, data)
                    end
                end
            end
        end
        -- 排序
        for characterId, data in pairs(tab) do
            table.sort(data.Items, function(a, b)
                return a.Order < b.Order
            end)
        end
        for characterId, data in pairs(tab) do
            local characterConfig = self._Model:GetTheatre5CharacterCfgById(characterId)
            if characterConfig then
                data.TagName = characterConfig.Name
            else
                data.TagName = "???"
                XLog.Error("[XTheatre5Control] GetDataHangBook characterId not found: " .. characterId)
            end
        end
        local tabSorted = {}
        for characterId, data in pairs(tab) do
            table.insert(tabSorted, data)
        end
        table.sort(tabSorted, function(a, b)
            return a.Order < b.Order
        end)
        return tabSorted
    end
    if itemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        local tab = {}

        -- 直接从所有tag中收集，比从item里收集tag要快
        local allTags = self._Model:GetTheatre5ItemTagCfgs()
        for id, config in pairs(allTags) do
            local tag = {
                TagName = config.Name,
                Id = id,
                Items = {},
                Order = id,
            }
            tab[id] = tag
        end

        local itemConfigs = self._Model:GetTheatre5ItemCfgs()
        for id, config in pairs(itemConfigs) do
            -- 配置了IsShow的才显示
            if config.IsShow then
                if config.Type == itemType then
                    -- 符文/宝珠 按tag区分
                    ---@type XUiTheatre5SkillHandbookItemGridData
                    local data = {
                        Id = id,
                        Order = config.Order,
                        Name = config.Name,
                        Quality = 0,
                        Icon = config.IconRes,
                        Desc = self:GetItemDesc(config),
                        Tags = config.Tags,
                    }
                    -- 同一个物品会出现在多个tag分类里
                    for i = 1, #config.Tags do
                        local tagId = config.Tags[i]
                        if tab[tagId] then
                            table.insert(tab[tagId].Items, data)
                        end
                    end
                end
            end
        end
        --排除掉items为空的
        for tagId, data in pairs(tab) do
            if #data.Items == 0 then
                tab[tagId] = nil
            end
        end
        local tabSorted = {}
        for tagId, data in pairs(tab) do
            table.insert(tabSorted, data)
        end
        -- 排序
        table.sort(tabSorted, function(a, b)
            return a.Order < b.Order
        end)
        for tagId, data in pairs(tabSorted) do
            table.sort(data.Items, function(a, b)
                return a.Order < b.Order
            end)
        end
        return tabSorted
    end
    XLog.Error("[XTheatre5Control] unimplemented item type")
    return {}
end

---@return XTableTheatre5Story[]
function XTheatre5Control:GetStoryData(groupId)
    local data = {}
    for i = 1, 99 do
        local id = groupId * 1000 + i
        local config = self._Model:GetStoryById(id)
        if config then
            data[#data + 1] = config
        else
            break
        end
    end
    return data
end

function XTheatre5Control:GetStoryTab()
    local configs = self._Model:GetStoryGroup()
    return configs
end

function XTheatre5Control:GetTipsNewStoryLine()
    local configs = self._Model:GetStoryLineCfgs()
    for i, config in pairs(configs) do
        if config.StoryLineCondition == 0 or XConditionManager.CheckCondition(config.StoryLineCondition) then
            local contentId = self._Model.PVERougeData:GetStoryLineContentId(config.Id)
            if contentId then
                local index = contentId % 100
                if index == 1 then
                    return config.StoryLineOpenTips
                end
            end
        end
    end
end

function XTheatre5Control:IsCharacterCanSelect(characterId)
    local configs = self._Model:GetStoryLineCfgs()
    for i, config in pairs(configs) do
        if config.StoryLineCondition == 0 or XConditionManager.CheckCondition(config.StoryLineCondition) then
            local contentId = self._Model.PVERougeData:GetStoryLineContentId(config.Id)
            if contentId > 0 then
                local contentConfig = self._Model:GetStoryLineContentCfg(contentId)
                if contentConfig then
                    for i = 1, #contentConfig.DisabledCharacters do
                        local characterCloseId = contentConfig.DisabledCharacters[i]
                        if characterCloseId == characterId then
                            return false, contentConfig.DisabledCharactersTips[i]
                        end
                    end
                end
            end
        end
    end
    return true
end

function XTheatre5Control:FormatString(format, args)
    if not format then
        return ""
    end

    -- 替换 {0}, {1}, ... 为对应的参数值
    local result = string.gsub(format, "{(%d+)}", function(index)
        local idx = tonumber(index) + 1  -- Lua索引从1开始，C#从0开始
        if idx > 0 and idx <= #args then
            return tostring(args[idx])
        else
            return "{" .. index .. "}"  -- 如果索引超出范围，保留原始占位符
        end
    end)

    return result
end

function XTheatre5Control:GetItemDesc(itemConfig)
    if not string.IsNilOrEmpty(itemConfig.Desc) then
        local desc = XUiHelper.ReplaceTextNewLine(itemConfig.Desc) or ''
        if #itemConfig.DescDigit > 0 then
            desc = self:FormatString(desc, itemConfig.DescDigit)
        end
        return desc
    end
    return ""
end

return XTheatre5Control