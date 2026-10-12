local XUiGuildDialog = XLuaUiManager.Register(XLuaUi, "UiGuildDialog")
local TIMER_OFFSET = 10
function XUiGuildDialog:OnStart()
    self.CurrTime = TIMER_OFFSET
    self.BtnClose:SetNameByGroup(1, CS.XTextManager.GetText("GuildDormClose", self.CurrTime))
    self:StartTimer()
    self.BtnClose.CallBack = function()
        XLuaUiManager.RunMain()
    end
end

function XUiGuildDialog:OnDestroy()
    self:StopTimer()
end

function XUiGuildDialog:OnTimer()
    if XTool.UObjIsNil(self.BtnClose) then
        self:StopTimer() 
        return
    end
    if self.CurrTime <= 0 then
        XLuaUiManager.RunMain()
        self:StopTimer()
        return
    end
    self.CurrTime = self.CurrTime - 1
    self.BtnClose:SetNameByGroup(1, CS.XTextManager.GetText("GuildDormClose", self.CurrTime))
end

function XUiGuildDialog:StopTimer()
    XScheduleManagerPro.UnSchedule(XUiGuildDialog._OnTimerScheduleCb, self)
end

function XUiGuildDialog:StartTimer()
    if not XScheduleManagerPro.HasSchedule(XUiGuildDialog._OnTimerScheduleCb, self) then
        XScheduleManagerPro.ScheduleForever(XUiGuildDialog._OnTimerScheduleCb, self, XScheduleManagerPro.SECOND)
    end
end

function XUiGuildDialog:_OnTimerScheduleCb()
    self:OnTimer()
end

return XUiGuildDialog