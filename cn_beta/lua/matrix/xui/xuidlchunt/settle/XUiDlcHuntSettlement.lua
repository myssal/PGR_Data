local XUiDlcHuntSettlementGrid = require("XUi/XUiDlcHunt/Settle/XUiDlcHuntSettlementGrid")

---@class XUiDlcHuntSettlement:XLuaUi
local XUiDlcHuntSettlement = XLuaUiManager.Register(XLuaUi, "UiDlcHuntSettlement")

function XUiDlcHuntSettlement:Ctor()
    self._CountDownTime = CS.XGame.Config:GetInt("OnlinePraiseCountDown")
    self._IsCountDownFinish = false
    ---@type XUiDlcHuntSettlementGrid[]
    self._UiMember = {}
    self._Data = false
end

function XUiDlcHuntSettlement:OnAwake()
    self:RegisterClickEvent(self.BtnBg, self.OnClickClose)
    self._UiMember = {
        XUiDlcHuntSettlementGrid.New(self.PanelMe, self),
        XUiDlcHuntSettlementGrid.New(self.PanelDy, self),
        XUiDlcHuntSettlementGrid.New(self.PanelDy2, self),
    }
end

---@param data XDlcHuntSettle
function XUiDlcHuntSettlement:OnStart(data)
    self._Data = data
    self.Text.text = data.Name
    self.TxtDifficulty2.text = data.PassedTime
    for i = 1, #self._UiMember do
        local member = data.Members[i]
        self._UiMember[i]:Update(member)
    end
end

function XUiDlcHuntSettlement:OnEnable()
    self:StartTimerClose()
    self:StartTimerUi()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ADD_LIKE_NOTIFY, self.OnNotifyAddLike, self)
end

function XUiDlcHuntSettlement:OnDisable()
    self:StopTimerClose()
    self:StopTimerUi()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ADD_LIKE_NOTIFY, self.OnNotifyAddLike, self)
end

function XUiDlcHuntSettlement:StartTimerClose()
    XScheduleManagerPro.ScheduleOnce(XUiDlcHuntSettlement._OnEnableCloseScheduleCb, self, self._CountDownTime * XScheduleManagerPro.SECOND)
end

function XUiDlcHuntSettlement:StopTimerClose()
    XScheduleManagerPro.UnSchedule(XUiDlcHuntSettlement._OnEnableCloseScheduleCb, self)
end

function XUiDlcHuntSettlement:StartTimerUi()
    self.PanelCountDown.gameObject:SetActive(true)
    if self.DescClose then
        self.DescClose.gameObject:SetActive(false)
    end
    self._CountDownStartTicks = CS.XTimerManager.Ticks
    XScheduleManagerPro.ScheduleNextFrame(XUiDlcHuntSettlement._OnRefreshCountDownScheduleCb, self)
end

function XUiDlcHuntSettlement:StopTimerUi()
    XScheduleManagerPro.UnSchedule(XUiDlcHuntSettlement._OnRefreshCountDownScheduleCb, self)
end

function XUiDlcHuntSettlement:OnClickClose()
    if self._IsCountDownFinish then
        XLuaUiManager.PopThenOpen("UiDlcHuntPersonalSettlement", self._Data)
    end
end

function XUiDlcHuntSettlement:OnAddLike(playerIdLike)
    XDataCenter.DlcRoomManager.AddLike(playerIdLike)
    for k, grid in pairs(self._UiMember) do
        local playerId = grid:GetPlayerId()
        if playerId ~= XPlayer.Id then
            if playerId == playerIdLike then
                grid:SwitchAlreadyLike()
            else
                grid:SwitchDisabledLike()
            end
        end
    end
end

function XUiDlcHuntSettlement:OnApplyFriend(playerId)
    XDataCenter.SocialManager.ApplyFriend(playerId)
end

function XUiDlcHuntSettlement:OnNotifyAddLike(data)
    local playerIdLike = data.ToPlayerId
    if playerIdLike == XPlayer.Id then
        for k, grid in pairs(self._UiMember) do
            local playerId = grid:GetPlayerId()
            if playerId == playerIdLike then
                grid:AddLikeNumber()
            end
        end
    end
end

function XUiDlcHuntSettlement:_OnEnableCloseScheduleCb()
    self._IsCountDownFinish = true
end

function XUiDlcHuntSettlement:_OnRefreshCountDownScheduleCb()
    local countDownTime = self._CountDownTime
    local t = countDownTime - (CS.XTimerManager.Ticks - self._CountDownStartTicks) / CS.System.TimeSpan.TicksPerSecond
    self.ImgCountDownBarRight.fillAmount = t / countDownTime
    self.ImgCountDownBarLeft.fillAmount = t / countDownTime
    if t <= 0 then
        self:StopTimerUi()
        self.PanelCountDown.gameObject:SetActive(false)
        if self.DescClose then
            self.DescClose.gameObject:SetActive(true)
        end
        return
    end
    XScheduleManagerPro.ScheduleNextFrame(XUiDlcHuntSettlement._OnRefreshCountDownScheduleCb, self)
end

return XUiDlcHuntSettlement