---@class XUiTheatre5PVEReasoning: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVEReasoning = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEReasoning')
local XUiTheatre5PVEMainClue = require("XUi/XUiTheatre5/XUiTheatre5PVEClue/XUiTheatre5PVEMainClue")
local XUiTheatre5PVEMinorClue = require("XUi/XUiTheatre5/XUiTheatre5PVEClue/XUiTheatre5PVEMinorClue")
local XUiTheatre5PVEReasoningAnswerItem = require("XUi/XUiTheatre5/XUiTheatre5PVEReasoning/XUiTheatre5PVEReasoningAnswerItem")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
function XUiTheatre5PVEReasoning:OnAwake()
    self._MainClueId = nil
    self._DeduceScriptId = nil
    self._QuestionCfgs = nil
    self._CurQuestionCfg = nil
    self._MainCluePanel= nil
    self._MinorCluePanel = nil
    self._CurSelectClueId = nil
    self._UpdateScheduleId = nil
    self._CompletedCb = nil
    self._QuestionCellList = nil
    self:RegisterClickEvent(self.BtnBack, self.OnClickClose, true)
    self:BindHelpBtn(self.BtnHelp, 'Theatre5') --先占坑
    self:RegisterClickEvent(self.BtnReasoning, self.OnClickDeduce, true, true, 0.3)
end

---@param mainClueId 核心线索id
---@param deduceScriptId 推演脚本id
function XUiTheatre5PVEReasoning:OnStart(deduceScriptId, completedCb)
    self._DeduceScriptId = deduceScriptId
    self._CompletedCb = completedCb
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfgByScriptId(deduceScriptId)
    if not clueCfg or clueCfg.Type ~= XMVCA.XTheatre5.EnumConst.PVEClueShowType.Core then
        XLog.Error(string.format("核查Theatre5PveDeduceScript的PreClueGroupId是否有配核心线索,deduceScriptId:%s", deduceScriptId))
        return
    end    
    self._MainClueId = clueCfg.Id
   
    local deduceScriptCfg = self._Control.PVEControl:GetDeduceScriptCfg(deduceScriptId)
    self._QuestionCfgs = self._Control.PVEControl:GetPveDeduceQuestionCfgs(deduceScriptCfg.QuestionGroupId)
    self:InitPanels()
end

function XUiTheatre5PVEReasoning:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_SELECT_DEDUCE_ANSWER, self.OnSelectDeduceAnswer, self)
    self:RefreshAll()
end

function XUiTheatre5PVEReasoning:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_SELECT_DEDUCE_ANSWER, self.OnSelectDeduceAnswer, self)
end

function XUiTheatre5PVEReasoning:RefreshAll()
    if XTool.IsTableEmpty(self._QuestionCfgs) then
        return
    end
    local scriptData = self._Control.PVEControl:GetScriptData(self._DeduceScriptId)
    if scriptData and scriptData.IsComplete then
        return
    end
    local questionCfg
    if not scriptData or not XTool.IsNumberValid(scriptData.CurStep) then
        questionCfg = self._QuestionCfgs[1]
    else
        for i = 1, #self._QuestionCfgs do
            if self._QuestionCfgs[i].Step == scriptData.CurStep then
                questionCfg = self._QuestionCfgs[i+1]
                break
            end    
        end
    end
    self._CurSelectClueId = nil
    self._MainCluePanel:Update(self._MainClueId)
    self._MainCluePanel:UpdateDesc(questionCfg.Info)
    self._MainCluePanel:HideDeduceBtn()
    self._MinorCluePanel:Close()
    self:RefreshQuestionShow(questionCfg) 
    self.BtnReasoning:SetDisable(true, false)
    self:UpdateSelected()   
end

function XUiTheatre5PVEReasoning:InitPanels()
    ---@type XUiTheatre5PVEMainClue
    self._MainCluePanel = XUiTheatre5PVEMainClue.New(self.UiTheatre5MainClue, self)
 
    ---@type XUiTheatre5PVEMinorClue
    self._MinorCluePanel = XUiTheatre5PVEMinorClue.New(self.UiTheatre5MinorClue, self)
    self.PanelTips.gameObject:SetActiveEx(false)
end

function XUiTheatre5PVEReasoning:RefreshQuestionShow(questionCfg)
    if not questionCfg then
        return
    end
    self._CurQuestionCfg = questionCfg
    self:RefreshQuestionList(questionCfg)
    self.TxtQuestion.text = questionCfg.Desc    
end

