---@class XUiSkyTowerCommon : XLuaUi
---@field _Control XSkyTowerControl
---@field ProductContainer UnityEngine.RectTransform 拖动克隆体的挂载层
local XUiSkyTowerCommon = XLuaUiManager.Register(XLuaUi, "UiSkyTowerCommon")

local XUiGridSkyTower3DDialog = require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DDialog")
local XUiCommonDragContext = require("XUi/XUiCommon/XCommonDrag/XUiCommonDragContext")

local DoEnable = false

--region 生命周期
function XUiSkyTowerCommon:OnAwake()
    self:InitUi()
end

function XUiSkyTowerCommon:OnStart()
    DoEnable = false
    self:InitView()
end

function XUiSkyTowerCommon:OnEnable()
    self:RefreshView()
    self._LoopTimerId = XScheduleManager.ScheduleForever(function()
        self:UpdateLoop()
    end, 0, 0)
    self._PerformTipEnable = true
    DoEnable = true
end

function XUiSkyTowerCommon:OnDisable()
    self:ClearTimer()
    self:CancelWorkPosDrag()
    self._PerformTipEnable = false
end

function XUiSkyTowerCommon:OnDestroy()
    self:ClearTimer()
    self.DialogPool:Clear()
    self:ReleaseDragContext()
end

function XUiSkyTowerCommon:InitUi()
    ---@type XStack
    self.DialogPool = XStack.New()
    ---@type table<number, XUiGridSkyTower3DDialog>
    self.GridDialog = {}

    ---@type XUiPanelSkyTowerCommonWorkbench 工作台
    self._Workbench = require("XUi/XUiSkyTower/XUiPanel/Common/XUiPanelSkyTowerCommonWorkbench").New(self.PanelWorkbench, self)
    ---@type XUiPanelSkyTowerCommonArea 分区
    --self._Area = require("XUi/XUiSkyTower/XUiPanel/Common/XUiPanelSkyTowerCommonArea").New(self.PanelArea, self)
    self.PanelArea.gameObject:SetActiveEx(false)
    ---@type XUiPanelSkyTowerCommonEvent 事件（演出）
    self._Event = require("XUi/XUiSkyTower/XUiPanel/Common/XUiPanelSkyTowerCommonEvent").New(self.PanelEvent, self)
    ---@type XUiPanelSkyTowerCommonGroupEvent 楼层区间事件
    self._GroupEvent = require("XUi/XUiSkyTower/XUiPanel/Common/XUiPanelSkyTowerCommonGroupEvent").New(self.PanelFloorGroupEvent, self)
    ---@type XUiPanelSkyTowerCommonIndent 订单
    self._Indent = require("XUi/XUiSkyTower/XUiPanel/Common/XUiPanelSkyTowerCommonIndent").New(self.PanelIndent, self)

    self.GridDialogBox.gameObject:SetActiveEx(false)
    self._Control:SetCommonSortingOrder(self.UiCanvas.sortingOrder)
end

function XUiSkyTowerCommon:InitView()
    self:ShowBillView()
end

function XUiSkyTowerCommon:HideUi(isHide)
    self.UiCanvas.enabled = not isHide
end

function XUiSkyTowerCommon:ShowBillView()
    if not self._Control:IsShowOfflineBill() then
        return
    end
    XLuaUiManager.Open("UiSkyTowerBill")
end

function XUiSkyTowerCommon:UpdateLoop()
    if XTool.UObjIsNil(self.GameObject) then
        self:ClearTimer()
        return
    end
    --隐藏其他区间的UI
    local edgeGroupId = self._Control:GetCurEdgeGroupId()
    if self._AllFloorIds and edgeGroupId ~= self._EdgeGroupId then
        for i = 1, #self._AllFloorIds do
            self:OnRecycleFloor(self._AllFloorIds[i])
        end
    end
    self._EdgeGroupId = edgeGroupId
    -- 先滚镜头，本帧的工位增删与位置刷新都按滚动后的视角来
    self:UpdateDragEdgeScroll()
    self:Refresh3DGridTransform()
    self._AllFloorIds = self._Control:GetFloorIdsByGroupId(self._EdgeGroupId)
    for i = 1, #self._AllFloorIds do
        local floorId = self._AllFloorIds[i]
        local room = self._Control:IsExistRoom(floorId) and self._Control:GetRoom(floorId)
        if not room or not room:Exist() then
            self:OnRecycleFloor(floorId)
        else
            self:UpdateLoopFloor(floorId)
        end
    end
    self._Workbench:UpdateLoop(self._AllFloorIds)
    self:RefreshDragZonesIfDirty()
end

function XUiSkyTowerCommon:OnRecycleFloor(floorId)
    self._Workbench:OnRecycleFloor(floorId)
    self._Event:OnRecycleFloor(floorId)
    self._Indent:OnRecycleFloor(floorId)
    self._GroupEvent:OnRecycleFloor(floorId)
