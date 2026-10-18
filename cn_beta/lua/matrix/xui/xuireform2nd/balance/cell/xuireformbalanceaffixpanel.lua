-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceAffixPanel : XUiNode
---@field RImgAffix UnityEngine.UI.RawImage
---@field ImgSelect UnityEngine.RectTransform
---@field TxtWeightNum UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field TagPower UiObject
---@field ImgAffixEnhance UnityEngine.RectTransform
---@field BalanceHightGlow UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- 4.9 天平词缀砝码的展示面板
--- 常态（PanelSelectionNor）与预选态（PanelPreSelection）两套节点内容相同，共用本类的内容逻辑
--- 但 BalanceHightGlow 只有常态面板挂了，两个 Glow 方法只能在常态面板实例上调
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

--- 羁绊强化箭头
---@param isEnhanced boolean
function XUiReformBalanceAffixPanel:SetSpecial(isEnhanced)
    self.ImgAffixEnhance.gameObject:SetActiveEx(isEnhanced)
end

--- 播高亮动效
function XUiReformBalanceAffixPanel:PlayGlow()
    self.BalanceHightGlow:PlayTimelineAnimation()
end

--- 停高亮动效（格子换绑到别的词缀时调，避免动效残留在别的格子上）
function XUiReformBalanceAffixPanel:StopGlow()
    self.BalanceHightGlow:StopTimelineAnimation(false, true)
end

return XUiReformBalanceAffixPanel
