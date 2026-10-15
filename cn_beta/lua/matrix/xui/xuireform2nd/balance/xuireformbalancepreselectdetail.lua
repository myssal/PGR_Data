local XUiReformBalanceExclusiveTag = require("XUi/XUiReform2nd/Balance/Cell/XUiReformBalanceExclusiveTag")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalancePreSelectDetail : XUiNode
---@field private _Control XReformControl
---@field UiTxtDesc UnityEngine.UI.Text
---@field UiTxtDescTips UnityEngine.UI.Text
---@field PanelSpecialBalance UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- 4.9 词缀预选详情气泡
local XUiReformBalancePreSelectDetail = XClass(XUiNode, "XUiReformBalancePreSelectDetail")

function XUiReformBalancePreSelectDetail:OnStart()
    ---@type XUiReformBalanceExclusiveTag[]
    self._Tags = {}
end

---@param massId number
---@param anchorTransform UnityEngine.Transform
function XUiReformBalancePreSelectDetail:ShowAffix(massId, anchorTransform)
    -- 气泡节点默认 inactive，OnStart 要等 Open 才跑，_Tags 得先初始化
    self:Open()

    local balanceControl = self._Control:GetBalanceControl()
    local affixId = balanceControl:GetBalanceMass(massId).TargetId
    local affixConfig = balanceControl:GetBalanceAffix(affixId)

    local desc = affixConfig.Desc
    if balanceControl:IsWeightBondEnhanced(massId) and not string.IsNilOrEmpty(affixConfig.UpgradedDesc) then
        desc = affixConfig.UpgradedDesc
    end
    self.UiTxtDesc.text = desc

    local storyDesc = affixConfig.StoryDesc
    local hasStoryDesc = not string.IsNilOrEmpty(storyDesc)
    self.UiTxtDescTips.gameObject:SetActiveEx(hasStoryDesc)
    if hasStoryDesc then
        self.UiTxtDescTips.text = storyDesc
    end

    XTool.UpdateDynamicItem(self._Tags, balanceControl:GetAffixTags(affixId), self.PanelSpecialBalance, XUiReformBalanceExclusiveTag, self)

    self:AlignToCell(anchorTransform)
end

--- 横向沿用 prefab 位置，纵向与来源格子对齐
---@param anchorTransform UnityEngine.Transform
function XUiReformBalancePreSelectDetail:AlignToCell(anchorTransform)
    local position = self.Transform.position
    position.y = anchorTransform.position.y
    self.Transform.position = position
end

return XUiReformBalancePreSelectDetail
