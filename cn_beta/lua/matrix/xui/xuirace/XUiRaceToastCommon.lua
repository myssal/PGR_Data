---@class XUiRaceToastCommon : XLuaUi 飘字
---@field _Control XRaceControl
local XUiRaceToastCommon = XLuaUiManager.Register(XLuaUi, "UiRaceToastCommon")

function XUiRaceToastCommon:OnStart(str)
    self.TxtTitle.text = str
    XScheduleManagerPro.ScheduleOnce(self._OnStartScheduleCb, self, self._Control:GetIntClientConfig("ToastKeepTime"))
end

function XUiRaceToastCommon:_OnStartScheduleCb()
    self:Close()
end

function XUiRaceToastCommon:OnDestroy()
    XScheduleManagerPro.UnSchedule(self._OnStartScheduleCb, self)
end

return XUiRaceToastCommon