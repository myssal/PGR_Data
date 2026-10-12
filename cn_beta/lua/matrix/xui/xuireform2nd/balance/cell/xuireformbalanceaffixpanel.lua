-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceAffixPanel : XUiNode
---@field RImgAffix UnityEngine.UI.RawImage
---@field ImgSelect UnityEngine.RectTransform
---@field TxtWeightNum UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field TagBond UnityEngine.RectTransform
---@field TagPower UiObject
---@field ImgAffixEnhance UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- 4.9 天平词缀砝码的展示面板
--- 常态（PanelSelectionNor）与预选态（PanelPreSelection）两套节点内容相同，共用本类的内容逻辑
local XUiReformBalanceAffixPanel = XClass(XUiNode, "XUiReformBalanceAffixPanel")

---@param affixConfig XTableReformBalanceAffix
---@param mass number
function XUiReformBalanceAffixPanel:SetContent(affixConfig, mass)
    self.RImgAffix:SetRawImage(affixConfig.Icon)
    self.TxtName.text = affixConfig.AffixName
    self.TxtWeightNum.text = mass

    local labels = affixConfig.Label or table.empty
    self._TagGrids = XUiHelper.RefreshUiObjectList(self._TagGrids, self.TagPower.transform.parent, self.TagPower, #labels,
        function(index, grid)
            grid.TxtPower.text = labels[index]
        end)
end

---@param isSelected boolean
function XUiReformBalanceAffixPanel:SetSelected(isSelected)
    self.ImgSelect.gameObject:SetActiveEx(isSelected)
end

--- 特殊词缀（羁绊触发）标记
---@param isSpecial boolean
function XUiReformBalanceAffixPanel:SetSpecial(isSpecial)
    self.ImgAffixEnhance.gameObject:SetActiveEx(isSpecial)
    self.TagBond.gameObject:SetActiveEx(isSpecial)
end

return XUiReformBalanceAffixPanel
