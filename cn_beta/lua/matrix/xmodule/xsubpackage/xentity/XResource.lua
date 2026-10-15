---@class XResource
---@field _Id number
---@field _TaskGroup XMTDownloadTaskGroup 下载任务组（延迟到实际下载时才构建任务）
local XResource = XClass(nil, "XResource")
local XLaunchDlcManager = require("XLaunchDlcManager")
local CSDownloadTaskGroupState = XTool.GetDownloadStateEnum()

function XResource:Ctor(resId)
    self._Id = resId
    self._RepeatName = {}
    self._DownSize = 0
    self._TotalSize = 0
    self._MaxProgress = 0
    -- 首次下载时再构建任务组。
    self._TaskGroup = nil
    self._TaskGroupBuilt = false
    self._HasDownloadTasks = false
    self._PendingFileInfos = {}
    self._WaitPause = false
end

function XResource:InitState()
    if XLaunchDlcManager.HasUninstalledResId(self._Id) then
        self:Uninstall()
        return
    end

    local downloadSize = self:GetDownloadSize()
    local totalSize = self:GetTotalSize()
    if totalSize and totalSize <= 0 then
        XLog.Error("XResource:InitState SizeError, totalSize = " .. totalSize .. ", id = " .. self._Id)
    end

    if downloadSize <= 0 then
        if totalSize <= 0 then
            self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
        else
            self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.NOT_DOWNLOAD
        end

    elseif downloadSize > 0 and downloadSize < totalSize then
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
    else
        self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
    end
end

function XResource:GetState()
    return self._State
end

function XResource:PrepareDownload()
    if self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
        XLog.Warning("XResource:PrepareDownload, already complete, id = " .. self._Id .. ", state = " .. self._State)
        return
    end

    XLaunchDlcManager.RemoveUninstalledResId(self._Id)
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD

    -- [F1] 通知父分包更新聚合状态（从 UNINSTALLED/NOT_DOWNLOAD 恢复）
    local subpackageIdList = XMVCA.XSubPackage:GetSubpackageIdByResId(self._Id)
    if not XTool.IsTableEmpty(subpackageIdList) then
        for _, subPackageId in pairs(subpackageIdList) do
            local subpackageItem = XMVCA.XSubPackage:GetSubpackageItem(subPackageId)
            if subpackageItem then
                local subState = subpackageItem:GetState()
                if subState == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.UNINSTALLED
                    or subState == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.NOT_DOWNLOAD then
                    subpackageItem:UpdateAggregateState()
                    XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_PREPARE, subPackageId)
                end
            end
        end
    end
end

function XResource:StartDownload()
    if self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
        XLog.Warning("XResource:StartDownload, already complete, id = " .. self._Id .. ", state = " .. self._State)
        return
    end

    XLaunchDlcManager.RemoveUninstalledResId(self._Id)
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING
    XMVCA.XSubPackage:Print(string.format("[SubPackage] Resource(%s) Start to Download!", self._Id))
end

--等待状态
function XResource:PreparePause()
    if self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
        XLog.Warning("XResource:PreparePause, already complete, id = " .. self._Id .. ", state = " .. self._State)
        return
    end

    XLaunchDlcManager.RemoveUninstalledResId(self._Id)
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XResource:Pause()
    if self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
        XLog.Warning("XResource:Pause, already complete, id = " .. self._Id .. ", state = " .. self._State)
        return
    end

    XLaunchDlcManager.RemoveUninstalledResId(self._Id)
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
    XMVCA.XSubPackage:Print(string.format("[SubPackage] Resource(%s) Paused!", self._Id))
end

