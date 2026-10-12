---@class XUiPanelTerminalTips
local XUiPanelTerminalTips = XClass(nil, "XUiPanelTerminalTips")

function XUiPanelTerminalTips:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.ImgTips01.gameObject:SetActiveEx(false)
    self.ImgTips02.gameObject:SetActiveEx(false)

    -- 延迟时间
    self.DelayTime = XUiHelper.GetClientConfig("DormQuestTerminalTipDelayTime", XUiHelper.ClientConfigType.Int)
end

function XUiPanelTerminalTips:ShowFileTips()
    XDataCenter.DormQuestManager.SetIsHaveNewQuestFile(false)
    self.GameObject:SetActiveEx(true)
    self.ImgTips02.gameObject:SetActiveEx(true)
    XScheduleManagerPro.ScheduleOnce(XUiPanelTerminalTips._OnHideFileTipsScheduleCb, self, XScheduleManagerPro.SECOND * self.DelayTime)
end

function XUiPanelTerminalTips:ShowUpgradeTips()
    XDataCenter.DormQuestManager.SaveTerminalShowUpgradeTip(true)
    self.GameObject:SetActiveEx(true)
    self.ImgTips01.gameObject:SetActiveEx(true)
    XScheduleManagerPro.ScheduleOnce(XUiPanelTerminalTips._OnHideUpgradeTipsScheduleCb, self, XScheduleManagerPro.SECOND * self.DelayTime)
end

function XUiPanelTerminalTips:ShowAutoQuestSuccess()
    XDataCenter.DormQuestManager.SaveTerminalShowUpgradeTip(true)
    self.GameObject:SetActiveEx(true)
    self.ImgTips03.gameObject:SetActiveEx(true)
    XScheduleManagerPro.ScheduleOnce(XUiPanelTerminalTips._OnHideAutoQuestSuccessScheduleCb, self, XScheduleManagerPro.SECOND * self.DelayTime)
end

function XUiPanelTerminalTips:OnDisable()
    self.GameObject:SetActiveEx(false)
    XScheduleManagerPro.UnSchedule(XUiPanelTerminalTips._OnHideFileTipsScheduleCb, self)
    XScheduleManagerPro.UnSchedule(XUiPanelTerminalTips._OnHideUpgradeTipsScheduleCb, self)
    XScheduleManagerPro.UnSchedule(XUiPanelTerminalTips._OnHideAutoQuestSuccessScheduleCb, self)
end

function XUiPanelTerminalTips:_OnHideFileTipsScheduleCb()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.ImgTips02.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(false)
end

function XUiPanelTerminalTips:_OnHideUpgradeTipsScheduleCb()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.ImgTips01.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(false)
end

function XUiPanelTerminalTips:_OnHideAutoQuestSuccessScheduleCb()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.ImgTips03.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(false)
end

return XUiPanelTerminalTips