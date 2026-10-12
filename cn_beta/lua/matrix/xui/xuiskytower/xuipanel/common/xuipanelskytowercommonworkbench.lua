local XUiGridSkyTower3DWorkBench = require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DWorkBench")
local XUiPanelSkyTowerCommonBase = require("XUi/XUiSkyTower/XUiPanel/Common/XUiPanelSkyTowerCommonBase")

---@class XUiPanelSkyTowerCommonWorkbench : XUiPanelSkyTowerCommonBase 通天塔工作台3DUi
---@field Parent XUiSkyTowerCommon
---@field GirdProduct UnityEngine.RectTransform
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerCommonWorkbench = XClass(XUiPanelSkyTowerCommonBase, "XUiPanelSkyTowerCommonWorkbench")

--region 生命周期
function XUiPanelSkyTowerCommonWorkbench:OnStart()
    self.Super.OnStart(self)
    ---@type table<number, table<number, XUiGridSkyTower3DWorkBench>> [楼层Id][工位下标]
    self._Grids = {}
    ---@type table<number, table<number, UnityEngine.Transform|boolean>> 工位UI挂点，false代表这个节点在楼层预制体里没有
    self._Targets = {}
    --self._PoolMaxCount = 6
    ---@type table<number, boolean> 当前该显示的楼层集合，每帧复用同一张表避免产生垃圾
    self._InRange = {}
    self:SetNodeTransform(self.GirdProduct)
end

function XUiPanelSkyTowerCommonWorkbench:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshRedPoint()
end

function XUiPanelSkyTowerCommonWorkbench:OnDisable()
    self.Parent:CancelWorkPosDrag()
    self.Super.OnDisable(self)
end

function XUiPanelSkyTowerCommonWorkbench:OnDestroy()
    self.Parent:CancelWorkPosDrag()
    self.Super.OnDestroy(self)
    self:DestroyDragClone()
end
--endregion

--region 事件
function XUiPanelSkyTowerCommonWorkbench:OnGetLuaEvents()
    return {
        XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE,
        XEventId.EVENT_SKY_TOWER_WORK_BENCH_CHANGE_STAFF,
        XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE,
    }
end

function XUiPanelSkyTowerCommonWorkbench:OnNotify(evt)
    if evt == XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE then
        self._Targets = {}
        return
    end
    self:RefreshRedPoint()
end
--endregion

function XUiPanelSkyTowerCommonWorkbench:OnCreateGrid(ui)
    return XUiGridSkyTower3DWorkBench.New(ui, self, self.Transform)
end

--region 对象池

---@return XUiGridSkyTower3DWorkBench|nil
function XUiPanelSkyTowerCommonWorkbench:CreateWorkBench(floorId, index, target)
    local grid = self:CreateGridWithPool()
    if not grid then
        return nil
    end
    local floorGrids = self._Grids[floorId]
    if not floorGrids then
        floorGrids = {}
        self._Grids[floorId] = floorGrids
    end
    grid:SetName(string.format("WorkBench_%s_%s", floorId, index))
    grid:SetTarget(target)
    --Open会触发OnEnable，先设置透明度，避免复用格子时显示出交换前的内容
    grid:SetSwapHidden(self:IsSwapWaitingKey(self._Control:MakeWorkPosKey(floorId, index)))
    grid:Show(floorId, index)
    -- 基类会把grid.Parent覆写成3D挂点
    grid:InitDraggable(self.Parent)
    floorGrids[index] = grid
    self._GridsDirty = true
    return grid
end

function XUiPanelSkyTowerCommonWorkbench:RecycleWorkBench(floorId, index)
    local floorGrids = self._Grids[floorId]
    local grid = floorGrids and floorGrids[index]
    if not grid then
        return
    end
    -- 拖动源一旦被回收，ResetDraggable会经EndIfDraggingBy误发一次落点，整次拖动期间都要留着
    if self._ProtectedKey and self._ProtectedKey == self._Control:MakeWorkPosKey(floorId, index) then
        return
    end
    floorGrids[index] = nil
    self._GridsDirty = true
    self:PushPool(grid)
end

function XUiPanelSkyTowerCommonWorkbench:OnRecycleFloor(floorId)
    local floorGrids = self._Grids[floorId]
    if not floorGrids then
        return
    end
    for index in pairs(floorGrids) do
        self:RecycleWorkBench(floorId, index)
    end
end

function XUiPanelSkyTowerCommonWorkbench:OnRecycleAll()
    -- 界面隐藏时无条件收干净，保护标记若未被抬手清掉会拦住回收
    self._ProtectedKey = nil
    for floorId in pairs(self._Grids) do
        self:OnRecycleFloor(floorId)
    end
