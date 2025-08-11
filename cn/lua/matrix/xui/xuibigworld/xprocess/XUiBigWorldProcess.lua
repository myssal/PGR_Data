local XUiBigWorldProcessCourse = require("XUi/XUiBigWorld/XProcess/Course/XUiBigWorldProcessCourse")
local XUiBigWorldProcessExplore = require("XUi/XUiBigWorld/XProcess/Explore/XUiBigWorldProcessExplore")
local XUiBigWorldProcessCore = require("XUi/XUiBigWorld/XProcess/Core/XUiBigWorldProcessCore")

---@class XUiBigWorldProcess : XBigWorldUi
---@field TopTabGroup XUiButtonGroup
---@field BtnTab XUiComponent.XUiButton
---@field BtnSwitch XUiComponent.XUiButton
---@field PanelProcess UnityEngine.RectTransform
---@field PanelExplore UnityEngine.RectTransform
---@field PanelCore UnityEngine.RectTransform
---@field ImgTitle UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButton
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcess = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldProcess")

function XUiBigWorldProcess:OnAwake()
    ---@type XBWCourseVersionEntity[]
    self._VersionEntitys = self._Control:GetValidVersionEntitys()

    self._CurrentIndex = 0
    self._CurrentVersion = XEnumConst.BWCourse.Version.One

    self._VersionValidCache = {}

    self._Timer = false

    self._TabMap = {}
    self._TabCache = {}

    ---@type XUiBigWorldProcessCourse
    self._CourseUi = XUiBigWorldProcessCourse.New(self.PanelProcess, self)
    ---@type XUiBigWorldProcessExplore
    self._ExploreUi = XUiBigWorldProcessExplore.New(self.PanelExplore, self)
    ---@type XUiBigWorldProcessCore
    self._CoreUi = XUiBigWorldProcessCore.New(self.PanelCore, self)

    self:_RegisterButtonClicks()
end

function XUiBigWorldProcess:OnStart()
    self:_InitUi()
end

function XUiBigWorldProcess:OnEnable()
    self:_RefreshTab()
    self:_RefreshVersion()
    self:_RefreshRedPoint()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcess:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcess:OnDestroy()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_HUD_RED_POINT_REFRESH)
end

function XUiBigWorldProcess:OnTopTabGroupClick(index)
    if self._CurrentIndex ~= index then
        local version = self:_GetCurrentVersion()

        if version then
            local contentEntity = version:GetContentEntityByIndex(index)

            self._CurrentIndex = index
            self:_RefreshPage(contentEntity)
            self:PlayAnimation("QieHuan")
        end
    end
end

function XUiBigWorldProcess:OnBtnSwitchClick()
    if self._CurrentVersion == XEnumConst.BWCourse.Version.One then
        self._CurrentVersion = XEnumConst.BWCourse.Version.Two
    else
        self._CurrentVersion = XEnumConst.BWCourse.Version.One
    end

    local currentIndex = self._CurrentIndex

    self._CurrentIndex = 0
    self:_RefreshTab(currentIndex)
    self:_RefreshVersion()
    self:_RefreshRedPoint()
end

function XUiBigWorldProcess:OnBtnCloseClick()
    self._CourseUi:PlayRewardDisableAnimation()
    self:Close()
end

function XUiBigWorldProcess:OnRefreshRedPoint()
    self:_RefreshRedPoint()
end

function XUiBigWorldProcess:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnSwitch.CallBack = Handler(self, self.OnBtnSwitchClick)
    self.BtnClose.CallBack = Handler(self, self.OnBtnCloseClick)
end

function XUiBigWorldProcess:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH,
        self.OnRefreshRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefreshRedPoint, self)
end

function XUiBigWorldProcess:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH,
        self.OnRefreshRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefreshRedPoint, self)
end

function XUiBigWorldProcess:_RegisterSchedules()
    -- 在此处注册定时器
    self:_RemoveSchedules()

    self._Timer = XScheduleManager.ScheduleForever(function()
        local versionEntitys = self._Control:GetValidVersionEntitys()
        local currentCount = table.nums(versionEntitys)
        local count = table.nums(self._VersionEntitys)

        if currentCount == 0 or count == 0 then
            self:_RemoveSchedules()
            self:Close()
        elseif currentCount ~= count then
            self._VersionEntitys = versionEntitys
            self._CurrentIndex = 0
            self._CurrentVersion = XEnumConst.BWCourse.Version.One
            self:_RefreshTab()
            self:_RefreshVersion()
            self:_RefreshRedPoint()
        end
    end, XScheduleManager.SECOND)
