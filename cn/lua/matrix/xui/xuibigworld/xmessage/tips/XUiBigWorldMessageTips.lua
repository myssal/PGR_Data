---@class XUiBigWorldMessageTips : XBigWorldUi
---@field BtnClick XUiComponent.XUiButton
---@field ImgHead UnityEngine.UI.RawImage
---@field TxtTips UnityEngine.UI.Text
---@field Mask UnityEngine.CanvasGroup
---@field _Control XBigWorldMessageControl
local XUiBigWorldMessageTips = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMessageTips")

-- region 生命周期

function XUiBigWorldMessageTips:OnAwake()
    ---@type XBWMessageData
    self._MessageData = false
    self._IsForce = false
    self._Timer = false

    self:_RegisterButtonClicks()
end

---@param messageData XBWMessageData
function XUiBigWorldMessageTips:OnStart(messageData)
    self._MessageData = messageData
    
    self:_Init()
    XMVCA.XBigWorldMessage:RecordStatistical(messageData.MessageId, XMVCA.XBigWorldMessage.OperatorType.Enter, 0, self.Name)
end

function XUiBigWorldMessageTips:OnEnable()
    self:_Refresh()
    self:_PlayEnableAnimation()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessageTips:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMessageTips:OnDestroy()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_COMPLETE)
    XMVCA.XBigWorldMessage:RecordStatistical(self._MessageData.MessageId, XMVCA.XBigWorldMessage.OperatorType.Leave, 0, self.Name)
end

-- endregion

-- region 按钮事件

function XUiBigWorldMessageTips:OnBtnClickClick()
    self:_AutoOpenMessage()
end

-- endregion

-- region 私有方法

function XUiBigWorldMessageTips:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick, true)
end

function XUiBigWorldMessageTips:_RegisterSchedules()
    self:_RemoveSchedules()

    if not self._MessageData then
        return
    end

    -- 在此处注册定时器
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self._Timer = false
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY)
        self:_PlayDisableAnimation()
    end, self._Control:GetMessageTipShowTime() * XScheduleManager.SECOND)

end

function XUiBigWorldMessageTips:_RemoveSchedules()
    -- 在此处移除定时器
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiBigWorldMessageTips:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldMessageTips:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldMessageTips:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMessageTips:_Refresh()
    if self._MessageData then
        self.ImgHead:SetRawImage(self._Control:GetContactsIconByMessageId(self._MessageData.MessageId))
    end
end

function XUiBigWorldMessageTips:_PlayEnableAnimation()
    self:PlayAnimationWithMask("Enable", function()
        self.Mask.gameObject:SetActiveEx(self._IsForce or false)
    end)
end

function XUiBigWorldMessageTips:_PlayDisableAnimation()
    self:PlayAnimationWithMask("Disable", function()
        if self._IsForce then
            self:_AutoOpenMessage()
        else
            self:Close()
        end
    end)
end

function XUiBigWorldMessageTips:_AutoOpenMessage()
    local messageData = self._MessageData

    if messageData then
        --self:BeginOpenOperatorAfterClose("UiBigWorldPopupMessageSingle", messageData.MessageId)
        XMVCA.XBigWorldUI:Close(self.Name, function() 
            XMVCA.XBigWorldUI:Open("UiBigWorldPopupMessageSingle", messageData.MessageId)
        end)
    else
        self:Close()
    end
end

function XUiBigWorldMessageTips:_Init()
    self._IsForce = self._Control:CheckMessageIsForcePlay(self._MessageData.MessageId)
    self.Mask.gameObject:SetActiveEx(true)
    self:ChangeInput(self._IsForce)
    self:ChangeHideFightUi(self._IsForce)
    if self._IsForce then
        self:ChangePopupUiArgByIndex(1, 1)
    else
        self:ChangePopupUiArgByIndex(1, 0)
    end
end

-- endregion

return XUiBigWorldMessageTips
