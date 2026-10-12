-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceExclusiveTag : XUiNode
---@field private _Control XReformControl
---@field TxtBalanceExclusive UnityEngine.UI.Text
---@field TxtBalanceExclusiveRoleName UnityEngine.UI.Text
---@field ImgArrow UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- 4.9 词缀的一条标签
local XUiReformBalanceExclusiveTag = XClass(XUiNode, "XUiReformBalanceExclusiveTag")

---@param tagData table { IsSpecial = boolean, Name = string }
function XUiReformBalanceExclusiveTag:Update(tagData)
    self.TxtBalanceExclusive.gameObject:SetActiveEx(tagData.IsSpecial)
    self.ImgArrow.gameObject:SetActiveEx(tagData.IsSpecial)
    self.TxtBalanceExclusiveRoleName.text = tagData.Name
end

return XUiReformBalanceExclusiveTag
