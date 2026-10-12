local XUiPanelAnniversaryPreHeatingContent =
    require("XUi/XUiAnniversaryPreHeating/XUiPanelAnniversaryPreHeatingContent")
local XAnniversaryPreHeatingEnumConst =
    require("XModule/XAnniversaryPreHeating/XAnniversaryPreHeatingEnumConst")

---@class XUiAnniversaryPreHeating : XLuaUi
---@field _Control XAnniversaryPreHeatingControl
local XUiAnniversaryPreHeating = XLuaUiManager.Register(XLuaUi, "UiAnniversaryPreHeating")

function XUiAnniversaryPreHeating:OnAwake()
    self:_InitComponents()
    self:_RegisterButtonEvents()
end

function XUiAnniversaryPreHeating:OnStart()
    self:_Refresh()
end

function XUiAnniversaryPreHeating:OnEnable()
    self:_StartTimer()
    self:_OnTimer()
end

function XUiAnniversaryPreHeating:OnDisable()
    self:_StopTimer()
end

function XUiAnniversaryPreHeating:_RegisterButtonEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiAnniversaryPreHeating:_InitComponents()
    self._PanelContent = XUiPanelAnniversaryPreHeatingContent.New(self.PanelContent, self)
    self._PanelContent:Close()

    self._GroupConfigs = {}  -- 组活动的读表数据
    self._GroupButtons = {}  -- 组按钮中所有按钮的实例
    self._LockedGroupButtons = {}  -- 待解锁的组按钮，key为groupId
    self._SelectGroupId = 0  -- 当前组按钮选中的Idx

    self._ContentConfigs = {}
    self._TopButtons = {}
    self._SelectContentId = 0

    self._RewardGrids = {}
    self.Grid256New.gameObject:SetActiveEx(false)
end

function XUiAnniversaryPreHeating:_Refresh()
    local activityId = self._Control:GetActivityId()
    self._SelectGroupId = 0
    self._GroupConfigs = self._Control:GetGroupConfigsByActivityId(activityId)
    self:_RefreshGroupTabs()

end

--region 开启定时器，更新剩余时间文本+Group解锁

function XUiAnniversaryPreHeating:_StartTimer()
    self:_StopTimer()
    XScheduleManagerPro.ScheduleForever(self._OnTimer, self, XScheduleManagerPro.SECOND)
end

function XUiAnniversaryPreHeating:_StopTimer()
    XScheduleManagerPro.UnSchedule(self._OnTimer, self)
end

function XUiAnniversaryPreHeating:_OnTimer()
    if not self:_RefreshTime() then
        return
    end
    self:_RefreshLockedGroupButtons()
end

---@return boolean
function XUiAnniversaryPreHeating:_RefreshTime()
    if not self._Control:IsActivityInTime() then
        self:_StopTimer()
        self:Close()
        return false
    end

    self.TxtTime.text = self._Control:GetRemainTimeText()
    return true
end

--endregion 开启定时器，更新剩余时间文本

--region GroupTab

