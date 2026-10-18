
---@class XUiSkyTowerPopupChat : XLuaUi 对话界面
---@field _Control XSkyTowerControl
---@field ListChat UnityEngine.UI.ScrollRect
local XUiSkyTowerPopupChat = XLuaUiManager.Register(XLuaUi, "UiSkyTowerPopupChat")

local XUiGridSkyTowerMessage = require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerMessage")

local MessageType = XMVCA.XSkyTower.MessageType

local MaxAnswerCount = 2

function XUiSkyTowerPopupChat:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyTowerPopupChat:OnStart(performId)
    self.PerformId = performId
end

function XUiSkyTowerPopupChat:InitUi()
    self.GridChats = {}
    self.GridChat.gameObject:SetActiveEx(false)
    self:RefreshFinish(false)
    self:RefreshAnswer(false)
end

function XUiSkyTowerPopupChat:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateView()
end

function XUiSkyTowerPopupChat:OnDisable()
    self:StopTimer()
end

function XUiSkyTowerPopupChat:InitCb()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end

end

function XUiSkyTowerPopupChat:UpdateView()
    self.Record = {}
    self.Index = 0
    self:RefreshFinish(false)
    self:RefreshAnswer(false)

    if not XTool.IsNumberValid(self.PerformId) then
        return
    end
    --已保存的选择不可修改，拷贝后只在本地补充尚未回答的选项
    for talkId, answerIndex in pairs(self._Control:GetPerformStoryInfo(self.PerformId) or table.empty) do
        self.Record[talkId] = answerIndex
    end
    self.TalkIds = self._Control:GetTalkStoryTalkIds(self.PerformId)
    self.Durations = self._Control:GetTalkStoryDurations(self.PerformId)
    self.TalkCount = #self.TalkIds
    self:OnChatRefresh()
end

function XUiSkyTowerPopupChat:UpdateChatList()
    self.DataList = self:GetMessageList()
    local count = #self.DataList
    for i = self.Index, count do
        local grid = self.GridChats[i]
        if not grid then
            local ui = XUiHelper.Instantiate(self.GridChat, self.Content)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridSkyTowerMessage.New(ui, self)
            self.GridChats[i] = grid
        end
        grid:Refresh(self.DataList[i], i)
    end
    self.ListChat.verticalNormalizedPosition = 0
end

function XUiSkyTowerPopupChat:OnChatRefresh()
    if XTool.UObjIsNil(self.GameObject) then
        self:StopTimer()
        return
    end
    self.Index = self.Index + 1
    if self.Index > self.TalkCount then
        self:StopTimer()
        self:RefreshFinish(true)
        return
    end
    local talkId = self.TalkIds[self.Index]
    local template = self._Control:GetTalkConfig(talkId)

    if template.Type == MessageType.Auto or self.Record[talkId] then
        self:PlayNext()
    elseif template.Type == MessageType.Select then
        self:StopTimer()
        self:RefreshAnswer(true)
    end
end

function XUiSkyTowerPopupChat:StartTimer()
    if XScheduleManagerPro.HasSchedule(self.OnChatRefresh, self) then
        self:StopTimer()
    end
    XScheduleManagerPro.ScheduleOnce(self.OnChatRefresh, self, self:GetDuration())
end

function XUiSkyTowerPopupChat:StopTimer()
    XScheduleManagerPro.UnSchedule(self.OnChatRefresh, self)
end

function XUiSkyTowerPopupChat:GetDuration()
    local duration = self.Durations[self.Index]
    return duration or 0
end

function XUiSkyTowerPopupChat:GetMessageList()
    local ids = {}
    for i = 1, self.Index do
        table.insert(ids, self.TalkIds[i])
    end
    return ids
end

function XUiSkyTowerPopupChat:PlayNext()
    self:UpdateChatList()
    self:StartTimer()
end

function XUiSkyTowerPopupChat:RefreshAnswer(isShow)
    local talkId = self.TalkIds and self.TalkIds[self.Index] or 0
    local answer
    if isShow then
        local template = self._Control:GetTalkConfig(talkId)
        answer = template.Answers
    end
    for i = 1, MaxAnswerCount do
        local btn = self["BtnAnswer" .. i]
        if XTool.UObjIsNil(btn) then
            break
        end
        btn.gameObject:SetActiveEx(isShow and not string.IsNilOrEmpty(answer[i]))
        if isShow then
            btn:SetNameByGroup(0, answer[i])
            btn.CallBack = function() 
                self:OnSelectAnswer(talkId, i)
            end
        end
    end
end

function XUiSkyTowerPopupChat:RefreshFinish(isFinish)
    self.BtnClose.gameObject:SetActiveEx(isFinish)
    self.TxtTips.gameObject:SetActiveEx(isFinish)

    if isFinish then
        self.ListChat.verticalNormalizedPosition = 0
    end
end

function XUiSkyTowerPopupChat:OnSelectAnswer(talkId, index)
    self.Record[talkId] = index
    self:RefreshAnswer(false)

    self:PlayNext()
end

function XUiSkyTowerPopupChat:GetTalkMessage(talkId)
    local template = self._Control:GetTalkConfig(talkId)
    if template.Type == MessageType.Auto then
        return template.Reply
    end
    local index = self.Record[talkId] or 1
    return template.Answers[index]
end

function XUiSkyTowerPopupChat:OnBtnCloseClick()
    local performId = self.PerformId
    self._Control:RequestSavePerformStory(performId, self.Record, function() 
        XLuaUiManager.PopThenOpen("UiSkyTowerPopupStory", performId)
    end)
end