local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")


local XUiRegression4Tips = XLuaUiManager.Register(XLuaUi, "UiRegression4Tips")

function XUiRegression4Tips:OnAwake()
    self.ViewModel = self._Control:GetMainViewModel()
    self:InitCb()
    self:InitUi()
end

function XUiRegression4Tips:OnStart(rewardId, previewRewardId, title, content, subContent, confirmCb)
    self.RewardId = rewardId
    self.PreviewRewardId = previewRewardId
    self.Title = title
    self.Content = content
    self.SubContent = subContent
    self.ConfirmCb = confirmCb

    self:InitView()
end

function XUiRegression4Tips:OnEnable()
    self.Super.OnEnable(self)
end

function XUiRegression4Tips:InitView()
    if self.Title then
        self.TxtTitle.text = self.Title
    end

    if self.Content then
        self.TxtContent.text = self.Content
    end

    if self.SubContent then
        self.TxtSubContent.text = self.SubContent
    end

    self:HideAllReward()
    self:RefreshReward(self.RewardId, self.PanelDrawItemSP)
    self:RefreshReward(self.PreviewRewardId, self.PanelDrawItemNA)

    self.ImgSpecialBg.gameObject:SetActiveEx(XTool.IsNumberValid(self.RewardId))

    local endTime = self.ViewModel:GetProperty("_ActivityEndTime")
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not self._Control:IsOpen() then
            self._Control:OnActivityEnd()
        end
    end)
end

function XUiRegression4Tips:InitUi()
    self.GridReward = {}
end

function XUiRegression4Tips:RefreshReward(rewardId, gridParent)
    if not XTool.IsNumberValid(rewardId) then
        return
    end
    local rewardList = XRewardManager.GetRewardList(rewardId)
    local grids = self.GridReward[gridParent]
    if not grids then
        grids = {}
        self.GridReward[gridParent] = grids
    end
    for i, reward in ipairs(rewardList or table.empty) do
        local grid = grids[i]
        if not grid then
            local ui = XUiHelper.Instantiate(self.GridDrawActivity, gridParent)
            grid = XUiGridCommon.New(self, ui)
            grids[i] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(reward)
    end
end

function XUiRegression4Tips:HideAllReward()
    for _, grids in pairs(self.GridReward) do
        for _, grid in pairs(grids) do
            if grid and not XTool.UObjIsNil(grid.GameObject) then
                grid.GameObject:SetActiveEx(false)
            end
        end
    end
    self.GridDrawActivity.gameObject:SetActiveEx(false)
end

function XUiRegression4Tips:InitCb()
    self.BtnTongBlack:AddEventListener(handler(self, self.OnBtnTongBlackClick))
    self.BtnPreviewClose:AddEventListener(handler(self, self.Close))
    self.BtnPreviewConfirm:AddEventListener(handler(self, self.Close))
end

function XUiRegression4Tips:OnBtnTongBlackClick()
    if self.ConfirmCb then self.ConfirmCb() end
    self:Close()
end