---@class XUiSoloReformChapterDetail: XLuaUi
---@field private _Control XSoloReformControl
local XUiSoloReformChapterDetail = XLuaUiManager.Register(XLuaUi, 'UiSoloReformChapterDetail')
local XUiSoloReformChapterDifficultyItem = require("XUi/XUiSoloReform/XUiSoloReformChapterDetail/XUiSoloReformChapterDifficultyItem")
local XUiSoloReformChapterFightEvent = require("XUi/XUiSoloReform/XUiSoloReformChapterDetail/XUiSoloReformChapterFightEvent")
local XUiSoloReformChapterStarInfo = require("XUi/XUiSoloReform/XUiSoloReformChapterDetail/XUiSoloReformChapterStarInfo")

function XUiSoloReformChapterDetail:OnAwake()
    self._ChapterId = nil
    self._CurStageId = nil
    self._ResumetageId = nil
    self._DifficultyCellList = {}
    self:RegisterClickEvent(self.BtnBack, self.Close, true)
    self:RegisterClickEvent(self.BtnMainUi, self.OnReturnMain, true)
    self:RegisterClickEvent(self.BtnTeaching, self.OnTeaching, true)
    self:RegisterClickEvent(self.BtnAgain, self.OnEnterBattle, true)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpString())
end

function XUiSoloReformChapterDetail:OnStart(chapterId)
    self._ChapterId = chapterId
    XMVCA.XSoloReform:SetEnterChapterId(chapterId)
    self:InitPanel()
    self:InitDifficultyList(chapterId)
    --放到start中，编队界面到期也会被踢出去
    self._Control:StartActivityEndCheckTimer()
end

function XUiSoloReformChapterDetail:OnEnable()
    self._Control:AddEventListener(XMVCA.XSoloReform.EventId.EVENT_CLICK_DIFFICULTY_TAG, self.OnClickDifficulty, self)
end

function XUiSoloReformChapterDetail:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XSoloReform.EventId.EVENT_CLICK_DIFFICULTY_TAG, self.OnClickDifficulty, self)
end

function XUiSoloReformChapterDetail:OnReleaseInst()
    local data = {
        CurStageId = self._CurStageId,
        CurSelectFightEventId = self._FightEvent:GetCurFightEventId()
    }
    return data
end

function XUiSoloReformChapterDetail:OnResume(data)
    if XTool.IsTableEmpty(data) then
        return
   end
   self._ResumetageId = data.CurStageId
   self._ResumeFightEvent = data.CurSelectFightEventId
end

function XUiSoloReformChapterDetail:InitPanel()
    self._FightEvent = XUiSoloReformChapterFightEvent.New(self.PanelReform, self)
    self._FightEvent:ResumeCurFightEventId(self._ResumeFightEvent)  
    self._StarInfo = XUiSoloReformChapterStarInfo.New(self.PanelTarget, self)
end

function XUiSoloReformChapterDetail:InitDifficultyList(chapterId)
    local chapterCfg = self._Control:GetSoloReformChapterCfg(chapterId)
    if XTool.IsTableEmpty(chapterCfg.ChapterStageId) then
        return
    end
    XTool.UpdateDynamicItem(self._DifficultyCellList, chapterCfg.ChapterStageId, self.BtnBoss, XUiSoloReformChapterDifficultyItem, self)
    local defaultSelect = self._ResumetageId or chapterCfg.ChapterStageId[1]  
    self:OnClickDifficulty(defaultSelect) --默认选第一个
    self._ResumetageId = nil
end

function XUiSoloReformChapterDetail:GetChapterId()
    return self._ChapterId
end

function XUiSoloReformChapterDetail:OnClickDifficulty(stageId)
    if self._CurStageId == stageId then
        return
    end
    local lastStageId = self._CurStageId    
    self._CurStageId = stageId
    for _, cell in pairs(self._DifficultyCellList) do
        cell:SetSelect(stageId)
    end
    self:RefreshSwitchDiff(stageId)

    if XTool.IsNumberValid(lastStageId) then
        self.RImgBossBg4.gameObject:SetActiveEx(true)
        if not self._LastStarInfo then
            self._LastStarInfo = XUiSoloReformChapterStarInfo.New(self.PanelTargetPrevious, self)
        end      
        self._LastStarInfo:Update(lastStageId)
        local lastStageCfg = self._Control:GetSoloReformStageCfg(lastStageId)
        self.RImgBossPrevious:SetRawImage(lastStageCfg.Img)  
        self:PlayAnimation("Qiehuan")
    end    
