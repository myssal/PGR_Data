local XMovieActionLeftTitleAppear = XClass(XMovieActionBase, "XMovieActionLeftTitleAppear")

function XMovieActionLeftTitleAppear:Ctor(actionData)
    local params = actionData.Params

    self.Title = params[1] or ""
    self.Subtitle = params[2] or ""
    self.TitleEn = params[3] or ""
    self.Subtitle2 = params[4] or ""
    self.Subtitle3 = params[5] or ""
end

function XMovieActionLeftTitleAppear:OnRunning()
    self.UiRoot.PanelLeftTitle.gameObject:SetActiveEx(true)
    local titleLocation
    if XOverseaManager.IsOverSeaRegion() then
        titleLocation = string.gsub(self.Title, "\\n", "\n")
    else
        titleLocation = self.Title
    end
    local uiObj = self.UiRoot.PanelLocationTip
    uiObj:GetObject("TxtLocation").text = titleLocation
    uiObj:GetObject("TxtSubtitle").text = self.Subtitle
    uiObj:GetObject("TxtLocationEn").text = self.TitleEn
    uiObj:GetObject("AnimEnable").gameObject:PlayTimelineAnimation()
    uiObj:GetObject("TxtSubtitle2").text = self.Subtitle2
    uiObj:GetObject("TxtSubtitle3").text = self.Subtitle3
end

return XMovieActionLeftTitleAppear