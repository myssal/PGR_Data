---@class XUiGridSkyTowerStorage : XUiNode 仓库项
---@field private _Control XSkyTowerControl
local XUiGridSkyTowerStorage = XClass(XUiNode, "XUiGridSkyTowerStorage")

---@param data XSkyTowerStorageInfoProtocol
function XUiGridSkyTowerStorage:SetData(data)
    if data.ProductType == XMVCA.XSkyTower.ProductType.Ingredient then
        self.RImgIcon:SetRawImage(self._Control:GetIngredientIcon(data.ProductId))
    elseif data.ProductType == XMVCA.XSkyTower.ProductType.Food then
        self.RImgIcon:SetRawImage(self._Control:GetFoodIcon(data.ProductId))
    end
    self.TxtCount.text = data.Count
    self.ImgFull.gameObject:SetActiveEx(self._Control:IsProductFull(data.ProductType, data.ProductId))
    self:RefreshTrend(0)
end

---@param data { WorkType:number, ProductId:number }
---@param state table|nil 主界面已计算的数量、容量与涨跌趋势
function XUiGridSkyTowerStorage:Refresh(data, groupId, state)
    local count
    local limit
    if state then
        count, limit = state.Count, state.Limit
    elseif XTool.IsNumberValid(groupId) then
        local productType = self._Control:GetProductTypeByWorkType(data.WorkType)
        count = self._Control:GetStorageProductCount(groupId, productType, data.ProductId)
        limit = self._Control:GetStorageProductLimit(groupId, productType, data.ProductId)
    else
        count = self._Control:GetProductCount(data.WorkType, data.ProductId)
        limit = self._Control:GetProductLimit(data.WorkType, data.ProductId)
    end

    self.RImgIcon:SetRawImage(self._Control:GetProductIcon(data.WorkType, data.ProductId))
    self:RefreshAmount(count, limit, state and state.Trend or 0)
    if not XTool.UObjIsNil(self.ImgQuality) then
        self.ImgQuality:SetSprite(self._Control:GetProductQualityIcon(data.WorkType, data.ProductId, true))
    end
end

---数量和趋势变化时只刷新动态内容，保留图标与品质
function XUiGridSkyTowerStorage:RefreshAmount(count, limit, trend)
    self.TxtCount.text = count
    self.ImgFull.gameObject:SetActiveEx(limit > 0 and count >= limit)
    self:RefreshTrend(trend)
end

function XUiGridSkyTowerStorage:RefreshTrend(trend)
    if not XTool.UObjIsNil(self.ImgArrowUp) then
        self.ImgArrowUp.gameObject:SetActiveEx(trend > 0)
    end
    if not XTool.UObjIsNil(self.ImgArrowDown) then
        self.ImgArrowDown.gameObject:SetActiveEx(trend < 0)
    end
end

return XUiGridSkyTowerStorage
