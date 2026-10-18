---@class XUiTheatre4TipsCommon : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4TipsCommon = XLuaUiManager.Register(XLuaUi, "UiTheatre4TipsCommon")
local TIP_MSG_SHOW_TIME = 2000

function XUiTheatre4TipsCommon:Refresh(content)
    self.TxtDes.text = XUiHelper.ConvertLineBreakSymbol(content)
    self:PlayAnimation("AnimShow")
    self:StopTimer()
    XScheduleManagerPro.ScheduleOnce(self._OnCloseScheduleCb, self, TIP_MSG_SHOW_TIME)
end

function XUiTheatre4TipsCommon:OnDisable()
    self:StopTimer()
end

function XUiTheatre4TipsCommon:StopTimer()
        XScheduleManagerPro.UnSchedule(self._OnCloseScheduleCb, self)
end

function XUiTheatre4TipsCommon:_OnCloseScheduleCb()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self:Close()
end

return XUiTheatre4TipsCommon
