local XUiPanelSkyTowerCommonBase = require("XUi/XUiSkyTower/XUiPanel/Common/XUiPanelSkyTowerCommonBase")

---@class XUiPanelSkyTowerCommonArea : XUiPanelSkyTowerCommonBase
---@field Parent XUiSkyTowerCommon
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerCommonArea = XClass(XUiPanelSkyTowerCommonBase, "XUiPanelSkyTowerCommonArea")

function XUiPanelSkyTowerCommonArea:OnStart()
    self.Super.OnStart(self)
    ---@type table<number, XUiGridSkyTower3DBase>
    self._Grids = {}
    self._Targets = {}
    self:InitFloorGroupData()
    self:SetNodeTransform(self.AreaTxt)
end

function XUiPanelSkyTowerCommonArea:InitFloorGroupData()
    self._FloorGroupHash = {}
    local values = self._Control:GetClientConfigValues("FloorGroupStartFloorId")
    for groupId, floorId in ipairs(values) do
        self._FloorGroupHash[tonumber(floorId)] = groupId
    end
end

function XUiPanelSkyTowerCommonArea:OnCreateGrid(ui)
    return require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DAreaText").New(ui, self, self.Transform)
end

function XUiPanelSkyTowerCommonArea:OnUpdateLoopFloor(floorId)
    if not self._FloorGroupHash[floorId] then
        self:OnRecycleFloor(floorId)
        return
    end
    local room = self._Control:GetRoom(floorId)
    local grid = self._Grids[floorId]
    if grid then
        if self:IsInScreen(grid.Transform) then
            grid:Open()
            grid:UpdateTransform(room)
        else
            self:OnRecycleFloor(floorId)
        end
    else
        local target = self:GetTarget(room, floorId)
        if target and self:IsTargetInScreen(room, target) then
            self:CreateAreaText(floorId, target):UpdateTransform(room)
        end
    end
end

function XUiPanelSkyTowerCommonArea:CreateAreaText(floorId, target)
    ---@type XUiGridSkyTower3DBase
    local grid = self:CreateGridWithPool()
    grid:SetName(string.format("FloorArea_%s", floorId))
    grid:SetTarget(target)
    grid:Show(self._FloorGroupHash[floorId])
    self._Grids[floorId] = grid
    return grid
end

function XUiPanelSkyTowerCommonArea:OnRecycleFloor(floorId)
    local grid = self._Grids[floorId]
    if not grid then
        return
    end
    self._Grids[floorId] = nil
    self:PushPool(grid)
end

function XUiPanelSkyTowerCommonArea:OnRecycleAll()
    for floorId in pairs(self._Grids) do
        self:OnRecycleFloor(floorId)
    end
end

function XUiPanelSkyTowerCommonArea:GetTarget(room, floorId)
    local target = self._Targets[floorId]
    if not target then
        target = room:GetFloorGroupAreaNode()
        self._Targets[floorId] = target
    end
    return target
end

return XUiPanelSkyTowerCommonArea