end

function XUiSkyTowerCommon:UpdateLoopFloor(floorId)
    self._Workbench:UpdateLoopFloor(floorId)
    self._Event:UpdateLoopFloor(floorId)
    self._Indent:UpdateLoopFloor(floorId)
    self._GroupEvent:UpdateLoopFloor(floorId)
end

function XUiSkyTowerCommon:ClearTimer()
    if self._LoopTimerId then
        XScheduleManager.UnSchedule(self._LoopTimerId)
        self._LoopTimerId = nil
    end
end
--endregion

--region 事件
function XUiSkyTowerCommon:OnGetLuaEvents()
    return {
        XEventId.EVENT_SKY_TOWER_SHOW_3D_DIALOG,
        XEventId.EVENT_SKY_TOWER_HIDE_3D_DIALOG,
        XEventId.EVENT_SKY_TOWER_HIDE_UI,
        XEventId.EVENT_SKY_TOWER_HIDE_GAMEPLAY_UI,
    }
end

function XUiSkyTowerCommon:OnNotify(evt, ...)
    if not self._Control then
        return
    end
    if evt == XEventId.EVENT_SKY_TOWER_SHOW_3D_DIALOG then
        self:ShowDialog(...)
    elseif evt == XEventId.EVENT_SKY_TOWER_HIDE_3D_DIALOG then
        self:RecycleDialog(...)
    elseif evt == XEventId.EVENT_SKY_TOWER_HIDE_UI or evt == XEventId.EVENT_SKY_TOWER_HIDE_GAMEPLAY_UI then
        self:HideUi(...)
    end
end
--endregion

--region 界面刷新
function XUiSkyTowerCommon:RefreshView()
    self:Refresh3DGridShow(true)
end

-- 订单、演出、对话等单例3DUi都跟随当前楼层
---@return XSkyTowerRoom
function XUiSkyTowerCommon:GetRoom()
    return self._Control:GetRoom(self._Control:GetCurFloorId())
end

-- 把单例3DUi的屏幕坐标刷到当前楼层的挂点上
function XUiSkyTowerCommon:Refresh3DGridTransform()
    local room = self:GetRoom()
    -- 楼层还没实例化完，Room里没有摄像机，坐标换算做不了
    if not room:Exist() then
        return
    end

    for _, grid in pairs(self.GridDialog) do
        grid:UpdateTransform(room)
    end
end

function XUiSkyTowerCommon:Refresh3DGridShow(state)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    --拖动与等待回包期间保留格子和副本，完成交接后再补刷显隐
    if self:IsDragging() or self:IsWorkPosSwapPending() then
        self._DragPendingGridShow = state
        return
    end
    local animName = state and "UiEnable" or "UiDisable"
    self:PlayAnimation(animName)
    self._Workbench:SetVisible(state)
    --self._Area:SetVisible(state)
    self._Event:SetVisible(state)
    self._Indent:SetVisible(state)
    self._GroupEvent:SetVisible(state)
end
--endregion

--region 3D对话框
function XUiSkyTowerCommon:ShowDialog(id, content, emoji, target, offset)
    if XTool.UObjIsNil(self.GridDialogBox) then
        return
    end

    if XTool.UObjIsNil(target) then
        return
    end
    local dialog = self.GridDialog[id]
    if not dialog then
        local count = self.DialogPool:Count()
        if count > 0 then
            dialog = self.DialogPool:Pop()
        else
            local ui = XUiHelper.Instantiate(self.GridDialogBox, self.DialogContainer)
            dialog = XUiGridSkyTower3DDialog.New(ui, self, self.DialogContainer, offset)
        end
    end
    dialog:SetOffset(offset)
    dialog:SetTarget(target)
    dialog:Show(id, content, emoji)
    self.GridDialog[id] = dialog
end

---@param id number 对话气泡Id
function XUiSkyTowerCommon:RecycleDialog(id)
    local dialog = self.GridDialog[id]
    if not dialog then
        return
    end
    dialog:Hide()
    self.DialogPool:Push(dialog)
    self.GridDialog[id] = nil
end
--endregion

--region 工位拖动换位
-- 全楼层工位共用一个拖拽域，克隆体挂在ProductContainer下
---@return XUiCommonDragContext
function XUiSkyTowerCommon:GetDragContext()
    if self._DragContext then
        return self._DragContext
    end
    if XTool.UObjIsNil(self.ProductContainer) then
        return nil
    end
    ---@type XUiCommonDragContext
    self._DragContext = XUiCommonDragContext.New(self, self.ProductContainer, {
        -- 工位格子被对象池复用，Enter模式回灌的zoneId会跟着旧工位失效，只能每帧按矩形判定
        HitTest = XEnumConst.CommonDrag.HitTest.Rect,
    })
    self._DragContext:SetOnHoverChange(function(fromKey, toKey)
        self:OnWorkPosDragHover(fromKey, toKey)
    end)
    self._DragContext:SetOnDrop(function(fromKey, toKey)
        self:OnWorkPosDrop(fromKey, toKey)
    end)
    return self._DragContext
