---@class XUiDlcRelinkToastCommonSmall : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkToastCommonSmall = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkToastCommonSmall")
local TIP_MSG_SHOW_TIME = 2000

function XUiDlcRelinkToastCommonSmall:Refresh(content)
    self.TxtDesc.text = XUiHelper.ConvertLineBreakSymbol(content)
    self:PlayAnimation("AnimShow")
    self:StopTimer()
    XScheduleManagerPro.ScheduleOnce(self._OnCloseScheduleCb, self, TIP_MSG_SHOW_TIME)
end

function XUiDlcRelinkToastCommonSmall:OnDisable()
    self:StopTimer()
end

function XUiDlcRelinkToastCommonSmall:StopTimer()
        XScheduleManagerPro.UnSchedule(self._OnCloseScheduleCb, self)
end

function XUiDlcRelinkToastCommonSmall:_OnCloseScheduleCb()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self:Close()
end

return XUiDlcRelinkToastCommonSmall
