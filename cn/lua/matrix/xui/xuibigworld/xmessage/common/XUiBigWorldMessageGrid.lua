---@class XUiBigWorldMessageGrid : XUiNode
---@field PanelCharacter UnityEngine.RectTransform
---@field PanelChat UnityEngine.RectTransform
---@field PanelHead UnityEngine.RectTransform
---@field StandIcon UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field TxtChat UnityEngine.UI.Text
---@field RImgExpression UnityEngine.UI.RawImage
---@field _Control XBigWorldMessageControl
local XUiBigWorldMessageGrid = XClass(XUiNode, "XUiBigWorldMessageGrid")

-- region 生命周期

function XUiBigWorldMessageGrid:OnStart()
    self.LoadingEffect = self.Transform:FindTransform("PanelMessageLoading")
    self._AnimationName = "PanelCharacter"
    self:_RegisterButtonClicks()
end

function XUiBigWorldMessageGrid:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessageGrid:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
    self._AnimationName = "PanelCharacter"
    self._IsPlayed = false
end

function XUiBigWorldMessageGrid:OnDestroy()

end

-- endregion

---@param content XBWMessageContentEntity
function XUiBigWorldMessageGrid:Refresh(content)
    if content:IsMultiple() then
        self.TxtName.gameObject:SetActiveEx(true)
        self.TxtName.text = content:GetSpeakerName()
    else
        self.TxtName.gameObject:SetActiveEx(false)
    end
    self.StandIcon:SetRawImage(content:GetSpeakerIcon())

    if content:IsMemes() then
        self.TxtChat.gameObject:SetActiveEx(false)
        self.RImgExpression.gameObject:SetActiveEx(true)
        self.RImgExpression:SetRawImage(content:GetMemes())
    else
        self.TxtChat.gameObject:SetActiveEx(true)
        self.RImgExpression.gameObject:SetActiveEx(false)
        self.TxtChat.text = content:GetText()
    end
end

function XUiBigWorldMessageGrid:SetLoadingEffectActive(isActive)
    if not XTool.UObjIsNil(self.LoadingEffect) then
        self.LoadingEffect.gameObject:SetActiveEx(isActive)
        self.PanelChat.gameObject:SetActiveEx(not isActive)
    end
    if isActive then
        self._AnimationName = "PanelChatEnable"
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageGrid:PlayEnableAnimation(content)
    if content:IsComplete() then
        self:_PlayFinish(content)
        return
    end
    if self._IsPlayed then
        return
    end

    self._IsPlayed = true
    self:PlayAnimation(self._AnimationName, function()
        self:_PlayFinish(content)
    end)
end

-- region 私有方法

function XUiBigWorldMessageGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiBigWorldMessageGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMessageGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMessageGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldMessageGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldMessageGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

-- endregion

---@param content XBWMessageContentEntity
function XUiBigWorldMessageGrid:_PlayFinish(content)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAY_NEXT_MESSAGE_NOTIFY)

    if content:IsEnd() then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_PLAY_FINISH_NOTIFY, content)
    end
end

return XUiBigWorldMessageGrid
