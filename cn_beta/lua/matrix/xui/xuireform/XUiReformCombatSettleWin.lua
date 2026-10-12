local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

--######################## XUiWinRoleGrid ########################
local XUiWinRoleGrid = XClass(nil, "XUiWinRoleGrid")

function XUiWinRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- data : XCharacterViewModel
function XUiWinRoleGrid:SetData(icon, level)
    self.RImgIcon:SetRawImage(icon)
    self.TxtLevel.text = level
end

--######################## XUiReformCombatSettleWin ########################
---@field _Control XReformControl
----@class UiReformCombatSettleWin:XLuaUi
local XUiReformCombatSettleWin = XLuaUiManager.Register(XLuaUi, "UiReformCombatSettleWin")

function XUiReformCombatSettleWin:OnAwake()
    self.GridWinRole.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.GridRewardList = {}
    self.RewardAnimationIndex = 1
    self:RegisterUiEvents()
end

function XUiReformCombatSettleWin:OnDestroy()
    XLuaUiManager.Remove("UiReformBalance")
end

function XUiReformCombatSettleWin:OnStart(winData, isUnlockHardMode)
    local stageId = winData.StageId
    --local currDiff = winData.SettleData.ReformFightResult.CurrDiff
    --local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(winData.StageId)
    --local evolvableStage = baseStage:GetEvolvableStageByDiffIndex(currDiff + 1)
    -- 名称
    self.TxtTitle.text = self._Control:GetStageName(stageId)
    -- 难度等级
    self.TxtDiffTitle.text = ""
    -- 角色
    local team = XDataCenter.Reform2ndManager.GetTeam(stageId)
    --local memberSource = nil
    --local memberGroup = evolvableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
    local winRoleGo = nil
    local winRoleGrid = nil
    for _, entityId in ipairs(team:GetEntityIds()) do
        if entityId > 0 then
            local icon = nil
            local level = XMVCA.XCharacter:GetCharacterLevel(entityId)

            winRoleGo = CS.UnityEngine.Object.Instantiate(self.GridWinRole, self.PanelRoleContent)
            winRoleGo.gameObject:SetActiveEx(true)
            winRoleGrid = XUiWinRoleGrid.New(winRoleGo)

            if XRobotManager.CheckIsRobotId(entityId) then
                entityId = XRobotManager.GetCharacterId(entityId)
            end

            icon = XMVCA.XCharacter:GetCharBigHeadIcon(entityId)

            --memberSource = memberGroup:GetSourceById(entityId)
            winRoleGrid:SetData(icon, level)
        end
    end

    self.RewardList.gameObject:SetActiveEx(winData.RewardGoodsList ~= nil and #winData.RewardGoodsList > 0)
    self.PanelAssist.gameObject:SetActiveEx(winData.RewardGoodsList == nil or #winData.RewardGoodsList <= 0)
    -- 奖励
    if winData.RewardGoodsList ~= nil and #winData.RewardGoodsList > 0 then
        self.RewardList.gameObject:SetActiveEx(true)
        local rewards = XRewardManager.FilterRewardGoodsList(winData.RewardGoodsList)
        rewards = XRewardManager.MergeAndSortRewardGoodsList(rewards)
        local rewardGo = nil
        local rewardGrid = nil
        for _, item in ipairs(rewards) do
            rewardGo = CS.UnityEngine.Object.Instantiate(self.GridReward)
            rewardGrid = XUiGridCommon.New(self, rewardGo)
            rewardGrid.Transform:SetParent(self.PanelRewardContent, false)
            rewardGrid:Refresh(item, nil, nil, true)
            rewardGo.gameObject:SetActiveEx(false)
            table.insert(self.GridRewardList, rewardGrid)
        end
    else
        self.RewardList.gameObject:SetActiveEx(false)
    end
    self.PanelAssist.gameObject:SetActiveEx(false)
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or nil
    if self.TxtLevelTitle and txtLevelName then
        self.TxtLevelTitle.text = txtLevelName
    end
    self.TxtPlayerLevel.text = XPlayer.GetLevelOrHonorLevel()
    self:PlayRewardAnimation()

    self:UpdateCombatWeight(winData)

    -- 解锁新难度提示
    if isUnlockHardMode then
        local name = self._Control:GetStageName(stageId)
        XUiManager.PopupLeftTip(name, XUiHelper.GetText("ReformDiffUnlockedTip", ""))
    end
end

--######################## 私有方法 ########################

-- 质量数值 + 完美配平额外奖励提示
function XUiReformCombatSettleWin:UpdateCombatWeight(winData)
    local fightResult = winData.SettleData.ReformFightResult
    self.TxtWeight.text = fightResult and fightResult.FinalWishWeight or 0

    -- 完美配平才有额外积分，无加成时服务端不下发
    local bonusWishWeight = fightResult and fightResult.BonusWishWeight or 0
    self.TxtRewardTip.gameObject:SetActiveEx(bonusWishWeight > 0)
    if bonusWishWeight > 0 then
        self.TxtRewardTip.text = XUiHelper.GetText("ReformSettlePerfectBalanceTip", bonusWishWeight)
    end
end

function XUiReformCombatSettleWin:RegisterUiEvents()
    self.BtnBlock.CallBack = function()
        self:Close()
    end
end

-- 奖励动画
function XUiReformCombatSettleWin:PlayRewardAnimation()
    XLuaUiManager.SetMask(true)
    local delay = XDataCenter.FubenManager.SettleRewardAnimationDelay
    local interval = XDataCenter.FubenManager.SettleRewardAnimationInterval
    -- 没有奖励则直接播放第二个动画
    if #self.GridRewardList == 0 then
        XScheduleManager.ScheduleOnce(function()
            self:PlaySecondAnimation()
        end, delay)
        return
    end
    self.RewardAnimationIndex = 1
    XScheduleManager.Schedule(function()
        if XTool.UObjIsNil(self.GridRewardList[self.RewardAnimationIndex].GameObject) then
            return
        end
        if self.RewardAnimationIndex == #self.GridRewardList then
            self:PlayReward(self.RewardAnimationIndex, function()
                self:PlaySecondAnimation()
            end)
        else
            self:PlayReward(self.RewardAnimationIndex)
        end
        self.RewardAnimationIndex = self.RewardAnimationIndex + 1
    end, interval, #self.GridRewardList, delay)
end

function XUiReformCombatSettleWin:PlaySecondAnimation()
    --self:PlayAnimation("AnimEnable2", function()
    XLuaUiManager.SetMask(false)
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    self.IsFirst = false;
    --end)
end

function XUiReformCombatSettleWin:PlayReward(index, cb)
    self.GridRewardList[index].GameObject:SetActiveEx(true)
    self:PlayAnimation("GridReward", cb)
end

return XUiReformCombatSettleWin