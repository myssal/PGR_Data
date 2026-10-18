----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateListNormal.lua
-- description: 模块更新 - 生成更新列表
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateListNormal : XModuleUpdateStateBase
local XModuleUpdateStateListNormal = XLaunchConst.CreateMetaTable("XModuleUpdateStateListNormal", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateListNormal:OnEnter()
    self.XFileInfoVersionIndex = XLaunchConst.XFileInfoVersionIndex
    self.XFileInfoPatchVersionListIndex = XLaunchConst.XFileInfoPatchVersionListIndex
    self.XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
    self.XFileInfoFlagIndex = XLaunchConst.XFileInfoFlagIndex
    self.PackageNeedDownload = self.UpdateManager.PackageNeedDownload or XLaunchConst.EmptyTable

    self._isNotMobile = not CS.UnityEngine.Application.isMobilePlatform
    -- 是不是Doc更新模块
    self._isMatrixMode = self.ModuleUpdateInfo:IsMatrixUpdate()
    self._isPredownload = self.ModuleUpdateInfo:IsPredownloadStatus()

    if self.ModuleUpdateInfo:HasUpdated() then
        if self._isPredownload then
            self:CollectInfo(self.UpdateManager.LocalIndexTable, self.UpdateManager.PreIndexTable)
        else
            self:CollectInfo(self.UpdateManager.LocalIndexTable, self.UpdateManager:GetTargetIndexMap())
        end
    else
        -- 处理非更新资源补全和修复
        if XLaunchConst.PackageUpdate then
            local XLaunchDlcManager = require("XLaunchDlcManager")
            local newIndexTable = self.UpdateManager:GetTargetIndexMap()
            for fileName, newInfo in pairs(newIndexTable) do
                if XLaunchDlcManager:IsDlcAsset(fileName) and not XLaunchDlcManager:IsNameDownloaded(fileName) then
                    self.UpdateManager:AddDownloadABMap(fileName)
                else
                    local packageInfo = self.UpdateManager:GetPackageInfo(fileName)
                    if packageInfo then
                        local newSha1 = newInfo[self.XFileInfoSha1Index]
                        local packageSha1 = packageInfo[self.XFileInfoSha1Index]
                        if newSha1 ~= packageSha1 then
                            local newVersion = newInfo[self.XFileInfoVersionIndex]
                            self:AddUpdateInfo(fileName, packageInfo, newInfo, newVersion)
                        elseif self.PackageNeedDownload[fileName] then
                            self.UpdateManager:AddDownloadABMap(fileName)
                        end
                    elseif self.PackageNeedDownload[fileName] then
                        self.UpdateManager:AddDownloadABMap(fileName)
                    end
                end
            end
            self.ModuleUpdateInfo:SetUpdateStatue(true)
        end
    end

    self:OnFinish()
end

-- 添加更新信息
function XModuleUpdateStateListNormal:AddUpdateInfo(fileName, info, newInfo, newVersion)
    if info then
        local curVersion = info[self.XFileInfoVersionIndex]
        local patchVersionList = newInfo[self.XFileInfoPatchVersionListIndex]
        local isAbUpdate = true
        for _, patchVersion in pairs(patchVersionList) do
            if patchVersion == curVersion then
                isAbUpdate = false
                break
            end
        end
        if isAbUpdate then
            self.UpdateManager:AddDownloadABMap(fileName)
        else
            self.UpdateManager:AddPatchInfo(fileName, curVersion, newVersion)
        end
    else
        self.UpdateManager:AddDownloadABMap(fileName)
    end
end

-- 收集热更数据
function XModuleUpdateStateListNormal:CollectInfo(localIndexTable, newIndexTable)
    local oldAssetMap = localIndexTable
    for fileName, newInfo in pairs(newIndexTable) do
        local newSha1 = newInfo[self.XFileInfoSha1Index]
        local newVersion = newInfo[self.XFileInfoVersionIndex]
        -- 不是包内才需要下载
        if self.ModuleUpdateInfo:IsNeedDownloadVersion(newVersion) and 
            not self.UpdateManager:IsInnerResource(fileName, newSha1) then
            local oldInfo = oldAssetMap[fileName]
            if oldInfo == nil then
                if self._isNotMobile then
                    -- 非手机可以通过包内patch方式
                    local packageInfo = self.UpdateManager:GetPackageInfo(fileName)
                    if packageInfo and packageInfo[self.XFileInfoFlagIndex] == 0 then
                        self:AddUpdateInfo(fileName, packageInfo, newInfo, newVersion)
                    else
                        self.UpdateManager:AddDownloadABMap(fileName)
                    end
                else
                    self.UpdateManager:AddDownloadABMap(fileName)
                end
            else
                local isNeedDownload = oldInfo[self.XFileInfoSha1Index] ~= newSha1
                if isNeedDownload then
                    -- 之前是包内，后面是包外的情况就不能走patch了，因为找包内的内容找不到对的了
                    if self._isMatrixMode then
                        -- 真机就版本和包内版本一只，不应该使用patch，如果是pc是可以用patch
                        local packageInfo = self.UpdateManager:GetPackageInfo(fileName)
                        local packageVersion = nil
                        if packageInfo then
                            if packageInfo[self.XFileInfoFlagIndex] == 0 then
                                packageVersion = packageInfo[self.XFileInfoVersionIndex]
                            end
                        end
                        if self._isNotMobile then
                            self:AddUpdateInfo(fileName, oldInfo, newInfo, newVersion)
                        else
                            local oldVersion = oldInfo[self.XFileInfoVersionIndex]
                            if oldVersion == packageVersion then
                                self.UpdateManager:AddDownloadABMap(fileName)
                            else
                                self:AddUpdateInfo(fileName, oldInfo, newInfo, newVersion)
                            end
                        end
                    else
                        self.UpdateManager:AddDownloadABMap(fileName)
                    end
                elseif self.PackageNeedDownload[fileName] then
                    self.UpdateManager:AddDownloadABMap(fileName)
                end
            end
        end
    end
end

return XModuleUpdateStateListNormal
