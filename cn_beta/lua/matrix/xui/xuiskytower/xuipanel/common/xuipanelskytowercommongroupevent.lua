local XUiPanelSkyTowerCommonBase = require("XUi/XUiSkyTower/XUiPanel/Common/XUiPanelSkyTowerCommonBase")

---@class XUiPanelSkyTowerCommonGroupEvent : XUiPanelSkyTowerCommonBase
---@field Parent XUiSkyTowerCommon
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerCommonGroupEvent = XClass(XUiPanelSkyTowerCommonBase, "XUiPanelSkyTowerCommonGroupEvent")

function XUiPanelSkyTowerCommonGroupEvent:OnStart()
    self.Super.OnStart(self)
    ---@type XUiGridSkyTower3DGroupPerform[]
    self._Grids = {}
    self._Targets = {}
    self:SetNodeTransform(self.GridFloorGroupEvent)
end

function XUiPanelSkyTowerCommonGroupEvent:OnCreateGrid(ui)
    return require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DGroupPerform").New(ui, self, self.Transform)
end

function XUiPanelSkyTowerCommonGroupEvent:OnUpdateLoopFloor(floorId)
    local performId = self._Control:GetRunningFloorGroupPerformId(floorId)
    if not XTool.IsNumberValid(performId) or self._Control:IsFinish(performId) then
        self:OnRecycleFloor(floorId)
        return
    end

    local room = self._Control:GetRoom(floorId)
    local grid = self._Grids[floorId]
    if grid then
        if self:IsInScreen(grid.Transform) then
            grid:Show(performId)
            grid:UpdateTransform(room)
        else
            self:OnRecycleFloor(floorId)
        end
    else
        local target = self:GetTarget(room, floorId)
        if target and self:IsTargetInScreen(room, target) then
            self:CreateEventBtn(floorId, target, performId):UpdateTransform(room)
        end
    end
end

function XUiPanelSkyTowerCommonGroupEvent:CreateEventBtn(floorId, target, performId)
    ---@type XUiGridSkyTower3DBase
    local grid = self:CreateGridWithPool()
    grid:SetTarget(target)
    grid:Show(performId)
    self._Grids[floorId] = grid
    return grid
end

function XUiPanelSkyTowerCommonGroupEvent:OnRecycleFloor(floorId)
    local grid = self._Grids[floorId]
    if not grid then
        return
    end
    self._Grids[floorId] = nil
    self:PushPool(grid)
end

function XUiPanelSkyTowerCommonGroupEvent:OnRecycleAll()
    for floorId in pairs(self._Grids) do
        self:OnRecycleFloor(floorId)
    end
end

---@param room XSkyTowerRoom
function XUiPanelSkyTowerCommonGroupEvent:GetTarget(room, floorId)
    local target = self._Targets[floorId]
    if not target then
        target = room:GetGroupPerformIconNode()
        self._Targets[floorId] = target
    end
    return target
end

return XUiPanelSkyTowerCommonGroupEvent
argets[floorId] = target
    end
    return target
end

return XUiPanelSkyTowerCommonGroupEvent
