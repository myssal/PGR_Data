local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridSkyTowerStorage = require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerStorage")
local XUiPanelSkyTowerNavigation = require("XUi/XUiSkyTower/XUiPanel/XUiPanelSkyTowerNavigation")

local MaskKeyTips = "UiSkyTowerMainTips"
local MaskKeyStorage = "UiSkyTowerMainStorage"
local SkyTowerUpgradeCoinEvent = XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XMVCA.XSkyTower.ItemId.SkyTowerUpgradeCoin

---@class XUiSkyTowerMain : XLuaUi
---@field GridSkillEffectActive UiObject
---@field private _Control XSkyTowerControl
local XUiSkyTowerMain = XLuaUiManager.Register(XLuaUi, "UiSkyTowerMain")

--region 生命周期
function XUiSkyTowerMain:OnAwake()
    self.PanelTips.gameObject:SetActiveEx(false)
    self.PanelSkillEffectActive.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
    self:InitNavigationPanel()
    self:RegisterUiEvents()
end

function XUiSkyTowerMain:OnStart(isOpenLevelUp)
    self._Control:NewPanelActivityAsset({ XMVCA.XSkyTower.ItemId.SkyTowerUpgradeCoin, XMVCA.XSkyTower.ItemId.SkyTowerAccelerate, XMVCA.XSkyTower.ItemId.SkyTowerCoin, }, self.PanelAsset, self)
    self:InitView(isOpenLevelUp)
    XLuaUiManager.OpenWithCallback("UiSkyTowerCommon", function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.PanelGameplayUi.sortingOrder = self._Control:GetCommonSortingOrder() + 1
    end)
end

function XUiSkyTowerMain:OnEnable()
    self._StorageRefreshEnabled = true
    self._StorageStates = nil
    local isFirstOpen = not self._CameraInputInvited
    self:EnableCameraInput()
    self:RefreshView()
    if isFirstOpen and self._CameraInputInvited then
        -- 打开界面并定位后，显示当前分区的事件/订单提示，沿用点击按钮的隐藏计时
        self.NavigationPanel:RefreshTip(self.NavigationPanel:GetSelectedGroupId(), true)
    end
end

function XUiSkyTowerMain:OnDisable()
    self._StorageRefreshEnabled = false
    self:CancelStorageRefresh()
    self:DisableCameraInput()
    self._DragState = nil
    self:HideSkillEffectTip()
    self:StopTipTimer()
end

function XUiSkyTowerMain:OnDestroy()
    self._StorageRefreshEnabled = false
    self:CancelStorageRefresh()
    self:ReleaseCameraInput()
    self:StopTipTimer()
end

function XUiSkyTowerMain:OnRelease()
    XLuaUiManager.Remove("UiSkyTowerCommon")
end

function XUiSkyTowerMain:Close()
    XLuaUiManager.Close("UiSkyTowerCommon")
    XUiSkyTowerMain.Super.Close(self)
end
--endregion

--region 事件
function XUiSkyTowerMain:OnGetLuaEvents()
    return {
        SkyTowerUpgradeCoinEvent,
        XEventId.EVENT_SKY_TOWER_SHOW_ASSIGN_WORK,
        XEventId.EVENT_SKY_TOWER_STAFF_CHANGE,
        XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE,
        XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE,
        XEventId.EVENT_SKY_TOWER_DATA_CHANGE,
        XEventId.EVENT_SKY_TOWER_DRAG_STATE_CHANGE,
        XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE,
        XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE,
        XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE,
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
        XEventId.EVENT_SKY_TOWER_HIDE_UI,
        XEventId.EVENT_SKY_TOWER_HIDE_GAMEPLAY_UI,
        XEventId.EVENT_SKY_TOWER_UPDATE_LEVEL_UP_CAM,
    }
end

