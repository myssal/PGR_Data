local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiReform2ndChapterGrid = require("XUi/XUiReform2nd/MainPage/XUiReform2ndChapterGrid")

---@class XUiReform2ndChapterData
---@field Name string
---@field QualityDesc string
---@field GuanText string
---@field IsUnlocked boolean
---@field IsFinished boolean
---@field IsShowRed boolean

---@class XUiReform2New : XLuaUi
---@field _Control XReformControl
local XUiReform2New = XLuaUiManager.Register(XLuaUi, "UiReform2")

function XUiReform2New:OnAwake()
    ---@type XViewModelReform2nd
    self._ViewModel = self._Control:GetViewModel()
    self._IsHard = false
    ---@type XUiReform2ndChapterGrid[]
    self._NorGrids = {}
    ---@type XUiReform2ndChapterGrid[]
    self._HardGrids = {}
    ---@type XUiReform2ndChapterData[]
    self._NorDatas = {}
    ---@type XUiReform2ndChapterData[]
    self._HardDatas = {}
    self._Timer = nil
    self._TaskRedPoint = nil

    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpKey())

    self.BtnGiftNor:AddEventListener(handler(self, self.OnBtnGiftClick))
    self.BtnGiftHard:AddEventListener(handler(self, self.OnBtnGiftClick))
    self.BtnChangeNorToHard:AddEventListener(handler(self, self.OnBtnChangeToHardClick))
    self.BtnChangeHardToNor:AddEventListener(handler(self, self.OnBtnChangeToNorClick))

    self:PreloadChapters()
    self._ViewModel:InitChapterList()
    self:InitTaskRewardDisplay()
    self._TaskRedPoint = XRedPointManager.AddRedPointEvent(self.BtnGiftNor, self.OnCheckTaskRedPoint, self,
            { XRedPointConditions.Types.CONDITION_REFORM_TASK_GET_REWARD }, nil, true)
    self:RefreshEndTime()
end

function XUiReform2New:OnEnable()
    XUiReform2New.Super.OnEnable(self)
    XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.Reform)

    self._IsHard = self._Control:GetViewModelList():IsSelectToggleHard()
    self:Refresh()

    self._Timer = XScheduleManager.ScheduleForever(handler(self, self.OnTick), XScheduleManager.SECOND, 0)
    if self._TaskRedPoint then
        XRedPointManager.Check(self._TaskRedPoint)
    end
    XEventManager.AddEventListener(XEventId.EVENT_ETCD_TIME_CHANGE, self.RefreshEndTime, self)
end

function XUiReform2New:OnDisable()
    XUiReform2New.Super.OnDisable(self)
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_ETCD_TIME_CHANGE, self.RefreshEndTime, self)
end

function XUiReform2New:Close()
    XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.Reform)
    XUiReform2New.Super.Close(self)
end

function XUiReform2New:OnDestroy()
    XRedPointManager.RemoveRedPointEvent(self._TaskRedPoint)
    self._ViewModel:ReleaseConfig()
    self._ViewModel = nil
    self._NorGrids = nil
    self._HardGrids = nil
    self._NorDatas = nil
    self._HardDatas = nil
    self._TaskRedPoint = nil
end

--region 刷新
-- InitChapterList 的循环上界取的是懒加载计数器，必须先把所有章节实体建出来
function XUiReform2New:PreloadChapters()
    for i = 1, self._ViewModel:GetChapterTotalNumber() do
        self._ViewModel:GetChapterByIndex(i)
    end
end

function XUiReform2New:Refresh()
    -- 先定难度样式：切困难要先激活 PanelGroupHard，否则格子建在未激活父节点下会报错
    self:RefreshDifficultyStyle()
    self:RefreshChapterGrids()
    self:RefreshTaskProgress()
    self:RefreshRemainTime()
end

-- 关卡目标质量按当前难度取，切换难度要整体重算
function XUiReform2New:RefreshChapterGrids()
    local isHard = self._IsHard
    local datas = isHard and self._HardDatas or self._NorDatas
    local grids = isHard and self._HardGrids or self._NorGrids
    local parent = isHard and self.PanelGroupHard or self.PanelGroupNor
    local viewModel = self._ViewModel
    local total = viewModel:GetChapterTotalNumber()
    local count = 0

    for i = 1, total do
        ---@type XReform2ndChapter
        local chapter = viewModel:GetChapterByIndex(i)
        if not isHard or self._Control:IsHasStageHard(chapter) then
            count = count + 1
            local data = datas[count]
            if not data then
                data = {}
                datas[count] = data
            end
            data.Name = self._Control:GetChapterName(chapter)
            -- 序号按当前难度列表内的位置排
            data.GuanText = string.format("%02d", count)
            data.ChapterIndex = i
            self:RefreshChapterData(chapter, i, isHard, data)
        end
    end

    for i = #datas, count + 1, -1 do
        datas[i] = nil
    end

    XTool.UpdateDynamicItemByUiCache(grids, datas, parent.transform, XUiReform2ndChapterGrid, self)

    -- 收起另一侧格子：面板已关，格子留着显示态会在下次子节点重启用时报错
    local hiddenGrids = isHard and self._NorGrids or self._HardGrids
    for i = 1, #hiddenGrids do
        hiddenGrids[i]:Close()
    end
end