end

function XUiSkyTowerCommon:ReleaseDragContext()
    self:CancelWorkPosDrag()
    if not self._DragContext then
        return
    end
    self._DragContext:Destroy()
    self._DragContext = nil
end

---@return boolean
function XUiSkyTowerCommon:IsDragging()
    return self._DragContext ~= nil and self._DragContext:IsDragging()
end

function XUiSkyTowerCommon:IsWorkPosSwapPending()
    return self._PendingWorkPosSwap ~= nil
end

-- 遍历当前在屏的工位格子
---@param func fun(grid:XUiGridSkyTower3DWorkBench)
function XUiSkyTowerCommon:EachWorkBenchGrid(func)
    self._Workbench:EachGrid(func)
end

-- 重登记落点：在屏工位随镜头增减，每次起拖都要按当前格子重建
function XUiSkyTowerCommon:RefreshDropZones()
    local context = self._DragContext
    if not context then
        return
    end
    context:ClearDropZones()
    self:EachWorkBenchGrid(function(grid)
        context:AddDropZone(grid.Transform, grid:GetWorkPosKey())
    end)
end

-- Context:Begin会立刻做一次落点命中，故落点必须在克隆工厂里就登记完
---@param fromKey number 拖动源工位复合键
---@return UnityEngine.RectTransform, XUiGridSkyTower3DWorkBench
function XUiSkyTowerCommon:CreateDragClone(fromKey)
    self:RefreshDropZones()
    return self._Workbench:CreateDragClone(fromKey, self.ProductContainer)
end

---@param cloneObj XUiGridSkyTower3DWorkBench
function XUiSkyTowerCommon:RecycleDragClone(cloneObj)
    --Context先回收副本再派发Drop，暂存到Drop判定后再决定保留或回收
    self._ReleasedDragClone = cloneObj
end

-- 起拖：保护源工位不被裁剪回收，否则出屏后会经ResetDraggable误发一次落点
---@param fromKey number 拖动源工位复合键
function XUiSkyTowerCommon:OnWorkPosDragBegin(fromKey)
    self._DragCanceled = false
    self._Workbench:SetProtectedWorkPos(fromKey)
    self._Control:BeginDragEdgeScroll()
    self:EachWorkBenchGrid(function(grid)
        grid:RefreshDragSourceFaded(fromKey)
        grid:RefreshDropDisable(fromKey)
    end)
    self:_NotifyDragState(fromKey, self._DragContext:GetHoverZoneId())
end

--先停滚动，源工位与副本的显示交给随后到来的Drop处理
function XUiSkyTowerCommon:OnWorkPosDragEnd()
    self._Control:EndDragEdgeScroll()
end

--落空、交换完成或界面关闭后统一还原交互表现
function XUiSkyTowerCommon:FinishWorkPosDrag()
    self._Workbench:SetProtectedWorkPos(nil)
    self:EachWorkBenchGrid(function(grid)
        grid:RefreshDragSourceFaded(nil)
        grid:RefreshDropDisable(nil)
        grid:RefreshDropHover(nil, false)
    end)
    self:_NotifyDragState(nil, nil)
    local pending = self._DragPendingGridShow
    self._DragPendingGridShow = nil
    -- 上下文此刻已是非拖动态，补刷不会再被挂起；作废的拖动不补刷，交给界面重开时的RefreshView
    if pending ~= nil and not self._DragCanceled then
        self:Refresh3DGridShow(pending)
    end
end

-- 指针贴近屏幕上下边缘时同步滚动镜头，屏幕高度属UI环境量，由这里传给Control
function XUiSkyTowerCommon:UpdateDragEdgeScroll()
    if not self:IsDragging() then
        return
    end
    local _, pointerY = self._DragContext:GetPointerScreenXY()
    self._Control:UpdateDragEdgeScroll(pointerY, CS.XUiManager.RealScreenHeight)
end

-- 镜头滚动会让在屏工位增减，落点表存的是格子Transform引用，增减后必须整表重建
-- 每帧无条件重建会产生垃圾，故只在工位真有变动时做
function XUiSkyTowerCommon:RefreshDragZonesIfDirty()
    if not self._Workbench:IsGridsDirty() then
        return
    end
    self._Workbench:ClearGridsDirty()
    if not self:IsDragging() then
        return
    end
    self:RefreshDropZones()
    local fromKey = self._DragContext:GetPayload()
    local toKey = self._DragContext:GetHoverZoneId()
    self:EachWorkBenchGrid(function(grid)
        grid:RefreshDragSourceFaded(fromKey)
        grid:RefreshDropDisable(fromKey)
        grid:RefreshDropHover(fromKey, grid:GetWorkPosKey() == toKey)
    end)
