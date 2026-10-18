---@class XUiSkyGardenCafePopupBroadcast : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
local XUiSkyGardenCafePopupBroadcast = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenCafePopupBroadcast")

function XUiSkyGardenCafePopupBroadcast:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafePopupBroadcast:OnStart()
    self:InitView()
    
    XMVCA.XSkyGardenCafe:AddInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_REFRESH_BROADCAST, self.InitView, self)
end

function XUiSkyGardenCafePopupBroadcast:OnDestroy()

    XMVCA.XSkyGardenCafe:RemoveInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_REFRESH_BROADCAST, self.InitView, self)
end

function XUiSkyGardenCafePopupBroadcast:StartTimer()
    self:StopTimer()
    XScheduleManagerPro.ScheduleOnce(self._OnStartTimerScheduleCb, self, 2000)
end

function XUiSkyGardenCafePopupBroadcast:_OnStartTimerScheduleCb()
        self:Close()
end

function XUiSkyGardenCafePopupBroadcast:StopTimer()
    XScheduleManagerPro.UnSchedule(self._OnStartTimerScheduleCb, self)
end

function XUiSkyGardenCafePopupBroadcast:InitUi()
end

function XUiSkyGardenCafePopupBroadcast:InitCb()
end

function XUiSkyGardenCafePopupBroadcast:InitView()
    self:StartTimer()
    self.PanelBuff.gameObject:SetActiveEx(false)
    local battleInfo = self._Control:GetBattle():GetBattleInfo()
    self.TxtRound.text = string.format(self._Control:GetRoundText(), battleInfo:GetRound())
end