---@class XUiTheatre5PVEReasoningEnd: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVEReasoningEnd = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEReasoningEnd')
local XUiTheatre5PVEMainClue = require("XUi/XUiTheatre5/XUiTheatre5PVEClue/XUiTheatre5PVEMainClue")

function XUiTheatre5PVEReasoningEnd:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close, true)
    self._DeduceScriptId = nil
    if self.BtnYes then
        self:RegisterClickEvent(self.BtnYes, self.Close, true)
    end    
end

---@param mainClueId 核心线索id
---@param deduceScriptId 推演脚本id
function XUiTheatre5PVEReasoningEnd:OnStart(deduceScriptId, mainClueId)
    self._DeduceScriptId = deduceScriptId
    ---@type XUiTheatre5PVEMainClue
    self._MainCluePanel = XUiTheatre5PVEMainClue.New(self.UiTheatre5MainClue, self)
    self._MainCluePanel:Update(mainClueId)
    self._MainCluePanel:HideDeduceBtn()
end

function XUiTheatre5PVEReasoningEnd:OnClickClose()
    local deduceCfg = self._Control.PVEControl:GetDeduceScriptCfg(self._DeduceScriptId)
    if not string.IsNilOrEmpty(deduceCfg.StoryId) then
        XDataCenter.MovieManager.PlayMovie(deduceCfg.StoryId, function()
            XLuaUiManager.PopThenOpen('UiTheatre5ChooseCharacter', XMVCA.XTheatre5.EnumConst.GameModel.PVE)
        end)
    else
        XLuaUiManager.PopThenOpen('UiTheatre5ChooseCharacter', XMVCA.XTheatre5.EnumConst.GameModel.PVE)
    end         
   
end

function XUiTheatre5PVEReasoningEnd:OnDestroy()
    self._DeduceScriptId = nil
end

return XUiTheatre5PVEReasoningEnd