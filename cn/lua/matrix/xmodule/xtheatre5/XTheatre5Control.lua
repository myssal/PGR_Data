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
    ---@type XTheatre5FlowControl
    self.FlowControl = self:AddSubControl(require('XModule/XTheatre5/XTheatre5FlowController'))
    ---@type XTheatre5GameEntityControl
    self.GameEntityControl = self:AddSubControl(require('XModule/XTheatre5/Common/XTheatre5GameEntityControl'))
    
    self._EnterFightHandler = handler(self, self.OnFightEnterEvent)
    self._ExitFightHandler = handler(self, self.OnFightExitEvent)

    CsGameEventManager:RegisterEvent(XEventId.EVENT_DLC_FIGHT_ENTER, self._EnterFightHandler)
    CsGameEventManager:RegisterEvent(XEventId.EVENT_DLC_FIGHT_EXIT, self._ExitFightHandler)
    self:SetDelayReleaseTime(10) --战斗、剧情之后，栈中的界面被Release, 后续当PopThenOpen关闭瞬间会释放control，故做延迟

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

function XTheatre5Control:OnFightPauseOrResumeEvent(type)
    if not CS.StatusSyncFight.XFightClient.FightInstance then
        return
    end
    
    if type == XMVCA.XTheatre5.EnumConst.FightPauseOrResumeType.Pause then
        CS.StatusSyncFight.XFightClient.FightInstance:OnPauseForClient()
    elseif type == XMVCA.XTheatre5.EnumConst.FightPauseOrResumeType.Resume then
        CS.StatusSyncFight.XFightClient.FightInstance:OnResumeForClient()
    else
        XLog.Error('战斗暂停控制事件传入了错误的type:'..tostring(type))
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
            table.insert(characterCfgs,cfg)
        end    
    end
    table.sort(characterCfgs, function (a, b)
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

--商店按钮旁边需要展示的奖励
function XTheatre5Control:GetShopShowRewards()
    local values = self._Model:GetTheatre5ConfigValListByKey("ShopShowRewards")
    if XTool.IsTableEmpty(values) then
        return
    end    
    local rewards = {}
    for i = 1, #values, 2 do
        local value = values[i]
        table.insert(rewards, XRewardManager.CreateRewardGoods(value, values[i+1]))
    end
    return rewards
end

function XTheatre5Control:GetTheatre5CoinIds()
    local resourceBarCoins = {XDataCenter.ItemManager.ItemId.Theatre5Coin}      
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

--endregion

return XTheatre5Control