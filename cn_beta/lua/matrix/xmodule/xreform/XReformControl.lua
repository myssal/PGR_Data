---@class XReformControl : XControl
---@field private _Model XReformModel
local XReformControl = XClass(XControl, "XReformControl")

-- 主页章节列表里质量进度已达成值的配色：普通关蓝 / 困难关红
local QUALITY_COLOR_NORMAL = "5d60ff"
local QUALITY_COLOR_HARD = "de3333"

function XReformControl:OnInit()
    --初始化内部变量
    self._Model:InitWithServerData()

    -- 4.9 天平质点子 Control（一次性封存功能，config 在其 config 分部 XReformBalanceConfigControl.lua）
    -- 封存时：删 SubModules/Balance/ 夹 + 去本行 AddSubControl
    self.BalanceControl = self:AddSubControl(require("XModule/XReform/SubModules/Balance/XReformBalanceControl"))
end

function XReformControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    self:GetAgency():AddEventListener(XEventId.EVENT_REFORM_SERVER_DATA, self.UpdateServerData, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_ON_ENVIRONMENT_CLOSE, self.SetUiEnvironmentAutoOpened, self)
end

function XReformControl:RemoveAgencyEvent()
    self:GetAgency():RemoveEventListener(XEventId.EVENT_REFORM_SERVER_DATA, self.UpdateServerData, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_ON_ENVIRONMENT_CLOSE, self.SetUiEnvironmentAutoOpened, self)
end

function XReformControl:OnRelease()
end

---region 获取子Control

---@return XReformBalanceControl
function XReformControl:GetBalanceControl()
    return self.BalanceControl
end

---endregion

function XReformControl:UpdateServerData()
    self._Model:InitWithServerData()
end

---@return XViewModelReform2ndList
function XReformControl:GetViewModel()
    return self._Model:GetViewModel()
end

---@return XViewModelReform2ndList
function XReformControl:GetViewModelList()
    return self._Model:GetViewModelList()
end

-- 4.9 天平界面用；封存时随 Balance 功能删
---@param stage XReform2ndStage
---@return string
function XReformControl:GetStageEnvironmentName(stage)
    local environment = stage:GetSelectedEnvironment(self._Model)
    if not environment then
        return ""
    end
    return environment:GetName(self._Model)
end

-- 4.9 天平进战：走通用编队界面 + 天平专属 Proxy（封存时删）
---@param stageId number
function XReformControl:OpenBattleRoleRoom(stageId)
    local team = XDataCenter.Reform2ndManager.GetTeam(stageId)
    XMVCA.XFuben:OpenUiBattleRoleRoom(stageId, team, require("XUi/XUiReform2nd/Balance/XUiReformBalanceBattleRoleRoom"))
end

function XReformControl:GetActivityTime()
    return self._Model:GetActivityTime()
end

function XReformControl:GetActivityEndTime()
    return self._Model:GetActivityEndTime()
end

function XReformControl:GetHelpKey()
    return self._Model:GetHelpKey()
end

function XReformControl:GetChapterStarDesc(chapter)
    return self._Model:GetChapterStarDesc(chapter)
end

-- 天平玩法：章节质量进度（"已完成/目标"，前端按需选用，不影响 GetChapterStarDesc）
function XReformControl:GetChapterQualityDesc(chapter)
    return self._Model:GetChapterQualityDesc(chapter)
end

-- 天平玩法：单关质量进度（"已完成/目标"）
function XReformControl:GetStageQualityDesc(stageId)
    return self._Model:GetStageQualityDesc(stageId)
end

-- 主页章节列表用：按难度取该关质量进度，已达成值按难度着色
---@param chapter XReform2ndChapter
---@param isHardMode boolean
function XReformControl:GetChapterQualityDescByDifficulty(chapter, isHardMode)
    local stage = chapter:GetStageByDifficulty(self._Model, isHardMode)
    if not stage then
        return ""
    end
    local achievedQuality, targetQuality = self._Model:GetStageBalanceQuality(stage:GetId())
    return string.format("<color=#%s>%s</color>/%s",
        isHardMode and QUALITY_COLOR_HARD or QUALITY_COLOR_NORMAL, achievedQuality, targetQuality)
end

function XReformControl:IsChapterFinished(chapter)
    return self._Model:IsChapterFinished(chapter)
end

