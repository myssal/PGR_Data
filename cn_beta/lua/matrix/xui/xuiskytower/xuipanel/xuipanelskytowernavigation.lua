---@class XUiPanelSkyTowerNavigation : XUiNode 分区定位
---@field private _Control XSkyTowerControl
---@field PanelBtnGroup XUiButtonGroup
local XUiPanelSkyTowerNavigation = XClass(XUiNode, "XUiPanelSkyTowerNavigation")

--region 生命周期
---@param onGroupSelected function 分区选中回调
function XUiPanelSkyTowerNavigation:OnStart(onGroupSelected)
    self.OnGroupSelected = onGroupSelected

    ---@type XUiComponent.XUiButton[]
    self.ButtonList = {}
    ---@type UnityEngine.RectTransform[]
    self.TipNodeList = {}
    ---@type XUiComponent.XUiRichTextCustomRender[]
    self.TipTextList = {}

    self:InitNavigation()
end

function XUiPanelSkyTowerNavigation:OnDisable()
    self:StopTipTimer()
    self:HideAllTips()
end

function XUiPanelSkyTowerNavigation:OnDestroy()
    self:StopTipTimer()
end
--endregion

--region 事件
function XUiPanelSkyTowerNavigation:OnGetLuaEvents()
    return {
        XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE,
        XEventId.EVENT_SKY_TOWER_CUR_FLOOR_GROUP_CHANGE,
        XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_UPDATE,
        XEventId.EVENT_FINISH_TASK,
    }
end

function XUiPanelSkyTowerNavigation:OnNotify(event, ...)
    if event == XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE
        or event == XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_UPDATE
        or event == XEventId.EVENT_FINISH_TASK then
        self:OnPerformStateChanged()
    elseif event == XEventId.EVENT_SKY_TOWER_CUR_FLOOR_GROUP_CHANGE then
        self:OnCurFloorGroupChanged(...)
    end
end

function XUiPanelSkyTowerNavigation:OnPerformStateChanged()
    self:RefreshRedPoint()
    self:RefreshTip(self:GetSelectedGroupId(), false)
end

-- 镜头滑动导致所处分区变化，同步按钮选中态
-- 不能触发OnNavigationClick，否则会反过来驱动镜头定位
---@param groupId number
function XUiPanelSkyTowerNavigation:OnCurFloorGroupChanged(groupId)
    if not XTool.IsNumberValid(groupId) or groupId == self:GetSelectedGroupId() then
        return
    end
    if XTool.UObjIsNil(self.ButtonList and self.ButtonList[groupId]) then
        return
    end
    self.SelectedGroupId = groupId
    self.PanelBtnGroup:SelectIndex(groupId, false)
    -- 滑动切换分区时收起旧提示，只有点击按钮才重新弹出
    self:StopTipTimer()
    self:HideAllTips()
    self:NotifyGroupSelected(groupId)
end
--endregion

--region 界面刷新
function XUiPanelSkyTowerNavigation:InitNavigation()
    for index = 1, XMVCA.XSkyTower.NavigationMaxButtonCount do
        local button = self["BtnArea" .. index]
        if not XTool.UObjIsNil(button) then
            local tipNode = self["PanelOrder" .. index]
            local tipText = self["TxtOrderDec" .. index]
            self.ButtonList[index] = button
            self.TipNodeList[index] = tipNode
            self.TipTextList[index] = tipText
            if not XTool.UObjIsNil(tipText) then
                -- 事件/订单描述为富文本，图片路径由Agency按客户端配置提供
                tipText.requestImage = XMVCA.XSkyTower.RichTextImageCallBack
            end
            if not XTool.UObjIsNil(tipNode) then
                tipNode.gameObject:SetActiveEx(false)
            end
        end
    end

    self.PanelBtnGroup:Init(self.ButtonList, handler(self, self.OnNavigationClick))
end

-- 点击分区按钮
---@param index number 按钮下标，与分区Id一致
function XUiPanelSkyTowerNavigation:OnNavigationClick(index)
    if not XTool.IsNumberValid(index) or XTool.UObjIsNil(self.ButtonList[index]) then
        return
    end

    self.SelectedGroupId = index
    -- 每次点击都重新弹出提示，停留一段时间后隐藏
    self:RefreshTip(index, true)
    self:NotifyGroupSelected(index)
    if XTool.IsNumberValid(self._TargetPerformId) then
        self._Control:LocatePerform(self._TargetPerformId)
    else
        self._Control:LocateFloor(self:GetGroupHighestFloorId(index))
    end
end

-- 刷新分区按钮与蓝点，不移动镜头
function XUiPanelSkyTowerNavigation:RefreshView()
    local maxGroupId = math.min(self._Control:GetMaxFloorGroupId(), XMVCA.XSkyTower.NavigationMaxButtonCount)
    if maxGroupId <= 0 then
        self.SelectedGroupId = 0
        self:Close()
        self:NotifyGroupSelected(0)
        return
    end

    self:Open()
    for index, button in ipairs(self.ButtonList) do
        button.gameObject:SetActiveEx(index <= maxGroupId)
    end

    local selectIndex = math.min(math.max(self._Control:GetCurFloorGroupId(), 1), maxGroupId)
    if self:GetSelectedGroupId() ~= selectIndex then
        self:StopTipTimer()
        self:HideAllTips()
    end
    self.PanelBtnGroup:SelectIndex(selectIndex, false)
    self.SelectedGroupId = selectIndex
    self:RefreshRedPoint()
    self:RefreshTip(selectIndex, false)
    self:NotifyGroupSelected(selectIndex)
