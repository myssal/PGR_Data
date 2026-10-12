
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiRegression4AutoWindow:XLuaUi
local XUiRegression4AutoWindow = XLuaUiManager.Register(XLuaUi, "UiRegression4AutoWindow")

function XUiRegression4AutoWindow:OnAwake()
    self.BtnBigSkin:AddEventListener(handler(self, self.OnBtnBigSkinClick))
    self.BtnBack:AddEventListener(handler(self, self.Close))
end

function XUiRegression4AutoWindow:OnStart(onCloseCb)
    self.OnCloseCb = type(onCloseCb) == "function" and onCloseCb or nil
    self._Control:PlayStory(handler(self, self.OnStoryFinish))
end

function XUiRegression4AutoWindow:OnStoryFinish()
    self:RefreshRewards()
end

function XUiRegression4AutoWindow:Close()
    self.Super.Close(self)
    if self.OnCloseCb then
        self.OnCloseCb()
    end
end

function XUiRegression4AutoWindow:RefreshRewards()
    local viewModel = self._Control:GetMainViewModel()
    self.RewardGoods = viewModel:GetTriggerRewardList()
    -- 已发放过的奖励直接展示领取态，未发放的先弹获得弹窗再切换
    self.IsReceived = viewModel:IsTriggerRewardSent()

    self.RewardItems = XUiHelper.RefreshUiObjectList(self.RewardItems, self.GridRewardNormal.transform.parent, self.GridRewardNormal, #self.RewardGoods, handler(self, self.OnRewardItemRefresh))

    if not self.IsReceived and not XTool.IsTableEmpty(self.RewardGoods) then
        XUiManager.OpenUiObtain(self.RewardGoods, nil, handler(self, self.OnObtainClose))
    end
end

function XUiRegression4AutoWindow:OnObtainClose()
    self.IsReceived = true
    self:RefreshReceivedState()
end

function XUiRegression4AutoWindow:RefreshReceivedState()
    for _, item in ipairs(self.RewardItems or table.empty) do
        if item.GridCommon then
            item.GridCommon:SetReceived(self.IsReceived)
        end
    end
end

function XUiRegression4AutoWindow:OnRewardItemRefresh(index, item)
    if not item.GridCommon then
        item.GridCommon = XUiGridCommon.New(self, item.GameObject)
    end
    item.GridCommon:Refresh(self.RewardGoods[index])
    item.GridCommon:SetReceived(self.IsReceived)
end

function XUiRegression4AutoWindow:OnBtnBigSkinClick()
    self._Control:EnterUiMain()
    self:Close()
end

return XUiRegression4AutoWindow