function XUiSkyTowerMain:OnNotify(event, ...)
    if event == XEventId.EVENT_SKY_TOWER_SHOW_ASSIGN_WORK then
        self:ShowTips(...)
    elseif event == XEventId.EVENT_SKY_TOWER_DRAG_STATE_CHANGE then
        self:OnDragStateChange(...)
    elseif event == XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE then
        self:RefreshSkillEffectTip()
        self:RequestStorageRefresh()
    elseif event == XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE then
        self:RequestStorageRefresh(...)
    elseif event == XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE then
        --员工光环可能影响其他楼层，统一比较当前分区各材料的最终净产出
        self:RequestStorageRefresh()
    elseif event == XEventId.EVENT_SKY_TOWER_STAFF_CHANGE then
        self:RefreshStaffCount()
        self:RequestStorageRefresh()
    elseif event == XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE
        or event == XEventId.EVENT_SKY_TOWER_DATA_CHANGE then
        self:RefreshView()
        self:RequestStorageRefresh()
    elseif event == XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE
        or event == SkyTowerUpgradeCoinEvent then
        self:RefreshUpgradeRedPoint()
    elseif event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshTaskRedPoint()
    elseif event == XEventId.EVENT_SKY_TOWER_HIDE_UI then
        self:HideUi(...)
    elseif event == XEventId.EVENT_SKY_TOWER_HIDE_GAMEPLAY_UI then
        self:SetGameplayUiVisible(...)
    elseif event == XEventId.EVENT_SKY_TOWER_UPDATE_LEVEL_UP_CAM then
        self:PlayOpenLevelUpCamAnim()
    end
end
--endregion

--region 界面刷新
function XUiSkyTowerMain:HideUi(isHide)
    local isShow = not isHide
    self.FullScreenBackground.gameObject:SetActiveEx(isShow)
    self.SafeAreaContentPane.gameObject:SetActiveEx(isShow)
end

function XUiSkyTowerMain:SetGameplayUiVisible(isHide)
    self.PanelGameplayUi.gameObject:SetActiveEx(not isHide)
end

function XUiSkyTowerMain:InitView(isOpenLevelUp)
    local endTime = self._Control:GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XMVCA.XSkyTower:OnActivityEnd()
        end
    end)

    if isOpenLevelUp then
        self:OnBtnSkyTowerClick()
    end
end

function XUiSkyTowerMain:RefreshView()
    self:RefreshSkyTowerLevel()
    self:RefreshUpgradeRedPoint()
    self:RefreshTaskRedPoint()
    self:RefreshStaffCount()
    self.NavigationPanel:RefreshView()
end

function XUiSkyTowerMain:RefreshSkyTowerLevel()
    local lv = self._Control:GetSkyTowerLv()
    self.BtnSkyTower:SetNameByGroup(0, self._Control:GetClientConfigText("SkyTowerLevelName", 1, lv))
end

function XUiSkyTowerMain:RefreshUpgradeRedPoint()
    self.BtnSkyTower:ShowReddot(XMVCA.XSkyTower:CheckLevelUpRedPoint())
end

function XUiSkyTowerMain:RefreshTaskRedPoint()
    self.BtnTask:ShowReddot(self._Control:CheckTaskRedPoint())
end

function XUiSkyTowerMain:RefreshStaffCount()
    local total = #self._Control:GetAllCharacterIds()
    self.BtnWorker:SetNameByGroup(0, string.format("%s/%s", self._Control:GetUnlockCharacterCount(), total))
end

function XUiSkyTowerMain:ShowTips(tips)
    if XTool.UObjIsNil(self.PanelTips) then
        return
    end
    self:StopTipTimer()
    self.TxtTips.text = tips
    self.PanelTips.gameObject:SetActiveEx(true)
    XLuaUiManager.SetMask(true, MaskKeyTips)
    XScheduleManagerPro.ScheduleOnce(self._OnStopTipTimerScheduleCb, self, XMVCA.XSkyTower.TipShowTime * XScheduleManager.SECOND)
end

function XUiSkyTowerMain:_OnStopTipTimerScheduleCb()
    self:StopTipTimer()
    if not XTool.UObjIsNil(self.PanelTips) then
        self.PanelTips.gameObject:SetActiveEx(false)
    end
end

function XUiSkyTowerMain:StopTipTimer()
    XScheduleManagerPro.UnSchedule(self._OnStopTipTimerScheduleCb, self)
    if XLuaUiManager.IsMaskShow(MaskKeyTips) then
        XLuaUiManager.SetMask(false, MaskKeyTips)
    end
end
--endregion

--region 镜头输入
function XUiSkyTowerMain:EnableCameraInput()
    local camera = self._Control:GetCameraModel()
    if not camera then
        return
    end
    camera:ShowDefault()
    if not self._CameraInputInvited then
        self._CameraInputInvited = true
        camera:BindMainInput(self.PanelCameraInput, handler(self, self.OnCameraFloorChanged))
        -- 定位到入口当前注视的楼层，首次进入活动时默认为已解锁的最高楼层
        self._Control:LocateFloor(camera:GetEntranceFloorId(), true, camera:GetDefaultLocalOffsetY())
    else
        camera:SetMainInputEnabled(true)
    end
