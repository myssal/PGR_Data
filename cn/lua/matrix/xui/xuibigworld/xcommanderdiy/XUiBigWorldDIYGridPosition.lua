---@class XUiBigWorldDIYGridPosition : XUiNode
---@field BtnClick XUiComponent.XUiButton
---@field ImgBg UnityEngine.UI.Image
---@field ImgPosition UnityEngine.UI.Image
---@field TxtName UnityEngine.UI.Text
---@field PanelNow UnityEngine.RectTransform
---@field Red UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
---@field ImgSelect UnityEngine.UI.Image
---@field PanelSuit UnityEngine.RectTransform
---@field PanelExclusive UnityEngine.RectTransform
---@field _Control XBigWorldCommanderDIYControl
---@field Parent XUiBigWorldDIY
local XUiBigWorldDIYGridPosition = XClass(XUiNode, "XUiBigWorldDIYGridPosition")

-- region 生命周期
function XUiBigWorldDIYGridPosition:OnStart()
    ---@type XBWCommanderDIYPartEntity
    self._Entity = false
    self._Index = 0
    self.CanvasGroup = self.Transform:GetComponent("CanvasGroup")
    self.GridEnable = self.Transform:FindTransform("GridEnable")
    self:_RegisterButtonClicks()
end

function XUiBigWorldDIYGridPosition:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldDIYGridPosition:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldDIYGridPosition:OnDestroy()

end
-- endregion

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIYGridPosition:Refresh(entity, index)
    if not entity then
        return
    end

    self._Entity = entity
    self._Index = index
    self.TxtName.text = entity:GetName()
    if not entity:IsTemporary() then
        self.ImgPosition:SetSprite(entity:GetIcon())
    end
    self:SetSelect(entity:IsAttired(), true)
    self:_RefreshEmpty(entity:IsTemporary())
    self:_RefreshPanelNow(entity:IsNow())
    self:_RefreshSuit(entity:IsSuit())
    self:_RefreshExclusive(entity:IsIncompatible())
end

function XUiBigWorldDIYGridPosition:RefreshCurrent()
    local entity = self._Entity

    self.TxtName.text = entity:GetName()
    if not entity:IsTemporary() then
        self.ImgPosition:SetSprite(entity:GetIcon())
    end
    self:SetSelect(entity:IsAttired(), false)
    self:_RefreshEmpty(entity:IsTemporary())
    self:_RefreshPanelNow(entity:IsNow())
    self:_RefreshSuit(entity:IsSuit())
    self:_RefreshExclusive(entity:IsIncompatible())
end

function XUiBigWorldDIYGridPosition:SetSelect(isSelect, isPlayEnable)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
    if isSelect then
        self.Parent:ShowColor(self._Entity, isPlayEnable)
    end
end

function XUiBigWorldDIYGridPosition:StopAnimationTimer()
    if not self._AnimationTimer then
        return
    end
    XScheduleManager.UnSchedule(self._AnimationTimer)
    self._AnimationTimer = false
end

function XUiBigWorldDIYGridPosition:PlayEnableAnimation(index)
    self:StopAnimationTimer()
    self.CanvasGroup.alpha = 0
    self._AnimationTimer = XScheduleManager.ScheduleOnce(function()
        self.GridEnable:PlayTimelineAnimation()
        self:StopAnimationTimer()
    end, 80 * index)
end

-- region 按钮事件

function XUiBigWorldDIYGridPosition:OnBtnClickClick()
    if self._Entity:IsIncompatible() then
        local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

        confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("DIYChangeSuitTip"))
        confirmData:InitSureClick(nil, function()
            self._Entity:Dress()
            self.Parent:ChangeSelect(self._Index, true)
            self:SetSelect(true, false)
        end)
        confirmData:InitToggleActive(true):InitKey("XUiBigWorldDIYGridPosition")

        if not XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData) then
            self._Entity:Dress()
            self.Parent:ChangeSelect(self._Index, true)
            self:SetSelect(true, false)
        end
    else
        self._Entity:Dress()
        self.Parent:ChangeSelect(self._Index)
        self:SetSelect(true, false)
    end
end

-- endregion

-- region 私有方法
function XUiBigWorldDIYGridPosition:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick, true)
end

function XUiBigWorldDIYGridPosition:_RefreshPanelNow(isNow)
    self.PanelNow.gameObject:SetActiveEx(isNow)
end

function XUiBigWorldDIYGridPosition:_RefreshEmpty(isEmpty)
    self.ImgPosition.gameObject:SetActiveEx(not isEmpty)
    self.PanelNone.gameObject:SetActiveEx(isEmpty)
end

function XUiBigWorldDIYGridPosition:_RefreshSuit(isSuit)
    if self.PanelSuit then
        self.PanelSuit.gameObject:SetActiveEx(isSuit)
    end
end

function XUiBigWorldDIYGridPosition:_RefreshExclusive(isExclusive)
    if self.PanelExclusive then
        self.PanelExclusive.gameObject:SetActiveEx(isExclusive)
    end
end

function XUiBigWorldDIYGridPosition:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldDIYGridPosition:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldDIYGridPosition:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldDIYGridPosition:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldDIYGridPosition:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end
-- endregion

return XUiBigWorldDIYGridPosition
