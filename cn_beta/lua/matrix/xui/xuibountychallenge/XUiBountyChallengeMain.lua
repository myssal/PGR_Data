local XUiBountyChallengeMainGrid = require("XUi/XUiBountyChallenge/XUiBountyChallengeMainGrid")

---@class XUiBountyChallengeMain : XLuaUi
---@field _Control XBountyChallengeControl
local XUiBountyChallengeMain = XLuaUiManager.Register(XLuaUi, "UiBountyChallengeMain")

function XUiBountyChallengeMain:OnAwake()
    self._GridArray = {
        XUiBountyChallengeMainGrid.New(self.GridChapter1, self),
        XUiBountyChallengeMainGrid.New(self.GridChapter2, self),
        XUiBountyChallengeMainGrid.New(self.GridChapter3, self),
        XUiBountyChallengeMainGrid.New(self.GridChapter4, self),
    }
    self:BindExitBtns()
    self:BindHelpBtn(nil, "BountyChallengeHelp")

    self._IsStartPlayed = false
end

function XUiBountyChallengeMain:OnStart()
    if not self._IsStartPlayed then
        self._IsStartPlayed = true
        self:PlayAnimation("Start")
    end
end

function XUiBountyChallengeMain:OnEnable()
    self:Update()
    self:UpdateTime()
    XScheduleManagerPro.ScheduleForever(XUiBountyChallengeMain._OnActivityTimeScheduleCb, self, XScheduleManagerPro.SECOND)
end

function XUiBountyChallengeMain:OnDisable()
    XScheduleManagerPro.UnSchedule(XUiBountyChallengeMain._OnActivityTimeScheduleCb, self)
end

function XUiBountyChallengeMain:Update()
    local data = self._Control:GetUiMain()
    XTool.UpdateDynamicItem(self._GridArray, data.BossList, self.GridChapter1, XUiBountyChallengeMainGrid, self)
end

function XUiBountyChallengeMain:UpdateTime()
    local remainTime = self._Control:GetRemainTime()
    self.TxtTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiBountyChallengeMain:OnResume()
    self._IsStartPlayed = true
end

function XUiBountyChallengeMain:_OnActivityTimeScheduleCb()
    self:UpdateTime()
end

return XUiBountyChallengeMain