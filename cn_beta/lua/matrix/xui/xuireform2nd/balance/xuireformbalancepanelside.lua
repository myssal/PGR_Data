local XUiReformBalanceRoleCell = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceRoleCell")
local XUiReformBalanceAffixCell = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceAffixCell")
local XUiReformBalanceRoleAnchorCell = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceRoleAnchorCell")
local XUiReformBalanceAffixAnchorCell = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceAffixAnchorCell")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalancePanelSide : XUiNode
---@field private _Control XReformControl
---@field ScrollViewHopeBalance UnityEngine.UI.ScrollRect
---@field GoContent UnityEngine.RectTransform
---@field GridRoleBalance UnityEngine.RectTransform
---@field GridAffixBalance UnityEngine.RectTransform
---@field GridTopRoleBalance UnityEngine.RectTransform
---@field GridBottomAffixBalance UnityEngine.RectTransform
---@field ArrowUp UnityEngine.RectTransform
---@field ArrowDown UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- 4.9 天平砝码列表（愿望侧 / 代价侧共用，构造传 side 区分）
--- 愿望侧 = 我方角色 + 我方词缀，代价侧 = 敌方怪物 + 敌方词缀
--- 词缀预选态属界面中间态（不上秤不计质量），由本面板持有，不进 Control
---@field Parent XUiReformBalance
local XUiReformBalancePanelSide = XClass(XUiNode, "XUiReformBalancePanelSide")

--- 砝码类型（对齐 ReformBalanceMass.WeightType）
local WeightType = {
    Character = 1,
    Monster = 2,
    MyAffix = 3,
    EnemyAffix = 4,
}

--- 滚动阈值
local SCROLL_CLEAR_MIN_OFFSET = 5
local SCROLL_TO_TWEEN_TIME = 0.3

---@param side number XReformBalanceControl.Side
function XUiReformBalancePanelSide:OnStart(side)
    self._Side = side
    ---@type XUiReformBalanceRoleCell[]
    self._RoleCells = {}
    ---@type XUiReformBalanceAffixCell[]
    self._AffixCells = {}
    ---@type XUiReformBalanceAffixCell 当前处于预选态的词缀格
    self._PreSelectCell = false

    ---@type XUiReformBalanceRoleAnchorCell
    self._RoleAnchor = XUiReformBalanceRoleAnchorCell.New(self.GridTopRoleBalance, self)
    ---@type XUiReformBalanceAffixAnchorCell
    self._AffixAnchor = XUiReformBalanceAffixAnchorCell.New(self.GridBottomAffixBalance, self)
    self._WorldCorners = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Vector3), 4)
    self._RoleAnchor:Close()
    self._AffixAnchor:Close()
    self.ArrowUp.gameObject:SetActiveEx(false)
    self.ArrowDown.gameObject:SetActiveEx(false)

    self._LastScrollPositionY = self.ScrollViewHopeBalance.content.anchoredPosition.y
    self.ScrollViewHopeBalance.onValueChanged:AddListener(handler(self, self.OnScrollChanged))
end

function XUiReformBalancePanelSide:OnScrollChanged()
    local positionY = self.ScrollViewHopeBalance.content.anchoredPosition.y
    local offset = math.abs(positionY - self._LastScrollPositionY)
    self._LastScrollPositionY = positionY

    self:RefreshAnchor()

    if offset < SCROLL_CLEAR_MIN_OFFSET then
        return
    end
    self:ClearPreSelect()
end

function XUiReformBalancePanelSide:OnDestroy()
    if self._AnchorTimer then
        XScheduleManager.UnSchedule(self._AnchorTimer)
        self._AnchorTimer = nil
    end
end

function XUiReformBalancePanelSide:IsCostSide()
    return self._Side == self._Control:GetBalanceControl().Side.Cost
end

--- 建砝码列表（进界面时一次）
--- 角色/敌人列表关卡固定，词缀列表会因羁绊解锁而变化，故拆成两个刷新时机
---@param stageId number
function XUiReformBalancePanelSide:Refresh(stageId)
    local configControl = self._Control:GetBalanceControl()
    local roleMassIds = configControl:GetBalanceMassIds(stageId, self:IsCostSide() and WeightType.Monster or WeightType.Character)
    XTool.UpdateDynamicItem(self._RoleCells, roleMassIds, self.GridRoleBalance, XUiReformBalanceRoleCell, self)
    self:RefreshAffixList()
end