function XResource:Uninstall()
    if self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.UNINSTALLED then
        XLog.Warning("XResource:Unistall, already UNINSTALLED, id = " .. self._Id .. ", state = " .. self._State)
        return
    end
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.UNINSTALLED
    
    -- 获取该资源所属的所有分包 Id，并通知它们刷新状态
    local subpackageIdList = XMVCA.XSubPackage:GetSubpackageIdByResId(self._Id)
    if not XTool.IsTableEmpty(subpackageIdList) then
        for _, subPackageId in pairs(subpackageIdList) do
            local subpackageItem = XMVCA.XSubPackage:GetSubpackageItem(subPackageId)
            if subpackageItem then
                -- 调用刚才新增的同步方法
                subpackageItem:UpdateUninstallState()
            end
        end
    end

    XMVCA.XSubPackage:Print(string.format("[SubPackage] Resource(%s) Unistall!", self._Id))
end

function XResource:Complete()
    self._State = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
    XEventManager.DispatchEvent(XEventId.EVENT_RES_COMPLETE, self._Id)
    -- 在Release前使所属Subpackage的TaskGroups缓存失效，避免缓存已释放的C#对象
    -- 同时通知Sub级进度更新，确保UiDownLoadMain的进度条在单个res完成时也能刷新
    local subpackageIdList = XMVCA.XSubPackage:GetSubpackageIdByResId(self._Id)
    if not XTool.IsTableEmpty(subpackageIdList) then
        for _, subPackageId in pairs(subpackageIdList) do
            local subpackageItem = XMVCA.XSubPackage:GetSubpackageItem(subPackageId)
            if subpackageItem then
                subpackageItem:InvalidateTaskGroupsCache()
                XEventManager.DispatchEvent(XEventId.EVENT_SUBPACKAGE_UPDATE, subPackageId, subpackageItem:GetProgress())
            end
        end
    end
    self:Release()
    XMVCA.XSubPackage:Print(string.format("[SubPackage] Resource(%s) Download Complete!", self._Id))
end

function XResource:IsStateComplete()
    if self._State == nil then
        self:InitState()
    end
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
end

function XResource:IsPrepare()
    if self._State == nil then
        self:InitState()
    end
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
end

function XResource:IsPause()
    if self._State == nil then
        self:InitState()
    end
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
end

function XResource:IsUninstalled()
    if self._State == nil then
        self:InitState()
    end
    return self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.UNINSTALLED
end

function XResource:GetSourceSizeWithUnit()
    local size = self:GetTotalSize()
    return XMVCA.XSubPackage:TransformSize(size)
end

function XResource:InitFileInfo(filePath, data)
    local fileName, size = data[1], data[3]
    if self._RepeatName[fileName] then
        return
    end
    self._RepeatName[fileName] = true
    local isComplete = XLaunchDlcManager.IsNameDownloaded(fileName)
    if isComplete then
        self._DownSize = self._DownSize + size
    else
        -- 保存待下载文件，首次下载时再添加任务。
        self._PendingFileInfos[fileName] = data
    end
end

function XResource:FileInitComplete()
    self:InitState()
    self._RepeatName = nil
end

---@return XMTDownloadTaskGroup
function XResource:GetTaskGroup()
    if not self._TaskGroup then
        self._TaskGroup = XTool.CreateDownloadTaskGroup(self._Id)
    end
    return self._TaskGroup
end

--- 是否包含待执行的下载任务
---@return boolean
function XResource:HasDownloadTasks()
    return self._HasDownloadTasks
end

--- 首次下载前构建任务，并补计其他资源已下载的共享文件
---@return XMTDownloadTaskGroup taskGroup
---@return number addedCount 本次新增任务数（0表示所有文件已落盘，无需真实下载）
function XResource:EnsureTaskGroupBuilt()
    if self._TaskGroupBuilt then
        return self._TaskGroup, 0
    end

    local taskGroup = self:GetTaskGroup()
    local downloadedSize = self._DownSize
    local addedCount = 0
    for fileName, info in pairs(self._PendingFileInfos) do
        -- 共享文件可能已被其他资源下载。
        if XLaunchDlcManager.IsNameDownloaded(fileName) then
            downloadedSize = downloadedSize + info[3]
        else
            taskGroup:AddTask(XMVCA.XSubPackage:GetUrlPath(fileName, info[4]), XMVCA.XSubPackage:GetSavePath(fileName), info[3], info[2])
            addedCount = addedCount + 1
        end
    end
    self._PendingFileInfos = nil
    taskGroup:AddFinishedSizeAfterAddTask(downloadedSize)
    self._TaskGroupBuilt = true
    self._HasDownloadTasks = addedCount > 0
    return taskGroup, addedCount
