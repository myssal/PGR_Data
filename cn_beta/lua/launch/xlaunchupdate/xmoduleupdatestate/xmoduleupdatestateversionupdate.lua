----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateVersionUpdate.lua
-- description: 模块更新 - 更新版本信息
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateVersionUpdate : XModuleUpdateStateBase
local XModuleUpdateStateVersionUpdate = XLaunchConst.CreateMetaTable("XModuleUpdateStateVersionUpdate", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateVersionUpdate:OnEnter()
    local CsFile = CS.System.IO.File
    -- 更新版本信息
    if self.ModuleUpdateInfo:HasUpdated() then
        local DocumentIndexFilePath = self.ModuleUpdateInfo.DocumentIndex
        local DownloadIndexFilePath = self.ModuleUpdateInfo:GetDownloadIndexPath()
        if CsFile.Exists(DownloadIndexFilePath) then
            if CsFile.Exists(DocumentIndexFilePath) then
                CsFile.Delete(DocumentIndexFilePath)
            end
            CsFile.Move(DownloadIndexFilePath, DocumentIndexFilePath)
        end
        self.ModuleUpdateInfo:UpdateVersion()
        self.ModuleUpdateInfo:DeleteTempVersionCache()

        -- 解锁cache
        self.UpdateManager:ClearCache()
        XLaunchConst.SetKeyValue(XLaunchConst.IsUpdateKey, true)
    end

    if self.UpdateManager:IsPackageCheckMode() then
        local tempPath = self.ModuleUpdateInfo:GetTempIndexPath()
        local originPath = self.ModuleUpdateInfo:GetOriginIndexPath()
        if CsFile.Exists(tempPath) then
            if CsFile.Exists(originPath) then
                CsFile.Delete(originPath)
            end
            CsFile.Move(tempPath, originPath)
        end
    end

    -- 清理
    self.ModuleUpdateInfo:DeleteAllCache()
    self:OnFinish()
end

return XModuleUpdateStateVersionUpdate
