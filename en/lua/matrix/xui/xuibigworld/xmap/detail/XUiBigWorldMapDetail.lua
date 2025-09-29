local XUiSGGridItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldMapDetail : XBigWorldUi
---@field BtnClose XUiComponent.XUiButton
---@field PanelIcon UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field PanelName UnityEngine.RectTransform
---@field TxtStoryDes UnityEngine.UI.Text
---@field PanelProgress XUiComponent.XUiTextGroup
---@field PanelReward UnityEngine.RectTransform
---@field PanelItem UnityEngine.RectTransform
---@field ItemGrid UnityEngine.RectTransform
---@field ProgressList UnityEngine.RectTransform
---@field PanelBottom UnityEngine.RectTransform
---@field BtnTracking XUiComponent.XUiButton
---@field BtnCancelTracking XUiComponent.XUiButton
---@field BtnTransmit XUiComponent.XUiButton
---@field _Control XBigWorldMapControl
---@field Parent XUiBigWorldMap
local XUiBigWorldMapDetail = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMapDetail")

local OperatorType = {
    Track = 0,
    Teleport = 1,
    CancelTrack = 2,
}

-- region 生命周期

function XUiBigWorldMapDetail:OnAwake()
    ---@type XBWMapPinData
    self._PinData = nil
    ---@type XUiGridBWItem[]
    self._RewardGrids = {}
    self._ProgerssGrids = {}

    self:_RegisterButtonClicks()
end

function XUiBigWorldMapDetail:OnEnable()
    self:_Refresh()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMapDetail:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMapDetail:OnDestroy()

end

-- endregion

---@param pinData XBWMapPinData
function XUiBigWorldMapDetail:Refresh(levelId, pinData)
    self._LevelId = levelId
    self._PinData = pinData

    self:_Refresh()
end

-- region 按钮事件

function XUiBigWorldMapDetail:OnBtnCloseClick()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_DETAIL_CLOSE)
end

function XUiBigWorldMapDetail:OnBtnTrackingClick()
    local pinData = self._PinData

    if pinData then
        if not pinData:IsTracking() then
            if pinData:IsVirtual() then
                self._Control:TrackPin(pinData.LevelId, pinData.ReferPinId)
            else
                self._Control:TrackPin(pinData.LevelId, pinData.PinId)
            end
        end
    end
end

function XUiBigWorldMapDetail:OnBtnCancelTrackingClick()
    local pinData = self._PinData

    if pinData then
        if pinData:IsTracking() then
            if pinData:IsVirtual() then
                self._Control:CancelTrackPin(pinData.LevelId, pinData.ReferPinId)
            else
                self._Control:CancelTrackPin(pinData.LevelId, pinData.PinId)
            end
        end
    end
end

function XUiBigWorldMapDetail:OnBtnTransmitClick()
    local pinData = self._PinData

    if pinData and pinData:IsActive() then
        if pinData.TeleportEnable then
            self:_Teleport(pinData)
        elseif pinData:IsNearbyPin() then
            local nearbyPinId = pinData.NearbyPinId
            local nearbyPinData = self._Control:GetPinDataByLevelIdAndPinId(pinData:GetValidLevelId(), nearbyPinId)

            self:_Teleport(nearbyPinData)
        end
    end
end

function XUiBigWorldMapDetail:OnPinTrackClick(pinId, levelId)
    if self._Control:CheckCurrentTrackPin(levelId, pinId) then
        self._Control:CancelTrackPin(levelId, pinId)
    else
        self._Control:TrackPin(levelId, pinId)
    end
end

function XUiBigWorldMapDetail:OnRefresh()
    self:_Refresh()
end

-- endregion

-- region 私有方法

function XUiBigWorldMapDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnTracking, self.OnBtnTrackingClick, true)
    self:RegisterClickEvent(self.BtnCancelTracking, self.OnBtnCancelTrackingClick, true)
    self:RegisterClickEvent(self.BtnTransmit, self.OnBtnTransmitClick, true)
