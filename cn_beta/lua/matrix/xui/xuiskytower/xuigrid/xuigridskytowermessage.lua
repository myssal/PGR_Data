
---@class XUiGridSkyTowerChatLocation : XUiNode
---@field _Control XSkyTowerControl
---@field Parent XUiSkyTowerPopupChat | XUiSkyTowerPopupStory
local XUiGridSkyTowerChatLocation = XClass(XUiNode, "XUiGridSkyTowerChatLocation")

function XUiGridSkyTowerChatLocation:Refresh(isShow, talkId, index)
    if not isShow then
        self:Close()
        return
    end
    self:Open()
    local template = self._Control:GetTalkConfig(talkId)

    self.StandIcon:SetRawImage(template.Icon)
    self.TxtName.text = template.Nickname
    self.TxtChat.text = self.Parent:GetTalkMessage(talkId)
end


---@class XUiGridSkyTowerMessage : XUiNode
---@field _Control XSkyTowerControl
local XUiGridSkyTowerMessage = XClass(XUiNode, "XUiGridSkyTowerMessage")

local LocationType = {
    Left = 1,
    Right = 2
}

function XUiGridSkyTowerMessage:OnStart()
    self.PanelLeft = XUiGridSkyTowerChatLocation.New(self.PanelLeft, self.Parent)
    self.PanelRight = XUiGridSkyTowerChatLocation.New(self.PanelRight, self.Parent)
end

function XUiGridSkyTowerMessage:Refresh(talkId, index)
    local template = self._Control:GetTalkConfig(talkId)
    local isShowRight = template.Type == LocationType.Right
    self.PanelLeft:Refresh(not isShowRight, talkId, index)
    self.PanelRight:Refresh(isShowRight, talkId, index)
end

return XUiGridSkyTowerMessage