function XUiTheatre5PVEReasoning:RefreshQuestionList(questionCfg)
    self._QuestionCellList = {}
    local clueGroupCfgs = self._Control.PVEControl:GetDeduceClueGroupCfgs(questionCfg.ShowClueGroupId)
    local count = clueGroupCfgs and #clueGroupCfgs or 0
    XUiHelper.RefreshCustomizedList(self.AnswerContent, self.GridAnswer01, count, function(index, go)
        local grid = XUiTheatre5PVEReasoningAnswerItem.New(go, self)
        table.insert(self._QuestionCellList, grid)
        grid:Update(clueGroupCfgs[index] and clueGroupCfgs[index].ClueId)
    end)
end

function XUiTheatre5PVEReasoning:OnSelectDeduceAnswer(clueId)
    self._CurSelectClueId = clueId
    self._MinorCluePanel:Open()
   
    self.BtnReasoning:SetDisable(false, true)
    self._MinorCluePanel:Update(clueId)
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueId)
    if not string.IsNilOrEmpty(clueCfg.ThinkDesc) then
        self:TipsMsg(clueCfg.ThinkDesc)
    end    
    self:UpdateSelected()
end

function XUiTheatre5PVEReasoning:UpdateSelected()
    for _, cell in ipairs(self._QuestionCellList) do
        cell:SetSelect(self._CurSelectClueId)
    end
end

function XUiTheatre5PVEReasoning:OnClickDeduce()
    if not XTool.IsNumberValid(self._CurSelectClueId) then
        return
    end
    if not self._CurQuestionCfg then
        return
    end
    local tipsText = self._CurQuestionCfg.NormalWrongTip
    local isRight = self._CurQuestionCfg.AnswerClue == self._CurSelectClueId
    if isRight then
        tipsText = self._CurQuestionCfg.AnswerTip
    elseif not XTool.IsTableEmpty(self._CurQuestionCfg.SpWrongClues) then
        for i = 1, #self._CurQuestionCfg.SpWrongClues do
            if self._CurSelectClueId == self._CurQuestionCfg.SpWrongClues[i] then
                tipsText = self._CurQuestionCfg.SpWrongTips[i]
            end    
        end
    end    
    XMVCA.XTheatre5.PVEAgency:RequestAnswerQuestion(self._DeduceScriptId, self._CurQuestionCfg.Step, isRight and 1 or 0, function(success, res)
        if success then
            self:TipsMsg(tipsText, isRight)
            if isRight then
                self:PlayRightAnswerAnim(res.IsScriptCompleted, function()
                    if res.IsScriptCompleted then
                        if self._CompletedCb then
                            self._CompletedCb()
                        end    
                        XLuaUiManager.PopThenOpen('UiTheatre5PVEReasoningEnd', self._DeduceScriptId, self._MainClueId)
                    else
                        self:RefreshAll()
                    end
                end)
            else
                self:PlayAnimationWithMask("LoadFail", function()
                    self:RefreshAll()
                end)
              
            end          
        end        
    end)
end

function XUiTheatre5PVEReasoning:TipsMsg(txt, right)
    if self._UpdateScheduleId then
        XScheduleManager.UnSchedule(self._UpdateScheduleId)
        self._UpdateScheduleId = nil
    end
    local time = self._Control.PVEControl:GetDeduceTipsTime(right)
    if time < 0 then
        time = 0
    end    
    self.PanelTips.gameObject:SetActiveEx(true)
    self.TxtQuestionTips.text = txt
    self._UpdateScheduleId = XScheduleManager.ScheduleOnce(function()
        self.PanelTips.gameObject:SetActiveEx(false)
    end, time)
end

function XUiTheatre5PVEReasoning:PlayRightAnswerAnim(isCompleted, cb)
    self:PlayAnimationWithMask("LoadUp", function()
        if not isCompleted then
             self:PlayAnimationWithMask("QieHuan", function()
                if cb then
                    cb()
                end    
             end)
        else
            if cb then
                cb()
            end
        end             
    end)
end

function XUiTheatre5PVEReasoning:OnClickClose()
    self:Close()
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_STORY_LINE_PROCESS_UPDATE)
end

function XUiTheatre5PVEReasoning:OnDestroy()
    if self._UpdateScheduleId then
        XScheduleManager.UnSchedule(self._UpdateScheduleId)
        self._UpdateScheduleId = nil
    end
    self._MainClueId = nil
    self._DeduceScriptId = nil
    self._QuestionCfgs = nil
    self._CurQuestionCfg = nil
    self._MainCluePanel= nil
    self._MinorCluePanel = nil
    self._CurSelectClueId = nil
    self._UpdateScheduleId = nil
    self._CompletedCb = nil
    self._QuestionCellList = nil
end

return XUiTheatre5PVEReasoning