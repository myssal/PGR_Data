local XUiPanelSkyTowerCommonBase = require("XUi/XUiSkyTower/XUiPanel/Common/XUiPanelSkyTowerCommonBase")

---@class XUiPanelSkyTowerCommonEvent : XUiPanelSkyTowerCommonBase
---@field Parent XUiSkyTowerCommon
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerCommonEvent = XClass(XUiPanelSkyTowerCommonBase, "XUiPanelSkyTowerCommonEvent")

function XUiPanelSkyTowerCommonEvent:OnStart()
    self.Super.OnStart(self)
    ---@type XUiGridSkyTower3DPerform[]
    self._Grids = {}
    self._Targets = {}
    self:SetNodeTransform(self.GridEvent)
end

function XUiPanelSkyTowerCommonEvent:OnCreateGrid(ui)
    return require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DPerform").New(ui, self, self.Transform)
end

function XUiPanelSkyTowerCommonEvent:OnUpdateLoopFloor(floorId)
    local performId = self._Control:GetRunningPerformId(floorId)
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
            grid = self:CreateEventBtn(floorId, target, performId)
            if grid then
                grid:UpdateTransform(room)
            end
        end
    end
end

function XUiPanelSkyTowerCommonEvent:CreateEventBtn(floorId, target, performId)
    ---@type XUiGridSkyTower3DBase
    local grid = self:CreateGridWithPool()
    if not grid then
        return
    end
    grid:SetTarget(target)
    grid:Show(performId)
    self._Grids[floorId] = grid
    return grid
end

function XUiPanelSkyTowerCommonEvent:OnRecycleFloor(floorId)
    local grid = self._Grids[floorId]
    if not grid then
        return
    end
    self._Grids[floorId] = nil
    self:PushPool(grid)
end

function XUiPanelSkyTowerCommonEvent:OnRecycleAll()
    for floorId in pairs(self._Grids) do
        self:OnRecycleFloor(floorId)
    end
end

---@param room XSkyTowerRoom
function XUiPanelSkyTowerCommonEvent:GetTarget(room, floorId)
    local target = self._Targets[floorId]
    if not target then
        target = room:GetPerformIconNode()
        self._Targets[floorId] = target
    end
    return target
end

return XUiPanelSkyTowerCommonEvent
