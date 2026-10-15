local XUiGridSkyTowerChange = XClass(nil, "XUiGridSkyTowerChange")

local Inaccurate = XMVCA.XSkyTower.Inaccurate

function XUiGridSkyTowerChange:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridSkyTowerChange:Refresh(title, speed, unit)
    if speed <= Inaccurate and speed >= -Inaccurate then
        speed = 0
    end
    if self.Title == title and self.Speed == speed and self.Unit == unit then
        return
    end
    if self.Title ~= title then
        self.TxtTitle.text = title
    end
    self.Title, self.Speed, self.Unit = title, speed, unit
    local isAdd = speed > 0
    if isAdd then
        self.TxtMinus.gameObject:SetActiveEx(false)
        self.TxtAdd.gameObject:SetActiveEx(true)
        self.TxtAdd.text = "+" .. speed .. unit
    else
        self.TxtMinus.gameObject:SetActiveEx(true)
        self.TxtAdd.gameObject:SetActiveEx(false)
        self.TxtMinus.text = speed .. unit
    end
end


---@class XUiGridSkyTowerStatistics : XUiNode
---@field _Control XSkyTowerControl
local XUiGridSkyTowerStatistics = XClass(XUiNode, "XUiGridSkyTowerStatistics")

function XUiGridSkyTowerStatistics:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.GridProduce = XUiGridSkyTowerChange.New(self.PanelCook)
    self.GridConsume = XUiGridSkyTowerChange.New(self.PanelSell)
    self.GridChange  = XUiGridSkyTowerChange.New(self.PanelChange)
end

--- 刷新产品产销统计
---@param productId number 产品Id
---@param workType number 区域类型
---@param data table 当前分区的产品统计
---@param titles string[] 统计标题
---@param unit string 单位
---@return void
function XUiGridSkyTowerStatistics:Refresh(productId, workType, data, titles, unit)
    if not XTool.IsNumberValid(productId) then
        self.GameObject:SetActiveEx(false)
        return
    end
    if self.ProductId ~= productId or self.WorkType ~= workType then
        self.RImgIcon:SetRawImage(self._Control:GetProductIcon(workType, productId))
        self.TxtName.text = self._Control:GetProductName(workType, productId)
    end
    self.ProductId = productId
    self.WorkType = workType
    self.Titles = titles
    self.Unit = unit
    self.EffectFlash.gameObject:SetActiveEx(false)
    self.PanelCount.gameObject:SetActiveEx(true)
    self.TxtInventory.gameObject:SetActiveEx(false)
    self:RefreshProfit(data, true)
end

-- 数据变更时只更新数值；图标、名称及列表布局在切页/格子复用时刷新
---@param forceRefresh boolean|nil 格子复用时强制刷新标题和单位
function XUiGridSkyTowerStatistics:RefreshProfit(data, forceRefresh)
    local digital = XMVCA.XSkyTower.Digital.One
    local produceSpeed = data and data.TheoreticalProduceSpeed or 0
    if forceRefresh or self._RawProduceSpeed ~= produceSpeed then
        self._RawProduceSpeed = produceSpeed
        local displaySpeed = self._Control:GetFloorValue(produceSpeed, digital)
        self.GridProduce:Refresh(self.Titles[1], displaySpeed, self.Unit)
    end
    local consumeSpeed = data and data.TheoreticalConsumeSpeed or 0
    if forceRefresh or self._RawConsumeSpeed ~= consumeSpeed then
        self._RawConsumeSpeed = consumeSpeed
        local displaySpeed = self._Control:GetFloorValue(consumeSpeed, digital)
        self.GridConsume:Refresh(self.Titles[2], -displaySpeed, self.Unit)
    end
    local changeSpeed = data and data.TheoreticalChangeSpeed or 0
    if forceRefresh or self._RawChangeSpeed ~= changeSpeed then
        self._RawChangeSpeed = changeSpeed
        local displaySpeed = self._Control:GetFloorValue(changeSpeed, digital)
        self.GridChange:Refresh(self.Titles[3], displaySpeed, self.Unit)
    end
    local count = data and data.Count or 0
    if self.Count ~= count then
        self.Count = count
        self.TxtCount.text = count
    end
end

function XUiGridSkyTowerStatistics:ShowEffect()
    self.EffectFlash.gameObject:SetActiveEx(true)
end

return XUiGridSkyTowerStatistics
