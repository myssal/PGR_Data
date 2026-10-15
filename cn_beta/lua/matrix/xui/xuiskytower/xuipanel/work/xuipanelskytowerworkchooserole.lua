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
function XUiPanelSkyTowerWorkChooseRole:RefreshView()
    self._FloorId = self.Parent:GetFloorId()
    self._Index = self.Parent:GetIndex()
    self._WorkType = self.Parent:GetWorkType()
    self._ProductId = self.Parent:GetSelectProductId()
    -- 排序与技能展示使用同一份目标工位预览
    self._CharacterIds, self._SkillDescMap = self._Control:GetWorkStaffIdsWithSort(self._FloorId, self._Index, self._WorkType, self._ProductId)
    -- 重新进入选人页时按当前工位初始化
    local workInfo = self.Parent:GetWorkInfo()
    self._SelectCharacterId = workInfo and workInfo.CharacterId
    -- 已选员工置顶，其余员工保持原有排序
    local selectIndex = table.indexof(self._CharacterIds, self._SelectCharacterId)
    if selectIndex and selectIndex > 1 then
        table.remove(self._CharacterIds, selectIndex)
        table.insert(self._CharacterIds, 1, self._SelectCharacterId)
    end
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self._CharacterIds))
    self.DynamicTable:SetDataSource(self._CharacterIds)
    self.DynamicTable:ReloadDataASync(1)
end

-- 事件复用进入页面时的角色和技能数据，不改排序及选中态
function XUiPanelSkyTowerWorkChooseRole:RefreshData()
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        local characterId = grid.CharacterId
        grid:Refresh(characterId, self._SkillDescMap[characterId])
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
