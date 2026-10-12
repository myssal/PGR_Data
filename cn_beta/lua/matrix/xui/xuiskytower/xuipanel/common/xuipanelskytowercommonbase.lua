---@class XUiPanelSkyTowerCommonBase : XUiNode 对象池+楼层管理
---@field Parent XUiSkyTowerCommon
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerCommonBase = XClass(XUiNode, "XUiPanelSkyTowerCommonBase")

---屏幕边缘往外多留这么多像素才算出屏，免得工位在边界上反复进出
local ScreenCullMargin = 200

function XUiPanelSkyTowerCommonBase:OnStart()
    self:InitPool()
    ---池子里最多留几个闲置Grid，多出来的直接销毁
    self._PoolMaxCount = 3
    self._HalfWidth = CS.XUiManager.RealScreenWidth * 0.5 + ScreenCullMargin
    self._HalfHeight = CS.XUiManager.RealScreenHeight * 0.5 + ScreenCullMargin
end

function XUiPanelSkyTowerCommonBase:OnDisable()
    self:OnRecycleAll()
end

function XUiPanelSkyTowerCommonBase:OnDestroy()
    self:OnRecycleAll()
    self:ClearPool()
end

function XUiPanelSkyTowerCommonBase:UpdateLoop(floorIds)
    if not self:IsNodeShow() then
        return
    end
    self:OnUpdateLoop(floorIds)
end

function XUiPanelSkyTowerCommonBase:UpdateLoopFloor(floorId)
    if not self:IsNodeShow() then
        return
    end
    self:OnUpdateLoopFloor(floorId)
end

function XUiPanelSkyTowerCommonBase:SetNodeTransform(node)
    node.gameObject:SetActiveEx(false)
    self._NodeTransform = node.transform
end

function XUiPanelSkyTowerCommonBase:InitPool()
    self._Pool = {}
end

function XUiPanelSkyTowerCommonBase:ClearPool()
    for i = 1, #self._Pool do
        self:DestroyGrid(self._Pool[i])
    end
    self._Pool = {}
end

---彻底销毁一个Grid：先解除父节点绑定，否则Panel Release时会访问到已销毁的GameObject
---@param grid XUiGridSkyTower3DBase
function XUiPanelSkyTowerCommonBase:DestroyGrid(grid)
    local go = grid.GameObject
    grid:UnBindParent()
    grid:OnDestroyUi()
    grid:Release()
    XUiHelper.Destroy(go)
end

function XUiPanelSkyTowerCommonBase:CreateGridWithPool()
    local count = #self._Pool
    if count > 0 then
        local grid = self._Pool[count]
        self._Pool[count] = nil
        return grid
    end
    local ui = XUiHelper.Instantiate(self._NodeTransform, self.Transform)
    return self:OnCreateGrid(ui)
end

---归还Grid，池子满了就直接销毁
---@param grid XUiGridSkyTower3DBase
function XUiPanelSkyTowerCommonBase:PushPool(grid)
    grid:OnRecycle()
    if #self._Pool >= self._PoolMaxCount then
        self:DestroyGrid(grid)
        return
    end
    self._Pool[#self._Pool + 1] = grid
end

---@param uiTransform UnityEngine.Transform 已换算过屏幕坐标的3DUi节点
function XUiPanelSkyTowerCommonBase:IsInScreen(uiTransform)
    local x, y = XTool.GetLocalPosition(uiTransform)
    return math.abs(x) <= self._HalfWidth and math.abs(y) <= self._HalfHeight
end

---@param room XSkyTowerRoom
---@param target UnityEngine.Transform 工位的3DUiOffset挂点
function XUiPanelSkyTowerCommonBase:IsTargetInScreen(room, target)
    room:SetViewPosToTransformLocalPosition(self._NodeTransform, target)
    return self:IsInScreen(self._NodeTransform)
end

-------------------------Overload-------------------------

function XUiPanelSkyTowerCommonBase:OnCreateGrid(ui)
    XLog.Error("子类未重写OnCreateGrid方法.")
    return nil
end

---回收所有节点
function XUiPanelSkyTowerCommonBase:OnRecycleAll()

end

---回收楼层节点
function XUiPanelSkyTowerCommonBase:OnRecycleFloor(floorId)

end

---每帧调用
function XUiPanelSkyTowerCommonBase:OnUpdateLoop(floorIds)

end

---每帧调用
function XUiPanelSkyTowerCommonBase:OnUpdateLoopFloor(floorId)

end

-------------------------Overload End---------------------

return XUiPanelSkyTowerCommonBase
