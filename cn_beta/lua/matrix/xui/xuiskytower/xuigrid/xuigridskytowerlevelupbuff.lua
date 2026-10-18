---@class XUiGridSkyTowerLevelUpBuff : XUiNode 楼层升级弹窗的收益行
---@field _Control XSkyTowerControl
local XUiGridSkyTowerLevelUpBuff = XClass(XUiNode, "XUiGridSkyTowerLevelUpBuff")

local RowType = XMVCA.XSkyTower.LevelUpRowType

function XUiGridSkyTowerLevelUpBuff:OnStart()
    self.PanelValue.gameObject:SetActiveEx(false)
    self.PanelValueChange.gameObject:SetActiveEx(false)
    self.PanelToggle.gameObject:SetActiveEx(false)

    self._Handlers = {
        [RowType.Value] = Handler(self, self.ShowValue),
        [RowType.ValueChange] = Handler(self, self.ShowValueChange),
        [RowType.Toggle] = Handler(self, self.ShowToggle),
    }

    self._RowTypeGrid = {
        [RowType.Value] = self.PanelValue,
        [RowType.ValueChange] = self.PanelValueChange,
        [RowType.Toggle] = self.PanelToggle,
    }

    self._RowGrids = {}
end

function XUiGridSkyTowerLevelUpBuff:SetLimitShowCount(showCount)
    self._ShowCount = showCount
end

function XUiGridSkyTowerLevelUpBuff:PlayRefreshAnimation()
    
end

function XUiGridSkyTowerLevelUpBuff:StopRefreshAnimation()
    
end

---@param datas XSkyTowerLevelUpParam[]
function XUiGridSkyTowerLevelUpBuff:Refresh(datas)
    for _, grids in pairs(self._RowGrids) do
        for _, grid in pairs(grids) do
            grid.GameObject:SetActiveEx(false)
        end
    end

    local rowTypeCount = {}
    for i, data in ipairs(datas) do
        --if i > self._ShowCount then
        --    return
        --end

        local rowType = data.RowType
        local index = (rowTypeCount[rowType] or 0) + 1
        local grid = self._RowGrids[rowType] and self._RowGrids[rowType][index]
        if not grid then
            local rowTypeGrid = self._RowTypeGrid[rowType]
            local go = index == 1 and rowTypeGrid or XUiHelper.Instantiate(rowTypeGrid, self.Transform)
            grid = {}
            XUiHelper.InitUiClass(grid, go)
            self._RowGrids[rowType] = self._RowGrids[rowType] or {}
            self._RowGrids[rowType][index] = grid
        end
        rowTypeCount[rowType] = index
        grid.GameObject:SetActiveEx(true)
        grid.Transform:SetSiblingIndex(i) --最顶上是标题
        self._Handlers[rowType](grid, data)
    end
end

---单数值行，用于没有前后对比的项
---@param data XSkyTowerLevelUpParam
function XUiGridSkyTowerLevelUpBuff:ShowValue(grid, data)
    grid.TxtTitle.text = data.Title
    grid.TxtValue.text = data.Value
end

---升级前后对比行
---@param data XSkyTowerLevelUpParam
function XUiGridSkyTowerLevelUpBuff:ShowValueChange(grid, data)
    grid.TxtTitle.text = data.Title
    grid.TxtValueBefore.text = data.Value
    grid.TxtValueAfter.text = data.AfterValue
end

---勾选行
---@param data XSkyTowerLevelUpParam
function XUiGridSkyTowerLevelUpBuff:ShowToggle(grid, data)
    local isOpen = self._Control:GetSetting(data.Key)
    grid.TxtTitle.text = data.Title
    grid.BtnToggle:SetButtonState(isOpen and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    grid.BtnToggle:AddEventListener(function()
        isOpen = not isOpen
        self._Control:SaveSetting(data.Key, isOpen)
        grid.BtnToggle:SetButtonState(isOpen and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end)
end

return XUiGridSkyTowerLevelUpBuff

---@class XSkyTowerLevelUpParam
---@field RowType number 样式
---@field Title string 标题
---@field Value string 单个文本
---@field AfterValue string 新数值文本
---@field Key string 持久化数据
