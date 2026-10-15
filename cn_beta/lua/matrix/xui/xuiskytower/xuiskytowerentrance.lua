local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiSkyTowerEntrance : XLuaUi
---@field private _Control XSkyTowerControl
local XUiSkyTowerEntrance = XLuaUiManager.Register(XLuaUi, "UiSkyTowerEntrance")

--region 生命周期
function XUiSkyTowerEntrance:OnAwake()
    self.PanelItem.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiSkyTowerEntrance:OnStart()
    self._Control:NewPanelActivityAsset({ XMVCA.XSkyTower.ItemId.SkyTowerUpgradeCoin, XMVCA.XSkyTower.ItemId.SkyTowerAccelerate, XMVCA.XSkyTower.ItemId.SkyTowerCoin, }, self.PanelAsset, self)
    self.EndTime = self._Control:GetActivityEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:OnActivityEnd()
            return
        end
        self:RefreshTime()
    end)

    self._Control:UpdateOfflineRecord()
    XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.SkyTower)
end

function XUiSkyTowerEntrance:OnEnable()
    local camera = self._Control:GetCameraModel()
    if camera then
        camera:ShowEntranceCamera()
    end
    self:RefreshView()
end

function XUiSkyTowerEntrance:OnRelease()
    XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.SkyTower)
    self._Control:ExitRoom()
end
--endregion

--region 事件
function XUiSkyTowerEntrance:OnGetLuaEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
        XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE,
        XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE,
        XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE,
        XEventId.EVENT_SKY_TOWER_DATA_CHANGE,
        XEventId.EVENT_SKY_TOWER_SHOP_UI_CLOSE,
    }
end

function XUiSkyTowerEntrance:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
    elseif event == XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE
            or event == XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE
            or event == XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE
            or event == XEventId.EVENT_SKY_TOWER_DATA_CHANGE then
        self:RefreshSkyTowerInfo()
    elseif event == XEventId.EVENT_SKY_TOWER_SHOP_UI_CLOSE then
        self:RefreshComplete()
    end
end
--endregion

--region 界面刷新
function XUiSkyTowerEntrance:RefreshView()
    self:RefreshTime()
    self:RefreshBusinessState()
    self:RefreshRedPoint()
    self:RefreshComplete()
    self:RefreshSkyTowerInfo()
end

function XUiSkyTowerEntrance:RefreshTime()
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end

    local timeLeft = self.EndTime - XTime.GetServerNowTimestamp()
    if timeLeft < 0 then
        timeLeft = 0
    end
    self.TxtTime.text = XUiHelper.GetTime(timeLeft, XUiHelper.TimeFormatType.DAY_HOUR_MINUTE)
    self.BtnRight:ShowReddot(XMVCA.XSkyTower:CheckEnterBtnRedPoint())
end

function XUiSkyTowerEntrance:RefreshBusinessState()
    local isInTime = self._Control:IsActivityInTime()
    self.BtnRight:SetDisable(not isInTime)
    self.ImgOpenMask.gameObject:SetActiveEx(isInTime)
    self.ImgCloseMask.gameObject:SetActiveEx(not isInTime)
    self.BtnTask.gameObject:SetActiveEx(isInTime)
end

function XUiSkyTowerEntrance:RefreshRedPoint()
    if XTool.UObjIsNil(self.BtnMenu) then
        return
    end
    --任务红点
    self.BtnTask:ShowReddot(self._Control:CheckTaskRedPoint())
    self.BtnMenu:ShowReddot(self._Control:CheckMenuRedPoint())
end

function XUiSkyTowerEntrance:RefreshComplete()
    self.BtnTask:ShowTag(self._Control:IsAllTaskFinished())
    self.BtnMenu:ShowTag(self._Control:IsAllLogCollect())
end

function XUiSkyTowerEntrance:RefreshShopReward(isComplete)
    self.PanelItem.gameObject:SetActiveEx(not isComplete)
    if isComplete then
        return
    end
    if not self.Rewards then
        self.Rewards = {}
    end
    local rewardId = self._Control:GetShopRewardId()
    local rewardList = XRewardManager.GetRewardList(rewardId)
    for index, reward in ipairs(rewardList) do
        local grid = self.Rewards[index]
        if not grid then
            local ui = index == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelItem)
            grid = XUiGridCommon.New(self, ui)
            self.Rewards[index] = grid
        end
        grid:Refresh(reward)
    end
end
--endregion

--region 通天塔等级
function XUiSkyTowerEntrance:RefreshSkyTowerInfo()
    local level = self._Control:GetSkyTowerLv()
    self.BtnLv:SetNameByGroup(2, string.format("%s%s", self._Control:GetSkyTowerInfoText(1), level)) --当前等级
    self.BtnLv:SetRawImage(self._Control:GetItemIcon(XMVCA.XSkyTower.ItemId.SkyTowerCoin))

    local isMax = self._Control:IsFloorMaxLevel(level)
    self.BtnLv:ShowTag(isMax)
    self.BtnLv:ActiveTextByGroup(0, not isMax)
    self.BtnLv:ActiveTextByGroup(1, not isMax)
    self.BtnLv:SetRawImageVisible(false)
    if isMax then
        return
    end
    local targetLv = level + 1
    self.BtnLv:SetNameByGroup(0, self._Control:GetSkyTowerInfoText(2)) --升级文本
    --条件未满足时以条件文本替代所需金币数
    local isUpgrade, desc = self._Control:GetFloorUnlockCondition(targetLv)
    if not isUpgrade then
        self.BtnLv:SetNameByGroup(1, desc)
        return
    end
    local needCount = self._Control:GetLvNeedGoldCount(targetLv)
    self.BtnLv:SetRawImageVisible(true)
    self.BtnLv:SetNameByGroup(1, needCount) --升级所需金币
    self.BtnLv:ShowReddot(XMVCA.XSkyTower:CheckLevelUpRedPoint())
end
--endregion

--region 按钮
function XUiSkyTowerEntrance:RegisterUiEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))
    self.BtnRight:AddEventListener(handler(self, self.OnBtnRightClick))
    self.BtnTask:AddEventListener(handler(self, self.OnBtnTaskClick))
    self.BtnMenu:AddEventListener(handler(self, self.OnBtnMenuClick))
    self.BtnLv:AddEventListener(handler(self, self.OnBtnLvClick))
    self:BindHelpBtn(self.BtnHelp, "UiSkyTowerMain")
end

function XUiSkyTowerEntrance:OnBtnBackClick()
    self:Close()
end

function XUiSkyTowerEntrance:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSkyTowerEntrance:OnBtnRightClick()
    self:OnEntrySkyTower()
end

function XUiSkyTowerEntrance:OnBtnTaskClick()
    self._Control:OpenTask()
end

function XUiSkyTowerEntrance:OnBtnMenuClick()
    XLuaUiManager.OpenWithCloseCallback("UiSkyTowerMenu", function()
        self:RefreshRedPoint()
    end)
end

function XUiSkyTowerEntrance:OnBtnLvClick()
    self:OnEntrySkyTower()
end

function XUiSkyTowerEntrance:OnEntrySkyTower()
    if not self._Control:IsActivityInTime() then
        XMVCA.XSkyTower:TipMsg(self._Control:GetSkyTowerNotInBusinessText())
        return
    end
    self._Control:UpdateEntranceTime()
    XLuaUiManager.Open("UiSkyTowerMain")
end
--endregion

return XUiSkyTowerEntrance
