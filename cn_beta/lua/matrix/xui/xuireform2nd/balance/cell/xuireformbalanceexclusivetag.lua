-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceExclusiveTag : XUiNode
---@field private _Control XReformControl
---@field TxtBalanceExclusiveRoleName UnityEngine.UI.Text
-- ======== AUTO FIELDS END ========
--- 4.9 词缀的一条标签
local XUiReformBalanceExclusiveTag = XClass(XUiNode, "XUiReformBalanceExclusiveTag")

---@param tagName string
function XUiReformBalanceExclusiveTag:Update(tagName)
    self.TxtBalanceExclusiveRoleName.text = tagName
end

return XUiReformBalanceExclusiveTag