--- 词缀列表（羁绊解锁的新增词缀会插到首位，故每次选择变更后重建）
function XUiReformBalancePanelSide:RefreshAffixList()
    local affixMassIds = self._Control:GetBalanceControl():GetDisplayAffixMassIds(
        self:IsCostSide() and WeightType.EnemyAffix or WeightType.MyAffix)
    XTool.UpdateDynamicItem(self._AffixCells, affixMassIds, self.GridAffixBalance, XUiReformBalanceAffixCell, self)
    self:ScheduleRefreshAnchor()
end

--- 刷新砝码格状态：选中态 + 词缀强化箭头 + 角色完美配平表现
---@param balanceControl XReformBalanceControl
function XUiReformBalancePanelSide:RefreshCellState(balanceControl)
    for index = 1, #self._RoleCells do
        self._RoleCells[index]:RefreshSelectState()
    end
    for index = 1, #self._AffixCells do
        local cell = self._AffixCells[index]
        cell:RefreshSelectState()
        cell:SetSpecial(balanceControl:IsWeightBondEnhanced(cell:GetMassId()))
    end
    self:RefreshAffixGlow(balanceControl)
    self:RefreshRolePerfect(balanceControl)
end

--- 新变为特殊的词缀在对应格子上播一次高亮
---@param balanceControl XReformBalanceControl
function XUiReformBalancePanelSide:RefreshAffixGlow(balanceControl)
    local specialAffixIdSet = balanceControl:GetSpecialAffixIdSet()
    local lastSpecialAffixIdSet = self._LastSpecialAffixIdSet or table.empty
    for index = 1, #self._AffixCells do
        local cell = self._AffixCells[index]
        local affixId = cell:GetAffixId()
        if specialAffixIdSet[affixId] and not lastSpecialAffixIdSet[affixId] then
            cell:PlayGlow()
        end
    end
    self._LastSpecialAffixIdSet = specialAffixIdSet
end

--- 我方角色砝码格：完美配平时全亮强化标并播一次高亮动效，否则全灭
---@param balanceControl XReformBalanceControl
function XUiReformBalancePanelSide:RefreshRolePerfect(balanceControl)
    if self:IsCostSide() then
        return
    end
    local BalanceResult = balanceControl:GetBalanceLogic().BalanceResult
    local isPerfect = balanceControl:GetBalanceViewModel().Data.BalanceResult == BalanceResult.Perfect
    local shouldPlayGlow = isPerfect and self._IsPerfectGlowOn == false
    self._IsPerfectGlowOn = isPerfect

    for index = 1, #self._RoleCells do
        local cell = self._RoleCells[index]
        cell:SetEnhanced(isPerfect)
        if shouldPlayGlow then
            cell:PlayHightGlow()
        end
    end
end

--region 锚定项

function XUiReformBalancePanelSide:ScheduleRefreshAnchor()
    if self._AnchorTimer then
        XScheduleManager.UnSchedule(self._AnchorTimer)
    end
    self._AnchorTimer = XScheduleManager.ScheduleOnce(handler(self, self.OnRefreshAnchorTimer), 0)
end

function XUiReformBalancePanelSide:OnRefreshAnchorTimer()
    self._AnchorTimer = nil
    self:RefreshAnchor()
end

function XUiReformBalancePanelSide:RefreshAnchor()
    local viewport = self.ScrollViewHopeBalance.viewport
    viewport:GetWorldCorners(self._WorldCorners)
    local viewportMinY = self._WorldCorners[0].y
    local viewportMaxY = self._WorldCorners[2].y

    self:SetRoleAnchorVisible(self:_IsAllCellsOutOfView(self._RoleCells, viewportMinY, viewportMaxY))
    self:SetAffixAnchorVisible(self:_IsAllCellsOutOfView(self._AffixCells, viewportMinY, viewportMaxY))
end

--- 该类砝码是否已全部滚出视窗（空列表不算）
---@param cells XUiNode[]
---@param viewportMinY number
---@param viewportMaxY number
---@return boolean
function XUiReformBalancePanelSide:_IsAllCellsOutOfView(cells, viewportMinY, viewportMaxY)
    if #cells == 0 then
        return false
    end
    for index = 1, #cells do
        if self:_IsCellVisible(cells[index], viewportMinY, viewportMaxY) then
            return false
        end
    end
    return true
end

