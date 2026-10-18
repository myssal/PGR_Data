---@class XUiGridSkyTowerWorkBase : XUiNode 工作台页签的产品列表项基类
---@field Parent XUiPanelSkyTowerWorkBase
---@field _Control XSkyTowerControl
local XUiGridSkyTowerWorkBase = XClass(XUiNode, "XUiGridSkyTowerWorkBase")

--region 生命周期
---@param onClick fun(grid:XUiGridSkyTowerWorkBase) 选中回调
function XUiGridSkyTowerWorkBase:OnStart(onClick)
    self._OnClick = onClick
    self:RegisterUiEvents()
end
--endregion

--region 界面刷新
function XUiGridSkyTowerWorkBase:SetData(floorId, productId)
    self.ProductId = productId
    local workType = self:GetWorkType()
    local groupId = self._Control:GetFloorGroupIdByFloorId(floorId)
    local count, isFull, trend = self:_GetInventoryData(groupId, workType, productId)
    self.RImgIcon:SetRawImageEx(self._Control:GetProductIcon(workType, productId))
    self.ImgQualityBg:SetSprite(self._Control:GetProductQualityIcon(workType, productId))
    self.TxtName.text = self._Control:GetProductName(workType, productId)
    self.TxtInventory.text = string.format(self._Control:GetStorageCountText(1), count)
    self.PanelUrgent.gameObject:SetActiveEx(self._Control:IsGroupUrgentProduct(groupId, workType, productId))
    self.TxtFull.gameObject:SetActiveEx(isFull)
    self.ImgUp.gameObject:SetActiveEx(not isFull and trend > 0)
    self.ImgDown.gameObject:SetActiveEx(not isFull and trend < 0)
    if self.TxtExpenditure then
        self.TxtExpenditure.text = self._Control:GetFoodBaseSellPrice(productId)
    end
end

function XUiGridSkyTowerWorkBase:SetSelect(isSelect)
    self.ImgNormal.gameObject:SetActiveEx(not isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end
--endregion

--region 数据获取
---@param groupId number
---@param workType number
---@param productId number
---@return number count 库存数量
---@return boolean isFull 是否满仓
---@return number trend 理论净趋势：增加为1，降低为-1，无变化为0
function XUiGridSkyTowerWorkBase:_GetInventoryData(groupId, workType, productId)
    local productType = self._Control:GetProductTypeByWorkType(workType)
    local groupData = self._Control:GetProductionStatistics()[groupId]
    local products = groupData and groupData.Products[productType]
    local profit = products and products[productId]
    -- 理论产出减理论消耗
    local speed = profit and profit.TheoreticalChangeSpeed / XMVCA.XSkyTower.TimeUnit.Hour or 0
    local trend = self._Control:IsZero(speed) and 0 or (speed > 0 and 1 or -1)
    local count = profit and profit.Count or self._Control:GetStorageProductCount(groupId, productType, productId)
    local limit = self._Control:GetStorageProductLimit(groupId, productType, productId)
    local isFull = limit > 0 and count >= limit
    return count, isFull, trend
end
--endregion

--region 按钮
function XUiGridSkyTowerWorkBase:RegisterUiEvents()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClickClick))
end

function XUiGridSkyTowerWorkBase:OnBtnClickClick()
    if not XTool.IsNumberValid(self.ProductId) then
        return
    end
    if self._OnClick then
        self._OnClick(self)
    end
end
--endregion

--region 子类重写
---@return number 本格子所属的工作类型
function XUiGridSkyTowerWorkBase:GetWorkType()
    return XMVCA.XSkyTower.WorkType.None
end
--endregion

return XUiGridSkyTowerWorkBase
