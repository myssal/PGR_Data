local XUiReformBalanceAffixCell = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceAffixCell")

---@class XUiReformBalanceAffixAnchorCell : XUiReformBalanceAffixCell
local XUiReformBalanceAffixAnchorCell = XClass(XUiReformBalanceAffixCell, "XUiReformBalanceAffixAnchorCell")

function XUiReformBalanceAffixAnchorCell:OnBtnAffixBalanceClick()
    self.Parent:ScrollToAffixListStart()
end

function XUiReformBalanceAffixAnchorCell:Update(massId)
    self.Super.Update(self, massId)
    self:SetSpecial(self._Control:GetBalanceControl():IsWeightBondEnhanced(massId))
end

return XUiReformBalanceAffixAnchorCell
