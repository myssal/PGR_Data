local XDlcRoom = require("XModule/XDlcRoom/XEntity/XDlcRoom")
---@class XDlcRelinkRoom : XDlcRoom
local XDlcRelinkRoom = XClass(XDlcRoom, "XDlcRelinkRoom")

function XDlcRelinkRoom:OpenMultiplayerRoom()
    XLuaUiManager.Open("UiRelinkPlayerRoom")
    XLuaUiManager.Remove("UiRelinkPopupChooseRoom")
end

function XDlcRelinkRoom:PopThenOpenMultiplayerRoom()
    XLuaUiManager.PopThenOpen("UiRelinkPlayerRoom")
end

function XDlcRelinkRoom:OpenFightUiLoading()
    XLuaUiManager.Open("UiRelinkLoading")
end

function XDlcRelinkRoom:CloseFightUiLoading()
    XLuaUiManager.Close("UiRelinkLoading")
end

function XDlcRelinkRoom:OnDisconnect()
    XLuaUiManager.Open("UiDlcSettleLose")
    XLuaUiManager.SafeClose("UiRelinkPlayerRoom")
end

function XDlcRelinkRoom:OnRoomLeaderTimeOut()
    if not XUiManager.CheckTopUi(CsXUiType.Normal, "UiRelinkPlayerRoom") then
        XLuaUiManager.Remove("UiRelinkPlayerRoom")
    end
end

function XDlcRelinkRoom:OnKickOut(code)
    if code == XCode.DlcMultiplayerClose then
        XLuaUiManager.RunMain(true)
    else
        XLuaUiManager.SafeClose("UiRelinkPopupChooseRoom")
        XLuaUiManager.SafeClose("UiRelinkPlayerRoom")
    end
end

function XDlcRelinkRoom:OnCreateRoom()
    XLuaUiManager.SafeClose("UiDialog")
end

function XDlcRelinkRoom:OnEnterWorld()
    --XLuaUiManager.SafeClose("UiRelinkPlayerRoom")
end

return XDlcRelinkRoom
