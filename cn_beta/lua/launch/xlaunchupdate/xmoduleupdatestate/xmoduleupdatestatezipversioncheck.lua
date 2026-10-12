----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateZipVersionCheck.lua
-- description: 模块更新 - 检查Zip版本
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsLog = CS.XLog
local CsApplication = CS.XApplication
local CsFile = CS.System.IO.File
local CsDirectory = CS.System.IO.Directory
local UnityPlayerPrefs = CS.UnityEngine.PlayerPrefs

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateZipVersionCheck : XModuleUpdateStateBase
local XModuleUpdateStateZipVersionCheck = XLaunchConst.CreateMetaTable("XModuleUpdateStateZipVersionCheck", XModuleUpdateStateBase)

function XModuleUpdateStateZipVersionCheck:Init()
    if self.ModuleUpdateInfo:HasUpdated() then
        self._baseProgressPart = 1
        self._DownloadCacheFile = self.ModuleUpdateInfo:GetDownloadZipFilePathWithName("ZipVersionDownload_" .. self.ModuleUpdateInfo:GetNewVersion())
        self._ZipInfoDownloadFailCallback = function() self:OnEnter() end
        self._ZipInfoDownloadFinishCallback = function() self:_DownloadZipFiles() end
        self._DownloadHDiffZipInfoFilesCallback = function() self:_DownloadHDiffZipInfoFiles() end
        self._DownloadFinishCallback = function()
            local cost = self.UpdateManager:EndProfile("DownloadUnzipFiles")
            local dict = {
                ["version"] = CS.XRemoteConfig.DocumentVersion,
                ["cnt"] = self._zipCnt,
                ["size"] = self._zipTotalSize,
                ["mode"] = "zip_download",
                ["time_cost"] = cost,
            }
            self.UpdateManager:DoRecord(dict, "80038", "UpdateModuleZip")
            XLaunchConst.WriteAllText(self._DownloadCacheFile, "")
            self:_StartUnzipFiles()
        end
        self._key = "zip_version_key"
        self._currentVersion = tostring(self.ModuleUpdateInfo:GetNewVersion())
    end
end

function XModuleUpdateStateZipVersionCheck:IsEnter()
    return self.ModuleUpdateInfo:HasUpdated()
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateZipVersionCheck:OnEnter()
    local lastVersion = UnityPlayerPrefs.GetString(self._key)
    if lastVersion == self._currentVersion then
        self:OnFinish()
        return
    end

    local XLaunchDlcManager = require("XLaunchDlcManager")
    if XLaunchDlcManager.NeedShowSelect() then
        self:OnFinish()
        return
    end

    local isZipPatch = self.ModuleUpdateInfo:IsZipPatchVersion()
    if isZipPatch then
        self.ModuleUpdateInfo:SetZipPatchStatue(true)
        self:_DownloadHDiffZipInfoFiles()
        return
    end
    self:OnFinish()
end

-- 下载splitPatch json
function XModuleUpdateStateZipVersionCheck:_DownloadHDiffZipInfoFiles()
    local zipDir = self.ModuleUpdateInfo:GetDownloadZipFilePath()
    if not CsDirectory.Exists(zipDir) then
        CsDirectory.CreateDirectory(zipDir)
    end

    local downloadZipListInfoFileName = string.format("HDiffZipInfo_%s.json", self.ModuleUpdateInfo:GetNewVersion())
    self._zipListInfoDownloadPath = self.ModuleUpdateInfo:GetDownloadZipFilePathWithName(downloadZipListInfoFileName)
    if CsFile.Exists(self._zipListInfoDownloadPath) then
        self:_DownloadZipFiles()
        return
    end

    local zipCacheDir = self.ModuleUpdateInfo:GetDownloadZipFileCachePath()
    if CsDirectory.Exists(zipCacheDir) then
        CsDirectory.Delete(zipCacheDir, true)
    end
    CsDirectory.CreateDirectory(zipCacheDir)

    local zipListInfoPrefixUrl = self.ModuleUpdateInfo:GetZipPathParentUrl("HDiffZipInfo.json")
    local addTaskFunc = function(group)
        group:AddTask(zipListInfoPrefixUrl, self._zipListInfoDownloadPath)
    end
    self.UpdateManager:DownloadFiles(addTaskFunc, 
        self._ZipInfoDownloadFinishCallback, self._DownloadHDiffZipInfoFilesCallback, 
        nil, true)
end

