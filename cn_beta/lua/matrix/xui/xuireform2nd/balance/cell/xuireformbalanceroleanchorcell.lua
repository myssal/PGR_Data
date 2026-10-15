local XUiReformBalanceRoleCell = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceRoleCell")

---@class XUiReformBalanceRoleAnchorCell : XUiReformBalanceRoleCell
local XUiReformBalanceRoleAnchorCell = XClass(XUiReformBalanceRoleCell, "XUiReformBalanceRoleAnchorCell")

function XUiReformBalanceRoleAnchorCell:OnBtnRoleBalanceClick()
    self.Parent:ScrollToRoleListStart()
end

return XUiReformBalanceRoleAnchorCell
