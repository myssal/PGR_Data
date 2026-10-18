local _, COLOR_TXT_RED = CS.UnityEngine.ColorUtility.TryParseHtmlString("#F67C7C")
local _, COLOR_TXT_BLUE = CS.UnityEngine.ColorUtility.TryParseHtmlString("#83CCFF")
local _, COLOR_TXT_GREY = CS.UnityEngine.ColorUtility.TryParseHtmlString("#737373")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceBubbleDetail : XUiNode
---@field private _Control XReformControl
---@field UiTxtDesc1 UnityEngine.UI.Text
---@field UiTxtDesc2 UnityEngine.UI.Text
-- ======== AUTO FIELDS END ========
--- 4.9 挑战难度详情气泡
--- 第一行固定显示配平效果（完美/基本/未配平 → 蓝/灰/红）
--- 第二行仅在代价砝码超出策划预设值时显示，固定红字
local XUiReformBalanceBubbleDetail = XClass(XUiNode, "XUiReformBalanceBubbleDetail")

function XUiReformBalanceBubbleDetail:Refresh()
    local balanceControl = self._Control:GetBalanceControl()
    local BalanceResult = balanceControl:GetBalanceLogic().BalanceResult
    local balanceResult = balanceControl:GetBalanceViewModel().Data.BalanceResult

    if balanceResult == BalanceResult.Perfect then
        self.UiTxtDesc1.text = XUiHelper.GetText("ReformBalanceBubblePerfect")
        self.UiTxtDesc1.color = COLOR_TXT_BLUE
    elseif balanceResult == BalanceResult.Normal then
        self.UiTxtDesc1.text = XUiHelper.GetText("ReformBalanceBubbleNormal")
        self.UiTxtDesc1.color = COLOR_TXT_GREY
    else
        self.UiTxtDesc1.text = XUiHelper.GetText("ReformBalanceBubbleUnbalanced")
        self.UiTxtDesc1.color = COLOR_TXT_RED
    end

    local isCostExceed = balanceControl:IsCostMassExceed()
    self.UiTxtDesc2.gameObject:SetActiveEx(isCostExceed)
    if isCostExceed then
        self.UiTxtDesc2.text = XUiHelper.GetText("ReformBalanceBubbleHigh", balanceControl:GetCostMassLimit())
        self.UiTxtDesc2.color = COLOR_TXT_RED
    end
end

--- 气泡内容标识：配平档位 + 代价是否超额
---@return number
function XUiReformBalanceBubbleDetail:GetContentKey()
    local balanceControl = self._Control:GetBalanceControl()
    local balanceResult = balanceControl:GetBalanceViewModel().Data.BalanceResult
    local costExceedFlag = balanceControl:IsCostMassExceed() and 1 or 0
    return balanceResult * 2 + costExceedFlag
end

return XUiReformBalanceBubbleDetail
