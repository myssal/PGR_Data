---@class XUiSkyGardenShoppingStreetToastNormal : XLuaUi
---@field TxtDetail UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetToastNormal = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetToastNormal")
local TIP_MSG_SHOW_TIME = 3000

--region 生命周期
function XUiSkyGardenShoppingStreetToastNormal:OnStart(params)
    if self.BtnBack then
        self.BtnBack:AddEventListener(handler(self, self.Close))
    end
    self.TxtDetail.text = params--.Tips
    
    XScheduleManagerPro.ScheduleOnce(self._OnStartScheduleCb, self, TIP_MSG_SHOW_TIME)
end

function XUiSkyGardenShoppingStreetToastNormal:_OnStartScheduleCb()
        self:Close()
end

function XUiSkyGardenShoppingStreetToastNormal:OnDestroy()
    XScheduleManagerPro.UnSchedule(self._OnStartScheduleCb, self)
end
--endregion

return XUiSkyGardenShoppingStreetToastNormal
