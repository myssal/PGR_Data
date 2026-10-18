local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridSkyTowerPerformTask = require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerPerformTask")

---@class XUiSkyTowerPopupStory : XLuaUi
---@field _Control XSkyTowerControl
local XUiSkyTowerPopupStory = XLuaUiManager.Register(XLuaUi, "UiSkyTowerPopupStory")

local XUiGridSkyTowerMessage = require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerMessage")

function XUiSkyTowerPopupStory:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyTowerPopupStory:InitUi()
    self.GridChats = {}
    self.GridChat.gameObject:SetActiveEx(false)
    self.GridFoods.gameObject:SetActiveEx(false)
    self.GridRewards = {}
end

function XUiSkyTowerPopupStory:InitCb()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnWndClose:AddEventListener(handler(self, self.Close))
    self.BtnPost:AddEventListener(handler(self, self.OnBtnPostClick))
end

function XUiSkyTowerPopupStory:OnBtnPostClick()
    self._Control:RequestFinishPerform(self.PerformanceId, function()
        self:Close()
    end)
end

---@param isHidePost boolean 是否隐藏交付按钮
function XUiSkyTowerPopupStory:OnStart(performanceId, isHidePost)
    self.PerformanceId = performanceId
    self.IsHidePost = isHidePost
    self.FloorId = self._Control:GetFloorId(performanceId)
end

function XUiSkyTowerPopupStory:OnEnable()
    self.Super.OnEnable(self)
    self:AddEventListener()
    self:UpdateView()
    --本地生产只做预测，打开未完成事件时让服务端结算，任务进度由NotifyTask同步
    if not self._Control:IsFinish(self.PerformanceId) then
        XMVCA.XSkyTower:SkyTowerActivityDataRequest()
    end
end

function XUiSkyTowerPopupStory:OnDisable()
    self:RemoveEventListener()
end

function XUiSkyTowerPopupStory:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, self.UpdateView, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.UpdateView, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_UPDATE, self.UpdatePanelState, self)
end

function XUiSkyTowerPopupStory:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, self.UpdateView, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.UpdateView, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_UPDATE, self.UpdatePanelState, self)
end

function XUiSkyTowerPopupStory:UpdateView(floorId)
    if not XTool.IsNumberValid(self.PerformanceId) then
        return
    end
    if floorId and floorId ~= self.FloorId then
        return
    end
    --玩家在剧情选项里选过的答案，键为talkId
    self.Record = self._Control:GetPerformStoryInfo(self.PerformanceId)

    self:UpdateTitle()
    self:UpdateChatList()
    self:UpdatePanelState()
    self:UpdateReward()
end

--标题
function XUiSkyTowerPopupStory:UpdateTitle()
    if self.TxtChatTitle and self.TxtChatTitle.gameObject.activeInHierarchy then
        self.TxtChatTitle.text = self._Control:GetPerformTitleWithStory(self.PerformanceId)
    end

    if self.RImgTitle and self.RImgTitle.gameObject.activeInHierarchy then
        self.TxtChatTitle.text = self._Control:GetPerformTypeTitleIcon(self.PerformanceId)
    end
    self.TxtTitle.text = self._Control:GetPerformTypeTitle(self.PerformanceId)
end

--面板显隐
function XUiSkyTowerPopupStory:UpdatePanelState()
    local isFinished = self._Control:IsFinish(self.PerformanceId)
    self.PanelTask.gameObject:SetActiveEx(not isFinished)
    self.PanelMessage.gameObject:SetActiveEx(isFinished)
    self.PanelReward.gameObject:SetActiveEx(not isFinished)
    self.BtnPost.gameObject:SetActiveEx(not isFinished and not self.IsHidePost)
    if isFinished then
        self:UpdateIndent()
    else
        --已完成，但是还未领取
        local isCanClaim = self._Control:CheckPerformClaimReward(self.PerformanceId)
        self.BtnPost:SetDisable(not isCanClaim, isCanClaim)
        self:UpdateDemand()
    end
end

--任务需求
function XUiSkyTowerPopupStory:UpdateDemand()
    local taskIds = self._Control:GetPerformTaskIds(self.PerformanceId)
    if not self.GridTaskUi then
        ---@type XUiGridSkyTowerPerformTask
        self.GridTaskUi = XUiGridSkyTowerPerformTask.New(self.GridTask, self, self.PerformanceId)
    end
    self.GridTaskUi:Refresh(taskIds)
end

--任务奖励
function XUiSkyTowerPopupStory:UpdateReward()
    local cfg = self._Control:GetPerformConfig(self.PerformanceId)
    local rewardId = cfg.RewardId
    if not XTool.IsNumberValid(rewardId) then
        self.Grid256.gameObject:SetActiveEx(false)
        return
    end
    local rewardList = XRewardManager.GetRewardList(rewardId)
    for idx, reward in ipairs(rewardList) do
        local grid = self.GridRewards[idx]
        if not grid then
            local ui = idx == 1 and self.Grid256 or XUiHelper.Instantiate(self.Grid256, self.ListReward)
            grid = XUiGridCommon.New(self, ui)
            self.GridRewards[idx] = grid
        end
        grid:Refresh(reward)
    end
    if cfg.IsShowLevelExpand then
        self.PanelLvTip.gameObject:SetActiveEx(true)
        self.PanelLvTip:SetAsLastSibling()
    end
    if not string.IsNilOrEmpty(cfg.ShowPic) then
        self.PanelNewScene.gameObject:SetActiveEx(true)
        self.PanelNewScene:SetAsLastSibling()
        self.RImgNewScene:SetRawImage(cfg.ShowPic)
    end
end

function XUiSkyTowerPopupStory:UpdateIndent()
    self.TxtMsgTime.text = self._Control:GetTimeStr(self.PerformanceId)
    self.ImgRole:SetRawImage(self._Control:GetPerformSmallIcon(self.PerformanceId))
    self.TxtMessage.text = self._Control:GetPerformDescription(self.PerformanceId)
end

function XUiSkyTowerPopupStory:UpdateChatList()
    self.DataList = self._Control:GetTalkStoryTalkIds(self.PerformanceId)

    for index, taskId in ipairs(self.DataList) do
        local grid = self.GridChats[index]
        if not grid then
            local ui = XUiHelper.Instantiate(self.GridChat, self.Content)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridSkyTowerMessage.New(ui, self)
            self.GridChats[index] = grid
        end
        grid:Refresh(taskId, index)
    end
end

function XUiSkyTowerPopupStory:GetTalkMessage(talkId)
    local template = self._Control:GetTalkConfig(talkId)
    if template.Type == XMVCA.XSkyTower.MessageType.Auto then
        return template.Reply
    end
    local index = self.Record and self.Record[talkId]
    return template.Answers[index or 1]
end