function XUiAnniversaryPreHeating:_RefreshGroupTabs()
    self._GroupButtons = {}
    self._LockedGroupButtons = {}
    -- RefreshCustomizedList 一个可以批量实例化子控件的工具，handleFunc用于对实例化后的控件reset
    -- 该方法不能兼容XUiNode类型子节点
    XUiHelper.RefreshCustomizedList(
        self.GroupTab.transform,
        self.BtnGroup,
        #self._GroupConfigs,
        function(index, grid)
            local groupConfig = self._GroupConfigs[index]
            local button = grid:GetComponent(typeof(CS.XUiComponent.XUiButton))
            local isOpen = self._Control:IsGroupInTime(groupConfig.Id)

            button:SetNameByGroup(0, groupConfig.Name or "")
            button:SetButtonState(isOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
            if not string.IsNilOrEmpty(groupConfig.GroupBg) then
                button:SetRawImage(groupConfig.GroupBg)
            end

            self._GroupButtons[index] = button
            if not isOpen then
                self._LockedGroupButtons[groupConfig.Id] = button
            end
        end
    )

    self.GroupTab:Init(self._GroupButtons, handler(self, self.OnGroupTabClick))
    self:_RefreshGroupRedPoints()
    local selectIndex = self:_GetDefaultGroupIndex()
    if not XTool.IsNumberValid(selectIndex) then
        self._PanelContent:Close()
        self:_RefreshContentTabs(0)
        self:_RefreshReadReward(0, 0)
        return
    end

    self.GroupTab:SelectIndex(selectIndex)
    return
end

function XUiAnniversaryPreHeating:OnGroupTabClick(index)
    local groupConfig = self._GroupConfigs[index]
    if not groupConfig or self._SelectGroupId == groupConfig.Id then
        return
    end
    
    --未到开放时间
    if not self._Control:IsGroupInTime(groupConfig.Id) then
        XUiManager.TipMsg(self._Control:GetGroupUnlockTips(groupConfig.Id))
        return
    end

    self._SelectGroupId = groupConfig.Id
    self._SelectContentId = 0

    self:_RefreshContentTabs(groupConfig.Id)
    self:_RefreshReadReward(groupConfig.Id, groupConfig.RewardId)
end

function XUiAnniversaryPreHeating:_GetDefaultGroupIndex()
    for index, groupConfig in ipairs(self._GroupConfigs) do
        if self._Control:IsGroupInTime(groupConfig.Id) then
            return index
        end
    end

    return 0
end

function XUiAnniversaryPreHeating:_RefreshGroupRedPoints()
    for index, groupConfig in ipairs(self._GroupConfigs) do
        local button = self._GroupButtons[index]
        if button then
            button:ShowReddot(self._Control:CheckGroupRedPoint(groupConfig.Id))
        end
    end
end

function XUiAnniversaryPreHeating:_RefreshLockedGroupButtons()
    for groupId, button in pairs(self._LockedGroupButtons) do
        if self._Control:IsGroupInTime(groupId) then
            button:SetButtonState(CS.UiButtonState.Normal)
            button:ShowReddot(self._Control:CheckGroupRedPoint(groupId))
            self._LockedGroupButtons[groupId] = nil
        end
    end
end

--endregion GroupTab

--region ContentTab

function XUiAnniversaryPreHeating:_RefreshContentTabs(groupId)
    self._ContentConfigs = self._Control:GetContentConfigsByGroupId(groupId)
    self._TopButtons = {}

    XUiHelper.RefreshCustomizedList(
        self.ContentTab.transform,
        self.BtnTopTab,
        #self._ContentConfigs,
        function(index, grid)
            local contentConfig = self._ContentConfigs[index]
            local button = grid:GetComponent(typeof(CS.XUiComponent.XUiButton))

            button:SetNameByGroup(0, contentConfig.Name or "")
            button:SetButtonState(CS.UiButtonState.Normal)
            button:SetSpriteVisible(XTool.IsNumberValid(contentConfig.Tag))
            if not string.IsNilOrEmpty(contentConfig.NameBg) then
                button:SetRawImage(contentConfig.NameBg)
            end

            self._TopButtons[index] = button
        end
    )

    self.ContentTab:Init(self._TopButtons, handler(self, self.OnTopTabClick))
    self:_RefreshContentRedPoints()
    if not XTool.IsTableEmpty(self._ContentConfigs) then
        self.ContentTab:SelectIndex(1)
    else
        self._PanelContent:Close()
    end
end

function XUiAnniversaryPreHeating:_RefreshContentRedPoints()
    for index, contentConfig in ipairs(self._ContentConfigs) do
        local button = self._TopButtons[index]
        if button then
            button:ShowReddot(not self._Control:IsContentRead(self._SelectGroupId, contentConfig.Id))
        end
    end
end

function XUiAnniversaryPreHeating:OnTopTabClick(index)
    local contentConfig = self._ContentConfigs[index]
    if not contentConfig or self._SelectContentId == contentConfig.Id then
        return
    end

    self._SelectContentId = contentConfig.Id
    self._PanelContent:Update(contentConfig.Id)
    self._PanelContent:Open()
end

function XUiAnniversaryPreHeating:_RequestContentRead(contentId)
    if self._SelectContentId ~= contentId then
        return
    end

    self._Control:AnniversaryPreHeatingReadRequest(
        self._SelectGroupId, contentId, handler(self, self._OnContentReadSuccess))
end

---@param groupId number
function XUiAnniversaryPreHeating:_OnContentReadSuccess(groupId)
    if self:IsDestroy() then
        return
    end

    self:_RefreshGroupRedPoints()
    self:_RefreshContentRedPoints()
    if self._SelectGroupId == groupId then
        local readCount, totalCount = self._Control:GetGroupReadProgress(groupId)
        self:_RefreshReadProgress(readCount, totalCount)
        self:_RefreshRewardState(self._Control:GetGroupWatchRewardState(groupId))
    end
end

--endregion ContentTab

--region PanelReadReward

---@param groupId number
---@param rewardId number
function XUiAnniversaryPreHeating:_RefreshReadReward(groupId, rewardId)
    if not XTool.IsNumberValid(groupId) then
        self:_RefreshReadProgress(0, 0)
        self:_RefreshRewardList({})
        self:_RefreshRewardState(nil)
        return
    end

    local readCount, totalCount = self._Control:GetGroupReadProgress(groupId)
    self:_RefreshReadProgress(readCount, totalCount)
    self:_RefreshRewardList(self._Control:GetRewardList(rewardId))
    self:_RefreshRewardState(self._Control:GetGroupWatchRewardState(groupId))
end

function XUiAnniversaryPreHeating:_RefreshReadProgress(readCount, totalCount)
    self.TxtRead.text = self._Control:GetWatchTimesText(readCount, totalCount)
end

function XUiAnniversaryPreHeating:_RefreshRewardList(rewardList)
    -- 按照Reward的数量生成对应个数的GridCommon，返回_RewardGrids,GridCommon控制Grid256New，且生成的Prefab的parent为Grid256New的parent
    XTool.UpdateDynamicGridCommon(self._RewardGrids, rewardList, self.Grid256New, self)
end

function XUiAnniversaryPreHeating:_RefreshRewardState(state)
    local stateEnum = XAnniversaryPreHeatingEnumConst.WatchRewardState
    local isCanReceive = state == stateEnum.CanReceive
    local isReceived = state == stateEnum.Received

    for _, rewardGrid in ipairs(self._RewardGrids) do
        rewardGrid:SetReceived(isReceived)
        rewardGrid:SetProxyClickFunc(isCanReceive and handler(self, self._OnRewardGridClick) or nil)
        rewardGrid.ImgCanReceive.gameObject:SetActiveEx(isCanReceive)
    end
end

function XUiAnniversaryPreHeating:_OnRewardGridClick()
    self._Control:AnniversaryPreHeatingRewardRequest(
        self._SelectGroupId, handler(self, self._OnGetRewardSuccess))
end

---@param groupId number
---@param rewardId number

-- 领取奖励后 1.更新奖励区状态  2.更新Group和Content的红点
function XUiAnniversaryPreHeating:_OnGetRewardSuccess(groupId, rewardId)
    if self:IsDestroy() then
        return
    end

    if self._SelectGroupId == groupId then
        self:_RefreshReadReward(groupId, rewardId)
    end
    self:_RefreshGroupRedPoints()
    self:_RefreshContentRedPoints()
end

--endregion PanelReadReward

function XUiAnniversaryPreHeating:OnBtnBackClick()
    self:Close()
end

function XUiAnniversaryPreHeating:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