end
--endregion

--region 每帧调用
function XUiPanelSkyTowerCommonWorkbench:OnUpdateLoop(floorIds)
    self:RecycleFloorsOutOfRange(floorIds)
    self:UpdateSwapWaiting()
end

function XUiPanelSkyTowerCommonWorkbench:OnUpdateLoopFloor(floorId)
    --镜头能拉远，同屏可见楼层数不固定，只能逐层交给屏幕裁剪判定
    self:UpdateFloorWorkBench(floorId)
end
--endregion

--region 界面刷新
-- 只显示当前楼层区间的工作区域，切区间后旧区间不再被每帧驱动，须显式回收
---@param floorIds number[] 当前该显示的楼层
function XUiPanelSkyTowerCommonWorkbench:RecycleFloorsOutOfRange(floorIds)
    for floorId in pairs(self._InRange) do
        self._InRange[floorId] = nil
    end
    for i = 1, #floorIds do
        self._InRange[floorIds[i]] = true
    end
    for floorId in pairs(self._Grids) do
        if not self._InRange[floorId] then
            self:OnRecycleFloor(floorId)
        end
    end
end

--刷新单层工位UI
---@param floorId number
function XUiPanelSkyTowerCommonWorkbench:UpdateFloorWorkBench(floorId)
    local room = self._Control:GetRoom(floorId)
    for index = 1, self:GetFloorWorkCount(floorId) do
        if not self._Control:GetWorkPos(floorId, index) then
            goto continue
        end
        local grid = self:GetWorkBench(floorId, index)
        if grid then
            grid:Open()
            grid:UpdateTransform(room)
            if self:IsInScreen(grid.Transform) then
                grid:OnRefresh()
            else
                self:RecycleWorkBench(floorId, index)
            end
        else
            local target = self:GetWorkTarget(room, floorId, index)
            if target and self:IsTargetInScreen(room, target) then
                grid = self:CreateWorkBench(floorId, index, target)
                if grid then
                    grid:UpdateTransform(room)
                    grid:OnRefresh()
                end
            end
        end
        :: continue ::
    end
end

function XUiPanelSkyTowerCommonWorkbench:RefreshRedPoint()
    self:EachGrid(function(grid)
        grid:RefreshRedPoint()
    end)
end

-- 楼层工位总数
---@param floorId number
---@return number
function XUiPanelSkyTowerCommonWorkbench:GetFloorWorkCount(floorId)
    return math.max(self._Control:GetFloorWorkNum(floorId), self._Control:GetWorkPosCount(floorId))
end

-- 工位UI挂点（带缓存）
---@param room XSkyTowerRoom
---@return UnityEngine.Transform
function XUiPanelSkyTowerCommonWorkbench:GetWorkTarget(room, floorId, index)
    local floorTargets = self._Targets[floorId]
    if not floorTargets then
        floorTargets = {}
        self._Targets[floorId] = floorTargets
    end
    local target = floorTargets[index]
    if not target then
        target = room:GetWorkUiOffsetNode(index)
        floorTargets[index] = target
    end
    return target
end

---@return XUiGridSkyTower3DWorkBench
function XUiPanelSkyTowerCommonWorkbench:GetWorkBench(floorId, index)
    local floorGrids = self._Grids[floorId]
    return floorGrids and floorGrids[index]
end

-- 遍历当前在屏的工位格子
---@param func fun(grid:XUiGridSkyTower3DWorkBench)
function XUiPanelSkyTowerCommonWorkbench:EachGrid(func)
    for _, floorGrids in pairs(self._Grids) do
        for _, grid in pairs(floorGrids) do
            func(grid)
        end
    end
end
--endregion

--region 拖动换位
-- 拖动期间保护源工位不被回收，为空表示解除保护
---@param fromKey number 拖动源工位复合键
function XUiPanelSkyTowerCommonWorkbench:SetProtectedWorkPos(fromKey)
    self._ProtectedKey = XTool.IsNumberValid(fromKey) and fromKey or nil
end

-- 在屏工位有增减时为true，宿主据此重登记拖拽落点
---@return boolean
function XUiPanelSkyTowerCommonWorkbench:IsGridsDirty()
    return self._GridsDirty == true
end

function XUiPanelSkyTowerCommonWorkbench:ClearGridsDirty()
    self._GridsDirty = false
end

