local XUiPanelSkyTowerWorkBase = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerWorkBase")

---@class XUiPanelSkyTowerWorkProduction : XUiPanelSkyTowerWorkBase 制作
---@field Parent XUiSkyTowerWork
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerWorkProduction = XClass(XUiPanelSkyTowerWorkBase, "XUiPanelSkyTowerWorkProduction")

--region 生命周期
function XUiPanelSkyTowerWorkProduction:OnStart()
    self.Super.OnStart(self)
    ---@type UiObject[] 配方材料格复用池
    self._NeedList = {}
end
--endregion

--region 界面刷新
-- 制作台比另两个页签多一块配方清单，仓库栏也要跟着当前产品重排
function XUiPanelSkyTowerWorkProduction:RefreshChooseInfo(productId)
    self.Super.RefreshChooseInfo(self, productId)
    self.PanelNeed.gameObject:SetActiveEx(true)
    self.TxtNeed.text = self._Control:GetProductionNeedText(self.TxtProductName.text)
    local consumes = self._Control:GetFoodConsumes(productId)
    local groupId = self._Control:GetFloorGroupIdByFloorId(self.Parent:GetFloorId())
    XUiHelper.RefreshUiObjectList(self._NeedList, self.GridNeed.parent, self.GridNeed, #consumes, function(index, grid)
        local consume = consumes[index]
        local ownCount = self._Control:GetStorageProductCount(groupId, consume.ProductType, consume.Id)
        grid.RImgIcon:SetRawImageEx(self._Control:GetProductIcon(consume.WorkType, consume.Id))
        grid.TxtCount.text = consume.Count
        grid.TxtCount.color = XUiHelper.Hexcolor2Color(self._Control:GetClientConfigValue("EnoughColor", ownCount >= consume.Count and 1 or 2))
    end)
    self.Parent:RefreshBaseFood(productId)
end

function XUiPanelSkyTowerWorkProduction:RefreshChoose()
    self.Super.RefreshChoose(self)
    -- 没选产品时配方清单整块隐藏，父类只管到PanelChoose
    if not XTool.IsNumberValid(self._SelectProductId) then
        self.PanelNeed.gameObject:SetActiveEx(false)
        self.Parent:RefreshBaseFood(nil)
    end
end

function XUiPanelSkyTowerWorkProduction:GetTargetWorkType()
    return XMVCA.XSkyTower.WorkType.Food
end

function XUiPanelSkyTowerWorkProduction:GetGridProxy()
    return require("XUi/XUiSkyTower/XUiGrid/Work/XUiGridSkyTowerWorkProduction")
end
--endregion

return XUiPanelSkyTowerWorkProduction
