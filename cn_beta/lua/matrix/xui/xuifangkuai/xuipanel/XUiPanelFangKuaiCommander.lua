---@class XUiPanelFangKuaiCommander : XUiNode 首席弹框
---@field Parent XUiFangKuaiFight
---@field _Control XFangKuaiControl
local XUiPanelFangKuaiCommander = XClass(XUiNode, "XUiPanelFangKuaiCommander")

function XUiPanelFangKuaiCommander:OnStart()
    self._CommandantPopTime = tonumber(self._Control:GetClientConfig("CommandantPopTime"))
    self.TxtTips.text = self._Control:GetClientConfig("CommandantText")
end

function XUiPanelFangKuaiCommander:OnEnable()
    XScheduleManagerPro.ScheduleOnce(self.Close, self, self._CommandantPopTime * 1000)
end

function XUiPanelFangKuaiCommander:OnDestroy()
    XScheduleManagerPro.UnSchedule(self.Close, self)
end

return XUiPanelFangKuaiCommander
