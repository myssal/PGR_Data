--- 资产显示面板（血量、金币）
---@class XUiPanelTheatre6Asset : XUiNode
---@field private _Control XTheatre6Control
local XUiPanelTheatre6Asset = XClass(XUiNode, "XUiPanelTheatre6Asset")

local WaitTime = 1000

function XUiPanelTheatre6Asset:OnStart()
    self._IsBubbleOpen = false

    self.BtnHP:AddEventListener(handler(self, self.OnBtnHPClick))
    self.BtnGlod:AddEventListener(handler(self, self.OnBtnGlodClick))
    if self.BtnTaskDetailClose then
        self.BtnTaskDetailClose:AddEventListener(handler(self, self.OnBtnTaskDetailCloseClick))
    end

    self.PanelBubble.gameObject:SetActiveEx(false)
    self.UiTxtHpAdd.gameObject:SetActiveEx(false)
    self.UiTxtHpReduce.gameObject:SetActiveEx(false)
    self.UiTxtGoldAdd.gameObject:SetActiveEx(false)
    self.UiTxtGoldReduce.gameObject:SetActiveEx(false)

    self.BtnHP:SetRawImage(self._Control:GetHpIcon())
    self.BtnGlod:SetRawImage(self._Control:GetCoinIcon())
end

function XUiPanelTheatre6Asset:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_HEALTH_CHANGE, self.PlayAddHp, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_GOLD_CHANGE, self.PlayAddGold, self)
end

function XUiPanelTheatre6Asset:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_HEALTH_CHANGE, self.PlayAddHp, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_GOLD_CHANGE, self.PlayAddGold, self)
end

function XUiPanelTheatre6Asset:OnDestroy()
    self:RemoveGoldTimer()
    self:RemoveHpTimer()
end

function XUiPanelTheatre6Asset:Refresh()
    self:RefreshHp()
    self:RefreshGold()
end

function XUiPanelTheatre6Asset:RefreshHp()
    local hp = self._Control:GetCurrentHp()
    self.BtnHP:SetName(hp)
end

function XUiPanelTheatre6Asset:RefreshGold()
    local gold = self._Control:GetCurrentGold()
    self.BtnGlod:SetNameByGroup(0, gold)
end

function XUiPanelTheatre6Asset:OnBtnHPClick()
    self._IsBubbleOpen = not self._IsBubbleOpen
    self.PanelBubble.gameObject:SetActiveEx(self._IsBubbleOpen)
    self.UiTxtDetail.text = self._Control:GetHpDetail()
    self:OpenClickMask()
end

function XUiPanelTheatre6Asset:OnBtnGlodClick()
    self._IsBubbleOpen = not self._IsBubbleOpen
    self.PanelBubble.gameObject:SetActiveEx(self._IsBubbleOpen)
    self.UiTxtDetail.text = self._Control:GetGoldDetail()
    self:OpenClickMask()
end

function XUiPanelTheatre6Asset:PlayAddGold(value)
    self:RefreshGold()
    self:RemoveGoldTimer()
    if value > 0 then
        self.UiTxtGoldAdd.gameObject:SetActiveEx(true)
        self.UiTxtGoldAdd.text = string.format("+%s", value)
        XScheduleManagerPro.ScheduleOnce(self._OnPlayAddGoldScheduleCb, self, WaitTime)
    else
        self.UiTxtGoldReduce.gameObject:SetActiveEx(true)
        self.UiTxtGoldReduce.text = value
        XScheduleManagerPro.ScheduleOnce(self._OnPlayAddGoldScheduleCb2, self, WaitTime)
    end
end

function XUiPanelTheatre6Asset:_OnPlayAddGoldScheduleCb2()
        self.UiTxtGoldReduce.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6Asset:_OnPlayAddGoldScheduleCb()
        self.UiTxtGoldAdd.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6Asset:PlayAddHp(value)
    self:RefreshHp()
    self:RemoveHpTimer()
    if value > 0 then
        self.UiTxtHpAdd.gameObject:SetActiveEx(true)
        self.UiTxtHpAdd.text = string.format("+%s", value)
        XScheduleManagerPro.ScheduleOnce(self._OnPlayAddHpScheduleCb, self, WaitTime)
    else
        self.UiTxtHpReduce.gameObject:SetActiveEx(true)
        self.UiTxtHpReduce.text = value
        XScheduleManagerPro.ScheduleOnce(self._OnPlayAddHpScheduleCb2, self, WaitTime)
    end
end

function XUiPanelTheatre6Asset:_OnPlayAddHpScheduleCb2()
        self.UiTxtHpReduce.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6Asset:_OnPlayAddHpScheduleCb()
        self.UiTxtHpAdd.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6Asset:RemoveGoldTimer()
    XScheduleManagerPro.UnSchedule(self._OnPlayAddGoldScheduleCb, self)
    XScheduleManagerPro.UnSchedule(self._OnPlayAddGoldScheduleCb2, self)
end

function XUiPanelTheatre6Asset:RemoveHpTimer()
    XScheduleManagerPro.UnSchedule(self._OnPlayAddHpScheduleCb, self)
    XScheduleManagerPro.UnSchedule(self._OnPlayAddHpScheduleCb2, self)
end

function XUiPanelTheatre6Asset:OnBtnTaskDetailCloseClick()
    self._IsBubbleOpen = false
    self.PanelBubble.gameObject:SetActiveEx(false)
    self.BtnTaskDetailClose.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6Asset:OpenClickMask()
    if self._IsBubbleOpen and self.BtnTaskDetailClose then
        self.BtnTaskDetailClose.gameObject:SetActiveEx(true)
    end
end

return XUiPanelTheatre6Asset
