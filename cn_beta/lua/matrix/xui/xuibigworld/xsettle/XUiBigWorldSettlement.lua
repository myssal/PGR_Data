---@class XUiGridBWSettleTarget : XUiNode
---@field ComponentGroup XUiComponent.XUiComponentGroup
---@field Parent XUiBigWorldSettlement
local XUiGridBWSettleTarget = XClass(XUiNode, "XUiGridBWSettleTarget")

local Delay = 100

function XUiGridBWSettleTarget:OnStart()
    self._CanvasGroup = self.Transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
end

function XUiGridBWSettleTarget:OnDisable()
    self:StopAnimationTimer()
end

function XUiGridBWSettleTarget:Update(objectiveId, index)
    local objTxt = XMVCA.XBigWorldQuest:GetObjectiveTitle(objectiveId)
    local max = XMVCA.XBigWorldQuest:GetObjectiveMaxProgress(objectiveId)
    self.ComponentGroup:SetTextWithGroup(0, objTxt)
    self.ComponentGroup:SetTextWithGroup(1, max)
    
    local finish = self.Parent:CheckObjectiveFinish(objectiveId)
    self.ComponentGroup:SetVisibleWithGroup(0, not finish)
    self.ComponentGroup:SetVisibleWithGroup(1, finish)
    self:Open()
end

function XUiGridBWSettleTarget:StopAnimationTimer()
    XScheduleManagerPro.UnSchedule(XUiGridBWSettleTarget._OnPlaySeqAnimationScheduleCb, self)
end

function XUiGridBWSettleTarget:PlaySeqAnimation(index)
    self:StopAnimationTimer()
    if not XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup.alpha = 0
    end
    local delay = (index - 1) * Delay
    if delay <= 1 then
        XScheduleManagerPro.ScheduleNextFrame(XUiGridBWSettleTarget._OnPlaySeqAnimationScheduleCb, self)
    else
        XScheduleManagerPro.ScheduleOnce(XUiGridBWSettleTarget._OnPlaySeqAnimationScheduleCb, self, delay)
    end
end

---@class XUiBigWorldSettlement : XBigWorldUi
local XUiBigWorldSettlement = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldSettlement")

function XUiBigWorldSettlement:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldSettlement:OnStart(settleData)
    self._QuestId = settleData.QuestId
    self._ObjectiveIds = self:CsCollection2Table(settleData.ObjectiveIds)
    self._Score = settleData.Score
    self._PlayTime = settleData.PlayTime
    self._IsWin = settleData.IsWin
    self._ShowScore = settleData.ShowScore
    self.SecondScreen = self.PanelSettleSuccessful:Find("SecondScreen")
    local successfulEnableTr = self.Transform:Find("Animation/SuccessfulEnable")
    if successfulEnableTr then
        self.SuccessfulEnable = successfulEnableTr:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
        self.SuccessfulEnable.playOnAwake = true
    end
end

function XUiBigWorldSettlement:OnEnable()
    self:InitView()
end

function XUiBigWorldSettlement:OnDestroy()
    self:StopCoolTimer()
    
    XMVCA.XBigWorldInstance:OnSettleClosed()
end

function XUiBigWorldSettlement:InitUi()
    self._GridsObj = {}
    self.TxtSuccessScore.text = 0
    self.TxtFailScore.text = 0
    self.GridTarget.gameObject:SetActiveEx(false)
end

function XUiBigWorldSettlement:InitCb()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    
    self.BtnCancel:AddEventListener(handler(self, self.OnBtnCancelClick))

    self.BtnReStart:AddEventListener(handler(self, self.OnBtnReStartClick))
end

function XUiBigWorldSettlement:InitView()
    if not self._QuestId or self._QuestId <= 0 then
        XLog.Error("结算界面更新失败, QuestId无效", self._QuestId)
        return
    end
    if self._IsWin then
        self:DoSettleWin()
    else
        self:DoSettleLose()
    end
end

function XUiBigWorldSettlement:DoSettleWin()
    --播放胜利动画
    --播放完之后显示结算界面
    self.PanelSettleSuccessful.gameObject:SetActiveEx(true)
    self.PanelSettleFail.gameObject:SetActiveEx(false)
    self:PlayAnimationWithMask("SuccessfulEnable", function()
        self:PlayScoreAnimation(self.TxtSuccessScore)
        self.SecondScreen.gameObject:SetActive(true)
        XTool.UpdateDynamicItem(self._GridsObj, self._ObjectiveIds, self.GridTarget, XUiGridBWSettleTarget, self)
        self:PlaySeqAnimation()
    end)
    self.TxtTime.text = XMVCA.XBigWorldCommon:GetCoolTime():GetPlayTimeStr(self._PlayTime)
end

function XUiBigWorldSettlement:DoSettleLose()
    self.PanelSettleSuccessful.gameObject:SetActiveEx(false)
    self.PanelSettleFail.gameObject:SetActiveEx(true)
    --倒计时
    self._CoolDown = 30
    self.TxtCoolDown.text = self._CoolDown
    self:StopCoolTimer()
    
    self:PlayAnimationWithMask("FailEnable", function()
        self:PlayScoreAnimation(self.TxtFailScore)

        XScheduleManagerPro.ScheduleForever(XUiBigWorldSettlement._OnCoolDownScheduleCb, self, XScheduleManagerPro.SECOND)
    end)
end

function XUiBigWorldSettlement:CheckObjectiveFinish(objectiveId)
    return XMVCA.XBigWorldQuest:CheckObjectiveFinishOnlyObjective(self._QuestId, objectiveId)
end

function XUiBigWorldSettlement:StopCoolTimer()
    XScheduleManagerPro.UnSchedule(XUiBigWorldSettlement._OnCoolDownScheduleCb, self)
end

function XUiBigWorldSettlement:OnBtnCancelClick()
    self:Close()
end

function XUiBigWorldSettlement:OnBtnReStartClick()
    XMVCA.XBigWorldGamePlay:RequestAgainChallengeInst(function() 
        self:Close()
    end)
end

function XUiBigWorldSettlement:PlayScoreAnimation(text)
    if not self._ShowScore then
        return
    end

    local score = self._Score
    self:Tween(0.5, function(dt)
        text.text = math.floor(score * dt)
    end)
end

function XUiBigWorldSettlement:PlaySeqAnimation()
    for i, grid in pairs(self._GridsObj) do
        grid:PlaySeqAnimation(i)
    end
end

function XUiBigWorldSettlement:CsCollection2Table(collection)
    if not collection then
        return
    end
    local count = collection.Count or collection.Length
    if not count or count <= 0 then
        return
    end
    local list = {}
    for i = 0, count - 1 do
        list[#list + 1] = collection[i]
    end
    return list
end

function XUiBigWorldSettlement:_OnCoolDownScheduleCb()
    self._CoolDown = self._CoolDown - 1
    self.TxtCoolDown.text = self._CoolDown
    if self._CoolDown <= 0 then
        self:OnBtnCancelClick()
    end
end

function XUiGridBWSettleTarget:_OnPlaySeqAnimationScheduleCb()
    self:PlayAnimation("GridTargetEnable")
    self:StopAnimationTimer()
end