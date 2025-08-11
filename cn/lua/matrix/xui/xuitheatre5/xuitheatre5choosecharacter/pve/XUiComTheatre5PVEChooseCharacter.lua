local XUiComTheatre5ChooseCharacter = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiComTheatre5ChooseCharacter')

---@class XUiComTheatre5PVEChooseCharacter: XUiComTheatre5ChooseCharacter
local XUiComTheatre5PVEChooseCharacter = XClass(XUiComTheatre5ChooseCharacter, 'XUiComTheatre5PVEChooseCharacter')

---@overload
function XUiComTheatre5PVEChooseCharacter:OnStart()
    XUiComTheatre5PVEChooseCharacter.Super.OnStart(self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_CLICK_CHARACTER_HEAD, self.OnClickCharacterHead, self)
    if self.Parent.UiModelGo then
        local uiModel = XTool.InitUiObjectByUi({}, self.Parent.UiModelGo)
        uiModel.FxWuya.gameObject:SetActiveEx(false)
        uiModel.FxHeiban.gameObject:SetActiveEx(true)
    end    
end

---@overload
function XUiComTheatre5PVEChooseCharacter:_InitButtons()
    self.BtnRank.gameObject:SetActiveEx(false)
    self.BtnStart.CallBack = handler(self, self.OnBtnStartClickEvent)
    self.BtnTalk.CallBack = handler(self, self.OnBtnStartClickEvent)
    self.BtnAVG.CallBack = handler(self, self.OnBtnStartClickEvent)
    self.BtnDeduction.CallBack = handler(self, self.OnBtnStartClickEvent)
end

---@overload
function XUiComTheatre5PVEChooseCharacter:OnSelectCharacter(index, BtnName)
    self._EntranceName = BtnName
    local entranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(BtnName)
    if not entranceCfg then
        return false
    end
    --点击的是角色
    if XTool.IsNumberValid(index) then
        local isUnlock = self._Control.PVEControl:IsCharacterAndStoryLineUnlock(index,self._EntranceName)
        if not isUnlock then
           XUiManager.TipMsg(self._Control:GetCharacterLock()) 
           return false 
        end    
    end    
    local teachingStoryLineId = self._Control.PVEControl:GetTeachingStoryLineId()
    local storyLineCfg = self._Control.PVEControl:GetStoryLineCfg(entranceCfg.StoryLine)
    local isTeaching = entranceCfg.StoryLine == teachingStoryLineId 
        and storyLineCfg.StoryLineType == XMVCA.XTheatre5.EnumConst.PVEStoryLineType.Guide
    if isTeaching then
        local curContentId = self._Control.PVEControl:GetStoryLineContentId(entranceCfg.StoryLine)
        local characterId = self._Control.PVEControl:GetFirstCharacterId(entranceCfg.StoryLine)
        if not curContentId then                         --教学故事线未初始化
            XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(entranceCfg.StoryLine, nil, function()
                self._Control.FlowControl:EnterStroryLineContent(entranceCfg.StoryLine, nil, characterId)
            end)
        elseif XTool.IsNumberValid(curContentId) then    --教学故事线处于某节点
            self._Control.FlowControl:EnterStroryLineContent(entranceCfg.StoryLine, nil, characterId)
        end
        --否则教学故事线完成结束直接返回
        return false   
    end

    if storyLineCfg.StoryLineType == XMVCA.XTheatre5.EnumConst.PVEStoryLineType.Together 
        and not self._Control.PVEControl:IsUnlockStoryLine(entranceCfg.StoryLine) then  --点的是一个普通物体或共通线未解锁
        return false
    end    
    if not XTool.IsNumberValid(index) then  --共通线
        index = self._Control.PVEControl:GetFirstUnlockCharacterId(self._EntranceName)
    end
    --通知角色列表更新
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CLICK_SCENE_OBJECT)
    self._CharacterId = index   
    XUiComTheatre5PVEChooseCharacter.Super.OnSelectCharacter(self,index)
    local isUnlock = self._Control.PVEControl:IsCharacterAndStoryLineUnlock(self._CharacterId,self._EntranceName)
    self.BtnStart:SetDisable(not isUnlock, isUnlock)
    local curStoryLineType = self._Control.PVEControl:GetStoryLineCurNodeType(entranceCfg.StoryLine, self._EntranceName)
    local isTalk = isUnlock and curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Chat
    local isAVG = isUnlock and curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.AVG
    local isDeduce = isUnlock and curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Deduce
    self.BtnStart.gameObject:SetActiveEx(not isTalk and not isAVG and not isDeduce)
    self.BtnTalk.gameObject:SetActiveEx(isTalk)
    self.BtnAVG.gameObject:SetActiveEx(isAVG)
    self.BtnDeduction.gameObject:SetActiveEx(isDeduce)
    self:CheckRepeatCharpter()
    return true