end

function XUiSkyTowerMain:DisableCameraInput()
    local camera = self._Control:GetCameraModel()
    if camera then
        camera:SetMainInputEnabled(false)
    end
    self.PanelGameplayUi.gameObject:SetActiveEx(true)
end

function XUiSkyTowerMain:ReleaseCameraInput()
    local camera = self._Control:GetCameraModel()
    if camera then
        camera:ReleaseMainInput()
    end
    self._CameraInputInvited = false
end

-- 镜头移动导致所处楼层变化
---@param floorId number
function XUiSkyTowerMain:OnCameraFloorChanged(floorId)
    self._Control:SetCurFloorId(floorId)
end

-- 供场景编辑器实时调参用，正常流程不会调到
function XUiSkyTowerMain:RefreshCameraParamFromEditor(cameraParam)
    local camera = self._Control:GetCameraModel()
    if camera then
        camera:RefreshCameraParam(cameraParam)
    end
end
--endregion

--region 升级镜头动画
-- 播放打开升级弹窗时的镜头动画
function XUiSkyTowerMain:PlayOpenLevelUpCamAnim()
    if self._Control:IsFloorMaxLevel() then
        return
    end
    --todo 隐藏其他家具和工作中的角色
    local lv = self._Control:GetSkyTowerLv()
    local nextLv = lv + 1
    local floorId = self._Control:GetLvFloorId(lv)
    local nextFloorId = self._Control:GetLvFloorId(nextLv)
    local isNewFloor = floorId ~= nextFloorId
    local unlockWorkNum = self._Control:GetLvUnlockWorkNum(nextLv)
    --解锁新楼层 镜头聚焦到最高层
    if isNewFloor then
        self._Control:GetRoom(floorId):LookAtFloor()
        return
    end
    --解锁工作台 镜头聚焦到新工作台
    if unlockWorkNum > 0 then
        --todo 呼吸光显示新工作台
        local _, lastWorkPosIndex = self._Control:GetLastUnlockedWork()
        local newWorkIndex = lastWorkPosIndex + unlockWorkNum
        local maxWork = self._Control:GetFloorWorkNum(floorId)
        self._Control:GetRoom(floorId):LookAtWork(math.min(newWorkIndex, maxWork))
        return
    end
    --聚焦到舞台
    local danceFloorId = self._Control:GetDanceFloorId()
    self._Control:GetRoom(danceFloorId):LookAtDance()
end

-- 关闭镜头动画
function XUiSkyTowerMain:CloseCamAnim()
    self._Control:GetRoom():ResetCamera()
end
--endregion

--region 分区与事件面板
function XUiSkyTowerMain:InitNavigationPanel()
    ---@type XUiPanelSkyTowerNavigation
    self.NavigationPanel = XUiPanelSkyTowerNavigation.New(self.PanelNavigation, self, handler(self, self.OnNavigationGroupSelected))
end

-- 分区选中回调
---@param groupId number 分区Id，0表示当前没有可用分区
function XUiSkyTowerMain:OnNavigationGroupSelected(groupId)
    self.SelectedGroupId = groupId
    if not XTool.IsNumberValid(groupId) then
        self:HideStorage()
        return
    end
    self:ShowStorageGroup(groupId)
end

-- 分区内要展示的事件Id，已完成的优先，其次取进行中的第一个
function XUiSkyTowerMain:GetGroupStoryPerformId(groupId)
    local onGoingId = 0
    for _, performId in ipairs(self._Control:GetAllPerformIds()) do
        local floorId = self._Control:GetFloorId(performId)
        if XTool.IsNumberValid(floorId)
            and self._Control:GetFloorGroupIdByFloorId(floorId) == groupId then
            if self._Control:CheckPerformFinish(performId) then
                return performId
            end
            if not XTool.IsNumberValid(onGoingId) and self._Control:IsOnGoing(performId) then
                onGoingId = performId
            end
        end
    end
    return onGoingId
end
--endregion

--region 仓库
function XUiSkyTowerMain:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.StorageTable = XDynamicTableNormal.New(self.PanelList)
    self.StorageTable:SetDelegate(self)
    self.StorageTable:SetProxy(XUiGridSkyTowerStorage, self)
    self.GridItem.gameObject:SetActiveEx(false)
    self.PanelListWarehouse.gameObject:SetActiveEx(false)
    self.IsStorageExpand = true
end