end

function XUiBigWorldMapDetail:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMapDetail:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMapDetail:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, self.OnRefresh, self)
end

function XUiBigWorldMapDetail:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, self.OnRefresh, self)
end

function XUiBigWorldMapDetail:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMapDetail:_Refresh()
    if self._PinData then
        if self._PinData:IsQuest() then
            self:_RefreshQuest(self._PinData.QuestId, self._PinData.QuestObjectiveId)
        elseif self._PinData:IsActivity() then
            self:_RefreshActivity(self._PinData.ActivityId)
        else
            self:_RefreshPin()
        end
    end
end

function XUiBigWorldMapDetail:_RefreshPin()
    local isActive = self._PinData:IsActive()

    self.TxtTitle.text = self._PinData.Name or ""
    self.TxtStoryDes.text = XUiHelper.ReplaceTextNewLine(self._PinData.Desc or "")
    self.TxtName.text = XMVCA.XBigWorldService:GetText("MapPinDesc")
    self:_RefreshPinStyle(self._PinData.StyleId, isActive)
    self:_RefreshTrackOperator(not (isActive and self._PinData.TeleportEnable))
    self:_RefreshTeleportOperator(isActive and self._PinData.TeleportEnable)
    self:_RefreshProgress()
    self:_RefreshReward()
end

function XUiBigWorldMapDetail:_RefreshQuest(questId, objectiveId)
    local rewardId = XMVCA.XBigWorldQuest:GetQuestRewardId(questId)
    local progressText = XMVCA.XBigWorldQuest:GetQuestDisplayProgress(questId)

    self.PanelIcon:SetSprite(XMVCA.XBigWorldQuest:GetQuestIcon(questId))
    self.TxtTitle.text = XMVCA.XBigWorldQuest:GetQuestText(questId)
    if XTool.IsNumberValid(objectiveId) then
        self.TxtStoryDes.text = XUiHelper.ReplaceTextNewLine(XMVCA.XBigWorldQuest:GetObjectiveDesc(objectiveId) or "")
    else
        self.TxtStoryDes.text = ""
    end
    self.TxtName.text = XMVCA.XBigWorldService:GetText("MapPinQuestDesc")
    self:_RefreshTrackOperator(true)
    self:_RefreshTeleportOperator(false)
    self:_RefreshProgress(progressText)
    self:_RefreshReward(rewardId)
end

function XUiBigWorldMapDetail:_RefreshActivity(activityId)
    local rewards = XMVCA.XBigWorldGamePlay:GetBigWorldActivityGoodsByActivityId(activityId)

    self:_RefreshPin()
    self:_RefreshRewardList(rewards)
end

function XUiBigWorldMapDetail:_RefreshTeleportOperator(isActive)
    if not self._PinData:IsNearbyPin() then
        self.BtnTransmit.gameObject:SetActiveEx(isActive)

        if isActive then
            if self._PinData:IsTeleportLevel() then
                self:_RefreshTeleportLevelText(self._PinData:GetTeleportLevelId())
            else
                self:_RefreshTeleportLevelText()
            end
        end
    else
        local nearbyPinId = self._PinData.NearbyPinId
        local nearbyPinData = self._Control:GetPinDataByLevelIdAndPinId(self._PinData:GetValidLevelId(), nearbyPinId)

        if nearbyPinData then
            if nearbyPinData.TeleportEnable then
                self.BtnTransmit.gameObject:SetActiveEx(true)
                if nearbyPinData:IsTeleportLevel() then
                    self:_RefreshTeleportLevelText(nearbyPinData:GetTeleportLevelId())
                else
                    self:_RefreshTeleportText(self._Control:GetTeleportText(nearbyPinData.Name))
                end
            else
                self.BtnTransmit.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiBigWorldMapDetail:_RefreshTrackOperator(isActive)
    local isTrack = self._PinData:IsTracking()

    self.BtnTracking.gameObject:SetActiveEx(isActive and not isTrack)
    self.BtnCancelTracking.gameObject:SetActiveEx(isActive and isTrack)
