---@class XUiSkyGardenShoppingStreetToastEventReward : XLuaUi
---@field TxtDetail UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetToastEventReward = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetToastEventReward")

local XUiSkyGardenShoppingStreetBuffGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffGrid")
local TIP_MSG_SHOW_TIME = 3000

--region 生命周期
function XUiSkyGardenShoppingStreetToastEventReward:OnStart()
    if self.BtnBack then
        self.BtnBack:AddEventListener(handler(self, self.CheckClose))
    end
    self._BuffUi = XUiSkyGardenShoppingStreetBuffGrid.New(self.UiSkyGardenShoppingStreetGridBuff, self)
    
    local buffData = self._Control:PopGetShowBuff()
    self:_ShowGetInfo(buffData)
end

function XUiSkyGardenShoppingStreetToastEventReward:_ShowGetInfo(buffData)
    self._BuffUi:Update(buffData)
    local buffCfg = self._Control:GetBuffConfigById(buffData.BuffConfigId)
    self.TxtName.text = buffCfg.Name
    self:_AddCloseTimer()
end

function XUiSkyGardenShoppingStreetToastEventReward:_AddCloseTimer()
    self:_RemoveCloseTimer()
    XScheduleManagerPro.ScheduleOnce(self._OnAddCloseTimerScheduleCb, self, TIP_MSG_SHOW_TIME)
end

function XUiSkyGardenShoppingStreetToastEventReward:_OnAddCloseTimerScheduleCb()
        self:CheckClose()
end

function XUiSkyGardenShoppingStreetToastEventReward:_RemoveCloseTimer()
    XScheduleManagerPro.UnSchedule(self._OnAddCloseTimerScheduleCb, self)
end

function XUiSkyGardenShoppingStreetToastEventReward:CheckClose()
    local buffData = self._Control:PopGetShowBuff()
    if not buffData then
        self:Close()
    else
        self:_ShowGetInfo(buffData)
    end
end

function XUiSkyGardenShoppingStreetToastEventReward:OnDestroy()
    self:_RemoveCloseTimer()
end
--endregion

return XUiSkyGardenShoppingStreetToastEventReward