end

-- 下载中心清空后，按完整索引重新整理任务，保留资源的业务状态。
function XResource:ResetDownloadTaskGroup(fileInfos)
    self:Release()
    self._TaskGroup = nil
    self._TaskGroupBuilt = false
    self._HasDownloadTasks = false
    self._PendingFileInfos = {}
    self._DownSize = 0
    self._MaxProgress = 0
    self._WaitPause = false
    self._RepeatName = {}
    for filePath, info in pairs(fileInfos) do
        self:InitFileInfo(filePath, info)
    end
    self._RepeatName = nil
end

function XResource:GetProgress()
    if self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
        return 1
    end
    if not self._TaskGroupBuilt then
        local totalSize = self:GetTotalSize()
        if totalSize and totalSize > 0 then
            return self._DownSize / totalSize
        end
        return 0
    end
    return self._TaskGroup.ProgressRatio
end

function XResource:GetMaxProgress()
    return math.max(self:GetProgress(), self._MaxProgress)
end

function XResource:UpdateMaxProgress(progress)
    self._MaxProgress = math.max(progress, self._MaxProgress)
end

-- 下载过程中，临时文件可能出错，删除掉会导致进度减少
function XResource:IsProgressLess()
    return self:GetProgress() < self._MaxProgress
end

function XResource:GetTotalSize()
    if self._TotalSize <= 0 then
        self._TotalSize = XMVCA.XSubPackage:GetResTotalSize(self._Id)
    end
    return self._TotalSize
end

function XResource:GetDownloadSize()
    -- 任务组释放后会清空统计，已完成资源返回完整大小。
    if self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
        return self:GetTotalSize()
    end
    if not self._TaskGroupBuilt then
        return self._DownSize
    end
    return self._TaskGroup.DownloadedBytes
end

function XResource:IsComplete()
    if self._State == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
        return true
    end
    if self._TaskGroupBuilt then
        return self._TaskGroup.State == CSDownloadTaskGroupState.Complete
    end
    return false
end

---@param center XMTDownloadCenter
function XResource:OnStateChanged()
    local state = self._TaskGroup.State
    -- print("SP/DN XResource:OnStateChanged", self._Id, state)
    if state == CSDownloadTaskGroupState.Registered and self._WaitPause then
        XMVCA.XSubPackage:OnResDownloadRelease(self._Id)
        self._WaitPause = false
    elseif state == CSDownloadTaskGroupState.Complete then
        self:Complete()
        XMVCA.XSubPackage:OnResDownloadRelease(self._Id)
        self._WaitPause = false
    elseif state == CSDownloadTaskGroupState.Pausing then
        self._WaitPause = true
    elseif state == CSDownloadTaskGroupState.CompleteError then
        XMVCA.XSubPackage:OnResDownloadRelease(self._Id)
    end

    local subpackageIdList = XMVCA.XSubPackage:GetSubpackageIdByResId(self._Id)
    if XTool.IsTableEmpty(subpackageIdList) then
        return
    end
    for k, subPackageId in pairs(subpackageIdList) do
        local subpackageItem = XMVCA.XSubPackage:GetSubpackageItem(subPackageId)
        if subpackageItem then
            subpackageItem:OnStateChanged(state)
        end
    end
end

function XResource:Release()
    if not self._TaskGroup then
        return
    end
    self._TaskGroup:Release()
end

return XResource