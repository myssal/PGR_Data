---推演问题
---@class XUiTheatre5PVEReasoningAnswerItem: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEReasoningAnswerItem = XClass(XUiNode, 'XUiTheatre5PVEReasoningAnswerItem')

function XUiTheatre5PVEReasoningAnswerItem:OnStart()
    self._ClueId = nil
    XUiHelper.RegisterClickEvent(self, self.BtnGridAnswer, self.OnClickAnswer,true)
end

function XUiTheatre5PVEReasoningAnswerItem:Update(clueId)
    self._ClueId = clueId
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueId)
    if not clueCfg then
        return
    end
    self.BtnGridAnswer:SetName(clueCfg.Title)
end

function XUiTheatre5PVEReasoningAnswerItem:SetSelect(clueId)
    local isLastSelect = self.BtnGridAnswer.ButtonState == CS.UiButtonState.Select
    if self.BtnGridAnswer then 
        self.BtnGridAnswer:SetButtonState(self._ClueId == clueId and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
    local btnNormalEnable = XUiHelper.TryGetComponent(self.Transform, "Normal/Animation/BtnNormalEnable", nil)
    if btnNormalEnable and isLastSelect then
        btnNormalEnable:PlayTimelineAnimation()
    end     
end

function XUiTheatre5PVEReasoningAnswerItem:OnClickAnswer()
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_SELECT_DEDUCE_ANSWER, self._ClueId)
end

return XUiTheatre5PVEReasoningAnswerItem