end

function XUiBigWorldMapDetail:_RefreshPinStyle(styleId, isActive)
    if XTool.IsNumberValid(styleId) then
        self.PanelIcon:SetSprite(self._Control:GetPinIconByStyleId(styleId, isActive))
    end
end

function XUiBigWorldMapDetail:_RefreshTeleportLevelText(teleportLevelId)
    if XTool.IsNumberValid(teleportLevelId) then
        self.BtnTransmit:SetNameByGroup(0, self._Control:GetTeleportLevelText(teleportLevelId))
    else
        self.BtnTransmit:SetNameByGroup(0, XMVCA.XBigWorldService:GetText("MapTeleportDesc"))
    end
end

function XUiBigWorldMapDetail:_RefreshTeleportText(text)
    self.BtnTransmit:SetNameByGroup(0, text or XMVCA.XBigWorldService:GetText("MapTeleportDesc"))
end

function XUiBigWorldMapDetail:_RefreshReward(rewardId)
    if XTool.IsNumberValid(rewardId) then
        local rewardList = XMVCA.XBigWorldService:GetRewardDataList(rewardId)

        self:_RefreshRewardList(rewardList)
    else
        self:_RefreshRewardList()
    end
end

function XUiBigWorldMapDetail:_RefreshRewardList(rewardList)
    if not XTool.IsTableEmpty(rewardList) then
        self.PanelReward.gameObject:SetActiveEx(true)
        for i, reward in pairs(rewardList) do
            local grid = self._RewardGrids[i]

            if not grid then
                local ui = i == 1 and self.ItemGrid or XUiHelper.Instantiate(self.ItemGrid, self.PanelItem)

                grid = XUiSGGridItem.New(ui, self)
                self._RewardGrids[i] = grid
            end

            grid:Open()
            grid:Refresh(reward)
            grid:RefreshName()
        end
        for i = #rewardList + 1, #self._RewardGrids do
            self._RewardGrids[i]:Close()
        end
    else
        for _, grid in pairs(self._RewardGrids) do
            grid:Close()
        end
        self.PanelReward.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldMapDetail:_RefreshProgress(progressList)
    if not XTool.IsTableEmpty(progressList) then
        self.ProgressList.gameObject:SetActiveEx(true)
        for i, progress in pairs(progressList) do
            local grid = self._ProgerssGrids[i]

            if not grid then
                grid = i == 1 and self.PanelProgress or XUiHelper.Instantiate(self.PanelProgress, self.ProgressList)

                self._ProgerssGrids[i] = grid
            end

            grid:SetName(progress)
        end
        for i = #progressList + 1, #self._ProgerssGrids do
            self._ProgerssGrids[i].gameObject:SetActiveEx(false)
        end
    else
        self.ProgressList.gameObject:SetActiveEx(false)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapDetail:_Teleport(pinData)
    if pinData and pinData.TeleportEnable then
        local teleportLevelId = pinData:GetTeleportLevelId()
        local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()

        if pinData:IsTeleportLevel() or teleportLevelId ~= currentLevelId then
            local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

            confirmData:InitInfo(nil, self._Control:GetTeleportLevelTips(teleportLevelId))
            confirmData:InitToggleActive(true):InitKey(self.Name)
            confirmData:InitSureClick(nil, function()
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
                    teleportLevelId, pinData.LevelId, pinData.PinId)
            end)
            confirmData:InitCancelAndCloseClick(nil, function()
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_CLOSE)
            end)

            if not XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData) then
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
                currentLevelId, pinData.LevelId, pinData.PinId)
            else
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_OPEN)
            end
        else
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT, currentLevelId,
                pinData.LevelId, pinData.PinId)
        end
    end
end

-- endregion

return XUiBigWorldMapDetail
