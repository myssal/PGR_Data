local XUiReformBalanceRoleCell = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceRoleCell")

---@class XUiReformBalanceRoleAnchorCell : XUiReformBalanceRoleCell
local XUiReformBalanceRoleAnchorCell = XClass(XUiReformBalanceRoleCell, "XUiReformBalanceRoleAnchorCell")

function XUiReformBalanceRoleAnchorCell:Update(massId)
    self.Super.Update(self, massId)
    self:SetEnhanced(self._Control:GetBalanceControl():IsWeightBondEnhanced(massId))
end

function XUiReformBalanceRoleAnchorCell:OnBtnRoleBalanceClick()
    self.Parent:ScrollToRoleListStart()
end

return XUiReformBalanceRoleAnchorCell
