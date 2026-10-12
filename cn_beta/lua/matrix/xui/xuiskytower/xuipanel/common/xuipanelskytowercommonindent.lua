local XUiPanelSkyTowerCommonBase = require("XUi/XUiSkyTower/XUiPanel/Common/XUiPanelSkyTowerCommonBase")

---@class XUiPanelSkyTowerCommonIndent : XUiPanelSkyTowerCommonBase
---@field Parent XUiSkyTowerCommon
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerCommonIndent = XClass(XUiPanelSkyTowerCommonBase, "XUiPanelSkyTowerCommonIndent")

function XUiPanelSkyTowerCommonIndent:OnStart()
    self.Super.OnStart(self)
    ---@type XUiGridSkyTower3DOrder[]
    self._Grids = {}
    self._Targets = {}
    self:SetNodeTransform(self.GridIndent)
end

function XUiPanelSkyTowerCommonIndent:OnCreateGrid(ui)
    return require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DOrder").New(ui, self, self.Transform)
end

function XUiPanelSkyTowerCommonIndent:OnUpdateLoopFloor(floorId)
    local performId = self._Control:GetRunningIndentId(floorId)
    if not XTool.IsNumberValid(performId) or self._Control:IsFinish(performId) then
        self:OnRecycleFloor(floorId)
        return
    end

    local room = self._Control:GetRoom(floorId)
    local grid = self._Grids[floorId]
    if grid then
        grid:Show(performId)
        grid:UpdateTransform(room)
        if not self:IsInScreen(grid.Transform) then
            self:OnRecycleFloor(floorId)
        end
    else
        local target = self:GetTarget(room, floorId)
        if target and self:IsTargetInScreen(room, target) then
            grid = self:CreateIndentBtn(floorId, target, performId)
            if grid then
                grid:UpdateTransform(room)
            end
        end
    end
end

function XUiPanelSkyTowerCommonIndent:CreateIndentBtn(floorId, target, performId)
    ---@type XUiGridSkyTower3DOrder
    local grid = self:CreateGridWithPool()
    if not grid then
        return
    end
    grid:SetTarget(target)
    grid:Show(performId)
    self._Grids[floorId] = grid
    return grid
end

function XUiPanelSkyTowerCommonIndent:OnRecycleFloor(floorId)
    local grid = self._Grids[floorId]
    if not grid then
        return
    end
    self._Grids[floorId] = nil
    self:PushPool(grid)
end

function XUiPanelSkyTowerCommonIndent:OnRecycleAll()
    for floorId in pairs(self._Grids) do
        self:OnRecycleFloor(floorId)
    end
end

---@param room XSkyTowerRoom
function XUiPanelSkyTowerCommonIndent:GetTarget(room, floorId)
    local target = self._Targets[floorId]
    if not target then
        target = room:GetIndentIconNode()
        self._Targets[floorId] = target
    end
    return target
end

return XUiPanelSkyTowerCommonIndent