-- 展示选中分区的库存
---@param groupId number
function XUiSkyTowerMain:ShowStorageGroup(groupId)
    if self.StorageGroupId ~= groupId then
        self._StorageStates = nil
    end
    self.StorageGroupId = groupId
    self.PanelListWarehouse.gameObject:SetActiveEx(true)
    self:RefreshStorageTitle()
    self:RequestStorageRefresh()
end

function XUiSkyTowerMain:HideStorage()
    self:CancelStorageRefresh()
    self.StorageGroupId = nil
    self._StorageListGroupId = nil
    self._StorageStates = nil
    self.PanelListWarehouse.gameObject:SetActiveEx(false)
end

-- 分区名
function XUiSkyTowerMain:RefreshStorageTitle()
    self.TxtArea.text = self._Control:GetFloorGroupName(self.StorageGroupId)
end

-- 同一帧的工位、库存及数据事件合并到下一帧，只读取最终状态
---@param changedGroupId number 库存变化的分区，为空表示全量变化
function XUiSkyTowerMain:RequestStorageRefresh(changedGroupId)
    if not self._StorageRefreshEnabled or not self.StorageTable or not XTool.IsNumberValid(self.StorageGroupId) then
        return
    end
    if XTool.IsNumberValid(changedGroupId) and changedGroupId ~= self.StorageGroupId then
        return
    end
    if self._StorageRefreshTimer then
        return
    end
    self._StorageRefreshCb = self._StorageRefreshCb or handler(self, self.OnStorageRefresh)
    self._StorageRefreshTimer = XScheduleManager.ScheduleNextFrame(self._StorageRefreshCb)
end

function XUiSkyTowerMain:OnStorageRefresh()
    self._StorageRefreshTimer = nil
    if self._StorageRefreshEnabled and not XTool.UObjIsNil(self.GameObject) then
        self:RefreshStorageList()
    end
end

function XUiSkyTowerMain:CancelStorageRefresh()
    if self._StorageRefreshTimer then
        XScheduleManager.UnSchedule(self._StorageRefreshTimer)
        self._StorageRefreshTimer = nil
    end
end

-- 首次展示更新全部格子，后续只刷新数量、容量或趋势发生变化的材料
function XUiSkyTowerMain:RefreshStorageList()
    if not self.StorageTable or not XTool.IsNumberValid(self.StorageGroupId) then
        return
    end
    local groupData = self._Control:GetProductionStatistics()[self.StorageGroupId]
    local productList = self._Control:GetFloorGroupProductList(self.StorageGroupId)
    local oldList = self.StorageProductList
    local sameProducts = self._StorageListGroupId == self.StorageGroupId and oldList and #oldList == #productList
    if sameProducts then
        for index, data in ipairs(productList) do
            local oldData = oldList[index]
            if oldData.WorkType ~= data.WorkType or oldData.ProductId ~= data.ProductId then
                sameProducts = false
                break
            end
        end
    end
    --数量刷新复用外层及每个材料的状态表，仅首次出现时分配
    local states = self._StorageStates
    if not states then
        states = {}
        self._StorageStates = states
    end
    for index, data in ipairs(productList) do
        local productType = self._Control:GetProductTypeByWorkType(data.WorkType)
        local products = groupData and groupData.Products[productType]
        local profit = products and products[data.ProductId]
        --共享统计以小时为单位，沿用仓库原有每秒精度判断
        local speed = profit and profit.ChangeSpeed / XMVCA.XSkyTower.TimeUnit.Hour or 0
        local trend = self._Control:IsZero(speed) and 0 or (speed > 0 and 1 or -1)
        local count = profit and profit.Count or self._Control:GetStorageProductCount(self.StorageGroupId, productType, data.ProductId)
        local limit = self._Control:GetStorageProductLimit(self.StorageGroupId, productType, data.ProductId)
        local state = states[index]
        local hadState = state ~= nil
        --先比较再写回，避免复用同一张表后丢失旧值
        local changed = not state or state.Count ~= count or state.Limit ~= limit or state.Trend ~= trend
        if not state then
            state = {}
            states[index] = state
        end
        state.Count, state.Limit, state.Trend = count, limit, trend
        if sameProducts then
            local grid = self.StorageTable:GetGridByIndex(index)
            if grid then
                if not hadState then
                    grid:Refresh(data, self.StorageGroupId, state)
                elseif changed then
                    grid:RefreshAmount(count, limit, trend)
                end
            end
        end
    end
    for index = #productList + 1, #states do
        states[index] = nil
    end
    if sameProducts then
        return
    end
    self._StorageListGroupId = self.StorageGroupId
    self.StorageProductList = productList
    self.StorageTable:SetDataSource(self.StorageProductList)
    self.StorageTable:ReloadDataASync()
