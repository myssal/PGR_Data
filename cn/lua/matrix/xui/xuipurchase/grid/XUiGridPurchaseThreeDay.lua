---@class XUiGridPurchaseThreeDay
---@field Parent XUiPanelRecommendThreeDay
local XUiGridPurchaseThreeDay = XClass(nil, "XUiGridPurchaseThreeDay")

function XUiGridPurchaseThreeDay:Ctor(ui, parent)
    ---@type UnityEngine.GameObject
    self.GameObject = ui.gameObject
    ---@type UnityEngine.RectTransform
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)

    self.BtnGift.CallBack = handler(self, self.OnBtnGiftClick)
end

function XUiGridPurchaseThreeDay:Update()
    self:UpdateData(self.Id, self.Reward, self.IsPurchaseEnter, self.IsShow, self.Index)
end

---@param purchase XPurchasePackage
function XUiGridPurchaseThreeDay:UpdateData(id, reward, isPurchaseEnter, isShow, index)
    self.Id = id
    self.Reward = reward
    self.IsPurchaseEnter = isPurchaseEnter
    self.IsShow = isShow
    self.Index = index
    self.WeekData = XDataCenter.PurchaseManager.GetWeekCardData(id)

    local isBatter = self.Parent.BetterIndexDic[index]
    local isToday, isGain, isExpired
    if self.WeekData then
        isToday = index == self.WeekData:GetCurRoundDay()
        isGain = self.WeekData:CheckIsGotByRoundAndDay(1, index)
        isExpired = self.WeekData:CheckIsPreviousDay(1, index)
    end

    --大奖
    self.RImgBgHighlight.gameObject:SetActiveEx(isBatter)
    --已领取
    self.ImgGot.gameObject:SetActiveEx(isGain)
    --已过期
    self.ImgMask.gameObject:SetActiveEx(isExpired)

    if reward then
        self.TemplateId = reward.TemplateId
        self.BtnGift:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.TemplateId))
        self.BtnGift:SetNameByGroup(0, reward.Count)
    end

    if not isPurchaseEnter and not reward then
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
        return
    end

    if not isShow or not isToday then
        return
    end

    if isToday and isGain then
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
        return
    end

    --登录时领取奖励
    self:GetThreeDayCardReward()
end

function XUiGridPurchaseThreeDay:OnBtnGiftClick()
    if self.TemplateId then
        XLuaUiManager.Open("UiTip", self.TemplateId)
    end
end

function XUiGridPurchaseThreeDay:GetThreeDayCardReward()
    XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(self.WeekData:GetId(), function(rewards)
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
        RunAsyn(function()
            asynWaitSecond(0.7)
            self:HandlerReward(rewards)
            self.WeekData:SetWeekCardGotToday()
            self:Update()
        end)
    end)
end

function XUiGridPurchaseThreeDay:HandlerReward(rewardItems)
    if rewardItems and #rewardItems > 0 then
        self:SetReward(rewardItems)
    else
        self:SetNoReward()
    end
end

function XUiGridPurchaseThreeDay:SetReward(rewardItems)
    --self.GameObject:PlayTimelineAnimation(function() 暂无动画
    --    XUiManager.OpenUiObtain(rewardItems)
    --    self:SetEffectActive(false)
    --    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
    --end, function()
    --    self:SetEffectActive(true)
    --end)
    XUiManager.OpenUiObtain(rewardItems)
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

function XUiGridPurchaseThreeDay:SetNoReward()
    self:SetEffectActive(false)
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

function XUiGridPurchaseThreeDay:SetEffectActive(active)

end

return XUiGridPurchaseThreeDay
