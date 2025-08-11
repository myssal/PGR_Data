local XUiBWProcessPlayerBase = require("XUi/XUiBigWorld/XProcess/XUiBWProcessPlayerBase")
local XUiBigWorldProcessCourseReward = require("XUi/XUiBigWorld/XProcess/Course/XUiBigWorldProcessCourseReward")
local XUiBigWorldProcessCourseTask = require("XUi/XUiBigWorld/XProcess/Course/XUiBigWorldProcessCourseTask")

---@class XUiBigWorldProcessCourse : XUiBWProcessPlayerBase
---@field ImgRewardBar UnityEngine.UI.Image
---@field ListReward UnityEngine.RectTransform
---@field GridReward UnityEngine.RectTransform
---@field ListTask UnityEngine.RectTransform
---@field GridTask UnityEngine.RectTransform
---@field TxtNum UnityEngine.UI.Text
---@field RImgIcon UnityEngine.UI.RawImage
---@field Parent XUiBigWorldProcess
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcessCourse = XClass(XUiBWProcessPlayerBase, "XUiBigWorldProcessCourse")

function XUiBigWorldProcessCourse:OnStart()
    ---@type XBWCourseContentEntity
    self._Entity = false
    ---@type XDynamicTableNormal
    self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.ListTask, XUiBigWorldProcessCourseTask)
    ---@type XUiBigWorldProcessCourseReward[]
    self._ProgressGrids = {}

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessCourse:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessCourse:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessCourse:OnDestroy()
end

---@param grid XUiBigWorldProcessCourseTask
function XUiBigWorldProcessCourse:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entity = self._DynamicTable:GetData(index)

        grid:Refresh(entity)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayDynamicAnimation()
    end
end

function XUiBigWorldProcessCourse:OnRefresh()
    if self._Entity then
        self:Refresh(self._Entity)
    end
end

---@param contentEntity XBWCourseContentEntity
function XUiBigWorldProcessCourse:Refresh(contentEntity)
    self._Entity = contentEntity
    self:_RefreshProgress(contentEntity:GetContentId(), contentEntity:GetCurrentTaskProgress(),
        contentEntity:GetMaxTaskProgress())
    self:_RefreshProgressReward(contentEntity:GetTaskProgressEntitys())
    self:_RefreshDynamicTable(contentEntity:GetUnlockTaskEntitys())
end

---@return XDynamicTableNormal
function XUiBigWorldProcessCourse:GetDynamicTable()
    return self._DynamicTable
end

function XUiBigWorldProcessCourse:PlayRewardDisableAnimation()
    if not XTool.IsTableEmpty(self._ProgressGrids) and self:IsNodeShow() then
        for _, grid in ipairs(self._ProgressGrids) do
            grid:PlayDisableAnimation()
        end
    end
end

function XUiBigWorldProcessCourse:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiBigWorldProcessCourse:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefresh, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_REWARD_RECEIVE, self.OnRefresh, self)
end

function XUiBigWorldProcessCourse:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefresh, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_REWARD_RECEIVE, self.OnRefresh,
        self)
end

function XUiBigWorldProcessCourse:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessCourse:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessCourse:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessCourse:_InitUi()
    self.GridTask.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
end

---@param entitys XBWCourseTaskEntity[]
function XUiBigWorldProcessCourse:_RefreshDynamicTable(entitys)
    self._DynamicTable:SetDataSource(entitys)
    self._DynamicTable:ReloadDataSync(1)
end

function XUiBigWorldProcessCourse:_RefreshProgress(contentId, currentProgress, maxProgress)
    if not XTool.IsNumberValid(maxProgress) then
        maxProgress = 1
    end

    local icon = self._Control:GetTaskRewardItemIcon(contentId)
    local progressCount = self._Control:GetTaskProgressCountByContentId(contentId)

    self.ImgRewardBar.fillAmount = currentProgress / (maxProgress + maxProgress / (progressCount + 1))
    self.TxtNum.text = currentProgress
    if string.IsNilOrEmpty(icon) then
        self.RImgIcon.gameObject:SetActiveEx(false)
    else
        self.RImgIcon.gameObject:SetActiveEx(true)
        self.RImgIcon:SetImage(icon)
    end
end

---@param progressEntitys XBWCourseTaskProgressEntity[]
function XUiBigWorldProcessCourse:_RefreshProgressReward(progressEntitys)
    local count = 0

    if not XTool.IsTableEmpty(progressEntitys) then
        for i, progressEntity in ipairs(progressEntitys) do
            local grid = self._ProgressGrids[i]

            if not grid then
                local gridUi = XUiHelper.Instantiate(self.GridReward, self.ListReward)

                grid = XUiBigWorldProcessCourseReward.New(gridUi, self)
                self._ProgressGrids[i] = grid
            end

            grid:Open()
            grid:Refresh(progressEntity)
            count = count + 1
        end
    end
    for i = count + 1, table.nums(self._ProgressGrids) do
        self._ProgressGrids[i]:Close()
    end
end

return XUiBigWorldProcessCourse
