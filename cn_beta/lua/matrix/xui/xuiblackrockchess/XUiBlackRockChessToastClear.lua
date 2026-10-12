---@class XUiBlackRockChessToastClear : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessToastClear = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessToastClear")

function XUiBlackRockChessToastClear:OnStart(title)
    local time = tonumber(self._Control:GetClientConfig("ToastShowTime"))
    XScheduleManagerPro.ScheduleOnce(self.Close, self, time)
end

function XUiBlackRockChessToastClear:OnDestroy()
    XScheduleManagerPro.UnSchedule(self.Close, self)
end

return XUiBlackRockChessToastClear