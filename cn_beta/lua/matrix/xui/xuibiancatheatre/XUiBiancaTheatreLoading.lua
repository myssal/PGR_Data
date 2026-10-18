local XUiBiancaTheatreLoading = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreLoading")

function XUiBiancaTheatreLoading:OnAwake()
    self.TheatreManager = XDataCenter.BiancaTheatreManager
    self.CurrentAdventureManager = self.TheatreManager:GetCurrentAdventureManager() or XDataCenter.BiancaTheatreManager.CreateAdventureManager()
    self.BtnClose.gameObject:SetActiveEx(false)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiBiancaTheatreLoading:OnStart()
    XDataCenter.BiancaTheatreManager.CheckBgmPlay()
    self.CurrentChapter = self.CurrentAdventureManager:GetCurrentChapter()
    self.RImgIndexIcon:SetRawImage(self.CurrentChapter:GetOpenIndexIcon())
    self.RImgTitleIcon:SetRawImage(self.CurrentChapter:GetOpenTitleIcon())
    self.BgCommonBai:SetRawImage(self.CurrentChapter:GetOpenBg())

    XScheduleManagerPro.ScheduleOnce(XUiBiancaTheatreLoading._OnShowCloseButtonScheduleCb, self, XScheduleManagerPro.SECOND)
end

function XUiBiancaTheatreLoading:OnBtnCloseClick()
    XDataCenter.BiancaTheatreManager.SetIsAutoOpen(true)
    XLuaUiManager.Remove("UiBiancaTheatreLoading")
    XDataCenter.BiancaTheatreManager.CheckOpenView()
end

function XUiBiancaTheatreLoading:_OnShowCloseButtonScheduleCb()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.BtnClose.gameObject:SetActiveEx(true)
end

return XUiBiancaTheatreLoading
