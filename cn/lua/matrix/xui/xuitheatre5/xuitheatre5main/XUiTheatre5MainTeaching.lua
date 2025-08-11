--- 主界面教学
---@class XUiTheatre5MainTeaching: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5MainTeaching = XClass(XUiNode, 'XUiTheatre5MainTeaching')

function XUiTheatre5MainTeaching:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnStart, self.OnClickStartEvent,true)
end

--eventData = {EventId = number, IsNew = bool}
function XUiTheatre5MainTeaching:OnEnable()
    --test 暂时隐藏
    -- local isTeaching = self._Control.PVEControl:IsInTeachingStoryLine()
    -- self.PanelFirst.gameObject:SetActiveEx(isTeaching)
    -- self.PanelSecond.gameObject:SetActiveEx(not isTeaching)  
end

function XUiTheatre5MainTeaching:OnClickStartEvent()
    self._Control.FlowControl:EnterModel()
end

return XUiTheatre5MainTeaching