-- 逐秒刷新：只碰会变的字段，名字和序号原样保留
function XUiReform2New:RefreshChapterStatus()
    local isHard = self._IsHard
    local datas = isHard and self._HardDatas or self._NorDatas
    local grids = isHard and self._HardGrids or self._NorGrids

    for i = 1, #datas do
        local data = datas[i]
        ---@type XReform2ndChapter
        local chapter = self._ViewModel:GetChapterByIndex(data.ChapterIndex)
        self:RefreshChapterData(chapter, data.ChapterIndex, isHard, data)
        grids[i]:RefreshStatus()
    end
end

---@param chapter XReform2ndChapter
function XUiReform2New:RefreshChapterData(chapter, chapterIndex, isHard, data)
    data.QualityDesc = self._Control:GetChapterQualityDescByDifficulty(chapter, isHard)
    data.IsFinished = self:IsChapterFinished(chapter, isHard)
    data.IsShowRed = XMVCA.XReform:CheckChapterRedDifficulty(chapter, isHard)
    if isHard then
        data.IsUnlocked = self._Control:IsChapterShowToggleHard(chapter)
                and self._ViewModel:GetChapterIsUnlockedByIndex(chapterIndex)
    else
        data.IsUnlocked = self._ViewModel:GetChapterIsUnlockedByIndex(chapterIndex)
    end
end

---@param chapter XReform2ndChapter
---@param isHard boolean
function XUiReform2New:IsChapterFinished(chapter, isHard)
    return self._Control:IsChapterStageFinished(chapter, isHard)
end

function XUiReform2New:RefreshTaskProgress()
    local txt, imgExp = self._ViewModel:GetTaskProgressTextAndImgExp()
    local button = self._IsHard and self.BtnGiftHard or self.BtnGiftNor

    button:SetNameByGroup(0, txt)
    button:SetFillAmount("Level/ImgExp", imgExp)
end

function XUiReform2New:RefreshDifficultyStyle()
    local isHard = self._IsHard

    self.RImgBg.gameObject:SetActiveEx(not isHard)
    self.RImgBgHard.gameObject:SetActiveEx(isHard)
    self.PanelEffect.gameObject:SetActiveEx(not isHard)
    self.PanelEffect02.gameObject:SetActiveEx(isHard)
    self.UiReformTitleNor.gameObject:SetActiveEx(not isHard)
    self.UiReformTitleHard.gameObject:SetActiveEx(isHard)
    self.PanelGroupNor.gameObject:SetActiveEx(not isHard)
    self.PanelGroupHard.gameObject:SetActiveEx(isHard)
    self.BtnGiftNor.gameObject:SetActiveEx(not isHard)
    self.BtnGiftHard.gameObject:SetActiveEx(isHard)
    self.BtnChangeNorToHard.gameObject:SetActiveEx(not isHard)
    self.BtnChangeHardToNor.gameObject:SetActiveEx(isHard)

    self.BtnChangeNorToHard:ShowReddot(not isHard and XMVCA.XReform:CheckToggleHard())
end

function XUiReform2New:InitTaskRewardDisplay()
    local rewards = self._ViewModel:GetDisplayRewards()

    XUiHelper.RefreshCustomizedList(self.PanelReward, self.GridReward, #rewards, function(index, obj)
        local grid = XUiGridCommon.New(self, obj)
        grid:Refresh(rewards[index])
    end)
end

function XUiReform2New:RefreshRemainTime()
    self.TxtRemainTime.text = self._Control:GetActivityTime()
end

function XUiReform2New:RefreshEndTime()
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XReform:HandleActivityEndTime()
        end
    end)
end

-- 章节按时间解锁，需逐秒重刷按钮状态
function XUiReform2New:OnTick()
    self:RefreshRemainTime()
    self:RefreshChapterStatus()
end
--endregion

--region 回调
function XUiReform2New:OnChapterClick(index)
    local datas = self._IsHard and self._HardDatas or self._NorDatas
    local data = datas[index]
    if not data then
        return
    end

    local chapterIndex = data.ChapterIndex
    if not data.IsUnlocked then
        XUiManager.TipMsg(self._ViewModel:GetHardChapterLockedTipByIndex(chapterIndex))
        return
    end

    self._ViewModel:SetCurrentChapterIndex(chapterIndex)
    ---@type XReform2ndChapter
    local chapter = self._ViewModel:GetChapterByIndex(chapterIndex)
    XDataCenter.Reform2ndManager.SetChapterRedPointToLocal(chapter:GetId(), self._IsHard)

    XLuaUiManager.Open("UiReformBalance", self._ViewModel:GetCurrentStage())
end

function XUiReform2New:OnBtnChangeToHardClick()
    if not self._Control:IsUnlockAllStageHard() and not self._Control:IsSuperior() then
        XUiManager.TipText("ReformLockDifficulty")
        return
    end
    self:SwitchDifficulty(true)
end

function XUiReform2New:OnBtnChangeToNorClick()
    self:SwitchDifficulty(false)
end

function XUiReform2New:SwitchDifficulty(isHard)
    self._IsHard = isHard
    self._Control:GetViewModelList():OnClickToggleHard(isHard)
    self:Refresh()
    if self._TaskRedPoint then
        XRedPointManager.Check(self._TaskRedPoint)
    end
    self:PlayAnimation("ModeQiehuan")
end

function XUiReform2New:OnBtnGiftClick()
    XLuaUiManager.Open("UiReformTask")
end

function XUiReform2New:OnCheckTaskRedPoint(count)
    local isShow = count >= 0
    self.BtnGiftNor:ShowReddot(isShow)
    self.BtnGiftHard:ShowReddot(isShow)
end
--endregion

return XUiReform2New
