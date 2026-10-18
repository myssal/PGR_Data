--- 通关飘窗
---@class XUiPanelDyeMergeFinish: XUiNode
---@field protected _Control
---@field Parent
local XUiPanelDyeMergeFinish = XClass(XUiNode, "XUiPanelDyeMergeFinish")

function XUiPanelDyeMergeFinish:OnStart()
end

function XUiPanelDyeMergeFinish:OnEnable()
    self:_StopDelayCloseTimer()
    
    local delay = math.floor(XScheduleManager.SECOND * XMVCA.XDyeMergeGame:GetClientDyeMergeNumberByKey("GameFinishPanelDelayCloseTime"))
    
    XScheduleManagerPro.ScheduleOnce(self.Close, self, delay)
    
    XLuaUiManager.SetMask(true)
end

function XUiPanelDyeMergeFinish:OnDisable()
    self:_StopDelayCloseTimer()

    XLuaUiManager.SetMask(false)
end

function XUiPanelDyeMergeFinish:_StopDelayCloseTimer()
    XScheduleManagerPro.UnSchedule(self.Close, self)
end

return XUiPanelDyeMergeFinish