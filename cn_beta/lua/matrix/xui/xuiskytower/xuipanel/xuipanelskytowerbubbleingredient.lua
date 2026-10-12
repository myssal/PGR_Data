
---@class XUiPanelSkyTowerBubbleIngredient : XUiNode
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerBubbleIngredient = XClass(XUiNode, "XUiPanelSkyTowerBubbleIngredient")

function XUiPanelSkyTowerBubbleIngredient:OnStart()
    self.Grids = {}
    self.OffsetLeft = CS.UnityEngine.Vector3(-300, 0, 0)
    self.OffsetRight = CS.UnityEngine.Vector3(256, 0, 0)

    self.OriginParent = self.Transform.parent
end

function XUiPanelSkyTowerBubbleIngredient:Show(dockRectTransform, foodId, isLeft)
    self:Open()
    local offset = isLeft and self.OffsetLeft or self.OffsetRight
    -- 这样处理可以避免分辨率问题
    self.Transform:SetParent(dockRectTransform)
    self.Transform.localPosition = offset
    self.Transform:SetParent(self.OriginParent)

    self.FoodId = foodId
    self:UpdateView()
end

function XUiPanelSkyTowerBubbleIngredient:UpdateView()
    self:UpdateIngredients()
end

--- 刷新材料列表
function XUiPanelSkyTowerBubbleIngredient:UpdateIngredients()
    local list = self._Control:GetFoodConsumes(self.FoodId)

    for _, grid in pairs(self.Grids) do
        grid.GameObject:SetActiveEx(false)
    end

    for index, data in pairs(list or {}) do
        local grid = self.Grids[index]
        if not grid then
            local ui = index == 1 and self.GridNeedFood or XUiHelper.Instantiate(self.GridNeedFood, self.ImgBubbleBg.transform)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.Grids[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid.RImgIcon:SetRawImage(self._Control:GetProductIcon(data.WorkType, data.Id))
        grid.TxtCount.text = data.Count
    end
end

function XUiPanelSkyTowerBubbleIngredient:Hide()
    self:Close()
end

return XUiPanelSkyTowerBubbleIngredient