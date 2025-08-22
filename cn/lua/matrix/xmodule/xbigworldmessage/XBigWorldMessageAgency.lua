---@class XBigWorldMessageAgency : XAgency
---@field private _Model XBigWorldMessageModel
local XBigWorldMessageAgency = XClass(XAgency, "XBigWorldMessageAgency")

function XBigWorldMessageAgency:OnInit()
    -- 初始化一些变量
    self.OperatorType = {
        None = 0, -- 无
        Receive = 1, -- 接收
        Read = 2, -- 阅读
        Options = 3, -- 选项
        Reply = 4, -- 回复
        Complete = 5, -- 完成
        Leave = 6, -- 离开
        Enter = 7, -- 进入
    }

    self:InitShieldController()
end

function XBigWorldMessageAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
    self:AddRpc("NotifyBigWorldNotReadMessage", handler(self, self.OnNotifyBigWorldNotReadMessage))
end

function XBigWorldMessageAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XBigWorldMessageAgency:OnRelease()
    self:RemoveShieldController()
end

function XBigWorldMessageAgency:InitShieldController()
    XMVCA.XBigWorldFunction:RegisterFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Message, self,
        self.OnShieldControl)
end

function XBigWorldMessageAgency:RemoveShieldController()
    XMVCA.XBigWorldFunction:RemoveFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Message, self,
        self.OnShieldControl)
end

function XBigWorldMessageAgency:OnNotifyBigWorldNotReadMessage(data)
    local messageId = data.MessageId
    local messageType = self._Model:GetBigWorldMessageTypeById(messageId)

    self:RecordStatistical(messageId, self.OperatorType.Receive)
    if messageType == XEnumConst.BWMessage.MessageType.Normal then
        self._Model:AddUnReadMessage(data)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY)
    else
        self._Model:AddForceMessage(data)
        self:TryOpenMessageTipUi()
    end
end

---@param controlData XBWFunctionControlData
function XBigWorldMessageAgency:OnShieldControl(controlData)
    if controlData and not controlData:IsEmpty() then
        self._Model:SetIsShieldUnReadMessage(controlData:GetArgByIndex(1))
    end
end

function XBigWorldMessageAgency:UpdateAllMessageData(data)
    self._Model:UpdateAllMessageData(data)
end

function XBigWorldMessageAgency:CheckCanPlayMessageTip()
    return self._Model:HasForceMessageData() and XMVCA.XBigWorldGamePlay:IsInGame()
end

function XBigWorldMessageAgency:CheckUnReadMessage()
    local messages = self._Model:GetUnReadMessageList()

    return not XTool.IsTableEmpty(messages)
end

function XBigWorldMessageAgency:CheckMessageUnRecord()
    local messages = self._Model:GetUnReadMessageList()

    if not XTool.IsTableEmpty(messages) then
        for _, message in pairs(messages) do
            if not self._Model:GetMessageReadRecord(message.MessageId) then
                return true
            end
        end
    end

    return false
end

function XBigWorldMessageAgency:CheckUnReadMessageShield()
    return self._Model:GetIsShieldUnReadMessage()
end

function XBigWorldMessageAgency:TryOpenMessageTipUi()
    if self:CheckCanPlayMessageTip() then
        local messageData = self._Model:PeekForceMessageData()

        if messageData then
            local state = XMVCA.XBigWorldUI:OpenWithFightSequence("UiBigWorldMessageTips", messageData)
            if state then
                self._Model:DequeueForceMessageData()
            end
            return state
        end
    end

    return false
end

function XBigWorldMessageAgency:OpenUnReadMessageUi()
    if not XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.BigWorldMessage) then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldPopupMessage")
end

function XBigWorldMessageAgency:OnReceiveMessage(message)
    -- 暂时屏蔽 后续有需求在接入
    -- local messageId = message.MessageId
    -- local messageType = self._Model:GetBigWorldMessageTypeById(messageId)

    -- if messageType == XEnumConst.BWMessage.MessageType.ForcePlay then
    --     self._Model:AddForceMessage({
    --         MessageId = messageId,
    --         State = XEnumConst.BWMessage.MessageState.NotRead,
    --     })
    --     self:TryOpenMessageTipUi()
    -- elseif messageType == XEnumConst.BWMessage.MessageType.Tips then
    --     self._Model:AddForceMessage({
    --         MessageId = messageId,
    --         State = XEnumConst.BWMessage.MessageState.NotRead,
    --     })
    --     XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY)
    --     self:TryOpenMessageTipUi()
    -- else
    --     self._Model:AddUnReadMessage({
    --         MessageId = messageId,
    --         State = XEnumConst.BWMessage.MessageState.NotRead,
    --     })
    --     XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY)
    -- end
end

function XBigWorldMessageAgency:RecordStatistical(messageId, operatorType, selectId, uiName)
    local contactsId = 0

    if XTool.IsNumberValid(messageId) then
        contactsId = self._Model:GetBigWorldMessageContactsIdById(messageId)
    end

    local record = {
        ["i_operate_type"] = operatorType or self.OperatorType.None,
        ["i_target_id"] = contactsId or 0,
        ["mail_id"] = messageId or 0,
        ["sign_id"] = selectId or 0,
        ["enter_name"] = uiName or "",
    }

    CS.XRecord.Record(record, "1100003", "BigWorldMessage")
end

function XBigWorldMessageAgency:RequestBigWorldMessageReadRecord(messageId, stepId, isFinish, callback)
    XNetwork.Call("BigWorldMessageReadRecordRequest", {
        MessageId = messageId,
        StepId = stepId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateMessageData(messageId, stepId, isFinish)

        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XMVCA.XBigWorldUI:OpenBigWorldObtain(res.RewardGoodsList)
        end

        if callback then
            callback()
        end
    end)
end

return XBigWorldMessageAgency
