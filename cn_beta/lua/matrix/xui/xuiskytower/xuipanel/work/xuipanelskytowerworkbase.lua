local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiPanelSkyTowerWorkBase : XUiNode 工作台界面页签基类
---@field _Control XSkyTowerControl
---@field Parent XUiSkyTowerWork
local XUiPanelSkyTowerWorkBase = XClass(XUiNode, "XUiPanelSkyTowerWorkBase")

--region 生命周期
function XUiPanelSkyTowerWorkBase:OnStart()
    self.GridFoods.gameObject:SetActiveEx(false)
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self:GetDynamicTable())
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(self:GetGridProxy(), self, handler(self, self.OnGridClick))
    self:RegisterUiEvents()
end

function XUiPanelSkyTowerWorkBase:OnEnable()
    self:RefreshView()
end
--endregion

--region 界面刷新
function XUiPanelSkyTowerWorkBase:RefreshView()
    if not self._HasDefaultSelected then
        self._HasDefaultSelected = true
        local workInfo = self.Parent:GetWorkInfo()
        -- 工位上的产品属于别的区域时不能拿来当本页签的默认选中
        local isWorking = workInfo and workInfo.WorkType == self:GetTargetWorkType()
        self._SelectProductId = isWorking and workInfo.ProductId or nil
    end
    -- 可选产品限本楼层所属分区，跨分区的产品在这个楼层没有仓库槽位
    self._ProductIds = self._Control:GetFloorGroupUnlockProductIds(self.Parent:GetFloorId(), self:GetTargetWorkType(), true)
    -- 只修正已失效的选中项，未选择或主动取消选择时不自动选中第一项
    if XTool.IsNumberValid(self._SelectProductId) and not table.contains(self._ProductIds, self._SelectProductId) then
        self._SelectProductId = self._ProductIds[1]
    end
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self._ProductIds))
    self.DynamicTable:SetDataSource(self._ProductIds)
    self.DynamicTable:ReloadDataSync(0)
    self:RefreshChoose()
end

-- 事件只刷新格子当前绑定的产品，保留列表顺序和选中态
function XUiPanelSkyTowerWorkBase:RefreshData()
    local floorId = self.Parent:GetFloorId()
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetData(floorId, grid.ProductId)
    end
    self:RefreshChoose()
end

-- 没选中产品时展示占位图，选中后才展示产品详情与确认按钮
function XUiPanelSkyTowerWorkBase:RefreshChoose()
    local isEmpty = not XTool.IsNumberValid(self._SelectProductId)
    self.PanelNoChoose.gameObject:SetActiveEx(isEmpty)
    self.PanelChoose.gameObject:SetActiveEx(not isEmpty)
    self.BtnConfirm:SetDisable(isEmpty, not isEmpty)
    if not isEmpty then
        self:RefreshChooseInfo(self._SelectProductId)
    end
end

function XUiPanelSkyTowerWorkBase:RefreshChooseInfo(productId)
    local workType = self:GetTargetWorkType()
    self.RImgIcon:SetRawImageEx(self._Control:GetProductIcon(workType, productId))
    self.ImgQualityBg:SetSprite(self._Control:GetProductQualityIcon(workType, productId))
    self.TxtProductName.text = self._Control:GetProductName(workType, productId)
    self.TxtProductionRate.text = self._Control:GetProductSpeedText(workType, productId)
end

---@param grid XUiGridSkyTowerWorkBase
function XUiPanelSkyTowerWorkBase:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local productId = self._ProductIds[index]
        grid:SetData(self.Parent:GetFloorId(), productId)
        -- 格子被复用滚回来时选中态得跟着数据走，不能留在上一条产品身上
        grid:SetSelect(productId == self._SelectProductId)
    end
end

-- 再点一次已选中的产品视为取消选择
---@param grid XUiGridSkyTowerWorkBase
function XUiPanelSkyTowerWorkBase:OnGridClick(grid)
    if self._SelectProductId == grid.ProductId then
        self._SelectProductId = nil
    else
        self._SelectProductId = grid.ProductId
    end
    for _, item in pairs(self.DynamicTable:GetGrids()) do
        item:SetSelect(item.ProductId == self._SelectProductId)
    end
    self:RefreshChoose()
end

function XUiPanelSkyTowerWorkBase:GetSelectProductId()
    return self._SelectProductId
end
--endregion

--region 按钮
function XUiPanelSkyTowerWorkBase:RegisterUiEvents()
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
end

-- 选完生产内容进选人页，工作类型以当前页签为准，可能与工位原有的不同
function XUiPanelSkyTowerWorkBase:OnBtnConfirmClick()
    if not XTool.IsNumberValid(self._SelectProductId) then
        return
    end
    self.Parent:ShowSelectRole()
end
--endregion

--region 子类重写
---@return number 本页签对应的工作类型
function XUiPanelSkyTowerWorkBase:GetTargetWorkType()
    return XMVCA.XSkyTower.WorkType.None
end

---@return UnityEngine.RectTransform 挂XDynamicTableNormal的节点
function XUiPanelSkyTowerWorkBase:GetDynamicTable()
    return self.PanelFoodList
end

function XUiPanelSkyTowerWorkBase:GetGridProxy()
    return nil
end
--endregion

return XUiPanelSkyTowerWorkBase
