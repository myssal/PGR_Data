local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiBigWorldProcessCoreTip = require("XUi/XUiBigWorld/XProcess/Core/Tip/XUiBigWorldProcessCoreTip")

---@class XUiBigWorldProcessCoreActivity : XUiNode
---@field ImgBg UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field BtnHelp XUiComponent.XUiButton
---@field Content UnityEngine.RectTransform
---@field GridCommon UnityEngine.RectTransform
---@field BtnGo XUiComponent.XUiButton
---@field BtnOngoing XUiComponent.XUiButton
---@field ListProgress UnityEngine.RectTransform
---@field TagNew UnityEngine.RectTransform
---@field Parent XUiBigWorldProcessCore
local XUiBigWorldProcessCoreActivity = XClass(XUiNode, "XUiBigWorldProcessCoreActivity")

function XUiBigWorldProcessCoreActivity:OnStart()
    ---@type XBWCourseCoreElementEntity
    self._Entity = false
    ---@type XUiGridBWItem[]
    self._RewardGridList = {}
    ---@type XUiBigWorldProcessCoreTip
    self._TipUi = XUiBigWorldProcessCoreTip.New(self.ListProgress, self)

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessCoreActivity:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessCoreActivity:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessCoreActivity:OnDestroy()
end

function XUiBigWorldProcessCoreActivity:OnBtnHelpClick()
    if self._Entity then
        local teachId = self._Entity:GetTeachId()

        if XTool.IsNumberValid(teachId) then
            XMVCA.XBigWorldTeach:OpenTeachTipUi(teachId)
        end
    end
end

function XUiBigWorldProcessCoreActivity:OnBtnGoClick()
    if self._Entity then
        if self._Entity:IsUnlockSkip() then
            local skipId = self._Entity:GetSkipId()

            if XTool.IsNumberValid(skipId) then
                XMVCA.XBigWorldSkipFunction:SkipTo(skipId)
            end
        elseif self._Entity:IsLockSkip() then
            local skipId = self._Entity:GetLockSkipId()

            if XTool.IsNumberValid(skipId) then
                XMVCA.XBigWorldSkipFunction:SkipTo(skipId)
            end
        end
    end
end

function XUiBigWorldProcessCoreActivity:OnBtnOngoingClick()
    if self._Entity then
        if not self._Entity:IsSkip() then
            local tip = self._Entity:GetUnableSkipTip()

            XMVCA.XBigWorldUI:TipMsg(tip)
        end
    end
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:Refresh(elementEntity)
    self._Entity = elementEntity
    self.TxtName.text = elementEntity:GetName()
    self.TagNew.gameObject:SetActiveEx(elementEntity:IsNew())
    self.BtnGo.gameObject:SetActiveEx(elementEntity:IsSkip())
    self.BtnGo:ShowReddot(elementEntity:IsSkipStateChange())
    self._TipUi:Refresh(elementEntity)
    self:_RefreshHelp(elementEntity)
    self:_RefreshLocked(elementEntity)
    self:_RefreshReward(elementEntity)
    self:_RefreshBackground(elementEntity)
    elementEntity:RecordSkipState()
end

function XUiBigWorldProcessCoreActivity:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnHelp.CallBack = Handler(self, self.OnBtnHelpClick)
    self.BtnGo.CallBack = Handler(self, self.OnBtnGoClick)
    self.BtnOngoing.CallBack = Handler(self, self.OnBtnOngoingClick)
end

function XUiBigWorldProcessCoreActivity:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessCoreActivity:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessCoreActivity:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessCoreActivity:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessCoreActivity:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessCoreActivity:_InitUi()
    self.GridCommon.gameObject:SetActiveEx(false)
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:_RefreshLocked(elementEntity)
    self.BtnOngoing.gameObject:SetActiveEx(not elementEntity:IsSkip())
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:_RefreshHelp(elementEntity)
    self.BtnHelp.gameObject:SetActiveEx(elementEntity:IsHaveTeach())
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:_RefreshBackground(elementEntity)
    self.ImgBg:SetImage(elementEntity:GetBackground())
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreActivity:_RefreshReward(elementEntity)
    local rewards = elementEntity:GetRewards()
    local index = 1

    if not XTool.IsTableEmpty(rewards) then
        for i, reward in pairs(rewards) do
            local grid = self._RewardGridList[i]

            if not grid then
                local gridUi = XUiHelper.Instantiate(self.GridCommon, self.Content)

                grid = XUiGridBWItem.New(gridUi, self)
                self._RewardGridList[i] = grid
            end

            grid:Open()
            grid:Refresh(reward)
            grid:RefreshCount()
            index = index + 1
        end
    end
    for i = index, #self._RewardGridList do
        self._RewardGridList[i]:Close()
    end
end

return XUiBigWorldProcessCoreActivity