end

---@param grid XUiGridSkyTowerStorage
function XUiSkyTowerMain:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.StorageProductList[index], self._StorageListGroupId, self._StorageStates and self._StorageStates[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnStorageProductClick(index)
    end
end

-- 点击仓库产品，自动定位到正在生产/售卖此材料的最高楼层。数量为0的物品则不定位
---@param index number 列表下标
function XUiSkyTowerMain:OnStorageProductClick(index)
    if not self.IsStorageExpand then
        return
    end
    local data = self.StorageProductList and self.StorageProductList[index]
    if not data then
        return
    end
    local productType = self._Control:GetProductTypeByWorkType(data.WorkType)
    local count = self._Control:GetStorageProductCount(self.StorageGroupId, productType, data.ProductId)
    if count <= 0 then
        return
    end
    local floorId = self._Control:GetGroupMaxProduceFloorId(self.StorageGroupId, data.WorkType, data.ProductId)
    if not XTool.IsNumberValid(floorId) then
        return
    end
    self._Control:LocateFloor(floorId, false)
end

-- 列表整体左右平移收起/展开，动画期间关掉滚动与按钮避免中途插入操作
function XUiSkyTowerMain:PlayStorageExpandAnim()
    if not self.StorageTable or self._StorageTweenId then
        return
    end
    local scrollRect = self.StorageTable:GetImpl().ScrRect
    if XTool.UObjIsNil(scrollRect) or XTool.UObjIsNil(scrollRect.content) then
        return
    end

    ---@type UnityEngine.RectTransform
    local content = scrollRect.content
    local width = self.IsStorageExpand and content.rect.width or -content.rect.width
    local position = content.anchoredPosition
    local posX = position.x
    self.BtnExpand.enabled = false
    scrollRect.enabled = false
    self.StorageTable:GetImpl().enabled = false
    XLuaUiManager.SetMask(true, MaskKeyStorage)
    self._StorageTweenId = self:Tween(XMVCA.XSkyTower.StorageMoveDuration, function(delta)
        if XTool.UObjIsNil(content) then
            return
        end
        position.x = posX + delta * width
        content.anchoredPosition = position
    end, function()
        self._StorageTweenId = nil
        XLuaUiManager.SetMask(false, MaskKeyStorage)
        self:OnStorageExpandAnimEnd()
    end)
end

function XUiSkyTowerMain:OnStorageExpandAnimEnd()
    self.IsStorageExpand = not self.IsStorageExpand
    if XTool.UObjIsNil(self.BtnExpand) or not self.StorageTable then
        return
    end
    local scrollRect = self.StorageTable:GetImpl().ScrRect
    self.BtnExpand.enabled = true
    if not XTool.UObjIsNil(scrollRect) then
        scrollRect.enabled = self.IsStorageExpand
    end
    self.StorageTable:GetImpl().enabled = self.IsStorageExpand
end
--endregion

--region 拖动换位提示
-- 工位拖动状态变化，由XUiSkyTowerCommon广播
---@param fromFloorId number 拖动源楼层，为空表示拖动结束
---@param fromIndex number 拖动源工位下标
---@param toFloorId number 当前悬浮的楼层，为空表示未悬浮在任何工位上
---@param toIndex number 当前悬浮的工位下标
function XUiSkyTowerMain:OnDragStateChange(fromFloorId, fromIndex, toFloorId, toIndex)
    if not XTool.IsNumberValid(fromFloorId) then
        self._DragState = nil
        self:HideSkillEffectTip()
        return
    end
    self._DragState = {
        FromFloorId = fromFloorId,
        FromIndex = fromIndex,
        ToFloorId = toFloorId,
        ToIndex = toIndex,
    }
    self:SetOtherUiVisibleForDrag(false)
    self:RefreshSkillEffectTip()
end

-- 按当前拖动参数重算提示条，服务端推送技能激活状态变更时调用
function XUiSkyTowerMain:RefreshSkillEffectTip()
    local drag = self._DragState
    if not drag then
        return
    end
    self:ShowSkillEffectTip(self._Control:GetDragSkillEffectPreview(drag.FromFloorId, drag.FromIndex, drag.ToFloorId, drag.ToIndex))
end

-- 刷新角色技能生效状态提示
---@param list XSkyTowerSkillEffectItem[]
function XUiSkyTowerMain:ShowSkillEffectTip(list)
    if XTool.UObjIsNil(self.GridSkillEffectActive) then
        return
    end
    local count = list and #list or 0
    self.PanelSkillEffectActive.gameObject:SetActiveEx(count > 0)
    self._SkillEffectUiList = self._SkillEffectUiList or {}
    XUiHelper.RefreshUiObjectList(self._SkillEffectUiList, self.PanelSkillEffectActive, self.GridSkillEffectActive, count, function(index, child)
        self:RefreshSkillEffectItem(child, list[index])
    end)
end

function XUiSkyTowerMain:HideSkillEffectTip()
    self.PanelSkillEffectActive.gameObject:SetActiveEx(false)
    self:SetOtherUiVisibleForDrag(true)
end

-- 单条技能生效提示
---@param child UiObject
---@param item XSkyTowerSkillEffectItem
function XUiSkyTowerMain:RefreshSkillEffectItem(child, item)
    if not item then
        return
    end
    if not XTool.UObjIsNil(child.RImgHead) then
        local icon = self._Control:GetCharacterPortrait(item.CharacterId)
        child.RImgHead:SetRawImageEx(icon)
    end
    if not XTool.UObjIsNil(child.TxtActiveDec) then
        child.TxtActiveDec.requestImage = XMVCA.XSkyTower.RichTextImageCallBack
        child.TxtActiveDec.text = self._Control:GetSkillEffectStateDesc(item.SkillId, item.State)
        child.TxtActiveDec:ForcePopulateIcons()
    end
    if not XTool.UObjIsNil(child.ImgArrow) then
        -- 即将生效/即将失效才画箭头，已生效与未生效是静态状态
        local state = item.State
        child.ImgArrow.gameObject:SetActiveEx(state == XMVCA.XSkyTower.SkillEffectState.WillActive or state == XMVCA.XSkyTower.SkillEffectState.WillDeactivate)
    end
end

-- 拖动期间只保留提示条与3D场景，其余UI暂时收起
function XUiSkyTowerMain:SetOtherUiVisibleForDrag(visible)
    if visible then
        if not self._DragHiddenUiList then
            return
        end
        for _, data in ipairs(self._DragHiddenUiList) do
            if not XTool.UObjIsNil(data.Ui) then
                data.Ui.gameObject:SetActiveEx(data.Active)
            end
        end
        self._DragHiddenUiList = nil
        return
    end
    if self._DragHiddenUiList then
        return
    end
    local nameList = { "PanelAsset", "BtnHelp", "PanelTitle", "PanelBtnDown", "PanelListWarehouse", "PanelNavigation" }
    self._DragHiddenUiList = {}
    for _, name in ipairs(nameList) do
        local ui = self[name]
        if not XTool.UObjIsNil(ui) then
            -- 记录原本的显隐，避免恢复时把本该隐藏的面板一起显示出来
            table.insert(self._DragHiddenUiList, { Ui = ui, Active = ui.gameObject.activeSelf })
            ui.gameObject:SetActiveEx(false)
        end
    end
end
--endregion

--region 按钮
function XUiSkyTowerMain:RegisterUiEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))
    self.BtnTask:AddEventListener(handler(self, self.OnBtnTaskClick))
    self.BtnStatistics:AddEventListener(handler(self, self.OnBtnStatisticsClick))
    self.BtnWorker:AddEventListener(handler(self, self.OnBtnWorkerClick))
    self.BtnSkyTower:AddEventListener(handler(self, self.OnBtnSkyTowerClick))
    self.BtnExpand:AddEventListener(handler(self, self.OnBtnExpandClick))
    self:BindHelpBtn(self.BtnHelp, "UiSkyTowerMain")
end

function XUiSkyTowerMain:OnBtnBackClick()
    self:Close()
end

function XUiSkyTowerMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSkyTowerMain:OnBtnTaskClick()
    self._Control:OpenTask()
end

function XUiSkyTowerMain:OnBtnStatisticsClick()
    self._Control:OpenStatistics()
end

function XUiSkyTowerMain:OnBtnWorkerClick()
    XLuaUiManager.Open("UiSkyTowerCook")
end

function XUiSkyTowerMain:OnBtnSkyTowerClick()
    self:PlayOpenLevelUpCamAnim()
    XLuaUiManager.OpenWithCloseCallback("UiSkyTowerLevelUp", function()
        self:CloseCamAnim()
    end)
end

function XUiSkyTowerMain:OnBtnExpandClick()
    self:PlayStorageExpandAnim()
end
--endregion

return XUiSkyTowerMain
