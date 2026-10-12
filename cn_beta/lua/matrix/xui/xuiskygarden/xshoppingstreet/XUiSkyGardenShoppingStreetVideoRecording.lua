---@class XUiSkyGardenShoppingStreetVideoRecording : XLuaUi
---@field TxtDetail UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetVideoRecording = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetVideoRecording")
local TIP_MSG_SHOW_TIME = 2400

--region 生命周期
function XUiSkyGardenShoppingStreetVideoRecording:OnStart()
    XScheduleManagerPro.ScheduleOnce(self._OnStartScheduleCb, self, TIP_MSG_SHOW_TIME)
end

function XUiSkyGardenShoppingStreetVideoRecording:_OnStartScheduleCb()
        self:Close()
end

function XUiSkyGardenShoppingStreetVideoRecording:OnDestroy()
    XScheduleManagerPro.UnSchedule(self._OnStartScheduleCb, self)
end
--endregion

return XUiSkyGardenShoppingStreetVideoRecording
