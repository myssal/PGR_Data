---@class XUiSkyTowerRadio : XLuaUi
local XUiSkyTowerRadio = XLuaUiManager.Register(XLuaUi, "UiSkyTowerRadio")

local TIP_MSG_SHOW_TIME = 2000

--region 生命周期
function XUiSkyTowerRadio:OnAwake()
    self:RegisterUiEvents()
end

function XUiSkyTowerRadio:OnStart(msg, isPlayEffect)
    self.TxtDesc.text = msg
    self.Effect.gameObject:SetActiveEx(isPlayEffect)
end

function XUiSkyTowerRadio:OnEnable()
    self._IsClosing = false
    self:DelayCallRaw(handler(self, self.CloseTip), TIP_MSG_SHOW_TIME)
end

function XUiSkyTowerRadio:OnDisable()
    self._IsClosing = true
    self:StopAllTweener()
end
--endregion

--region 提示
function XUiSkyTowerRadio:CloseTip()
    if self._IsClosing then
        return
    end
    self._IsClosing = true
    self:Close()
end
--endregion

--region 按钮
function XUiSkyTowerRadio:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiSkyTowerRadio:OnBtnCloseClick()
    self:CloseTip()
end
--endregion

return XUiSkyTowerRadio
