
---@class XUiPanelSkyTowerLevelUp : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerLevelUp = XClass(XUiNode, "XUiPanelSkyTowerLevelUp")

function XUiPanelSkyTowerLevelUp:OnStart(gridClass)
    self.GridClass = gridClass
    self:InitUi()
    self:InitCb()
end

function XUiPanelSkyTowerLevelUp:InitUi()
    self.Grids = {}
    self.DataList = {}
    self.GridItem.gameObject:SetActiveEx(false)
end

function XUiPanelSkyTowerLevelUp:InitCb()
end

function XUiPanelSkyTowerLevelUp:Refresh(list, ...)
    self.DataList = list
    self.PanelNothing.gameObject:SetActiveEx(self:IsEmpty())
    if self:GetTxtTitle() then
        self.TxtTitle.text = self:GetTxtTitle()
    end
    if self:IsEmpty() and self:GetTxtEmpty() then
        self.TxtEmpty.text = self:GetTxtEmpty()
    end
    
    self:RefreshGrids()
end

function XUiPanelSkyTowerLevelUp:IsEmpty()
    return XTool.IsTableEmpty(self.DataList)
end

function XUiPanelSkyTowerLevelUp:GetTxtTitle()
end

function XUiPanelSkyTowerLevelUp:GetTxtEmpty()
end

function XUiPanelSkyTowerLevelUp:HideAllGrids()
    for _, grid in pairs(self.Grids) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid:Close()
        end
    end
end

function XUiPanelSkyTowerLevelUp:RefreshGrids()
    self:HideAllGrids()
    if self:IsEmpty() then
        return
    end
    for idx, data in ipairs(self.DataList) do
        local grid = self.Grids[idx]
        if not grid then
            local ui = idx == 1 and self.GridItem or XUiHelper.Instantiate(self.GridItem, self.Container.transform)
            ui.gameObject:SetActiveEx(true)
            grid = self.GridClass.New(ui, self.Parent)
            self.Grids[idx] = grid
        end
        grid:Open()
        grid:Refresh(data)
    end
end

return XUiPanelSkyTowerLevelUp