


local XUiGridHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHud")
---@class XUiGridDialogHud : XUiGridHud
---@field
local XUiGridDialogHud = XClass(XUiGridHud, "XUiGridDialogHud")

local DURATION = 2 

function XUiGridDialogHud:OnDisable()
    self:StopTimer()
end

function XUiGridDialogHud:BindTarget(target, offset, text)
    XUiGridHud.BindTarget(self, target, offset)
    self.Text = text
end

function XUiGridDialogHud:RefreshView()
    self.TxtDesc.text = self.Text
    self:StartTimer()
end

function XUiGridDialogHud:StartTimer()
    self:StopTimer()
    XScheduleManagerPro.ScheduleOnce(XUiGridDialogHud._OnCloseDialogScheduleCb, self, DURATION * XScheduleManagerPro.SECOND)
end

function XUiGridDialogHud:StopTimer()
    XScheduleManagerPro.UnSchedule(XUiGridDialogHud._OnCloseDialogScheduleCb, self)
end

function XUiGridDialogHud:_OnCloseDialogScheduleCb()
    if not XTool.UObjIsNil(self.GameObject) then
        self:Close()
    end
end

return XUiGridDialogHud