end

function XUiSoloReformChapterDetail:RefreshSwitchDiff(stageId)
    local chapterCfg = self._Control:GetSoloReformChapterCfg(self._ChapterId)
    local stageCfg = self._Control:GetSoloReformStageCfg(stageId)
    self.RImgBoss:SetRawImage(stageCfg.Img)
    self:RefreshCharacter()
    self._FightEvent:Update(stageId)
    self._StarInfo:Update(stageId)
    self.Logo01:SetRawImage(chapterCfg.StageLogo)
    self.Logo02:SetRawImage(chapterCfg.StageLogo)
end

function XUiSoloReformChapterDetail:RefreshCharacter()
    local characterId = self._Control:GetChapterCharacterId(self._ChapterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end    
    self.TxtName.text = XMVCA.XCharacter:GetCharacterLogName(characterId)
    local headIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
    self.RImgCharacterHead:SetRawImage(headIcon)
end

function XUiSoloReformChapterDetail:OnReturnMain()
    XLuaUiManager.RunMain()
end

function XUiSoloReformChapterDetail:OnTeaching()
    local characterId = self._Control:GetChapterCharacterId(self._ChapterId)
    --XDataCenter.PracticeManager.OpenUiFubenPractice(characterId)

    local groupId = XPracticeConfigs.GetGroupIdByCharacterId(characterId)       
    if not groupId then 
        return 
    end
    local isLock = not XDataCenter.PracticeManager.CheckPracticeChapterOpen(groupId)
    if isLock then
        local _, description = XDataCenter.PracticeManager.CheckPracticeChapterOpen(groupId)
        XUiManager.TipMsg(description)
    else
        local skipId = XPracticeConfigs.GetPracticeSkipIdByGroupId(groupId)
        if XTool.IsNumberValid(skipId) then
            if XFunctionManager.IsCanSkip(skipId) then
                XFunctionManager.SkipInterface(skipId)
            else
                local skipCfg = XFunctionConfig.GetSkipFuncCfg(skipId)
                if skipCfg and XTool.IsNumberValid(skipCfg.FunctionalId) then
                    local desc = XFunctionManager.GetFunctionOpenCondition(skipCfg.FunctionalId)
                    XUiManager.TipMsg(desc)
                end
            end
        end
    end
end

function XUiSoloReformChapterDetail:CanSkipToTeaching()
    local characterId = self._Control:GetChapterCharacterId(self._ChapterId)
    local groupId = XPracticeConfigs.GetGroupIdByCharacterId(characterId)       
    if not groupId then 
        return false
    end
    local isLock = not XDataCenter.PracticeManager.CheckPracticeChapterOpen(groupId)
    if isLock then
        return false
    end
    local skipId = XPracticeConfigs.GetPracticeSkipIdByGroupId(groupId)
    if XTool.IsNumberValid(skipId) then
        if XFunctionManager.IsCanSkip(skipId) then
            return true
        end    
    end
    return false
end

function XUiSoloReformChapterDetail:OnEnterBattle()
    local team = XMVCA.XSoloReform:GetTeam(self._CurStageId)
    local proxy = require("XUi/XUiSoloReform/XUiSoloReformRoleRoom/XUiSoloReformRoleRoomProxy")
    XLuaUiManager.Open("UiBattleRoleRoom", self._CurStageId, team, proxy)
end

function XUiSoloReformChapterDetail:OnDestroy()
    self._Control:StopActivityEndCheckTimer()
    self._ChapterId = nil
    self._CurStageId = nil
    self._DifficultyCellList = nil
    self._ResumetageId = nil
end

return XUiSoloReformChapterDetail