local XUiReformBalanceExclusiveTag = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceExclusiveTag")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceInfoDesc : XUiNode
---@field private _Control XReformControl
---@field TxtDescTitle UnityEngine.UI.Text
---@field TxtDesc UnityEngine.UI.Text
---@field PanelSpecialBalance UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- 4.9 天平详情·单个砝码条目
local XUiReformBalanceInfoDesc = XClass(XUiNode, "XUiReformBalanceInfoDesc")

function XUiReformBalanceInfoDesc:OnStart()
    ---@type XUiReformBalanceExclusiveTag[]
    self._Tags = {}
end

--- 由 XTool.UpdateDynamicItem 驱动
---@param massId number
function XUiReformBalanceInfoDesc:Update(massId)
    local balanceControl = self._Control:GetBalanceControl()
    local massConfig = balanceControl:GetBalanceMass(massId)
    local weightType = massConfig.WeightType
    local weightTypeEnum = balanceControl.WeightType

    if weightType == weightTypeEnum.Character or weightType == weightTypeEnum.Monster then
        self.TxtDescTitle.text = balanceControl:GetWeightName(massId)
        self.TxtDesc.gameObject:SetActiveEx(false)
        self:ShowTags(table.empty)
        return
    end

    local affixId = massConfig.TargetId
    local affixConfig = balanceControl:GetBalanceAffix(affixId)
    local isSpecial = balanceControl:IsSpecialAffix(affixId)
    self.TxtDescTitle.text = affixConfig.AffixName
    self.TxtDesc.gameObject:SetActiveEx(true)

    local desc = affixConfig.Desc
    if isSpecial and not string.IsNilOrEmpty(affixConfig.UpgradedDesc) then
        desc = affixConfig.UpgradedDesc
    end
    self.TxtDesc.text = desc

    self:ShowTags(balanceControl:GetAffixTags(affixId))
end

---@param tags string[]
function XUiReformBalanceInfoDesc:ShowTags(tags)
    XTool.UpdateDynamicItem(self._Tags, tags, self.PanelSpecialBalance, XUiReformBalanceExclusiveTag, self)
end

return XUiReformBalanceInfoDesc
