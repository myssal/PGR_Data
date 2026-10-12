local XUiGridSkyTowerWorkRole = require("XUi/XUiSkyTower/XUiGrid/Work/XUiGridSkyTowerWorkRole")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiPanelSkyTowerWorkChooseRole : XUiNode 选择角色
---@field private _Control XSkyTowerControl
---@field Parent XUiSkyTowerWork
local XUiPanelSkyTowerWorkChooseRole = XClass(XUiNode, "XUiPanelSkyTowerWorkChooseRole")

--region 生命周期
function XUiPanelSkyTowerWorkChooseRole:OnStart()
    self.GridRole.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRoleList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridSkyTowerWorkRole, self, handler(self, self.OnGridClick))
    self:RegisterUiEvents()
end

function XUiPanelSkyTowerWorkChooseRole:OnEnable()
    self:RefreshView()
end
--endregion

--region 界面刷新
---@param isKeepSelection boolean 数据更新时保留当前选择，包括主动取消
function XUiPanelSkyTowerWorkChooseRole:RefreshView(isKeepSelection)
    self._FloorId = self.Parent:GetFloorId()
    self._Index = self.Parent:GetIndex()
    self._WorkType = self.Parent:GetWorkType()
    self._ProductId = self.Parent:GetSelectProductId()
    -- 排序与技能展示使用同一份目标工位预览
    self._CharacterIds, self._SkillDescMap = self._Control:GetWorkStaffIdsWithSort(self._FloorId, self._Index, self._WorkType, self._ProductId)
    if not isKeepSelection then
        -- 重新进入选人页时按当前工位初始化，数据更新不能覆盖用户正在选择的角色
        local workInfo = self.Parent:GetWorkInfo()
        self._SelectCharacterId = workInfo and workInfo.CharacterId
    elseif XTool.IsNumberValid(self._SelectCharacterId) and not table.contains(self._CharacterIds, self._SelectCharacterId) then
        self._SelectCharacterId = 0
    end
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self._CharacterIds))
    self.DynamicTable:SetDataSource(self._CharacterIds)
    if isKeepSelection then
        self.DynamicTable:ReloadDataSync()
    else
        local index = table.indexof(self._CharacterIds, self._SelectCharacterId) or 1
        self.DynamicTable:ReloadDataASync(index)
    end
end

---@param grid XUiGridSkyTowerWorkRole
function XUiPanelSkyTowerWorkChooseRole:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local characterId = self._CharacterIds[index]
        grid:Refresh(characterId, self._SkillDescMap[characterId])
        grid:SetSelect(characterId == self._SelectCharacterId)
    end
end

---@param grid XUiGridSkyTowerWorkRole
function XUiPanelSkyTowerWorkChooseRole:OnGridClick(grid)
    -- 再点一次已选中的角色即取消选择
    self._SelectCharacterId = self._SelectCharacterId ~= grid.CharacterId and grid.CharacterId or 0
    for _, item in pairs(self.DynamicTable:GetGrids()) do
        item:SetSelect(item.CharacterId == self._SelectCharacterId)
    end
end
--endregion

--region 按钮
function XUiPanelSkyTowerWorkChooseRole:RegisterUiEvents()
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
end

function XUiPanelSkyTowerWorkChooseRole:OnBtnConfirmClick()
    if not XTool.IsNumberValid(self._SelectCharacterId) then
        XMVCA.XSkyTower:TipMsg(self._Control:GetProduceDesc(4))
        return
    end
    local enter = function()
        self.Parent:ShowMakeSureView(self._SelectCharacterId)
    end
    -- 角色已在别的工位上工作时，安排过来等于把他从原岗位撤下，需要二次确认
    local floorId, index = self._Control:FindOtherWorkPos(self._SelectCharacterId, self.Parent:GetFloorId(), self.Parent:GetIndex())
    if not floorId then
        enter()
        return
    end

    local name = self._Control:GetCharacterName(self._SelectCharacterId)
    local floorText = self._Control:GetClientConfigText("FloorText", 1, floorId)
    local directionText = self._Control:GetClientConfigValue("DirectionText", index)
    local title = self._Control:GetClientConfigValue("SwitchStaffContent", 1)
    local content = self._Control:GetClientConfigText("SwitchStaffContent", 2, name, floorText, directionText)
    self._Control:OpenPopup(title, content, nil, nil, enter)
end
--endregion

return XUiPanelSkyTowerWorkChooseRole
