---@class XUiPacMan2PopupStageStop : XLuaUi
---@field _Control XPacMan2Control
local XUiPacMan2PopupStageStop = XLuaUiManager.Register(XLuaUi, "UiPacMan2PopupStageStop")

function XUiPacMan2PopupStageStop:OnStart(stageId, resume, submitAbort, reportLeave)
    self._Resume = resume
    if not resume then
        XLog.Error("[XUiPacMan2PopupStageStop] 需要恢复游戏的callback")
    end
    self._StageId = stageId
    self._SubmitAbort = submitAbort
    -- reportLeave(isRestart)：false为放弃，true为重开。
    self._ReportLeave = reportLeave
end

function XUiPacMan2PopupStageStop:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.Resume)
    XUiHelper.RegisterClickEvent(self, self.BtnAbort, self.LeaveGame)
    XUiHelper.RegisterClickEvent(self, self.BtnAgain, self.Again)
end

function XUiPacMan2PopupStageStop:Resume()
    self:Close()
    if self._Resume then
        self._Resume()
    end
end

function XUiPacMan2PopupStageStop:LeaveGame()
    if self._SubmitAbort then
        self._SubmitAbort()
    end

    if self._ReportLeave then
        self._ReportLeave(false)
    end
    
    self:Close()
    XLuaUiManager.Close("UiPacMan2Game")
end

function XUiPacMan2PopupStageStop:Again()
    if self._StageId then
        if self._SubmitAbort then
            self._SubmitAbort()
        end

        if self._ReportLeave then
            self._ReportLeave(true)
        end
        
        self:Close()
        XLuaUiManager.Remove("UiPacMan2Game")
        XScheduleManagerPro.ScheduleNextFrame(self._OnAgainScheduleCb, self)
    end
end

function XUiPacMan2PopupStageStop:_OnAgainScheduleCb()
    -- 开局播放规则上属于局内重开，不重复播放开局事件。
    -- 新的Game实例会重新建立本次运行的1000050统计。
    XLuaUiManager.Open("UiPacMan2Game", self._StageId, true)
end

return XUiPacMan2PopupStageStop