local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiPanelSkyTowerWorkBaseFood : XUiNode 手作所需材料列表栏
---@field Parent XUiSkyTowerWork
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerWorkBaseFood = XClass(XUiNode, "XUiPanelSkyTowerWorkBaseFood")

--region 生命周期
function XUiPanelSkyTowerWorkBaseFood:OnStart()
    self.GridItem.gameObject:SetActiveEx(false)
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerStorage"), self)
end

function XUiPanelSkyTowerWorkBaseFood:OnEnable()
    self:RefreshView()
end
--endregion

--region 界面刷新
-- 换了选中的产品要重排，配方要用的材料得浮到前面
function XUiPanelSkyTowerWorkBaseFood:SetProductId(productId)
    local changed = self._ProductId ~= productId
    self._ProductId = productId
    self:RefreshView(changed)
end

function XUiPanelSkyTowerWorkBaseFood:RefreshView(resetPosition)
    local groupId = self._Control:GetFloorGroupIdByFloorId(self.Parent:GetFloorId())
    self._StorageList = self._Control:GetSortedStorageList(groupId, self._ProductId)
    self.DynamicTable:SetDataSource(self._StorageList)
    self.DynamicTable:ReloadDataSync(resetPosition and 1 or nil)
end

---@param grid XUiGridSkyTowerStorage
function XUiPanelSkyTowerWorkBaseFood:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self._StorageList[index])
    end
end
--endregion

return XUiPanelSkyTowerWorkBaseFood
