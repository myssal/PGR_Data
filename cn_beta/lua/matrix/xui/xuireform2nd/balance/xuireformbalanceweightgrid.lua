-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceWeightGrid : XUiNode
---@field private _Control XReformControl
---@field PanelNone UnityEngine.RectTransform
---@field PanelRole UnityEngine.RectTransform
---@field PanelForceSelect UnityEngine.RectTransform
---@field RImgHead UnityEngine.UI.RawImage
-- ======== AUTO FIELDS END ========
--- 4.9 天平秤盘砝码格（空槽 / 已放砝码两态）
local XUiReformBalanceWeightGrid = XClass(XUiNode, "XUiReformBalanceWeightGrid")

--- 由 XTool.UpdateDynamicItem 驱动
---@param slotState table { Index, WeightId, IsFixed }
function XUiReformBalanceWeightGrid:Update(slotState)
    local massId = slotState.WeightId
    local hasWeight = XTool.IsNumberValid(massId)
    self.PanelNone.gameObject:SetActiveEx(not hasWeight)
    self.PanelRole.gameObject:SetActiveEx(hasWeight)
    -- 固定怪亮专属选中框
    self.PanelForceSelect.gameObject:SetActiveEx(hasWeight and slotState.IsFixed == true)
    if not hasWeight then
        return
    end
    self.RImgHead:SetRawImage(self._Control:GetBalanceControl():GetWeightIcon(massId))
end

return XUiReformBalanceWeightGrid