---@param chapter XReform2ndChapter
function XReformControl:IsChapterStageFinished(chapter, isHardMode)
    local stage = chapter:GetStageByDifficulty(self._Model, isHardMode)
    if stage then
        if stage:GetIsPassed() then
            return true
        end
    end
    return false
end

function XReformControl:GetChapterName(chapter)
    return self._Model:GetChapterName(chapter)
end

function XReformControl:GetStageName(stageId)
    return self._Model:GetStageName(stageId)
end

---@param chapter XReform2ndChapter
function XReformControl:IsChapterShowToggleHard(chapter)
    local isShowToggleHard = chapter:IsShowToggleHard(self._Model)
    return isShowToggleHard
end

function XReformControl:IsUnlockAllStageHard()
    return self._Model:IsUnlockAllStageHard()
end

---@param chapter XReform2ndChapter
function XReformControl:IsHasStageHard(chapter)
    return chapter:IsHasStageHard(self._Model)
end

---@param stage XReform2ndStage
function XReformControl:IsHardStage(stage)
    return stage:IsHardStage(self._Model)
end

function XReformControl:IsSuperior()
    return self._Model:IsSuperior()
end

function XReformControl:GetKeyChapterJustUnlockToggleHard(chapterId)
    return "XReformJustUnlockToggleHard" .. XPlayer.Id .. chapterId
end

function XReformControl:GetCurrentChapterId()
    local viewModel = self._Model:GetViewModelList()
    local chapter = viewModel:GetCurrentChapter()
    return chapter:GetId()
end

--function XReformControl:IsChapterJustUnlockToggleHard(chapterId)
--    chapterId = chapterId or self:GetCurrentChapterId()
--    local key = self:GetKeyChapterJustUnlockToggleHard(chapterId)
--    local value = XSaveTool.GetData(key)
--    return value == nil
--end

--function XReformControl:IsHasChapterJustUnlockToggleHard()
--    local allChapter = self._Model:GetChapterConfig()
--    for i, config in pairs(allChapter) do
--        if self:IsChapterJustUnlockToggleHard(config.Id) then
--            return true
--        end
--    end
--    return false
--end

--function XReformControl:SetNotJustUnlockToggleHard(chapterId)
--    chapterId = chapterId or self:GetCurrentChapterId()
--    local key = self:GetKeyChapterJustUnlockToggleHard(chapterId)
--    XSaveTool.SaveData(key, true)
--end

--function XReformControl:SetAllChapterCanChallengeNotJustUnlockToggleHard()
--    local viewModel = self._Model:GetViewModel()
--    local totalNumber = viewModel:GetChapterTotalNumber()
--    for i = 1, totalNumber do
--        ---@type XReform2ndChapter
--        local chapter = viewModel:GetChapterByIndex(i)
--        local chapterId = chapter:GetId()
--        if self:IsChapterJustUnlockToggleHard(chapterId) then
--            local isHasStageHard = self:IsHasStageHard(chapter)
--            local isUnlockStageHard = self:IsChapterShowToggleHard(chapter)
--            if isHasStageHard and isUnlockStageHard then
--                self:SetNotJustUnlockToggleHard(chapterId)
--            end
--        end
--    end
--end

---@param stage XReform2ndStage
function XReformControl:CheckUiEnvironmentAutoOpen(stage)
    local key = self._Model:GetReformAutoEnvironmentKey(stage:GetId())
    local value = XSaveTool.GetData(key)
    if value == nil then
        -- 为了指引，延迟到关闭界面之时
        --XSaveTool.SaveData(key, true)
        self:OpenUiEnvironment()
    end
end

function XReformControl:SetUiEnvironmentAutoOpened()
    local stageId = self._Model:GetUiCurrentStageId()
    if stageId then
        local key = self._Model:GetReformAutoEnvironmentKey(stageId)
        local value = XSaveTool.GetData(key)
        if value == nil then
            XSaveTool.SaveData(key, true)
        end
    end
end

--- 打开环境情报页
---@param stage XReform2ndStage|nil
function XReformControl:OpenUiEnvironment(stage)
    local XReformEnvironmentData = require("XEntity/XReform/Environment/XReformEnvironmentData")
    local viewModel = self:GetViewModelList()
    viewModel:UpdateEnvironment(stage)
    local uiData = viewModel:GetUiDataEnvironment()
    local data = XReformEnvironmentData.New(uiData.List)
    XLuaUiManager.Open("UiTransfiniteEnvironmentDetail", data)
end

return XReformControl