-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceRoleCell : XUiNode
---@field private _Control XReformControl
---@field BtnRoleBalance XUiComponent.XUiButton
---@field GoPanelNor UnityEngine.RectTransform
---@field RImgHead UnityEngine.UI.RawImage
---@field ImgRoleEnhance UnityEngine.RectTransform
---@field ImgSelect UnityEngine.RectTransform
---@field ImgRoleLock UnityEngine.RectTransform
---@field TagWeight UnityEngine.RectTransform
---@field TxtWeightNum UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field TagPower UiObject
-- ======== AUTO FIELDS END ========
--- 4.9 天平角色砝码格（我方角色 / 敌方怪物共用，靠 side 区分取数据源）
local XUiReformBalanceRoleCell = XClass(XUiNode, "XUiReformBalanceRoleCell")

function XUiReformBalanceRoleCell:OnStart()
    self.BtnRoleBalance:AddEventListener(handler(self, self.OnBtnRoleBalanceClick))
end

--- 由 XTool.UpdateDynamicItem 驱动
---@param massId number
function XUiReformBalanceRoleCell:Update(massId)
    self._MassId = massId
    local balanceControl = self._Control:GetBalanceControl()
    local massConfig = balanceControl:GetBalanceMass(massId)

    self.TxtWeightNum.text = balanceControl:GetWeightMass(massId)
    self:RefreshTarget(massConfig.TargetId)
    self:RefreshSelectState()
end

--- 我方角色显示单条战力，敌方怪物按 Label 克隆多条特性标签
function XUiReformBalanceRoleCell:RefreshTarget(targetId)
    local configControl = self._Control:GetBalanceControl()
    if self.Parent:IsCostSide() then
        local mobConfig = configControl:GetBalanceMob(targetId)
        self.RImgHead:SetRawImage(mobConfig.HeadIcon)
        self.TxtName.text = mobConfig.Name
        self:RefreshTags(mobConfig.Label)
        return
    end

    local characterConfig = configControl:GetBalanceCharacter(targetId)
    local robotId = characterConfig.RobotId
    self.RImgHead:SetRawImage(XRobotManager.GetRobotSmallHeadIcon(robotId))
    self.TxtName.text = XMVCA.XCharacter:GetCharacterLogName(XRobotManager.GetCharacterId(robotId))
    self:RefreshTags({ XRobotManager.GetRobotAbility(robotId) })
end

---@param labels string[]|nil
function XUiReformBalanceRoleCell:RefreshTags(labels)
    labels = labels or table.empty
    self._TagGrids = XUiHelper.RefreshUiObjectList(self._TagGrids, self.TagPower.transform.parent, self.TagPower, #labels,
        function(index, grid)
            grid.TxtPower.text = labels[index]
        end)
end

function XUiReformBalanceRoleCell:RefreshSelectState()
    local balanceControl = self._Control:GetBalanceControl()
    local isSelected = balanceControl:IsWeightSelected(self._MassId)
    self.ImgRoleLock.gameObject:SetActiveEx(balanceControl:IsFixedWeight(self._MassId))
    self.ImgSelect.gameObject:SetActiveEx(isSelected)
end

--- 强化态：参与了已触发的羁绊才亮
---@param isEnhanced boolean
function XUiReformBalanceRoleCell:SetEnhanced(isEnhanced)
    self.ImgRoleEnhance.gameObject:SetActiveEx(isEnhanced)
end

function XUiReformBalanceRoleCell:GetMassId()
    return self._MassId
end

function XUiReformBalanceRoleCell:OnBtnRoleBalanceClick()
    self.Parent:OnRoleCellClick(self)
end

return XUiReformBalanceRoleCell