end

-- 刷新分区提示
---@param index number 按钮下标
---@param restartTimer boolean 是否重新弹出并重新计时
function XUiPanelSkyTowerNavigation:RefreshTip(index, restartTimer)
    self._TargetPerformId = nil
    if not XTool.IsNumberValid(index) then
        return
    end
    local tipNode = self.TipNodeList and self.TipNodeList[index]
    if XTool.UObjIsNil(tipNode) then
        return
    end

    -- 未重新弹出时，只在提示仍在显示的情况下同步文本
    if not restartTimer and not tipNode.gameObject.activeSelf then
        return
    end
    if restartTimer then
        self:StopTipTimer()
        self:HideAllTips()
    end
    self._TargetPerformId = self:GetGroupPerformId(index)
    local desc = self:GetPerformDesc(self._TargetPerformId)
    local needShow = not string.IsNilOrEmpty(desc)
    tipNode.gameObject:SetActiveEx(needShow)

    local tipText = self.TipTextList[index]
    if not XTool.UObjIsNil(tipText) then
        tipText.text = desc
    end

    if not needShow then
        self:StopTipTimer()
        return
    end

    if restartTimer then
        self.TipTimer = XScheduleManager.ScheduleOnce(function()
            self.TipTimer = nil
            if not XTool.UObjIsNil(tipNode) then
                tipNode.gameObject:SetActiveEx(false)
            end
        end, XMVCA.XSkyTower.NavigationTipShowTime * XScheduleManager.SECOND)
    end
end

function XUiPanelSkyTowerNavigation:HideAllTips()
    for _, tipNode in pairs(self.TipNodeList) do
        if not XTool.UObjIsNil(tipNode) then
            tipNode.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelSkyTowerNavigation:StopTipTimer()
    if self.TipTimer then
        XScheduleManager.UnSchedule(self.TipTimer)
        self.TipTimer = nil
    end
end

-- 分区内存在已完成且未领奖的事件/订单时，按钮上显示蓝点
function XUiPanelSkyTowerNavigation:RefreshRedPoint()
    for groupId, button in ipairs(self.ButtonList) do
        local _, canReceiveReward = self:GetGroupPerformId(groupId)
        button:ShowReddot(canReceiveReward)
    end
end
--endregion

--region 分区数据
-- 当前选中的分区Id
---@return number
function XUiPanelSkyTowerNavigation:GetSelectedGroupId()
    return self.SelectedGroupId or 0
end

function XUiPanelSkyTowerNavigation:NotifyGroupSelected(groupId)
    if self.OnGroupSelected then
        self.OnGroupSelected(groupId)
    end
end

-- 分区内已解锁的最高楼层
---@param groupId number
---@return number
function XUiPanelSkyTowerNavigation:GetGroupHighestFloorId(groupId)
    local maxFloorId = self._Control:GetMaxFloorId()
    local result = 0
    for _, floorId in ipairs(self._Control:GetFloorIdsByGroupId(groupId)) do
        if floorId <= maxFloorId and floorId > result then
            result = floorId
        end
    end
    return result
end

-- 分区提示优先待领奖，其次未完成；同状态下普通事件 > 楼层区间事件 > 订单
---@param groupId number
---@return number performId
---@return boolean canReceiveReward 是否已达成且未领奖
function XUiPanelSkyTowerNavigation:GetGroupPerformId(groupId)
    if not XTool.IsNumberValid(groupId) then
        return 0, false
    end
    local resultId = 0
    local resultPriority = math.huge
    local resultCanReceiveReward = false
    local maxFloorId = self._Control:GetMaxFloorId()
    local PerformType = XMVCA.XSkyTower.PerformType
    for _, info in pairs(self._Control:GetPerformInfos()) do
        local performId = info.PerformId
        -- Finish表示已经领奖；未接取和已领奖的内容都不参与导航
        if not self._Control:IsOnGoing(performId) then
            goto continue
        end
        local floorId = self._Control:GetFloorId(performId)
        if not XTool.IsNumberValid(floorId) or floorId > maxFloorId
            or self._Control:GetFloorGroupIdByFloorId(floorId) ~= groupId then
            goto continue
        end
        local performType = self._Control:GetPerformType(performId)
        local priority
        if performType == PerformType.Event then
            priority = 1
        elseif performType == PerformType.FloorGroup then
            priority = 2
        elseif performType == PerformType.Indent then
            priority = 3
        else
            goto continue
        end
        local canReceiveReward = self._Control:CheckPerformFinish(performId)
        if not canReceiveReward then
            priority = priority + 3
        end
        if priority < resultPriority or (priority == resultPriority and performId > resultId) then
            resultId = performId
            resultPriority = priority
            resultCanReceiveReward = canReceiveReward
        end
        :: continue ::
    end
    return resultId, resultCanReceiveReward
end

-- 提示文本，取第一个未完成的任务描述
---@param performId number
---@return string
function XUiPanelSkyTowerNavigation:GetPerformDesc(performId)
    if not XTool.IsNumberValid(performId) then
        return nil
    end
    local taskIds = self._Control:GetPerformTaskIds(performId)
    for _, taskId in ipairs(taskIds) do
        if not self._Control:CheckPerformTaskFinish(taskId) then
            return self._Control:GetTaskDescWithProgress(taskId)
        end
    end
    local firstTaskId = taskIds[1]
    return firstTaskId and self._Control:GetTaskDescWithProgress(firstTaskId) or self._Control:GetPerformDescription(performId)
end
--endregion

return XUiPanelSkyTowerNavigation
