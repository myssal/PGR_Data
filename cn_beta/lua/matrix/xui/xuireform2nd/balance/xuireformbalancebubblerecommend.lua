-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalanceBubbleRecommend : XUiNode
---@field private _Control XReformControl
---@field UiTxtDesc UnityEngine.UI.Text
-- ======== AUTO FIELDS END ========
--- 4.9【莱亚的直觉】对话气泡，N 秒后自动消失
local XUiReformBalanceBubbleRecommend = XClass(XUiNode, "XUiReformBalanceBubbleRecommend")

local AUTO_CLOSE_DELAY = 3000

function XUiReformBalanceBubbleRecommend:OnDisable()
    self:StopAutoCloseTimer()
end

function XUiReformBalanceBubbleRecommend:OnDestroy()
    self:StopAutoCloseTimer()
end

---@param desc string
function XUiReformBalanceBubbleRecommend:ShowTips(desc)
    self.UiTxtDesc.text = desc
    self:Close()
    self:Open()
    self:StopAutoCloseTimer()
    self._AutoCloseTimer = XScheduleManager.ScheduleOnce(handler(self, self.Close), AUTO_CLOSE_DELAY)
end

function XUiReformBalanceBubbleRecommend:StopAutoCloseTimer()
    if not self._AutoCloseTimer then
        return
    end
    XScheduleManager.UnSchedule(self._AutoCloseTimer)
    self._AutoCloseTimer = nil
end

return XUiReformBalanceBubbleRecommend
