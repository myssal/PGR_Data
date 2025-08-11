---@class XUiGridRelinkPopupPlayerInvite : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiRelinkPopupPlayerInvite
local XUiGridRelinkPopupPlayerInvite = XClass(XUiNode, "XUiGridRelinkPopupPlayerInvite")

function XUiGridRelinkPopupPlayerInvite:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnInvite, self.OnBtnInviteClick, true)
end

---@param friendInfo XDlcRelinkFriend
function XUiGridRelinkPopupPlayerInvite:Refresh(friendInfo)
    self.FriendInfo = friendInfo
    self.TxtName.text = friendInfo:GetName()
    XUiPlayerHead.InitPortraitWithoutStandIcon(friendInfo:GetHeadIconId(), friendInfo:GetHeadFrameId(), self.HeadObject)
    self:RefreshState()
end

function XUiGridRelinkPopupPlayerInvite:RefreshState()
    if self._Control:CheckPlayerInRoom(self.FriendInfo:GetFriendId()) then
        self.BtnInvite.gameObject:SetActiveEx(false)
        self.TxtTips.gameObject:SetActiveEx(true)
        self.TxtTips.text = XUiHelper.GetText("DlcMultiplayerInvitedInRoomTips")
    else
        self:RefreshInvitedState()
    end
end

function XUiGridRelinkPopupPlayerInvite:RefreshInvitedState()
    local isOnline = self.FriendInfo:GetIsOnline()
    self.TxtTips.gameObject:SetActiveEx(not isOnline)
    self.BtnInvite.gameObject:SetActiveEx(isOnline)
    if isOnline then
        local canInvite = self:CheckInviteCd()
        self.BtnInvite:SetButtonState(canInvite and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    else
        self.TxtTips.text = XUiHelper.GetText("FriendLatelyLogin") .. XUiHelper.CalcLatelyLoginTimeEx(self.FriendInfo:GetLastLoginTime())
    end
end

function XUiGridRelinkPopupPlayerInvite:CheckInviteCd()
    local invitedTime = self.FriendInfo:GetInvitedTime()
    if invitedTime <= 0 then
        return true
    end
    local nowTime = XTime.GetServerNowTimestamp()
    local invitedCd = XMVCA.XDlcRoom:GetInviteShowTime()
    return nowTime - invitedTime >= invitedCd
end

function XUiGridRelinkPopupPlayerInvite:OnBtnInviteClick()
    if not self.FriendInfo:GetIsOnline() then
        return
    end

    if not self:CheckInviteCd() then
        return
    end

    if XMVCA.XDlcRoom:IsInRoom() then
        local team = XMVCA.XDlcRoom:GetTeam()
        if team and team:IsFull() then
            XUiManager.TipText("DlcMultiplayerFullInvitedTip")
            return
        end
    end

    self.FriendInfo:SetInvitedTime(XTime.GetServerNowTimestamp())
    self.Parent:OnInviteClick(self.FriendInfo:GetFriendId())
    self:RefreshInvitedState()
end

return XUiGridRelinkPopupPlayerInvite
