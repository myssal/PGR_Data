local XUiReformBalanceAffixPanel = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceAffixPanel")
local XUiReformBalanceAffixPrePanel = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceAffixPrePanel")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceAffixCell : XUiNode
---@field private _Control XReformControl
---@field BtnAffixBalance XUiComponent.XUiButton
---@field PanelSelectionNor UiObject
---@field PanelPreSelection UiObject
-- ======== AUTO FIELDS END ========
--- 4.9 天平词缀砝码格（我方词缀 / 敌方词缀共用）
--- 词缀需二次点击确认：常态(PanelSelectionNor) ↔ 预选态(PanelPreSelection，内含 +添加/-移除 提示)
--- 内容节点在两个子面板里各有一套，故两套都要写，保证切换过去时数据正确
local XUiReformBalanceAffixCell = XClass(XUiNode, "XUiReformBalanceAffixCell")

local PreSelectState = {
    None = 0,   -- 常态，展示 PanelSelectionNor
    Add = 1,    -- 预选-添加，展示 PanelPreSelection 的"+添加"
    Reduce = 2, -- 预选-取消，展示 PanelPreSelection 的"-移除"
}
XUiReformBalanceAffixCell.PreSelectState = PreSelectState

function XUiReformBalanceAffixCell:OnStart()
    self.BtnAffixBalance:AddEventListener(handler(self, self.OnBtnAffixBalanceClick))
    ---@type XUiReformBalanceAffixPanel
    self._NorPanel = XUiReformBalanceAffixPanel.New(self.PanelSelectionNor, self)
    ---@type XUiReformBalanceAffixPrePanel
    self._PrePanel = XUiReformBalanceAffixPrePanel.New(self.PanelPreSelection, self)
end

--- 由 XTool.UpdateDynamicItem 驱动
---@param massId number
function XUiReformBalanceAffixCell:Update(massId)
    if self._MassId ~= massId then
        self:StopGlow()
    end
    self._MassId = massId
    local balanceControl = self._Control:GetBalanceControl()
    local massConfig = balanceControl:GetBalanceMass(massId)
    local affixConfig = balanceControl:GetBalanceAffix(massConfig.TargetId)

    self._AffixId = massConfig.TargetId
    local mass = balanceControl:GetWeightMass(massId)
    self._NorPanel:SetContent(affixConfig, mass)
    self._PrePanel:SetContent(affixConfig, mass)

    self:SetPreSelectState(PreSelectState.None)
    self:RefreshSelectState()
end

function XUiReformBalanceAffixCell:RefreshSelectState()
    local isSelected = self._Control:GetBalanceControl():IsWeightSelected(self._MassId)
    self._NorPanel:SetSelected(isSelected)
    self._PrePanel:SetSelected(isSelected)
end

--- 常态 / 预选态二选一；预选态内再选 +添加 / -移除
---@param state number XUiReformBalanceAffixCell.PreSelectState
function XUiReformBalanceAffixCell:SetPreSelectState(state)
    self._PreSelectState = state
    local isPreSelecting = state ~= PreSelectState.None
    self.PanelSelectionNor.gameObject:SetActiveEx(not isPreSelecting)
    self.PanelPreSelection.gameObject:SetActiveEx(isPreSelecting)
    if isPreSelecting then
        self._PrePanel:SetGroupState(state == PreSelectState.Add)
    end
end

function XUiReformBalanceAffixCell:IsPreSelecting()
    return self._PreSelectState ~= PreSelectState.None
end

--- 强化箭头：羁绊相关的词缀才亮；敌方词缀无此表现
---@param isEnhanced boolean
function XUiReformBalanceAffixCell:SetSpecial(isEnhanced)
    if self.Parent:IsCostSide() then
        return
    end
    self._NorPanel:SetSpecial(isEnhanced)
    self._PrePanel:SetSpecial(isEnhanced)
end

--- 播高亮动效；敌方词缀无此表现
function XUiReformBalanceAffixCell:PlayGlow()
    if self.Parent:IsCostSide() then
        return
    end
    self._NorPanel:PlayGlow()
end

--- 停高亮动效；敌方词缀无此表现
function XUiReformBalanceAffixCell:StopGlow()
    if self.Parent:IsCostSide() then
        return
    end
    self._NorPanel:StopGlow()
end

function XUiReformBalanceAffixCell:GetMassId()
    return self._MassId
end

function XUiReformBalanceAffixCell:GetAffixId()
    return self._AffixId
end

function XUiReformBalanceAffixCell:OnBtnAffixBalanceClick()
    self.Parent:OnAffixCellClick(self)
end

return XUiReformBalanceAffixCell
