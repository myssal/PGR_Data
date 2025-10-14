---@class XUiRacePopupResultDetail : XLuaUi 赛事预测结果弹框
---@field _Control XRaceControl
local XUiRacePopupResultDetail = XLuaUiManager.Register(XLuaUi, "UiRacePopupResultDetail")

function XUiRacePopupResultDetail:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
    self.BtnPlayback.CallBack = handler(self, self.OnBtnPlaybackClick)
end

function XUiRacePopupResultDetail:OnStart(guessId)
    self._GuessId = guessId
    self._MatchData = self._Control:GetMatchGuessData()
    self._Info = self._MatchData:GetInfo(guessId)

    local isSuccess = self._MatchData:IsPredictSuccess(guessId)
    self.ImgRight.gameObject:SetActiveEx(isSuccess)
    self.ImgWrong.gameObject:SetActiveEx(not isSuccess)
    self.TxtProject.text = self._Control:GetRaceGuessById(guessId).Name

    self:InitPredict(self.PanelWinner, true)
    self:InitPredict(self.PanelMine, false)

    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end)
end

function XUiRacePopupResultDetail:InitPredict(go, isResultOrPredict)
    local isRole = self._Control:IsGuessNeedCharacter(self._GuessId)
    local mineOption = self._Control:GetGuessProjectOption(nil, self._GuessId)
    local resultOption = self._Control:GetGuessProjectResult(nil, self._GuessId)
    local option = isResultOrPredict and resultOption or mineOption

    if isRole then
        local roleCfg = self._Control:GetRaceCharacterById(option)
        local property = isResultOrPredict and self._Info.ResultPropertyValue or self._Info.GuessPropertyValue
        self.PanelRole.gameObject:SetActiveEx(true)
        self.PanelOption.gameObject:SetActiveEx(false)
        self.ImgHead:SetRawImage(roleCfg.Icon)
        self.TxtRoleName.text = roleCfg.Name
        self.TxtType.text = self._Control:GetPropertyName(self._GuessId)
        self.TxtDetail.text = self._Control:GetPropertyDesc(self._GuessId, property)
    else
        self.PanelRole.gameObject:SetActiveEx(false)
        self.PanelOption.gameObject:SetActiveEx(true)
        self.TxtOption.text = self._Control:GetGuessParamDesc(option)
    end
end

function XUiRacePopupResultDetail:OnBtnPlaybackClick()

end

return XUiRacePopupResultDetail