-- 下载Zip
function XModuleUpdateStateZipVersionCheck:_DownloadZipFiles()
    local zipInfo = XLaunchConst.LoadJsonFile(self._zipListInfoDownloadPath)
    if not zipInfo then
        CsFile.Delete(self._zipListInfoDownloadPath)
        self:_DownloadHDiffZipInfoFiles()
        return
    end

    if not next(zipInfo) then
        self:OnFinish()
        return
    end

    local count = 0
    self._upzipIndex = 0
    self._unzipList = {}
    for fileName, _ in pairs(zipInfo) do
        local downloadPath = self.ModuleUpdateInfo:GetDownloadZipFileCachePathWithName(fileName)
        count = count + 1
        self._unzipList[count] = downloadPath
    end

    if XLaunchConst.FileExists(self._DownloadCacheFile) then
        self:_StartUnzipFiles()
        return
    end
    local totalSize = 0
    for fileName, info in pairs(zipInfo) do
        local downloadPath = self.ModuleUpdateInfo:GetDownloadZipFileCachePathWithName(fileName)
        if not XLaunchConst.FileExists(downloadPath) then
            totalSize = totalSize + info.Size
        end
    end
    if totalSize > 0 then
        XLaunchConst.BeforeDownloadTips(totalSize, function() self:_StartDownload(zipInfo) end)
    else
        self:_StartUnzipFiles()
    end
end

function XModuleUpdateStateZipVersionCheck:_StartDownload(zipInfo)
    self._baseProgressPart = self._baseProgressPart + 1
    -- 检测本地和解压进度，加压到一半杀进程
    local appendTaskFunction = function(group)
        self._zipCnt = 0
        self._zipTotalSize = 0
        for fileName, info in pairs(zipInfo) do
            local downloadPath = self.ModuleUpdateInfo:GetDownloadZipFileCachePathWithName(fileName)
            if not XLaunchConst.FileExists(downloadPath) then
                local url = self.ModuleUpdateInfo:GetZipPathParentUrl(fileName)
                self._zipTotalSize = self._zipTotalSize + info.Size
                self._zipCnt = self._zipCnt + 1
                group:AddTask(url, downloadPath, info.Size, info.Sha1, false, true)
            end
        end
        CS.XLog.Debug(string.format("[Download] StartDownload zip files, totalSize:%s", self._zipTotalSize))
        CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, self._zipTotalSize, nil, nil, 0.5)
    end
    self.UpdateManager:StartProfile("DownloadUnzipFiles")
    self.UpdateManager:DownloadFiles(appendTaskFunction, self._DownloadFinishCallback, nil, function(progress)
        self.UpdateManager:UpdateProgress(progress / self._baseProgressPart)
    end, true)
end

function XModuleUpdateStateZipVersionCheck:_StartUnzipFiles()
    self.UpdateManager:StartProfile("UnzipFiles")
    self:_UnzipFilesMultiThread()
end

function XModuleUpdateStateZipVersionCheck:_UnzipFilesMultiThread()
    local unzipManager = CS.XHaruUnzip.XUnzipManager()
    local currentCount = 1
    unzipManager.OnTotalProgress = function(progress)
        self.UpdateManager:UpdateProgress((self._baseProgressPart - 1 + progress * (currentCount / self._zipCnt)) / self._baseProgressPart)
    end
    unzipManager.OnFileUnzipped = function(taskName, filePath)
        self.UpdateManager:WriteDownloadCache(filePath, true)
    end
    unzipManager.OnStateChanged = function(state)
        if state == 2 or state == 3 then
            local cost = self.UpdateManager:EndProfile("UnzipFiles")
            local dict = {
                ["version"] = CS.XRemoteConfig.DocumentVersion,
                ["cnt"] = self._zipCnt,
                ["mode"] = "zip_unzip",
                ["time_cost"] = cost,
            }
            self.UpdateManager:DoRecord(dict, "80038", "UpdateModuleZip")
            self.UpdateManager:UpdateProgress(1)
            local zipBaseDir = self.ModuleUpdateInfo:GetDownloadZipFilePath()
            if CsDirectory.Exists(zipBaseDir) then
                CsDirectory.Delete(zipBaseDir, true)
            end
            UnityPlayerPrefs.SetString(self._key, self._currentVersion)
            self:OnFinish()
        end
    end
    local zipDir = self.ModuleUpdateInfo:GetDownloadZipFileCachePath()
    unzipManager.OnZipFinished = function(zipName)
        -- 嵌套任务名为"外层名!子zip名", 不在zipPathMap里, 天然跳过删除
        local zipPath = zipDir .. "/" .. zipName
        CsLog.Debug(string.format("[Unzip] Completed file:%s", tostring(zipPath or zipName)))
        if CsFile.Exists(zipPath) then
            CsFile.Delete(zipPath)
        end
        self.UpdateManager:WriteTempDownloadCache()
        currentCount = currentCount + 1
    end
    
    local unzipPath = self.ModuleUpdateInfo:GetMergePatchFilePath()
    local password = nil
    self._zipCnt = 0
    for _, zipPath in pairs(self._unzipList) do
        if XLaunchConst.FileExists(zipPath) then
            self._zipCnt = self._zipCnt + 1
            unzipManager:AddTask(zipPath, unzipPath, password)
        end
    end
    CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, self._zipCnt, false, CsApplication.GetText("Unzip") .. "(%d/%d)", 1 / self._baseProgressPart, (self._baseProgressPart - 1) * (1 / self._baseProgressPart)) -- 解压资源
    unzipManager:Start()
end

return XModuleUpdateStateZipVersionCheck
