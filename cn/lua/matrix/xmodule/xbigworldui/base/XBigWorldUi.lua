---@class XBigWorldUi : XLuaUi 大世界UI专用
---@field _IsPauseFight boolean 界面打开时是否暂停战斗
---@field _IsChangeInput boolean 界面打开时是否切换为系统输入
local XBigWorldUi = XClass(XLuaUi, "XBigWorldUi")

function XBigWorldUi:OnAwakeUi()
    self._IsPauseFight = XMVCA.XBigWorldUI:IsPauseFight(self.Name)
    self._IsChangeInput = XMVCA.XBigWorldUI:IsChangeInput(self.Name)
    self._IsHideFightUi = XMVCA.XBigWorldUI:IsHideFightUi(self.Name)
    self._IsCloseCameraControl = XMVCA.XBigWorldUI:IsCloseCameraControl(self.Name)

    if self._IsPauseFight then
        XMVCA.XBigWorldGamePlay:PauseFight()
    end

    if self._IsChangeInput then
        XMVCA.XBigWorldGamePlay:ChangeSystemInput()
    end

    if self._IsHideFightUi then
        XMVCA.XBigWorldGamePlay:SetFightUiActive(false)
    end

    XLuaUi.OnAwakeUi(self)
end

function XBigWorldUi:OnDestroyUi()
    if self._IsPauseFight then
        XMVCA.XBigWorldGamePlay:ResumeFight()
    end
    
    if self._IsChangeInput then
        XMVCA.XBigWorldGamePlay:ChangeFightInput()
    end
    
    if self._IsHideFightUi then
        XMVCA.XBigWorldGamePlay:SetFightUiActive(true)
    end

    XLuaUi.OnDestroyUi(self)
end

function XBigWorldUi:SetCameraControlStatus(isActive)
    if not self._IsCloseCameraControl then return end
    XFightUtil.SetCameraOpEnabled(isActive)
end

function XBigWorldUi:OnEnableUi(...)
    self:SetCameraControlStatus(false)
    XUiManager.AddControllerTips(self.Name)
    XLuaUi.OnEnableUi(self, ...)
end

function XBigWorldUi:OnDisableUi(...)
    self:SetCameraControlStatus(true)
    XLuaUi.OnDisableUi(self, ...)
    XUiManager.RemoveControllerTips(self.Name)
end

function XBigWorldUi:ChangePauseFight(value)
    if value ~= self._IsPauseFight then
        if self._IsPauseFight then
            XMVCA.XBigWorldGamePlay:ResumeFight()
        else
            XMVCA.XBigWorldGamePlay:PauseFight()
        end
        self._IsPauseFight = value
    end
end

function XBigWorldUi:ChangeInput(value)
    if value ~= self._IsChangeInput then
        if self._IsChangeInput then
            XMVCA.XBigWorldGamePlay:ChangeFightInput()
        else
            XMVCA.XBigWorldGamePlay:ChangeSystemInput()
        end
        self._IsChangeInput = value
    end
end

function XBigWorldUi:ChangeHideFightUi(value)
    if value ~= self._IsHideFightUi then
        if self._IsHideFightUi then
            XMVCA.XBigWorldGamePlay:SetFightUiActive(true)
        else
            XMVCA.XBigWorldGamePlay:SetFightUiActive(false)
        end
        self._IsHideFightUi = value
    end
end

--- 锁住弹窗队列，直至打开的后续界面全部关闭
function XBigWorldUi:BeginOpenOperator(uiName, ...)
    if not string.IsNilOrEmpty(uiName) then
        XMVCA.XBigWorldUI:BeginPopupQueueOperator(self.Name)
        XMVCA.XBigWorldUI:Open(uiName, ...)
    end
end

--- 锁住弹窗队列，直至打开的后续界面全部关闭
function XBigWorldUi:BeginOpenOperatorAfterClose(uiName, ...)
    if not string.IsNilOrEmpty(uiName) then
        XMVCA.XBigWorldUI:InsertHeaderAwaitUi(uiName, ...)
        XMVCA.XBigWorldUI:Close(self.Name, function() 
            XMVCA.XBigWorldUI:BeginPopupQueueOperator(uiName)
        end)
    end
end

--- 修改当前Ui打开的Param， 便于动态判断是否阻塞后续弹窗
--- 对应BigWorldPopupUi的CustomModalityParams字段
function XBigWorldUi:ChangePopupUiArgByIndex(index, value)
    XMVCA.XBigWorldUI:ChangeUiDataArgByIndex(self.Name, index, value)
end

return XBigWorldUi
