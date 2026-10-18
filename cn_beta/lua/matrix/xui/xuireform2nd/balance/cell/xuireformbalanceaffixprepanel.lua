local XUiReformBalanceAffixPanel = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceAffixPanel")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceAffixPrePanel : XUiReformBalanceAffixPanel
---@field GroupAdd UnityEngine.RectTransform
---@field GroupReduce UnityEngine.RectTransform
---@field GroupInfo UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
local XUiReformBalanceAffixPrePanel = XClass(XUiReformBalanceAffixPanel, "XUiReformBalanceAffixPrePanel")

---@param isAdd boolean true=+添加 / false=-移除
function XUiReformBalanceAffixPrePanel:SetGroupState(isAdd)
    self.GroupAdd.gameObject:SetActiveEx(isAdd)
    self.GroupReduce.gameObject:SetActiveEx(not isAdd)
end

return XUiReformBalanceAffixPrePanel