end

function XUiBigWorldProcess:_RemoveSchedules()
    -- 在此处移除定时器
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiBigWorldProcess:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcess:_InitUi()
    self.BtnTab.gameObject:SetActive(false)
end

function XUiBigWorldProcess:_RefreshTab(currentSelectIndex)
    local versionEntity = self:_GetCurrentVersion()
    self._TabMap = {}
    if versionEntity then
        local tabList = {}
        local contentEntitys = versionEntity:GetContentEntitys()
        local selectIndex = self._CurrentIndex

        if not XTool.IsTableEmpty(contentEntitys) then
            local count = 1

            for index, contentEntity in pairs(contentEntitys) do
                if contentEntity:IsUnlock() then
                    local tab = self._TabCache[index]

                    if not tab then
                        tab = XUiHelper.Instantiate(self.BtnTab, self.TopTabGroup.transform)
                        self._TabCache[index] = tab
                    end

                    count = count + 1
                    self._TabMap[contentEntity:GetContentType()] = tab
                    tab.gameObject:SetActiveEx(true)
                    tab:SetNameByGroup(0, contentEntity:GetName())
                    tab:ShowReddot(false)
                    table.insert(tabList, tab)
                end
            end
            for i = count, #self._TabCache do
                self._TabCache[i].gameObject:SetActiveEx(false)
            end
        end

        if not XTool.IsNumberValid(selectIndex) then
            selectIndex = currentSelectIndex or 1

            if selectIndex > #tabList then
                selectIndex = 1
            end
       end

        self.TopTabGroup:Init(tabList, Handler(self, self.OnTopTabGroupClick))
        self.TopTabGroup:SelectIndex(selectIndex)
    end
end

---@return XBWCourseVersionEntity
function XUiBigWorldProcess:_GetCurrentVersion()
    return self._VersionEntitys[self._CurrentVersion]
end

---@param contentEntity XBWCourseContentEntity
function XUiBigWorldProcess:_RefreshPage(contentEntity)
    if not contentEntity or contentEntity:IsNil() then
        return
    end

    if contentEntity:IsTask() then
        self._CourseUi:Open()
        self._CourseUi:Refresh(contentEntity)
        self._CoreUi:Close()
        self._ExploreUi:Close()
    elseif contentEntity:IsExplore() then
        self._ExploreUi:Open()
        self._ExploreUi:Refresh(contentEntity)
        self._CourseUi:Close()
        self._CoreUi:Close()
    elseif contentEntity:IsCore() then
        self._CoreUi:Open()
        self._CoreUi:Refresh(contentEntity)
        self._CourseUi:Close()
        self._ExploreUi:Close()
    end

    self:_RefreshRedPoint()
end

function XUiBigWorldProcess:_RefreshVersion()
    local version = self:_GetCurrentVersion()
    local count = table.nums(self._VersionEntitys)
    local otherVersion = self._VersionEntitys[XEnumConst.BWCourse.Version.Two]

    self.BtnSwitch.gameObject:SetActiveEx(count > 1)
    self.TxtTitle.text = version and version:GetName() or ""

    if self._CurrentVersion == XEnumConst.BWCourse.Version.Two then
        otherVersion = self._VersionEntitys[XEnumConst.BWCourse.Version.One]
    end

    if otherVersion and not otherVersion:IsNil() then
        self.BtnSwitch:ShowReddot(XMVCA.XBigWorldCourse:CheckVersionAchieved(otherVersion:GetVersionId()))
    else
        self.BtnSwitch:ShowReddot(false)
    end
end

function XUiBigWorldProcess:_RefreshRedPoint()
    local version = self:_GetCurrentVersion()

    if version and not version:IsNil() then
        local versionId = version:GetVersionId()

        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Task,
            XMVCA.XBigWorldCourse:CheckVersionTaskAchieved(versionId))
        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Explore,
            XMVCA.XBigWorldCourse:CheckVersionExploreAchieved(versionId))
        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Core,
            XMVCA.XBigWorldCourse:CheckVersionNewCore(versionId))
    else
        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Task, false)
        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Explore, false)
        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Core, false)
    end
end

function XUiBigWorldProcess:_RefreshTabRedPoint(contentType, isShow)
    local contentTab = self._TabMap[contentType]

    if contentTab then
        contentTab:ShowReddot(isShow)
    end
end

return XUiBigWorldProcess
