---@class XUiBigWorldNarrative : XBigWorldUi
---@field TitleText UnityEngine.UI.Text
---@field ContentText UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButton
---@field PanelPhoto UnityEngine.Transform
---@field PanelNarrative UnityEngine.Transform
local XUiBigWorldNarrative = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldNarrative")

--dlc的通用问题，不打开界面也会require, 在后面加个容错
local OpType
local NarrativeType = {
    Text = 1,
    Photo = 2,
}

function XUiBigWorldNarrative:OnAwake()
    if XMVCA:IsRegisterAgency(ModuleId.XBigWorldQuest) then
        OpType = XMVCA.XBigWorldQuest.QuestOpType
    end
    self._currentId = 0
    self._closedCallback = nil
    ---@type XUiBigWorldNarrativePhotoPanel
    self._panelPhoto = require("XUi/XUiBigWorld/XNarrative/XUiBigWorldNarrativePhotoPanel").New(self.PanelPhoto, self)
    self._panelPhoto:Close()
end

function XUiBigWorldNarrative:OnStart()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
end

function XUiBigWorldNarrative:OnEnable(id, closedCallback)
    self._currentId = id
    self._curNarrativeType = XMVCA.XBigWorldService:GetNarrativeType(self._currentId)
    self._closedCallback = closedCallback

    self:Refresh()

    -- 通用的ui流程不支持子UI，所以这里需要自己手动调用
    self:ChangePauseFight(true)
    self:ChangeInput(true)
    if OpType then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupBegin)
    end
end

function XUiBigWorldNarrative:OnDisable()
    self._currentId = 0
    self._closedCallback = nil
    self:ChangePauseFight(false)
    self:ChangeInput(false)
    
    if OpType then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupEnd)
    end
end

function XUiBigWorldNarrative:Refresh()
    self.PanelNarrative.gameObject:SetActiveEx(self._curNarrativeType == NarrativeType.Text)
    self.PanelPhoto.gameObject:SetActiveEx(self._curNarrativeType == NarrativeType.Photo)
    if self._curNarrativeType == NarrativeType.Text then
        self.TitleText.text = XMVCA.XBigWorldService:GetNarrativeTitle(self._currentId)
        self.ContentText.text = XMVCA.XBigWorldService:GetNarrativeContent(self._currentId)
        self.ContentText.alignment = XMVCA.XBigWorldService:GetNarrativeAlignment(self._currentId)
        self._panelPhoto:Close()
    elseif self._curNarrativeType == NarrativeType.Photo then
        self._panelPhoto:Open()
        self._panelPhoto:Refresh(self._currentId)
    end

    local signature = XMVCA.XBigWorldService:GetNarrativeSignature(self._currentId)
    if string.IsNilOrEmpty(signature) then
        self.SignatureText.gameObject:SetActiveEx(false)
    else
        self.SignatureText.gameObject:SetActiveEx(true)
        self.SignatureText.text = signature
    end

    local rawImage = XMVCA.XBigWorldService:GetNarrativeRawImage(self._currentId)
    if string.IsNilOrEmpty(rawImage) then
        self.BgRImg.gameObject:SetActiveEx(false)
    else
        self.BgRImg.gameObject:SetActiveEx(true)
        self.BgRImg:SetRawImage(rawImage)
    end
end

function XUiBigWorldNarrative:OnBtnCloseClick()
    local cb = self._closedCallback
    local id = self._currentId
    self._closedCallback = nil
    self:Close()
    if cb then
        cb(id)
    end
end