end

-- 界面隐藏或工位批量回收时作废本次拖动，避免回收路径误发一次换位协议
function XUiSkyTowerCommon:CancelWorkPosDrag()
    self._DragCanceled = true
    if self:IsDragging() then
        self._DragContext:End()
    elseif self:IsWorkPosSwapPending() or self._ReleasedDragClone then
        self:ClearWorkPosSwap()
    end
end

-- 悬浮工位变化
---@param fromKey number 拖动源工位复合键
---@param toKey number 悬浮的工位复合键，为空表示未悬浮在任何工位上
function XUiSkyTowerCommon:OnWorkPosDragHover(fromKey, toKey)
    self:EachWorkBenchGrid(function(grid)
        grid:RefreshDropHover(fromKey, grid:GetWorkPosKey() == toKey)
    end)
    self:_NotifyDragState(fromKey, toKey)
end

-- 抬手放下
---@param fromKey number 拖动源工位复合键
---@param toKey number 落点工位复合键，为空表示落空
function XUiSkyTowerCommon:OnWorkPosDrop(fromKey, toKey)
    if self._DragCanceled then
        self:ClearWorkPosSwap()
        return
    end
    if not XTool.IsNumberValid(fromKey) or not XTool.IsNumberValid(toKey) or fromKey == toKey then
        self:ClearWorkPosSwap()
        return
    end
    local fromFloorId, fromIndex = self._Control:ParseWorkPosKey(fromKey)
    local toFloorId, toIndex = self._Control:ParseWorkPosKey(toKey)
    local result = self._Control:CheckWorkPosDrop(fromFloorId, fromIndex, toFloorId, toIndex)
    if result ~= XMVCA.XSkyTower.DropCheckResult.Ok then
        XMVCA.XSkyTower:TipMsg(self._Control:GetClientConfigValue("WorkPosDropTip"))
        self:ClearWorkPosSwap()
        return
    end
    --只保留交换后的显示，不提前修改Model中的工位数据
    local pending = {}
    self._PendingWorkPosSwap = pending
    self._Workbench:BeginSwapWaiting(self._ReleasedDragClone, fromKey, toKey, self.ProductContainer)
    self._ReleasedDragClone = nil
    self._Workbench:SetProtectedWorkPos(nil)
    self:EachWorkBenchGrid(function(grid)
        grid:RefreshDropDisable(nil)
        grid:RefreshDropHover(nil, false)
    end)
    self._Control:RequestSwapWorkPos(fromFloorId, fromIndex, toFloorId, toIndex, nil, function()
        --关闭界面后旧回包不能清理新一轮拖动的副本
        if self._PendingWorkPosSwap == pending then
            self:ClearWorkPosSwap()
        end
    end)
end

function XUiSkyTowerCommon:ClearWorkPosSwap()
    self._PendingWorkPosSwap = nil
    self._Workbench:EndSwapWaiting()
    if self._ReleasedDragClone then
        self._Workbench:RecycleDragClone(self._ReleasedDragClone)
        self._ReleasedDragClone = nil
    end
    self:FinishWorkPosDrag()
end

-- 广播拖动状态，2D主界面据此刷新技能生效提示
function XUiSkyTowerCommon:_NotifyDragState(fromKey, toKey)
    local fromFloorId, fromIndex, toFloorId, toIndex
    if XTool.IsNumberValid(fromKey) then
        fromFloorId, fromIndex = self._Control:ParseWorkPosKey(fromKey)
    end
    if XTool.IsNumberValid(toKey) then
        toFloorId, toIndex = self._Control:ParseWorkPosKey(toKey)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_DRAG_STATE_CHANGE, fromFloorId, fromIndex, toFloorId, toIndex)
end
--endregion

return XUiSkyTowerCommon
ecycleDragClone(self._ReleasedDragClone)
        self._ReleasedDragClone = nil
    end
    self:FinishWorkPosDrag()
end

-- 广播拖动状态，2D主界面据此刷新技能生效提示
function XUiSkyTowerCommon:_NotifyDragState(fromKey, toKey)
    local fromFloorId, fromIndex, toFloorId, toIndex
    if XTool.IsNumberValid(fromKey) then
        fromFloorId, fromIndex = self._Control:ParseWorkPosKey(fromKey)
    end
    if XTool.IsNumberValid(toKey) then
        toFloorId, toIndex = self._Control:ParseWorkPosKey(toKey)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_DRAG_STATE_CHANGE, fromFloorId, fromIndex, toFloorId, toIndex)
end
--endregion

return XUiSkyTowerCommon
