----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitPackageIndex.lua
-- description: 模块更新 - 初始化包内Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitPackageIndex : XModuleUpdateStateBase
local XModuleUpdateStateInitPackageIndex = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitPackageIndex", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitPackageIndex:OnEnter()
    local packageIndexTable, originIndexTable
    if self.UpdateManager:IsPackageCheckMode() then
        local originPath = self.ModuleUpdateInfo:GetOriginIndexPath()
        local tempPath = self.ModuleUpdateInfo:GetTempIndexPath()
        -- 包内index
        packageIndexTable, originIndexTable = self.UpdateManager:LoadIndexTableAndCheck(self.ModuleUpdateInfo.ApplicationIndex, originPath, tempPath)
    else
        packageIndexTable = self.UpdateManager:LoadIndexTable(self.ModuleUpdateInfo.ApplicationIndex, true)
    end
    
    -- 包体内判断
    self.UpdateManager.OriginIndexTable = originIndexTable
    self.UpdateManager.PackageIndexTable = packageIndexTable
    self.UpdateManager:SetUpdateCheckTable(packageIndexTable)
    self.UpdateManager:SetTargetIndexMap(packageIndexTable)

    self:OnFinish()
end

return XModuleUpdateStateInitPackageIndex