---@param cell XUiNode
---@param viewportMinY number
---@param viewportMaxY number
---@return boolean
function XUiReformBalancePanelSide:_IsCellVisible(cell, viewportMinY, viewportMaxY)
    cell.Transform:GetWorldCorners(self._WorldCorners)
    return self._WorldCorners[2].y > viewportMinY and self._WorldCorners[0].y < viewportMaxY
end

---@param isVisible boolean
function XUiReformBalancePanelSide:SetRoleAnchorVisible(isVisible)
    if isVisible then
        self._RoleAnchor:Update(self._RoleCells[1]:GetMassId())
        self._RoleAnchor:Open()
    else
        self._RoleAnchor:Close()
    end
    self.ArrowUp.gameObject:SetActiveEx(isVisible)
end

---@param isVisible boolean
function XUiReformBalancePanelSide:SetAffixAnchorVisible(isVisible)
    if isVisible then
        self._AffixAnchor:Update(self._AffixCells[1]:GetMassId())
        self._AffixAnchor:Open()
    else
        self._AffixAnchor:Close()
    end
    self.ArrowDown.gameObject:SetActiveEx(isVisible)
end

function XUiReformBalancePanelSide:ScrollToRoleListStart()
    local firstCell = self._RoleCells[1]
    if firstCell then
        XUiHelper.ScrollTo(self.ScrollViewHopeBalance, firstCell.Transform, true, SCROLL_TO_TWEEN_TIME)
    end
end

function XUiReformBalancePanelSide:ScrollToAffixListStart()
    local firstCell = self._AffixCells[1]
    if firstCell then
        XUiHelper.ScrollTo(self.ScrollViewHopeBalance, firstCell.Transform, true, SCROLL_TO_TWEEN_TIME)
    end
end

--endregion

--region 点击处理

--- 角色砝码：直接选中 / 取消，无预选
---@param cell XUiReformBalanceRoleCell
function XUiReformBalancePanelSide:OnRoleCellClick(cell)
    self.Parent:CloseTransientPanels()
    self:ToggleWeight(cell:GetMassId())
end

--- 词缀砝码：首次点击进预选，再点同一个才生效
---@param cell XUiReformBalanceAffixCell
function XUiReformBalancePanelSide:OnAffixCellClick(cell)
    if self._PreSelectCell == cell then
        local massId = cell:GetMassId()
        self.Parent:CloseTransientPanels()
        self:ToggleWeight(massId)
        return
    end

    self.Parent:CloseTransientPanels()
    local isSelected = self._Control:GetBalanceControl():IsWeightSelected(cell:GetMassId())
    cell:SetPreSelectState(isSelected and cell.PreSelectState.Reduce or cell.PreSelectState.Add)
    self._PreSelectCell = cell
    self.Parent:OnAffixPreSelect(cell)
end

--- 选中态取反，失败时弹对应 toast
function XUiReformBalancePanelSide:ToggleWeight(massId)
    local balanceControl = self._Control:GetBalanceControl()
    if balanceControl:IsWeightSelected(massId) then
        local success, reason = balanceControl:UnSelectWeight(massId)
        if not success then
            self:ShowSelectFailTip(reason)
            return
        end
        self.Parent:OnWeightChanged()
        return
    end

    local success, reason = balanceControl:SelectWeight(massId)
    if not success then
        self:ShowSelectFailTip(reason)
        return
    end
    self.Parent:OnWeightChanged()
end

function XUiReformBalancePanelSide:ShowSelectFailTip(reason)
    local balanceControl = self._Control:GetBalanceControl()
    local SelectFailReason = balanceControl.SelectFailReason
    if reason == SelectFailReason.Fixed then
        XUiManager.TipMsg(XUiHelper.GetText("ReformBalanceFixedWeightCannotRemove"))
        return
    end
    if reason == SelectFailReason.CharacterFull then
        XUiManager.TipMsg(XUiHelper.GetText("ReformBalanceRoleWeightLimit", balanceControl:GetCharacterAmountLimit()))
        return
    end
    XUiManager.TipMsg(XUiHelper.GetText("ReformBalanceWeightSlotFull"))
end

--- 清除预选态（点其他按钮或空白处时调）
function XUiReformBalancePanelSide:ClearPreSelect()
    if not self._PreSelectCell then
        return
    end
    self._PreSelectCell:SetPreSelectState(self._PreSelectCell.PreSelectState.None)
    self._PreSelectCell = false
    self.Parent:OnAffixPreSelectClear()
end

--endregion

return XUiReformBalancePanelSide
