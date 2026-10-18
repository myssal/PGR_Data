----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitPackageIndexMerge.lua
-- description: 模块更新 - 初始化包内Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsFile = CS.System.IO.File
local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitPackageIndexMerge : XModuleUpdateStateBase
local XModuleUpdateStateInitPackageIndexMerge = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitPackageIndexMerge", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitPackageIndexMerge:OnEnter()
    -- 包体内判断
    local originIndexTable = self.UpdateManager.OriginIndexTable
    local packageIndexTable = self.UpdateManager.PackageIndexTable
    if originIndexTable == nil or next(originIndexTable) == nil then
        self:OnFinish()
        return
    end

    XLaunchConst.PackageUpdate = true
    local needDownload = {}
    local XFileInfoFlagIndex = XLaunchConst.XFileInfoFlagIndex
    for fileName, packageInfo in pairs(packageIndexTable) do
        local originInfo = originIndexTable[fileName]
        if originInfo and originInfo[XFileInfoFlagIndex] == 0 and packageInfo[XFileInfoFlagIndex] == 1 then
            needDownload[fileName] = true
        end
    end
    self.UpdateManager.PackageNeedDownload = needDownload

    self:OnFinish()
end

return XModuleUpdateStateInitPackageIndexMerge