end

function XUiComTheatre5PVEChooseCharacter:GetEntranceName()
    return self._EntranceName
end

function XUiComTheatre5PVEChooseCharacter:OnBtnStartClickEvent()
    local isUnlock = self._Control.PVEControl:IsCharacterAndStoryLineUnlock(self._CharacterId,self._EntranceName)
    if not isUnlock then
        return
    end
   
    local storyEntranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(self._EntranceName)
    local curStoryLineType = self._Control.PVEControl:GetStoryLineCurNodeType(storyEntranceCfg.StoryLine, self._EntranceName)
    if curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Deduce then
        if self:CheckIsShowDetail() then
            self:SwitchToFullView()
        end
        XLuaUiManager.Open('UiTheatre5PVEClueBoard')
        return
    elseif curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.NormalAttack or 
        curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.DeduceBattle then
        local contentId = self._Control.PVEControl:GetStoryLineContentId(storyEntranceCfg.StoryLine)
        if XTool.IsNumberValid(contentId) then --无效可能是复刷章节
            local contentCfg = self._Control.PVEControl:GetStoryLineContentCfg(contentId)
            local isEnterAvgPlay = self._Control.PVEControl:IsEnterAvgPlay(contentCfg.ContentId)
            local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(contentCfg.ContentId)
            local isSkip = XTool.IsNumberValid(chapterCfg.CloseStoryTips) --跳过弹窗
            if not isSkip and not isEnterAvgPlay and not string.IsNilOrEmpty(chapterCfg.StartStory) then
                local content = self._Control.PVEControl:GetEnterChapterStoryTips()
                XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, 
                function()
                    if self:CheckIsShowDetail() then
                        self:SwitchToFullView()
                    end 
                    self._Control.FlowControl:EnterStroryLineContent(storyEntranceCfg.StoryLine, storyEntranceCfg.Id, self._CharacterId)
                end)
                return
            end
        end               
    end    
    if self:CheckIsShowDetail() then
        self:SwitchToFullView()
    end
    self._Control.FlowControl:EnterStroryLineContent(storyEntranceCfg.StoryLine, storyEntranceCfg.Id, self._CharacterId)    
end

function XUiComTheatre5PVEChooseCharacter:OnClickCharacterHead(entranceName, characterId)
    self.BtnStart:SetDisable(false)
    self._EntranceName = entranceName
    self._CharacterId = characterId
    self:CheckRepeatCharpter()
end

function XUiComTheatre5PVEChooseCharacter:CheckRepeatCharpter()
    local storyEntranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(self._EntranceName)  
    local isStoryLineCompleted = self._Control.PVEControl:IsStoryLineCompleted(storyEntranceCfg.StoryLine)
    if not isStoryLineCompleted then
        return
    end    
    local hasRepeatChapter = self._Control.PVEControl:HasUnlockRepeatChapter(self._EntranceName)
    self.BtnStart.gameObject:SetActiveEx(hasRepeatChapter)
end

function XUiComTheatre5PVEChooseCharacter:OnDestroy()
    XUiComTheatre5PVEChooseCharacter.Super.OnDestroy(self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_CLICK_CHARACTER_HEAD, self.OnClickCharacterHead, self)
end

return XUiComTheatre5PVEChooseCharacter