-- 跟手克隆体：不进_Grids，故不会被每帧重定位，位置全交给拖拽上下文
---@param fromKey number 拖动源工位复合键
---@param root UnityEngine.RectTransform 克隆体挂载层
---@return UnityEngine.RectTransform, XUiGridSkyTower3DWorkBench
function XUiPanelSkyTowerCommonWorkbench:CreateDragClone(fromKey, root)
    if not self._DragClone then
        local ui = XUiHelper.Instantiate(self.GirdProduct, root)
        ---@type XUiGridSkyTower3DWorkBench
        self._DragClone = XUiGridSkyTower3DWorkBench.New(ui, self, root)
        self._DragClone:SetName("WorkBenchDragClone")
    end
    local floorId, index = self._Control:ParseWorkPosKey(fromKey)
    self._DragClone:Show(floorId, index)
    self._DragClone:SetupAsDragClone()
    return self._DragClone.Transform, self._DragClone
end

---@param cloneObj XUiGridSkyTower3DWorkBench
function XUiPanelSkyTowerCommonWorkbench:RecycleDragClone(cloneObj)
    if not cloneObj then
        return
    end
    cloneObj:SetSwapWaiting(false)
    cloneObj:SetTarget(nil)
    cloneObj:Close()
end

--松手后把两边的显示留在交换位置，真实工位仍按服务端数据刷新
function XUiPanelSkyTowerCommonWorkbench:BeginSwapWaiting(cloneObj, fromKey, toKey, root)
    if not cloneObj then
        return
    end
    if not self._SwapReturnClone then
        local ui = XUiHelper.Instantiate(self.GirdProduct, root)
        self._SwapReturnClone = XUiGridSkyTower3DWorkBench.New(ui, self, root)
        self._SwapReturnClone:SetName("WorkBenchSwapReturnClone")
    end
    local fromFloorId, fromIndex = self._Control:ParseWorkPosKey(fromKey)
    local toFloorId, toIndex = self._Control:ParseWorkPosKey(toKey)
    local returnClone = self._SwapReturnClone
    returnClone:Show(toFloorId, toIndex)
    returnClone:SetupAsDragClone()
    cloneObj:SetSwapWaiting(true)
    returnClone:SetSwapWaiting(true)
    self._SwapWaiting = {
        FromKey = fromKey,
        ToKey = toKey,
        { Clone = cloneObj, FloorId = toFloorId, Index = toIndex },
        { Clone = returnClone, FloorId = fromFloorId, Index = fromIndex },
    }
    self:EachGrid(function(grid)
        grid:SetSwapHidden(self:IsSwapWaitingKey(grid:GetWorkPosKey()))
    end)
    self:UpdateSwapWaiting()
end

function XUiPanelSkyTowerCommonWorkbench:IsSwapWaitingKey(key)
    local waiting = self._SwapWaiting
    return waiting ~= nil and (key == waiting.FromKey or key == waiting.ToKey)
end

--等待期间仍随镜头定位，但不读取回包后的另一工位内容
function XUiPanelSkyTowerCommonWorkbench:UpdateSwapWaiting()
    for _, entry in ipairs(self._SwapWaiting or table.empty) do
        local room = self._Control:IsExistRoom(entry.FloorId) and self._Control:GetRoom(entry.FloorId) or nil
        if room and room:Exist() then
            entry.Clone:SetTarget(self:GetWorkTarget(room, entry.FloorId, entry.Index))
            entry.Clone:Open()
            entry.Clone:UpdateTransform(room)
        else
            entry.Clone:Close()
        end
    end
end

function XUiPanelSkyTowerCommonWorkbench:EndSwapWaiting()
    local waiting = self._SwapWaiting
    if not waiting then
        return
    end
    self._SwapWaiting = nil
    --先用当前服务端数据刷新真实格子，再撤副本，避免依赖下一次秒刷新
    self:EachGrid(function(grid)
        local key = grid:GetWorkPosKey()
        if key == waiting.FromKey or key == waiting.ToKey then
            grid:OnRefresh()
            grid:SetSwapHidden(false)
        end
    end)
    for _, entry in ipairs(waiting) do
        self:RecycleDragClone(entry.Clone)
    end
end

function XUiPanelSkyTowerCommonWorkbench:DestroyDragClone()
    self:EndSwapWaiting()
    if self._DragClone then
        self:DestroyGrid(self._DragClone)
        self._DragClone = nil
    end
    if self._SwapReturnClone then
        self:DestroyGrid(self._SwapReturnClone)
        self._SwapReturnClone = nil
    end
end
--endregion

return XUiPanelSkyTowerCommonWorkbench
