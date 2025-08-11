---@class XBigWorldCourseAgency : XAgency
---@field private _Model XBigWorldCourseModel
local XBigWorldCourseAgency = XClass(XAgency, "XBigWorldCourseAgency")

function XBigWorldCourseAgency:OnInit()
    -- 初始化一些变量
end

function XBigWorldCourseAgency:InitRpc()
    -- 实现服务器事件注册
    self:AddRpc("NotifyBigWorldCourseData", handler(self, self.OnNotifyBigWorldCourseData))
    self:AddRpc("NotifyBigWorldCourseTaskCntProgress", handler(self, self.OnNotifyBigWorldCourseTaskCntProgress))
    self:AddRpc("NotifyBigWorldCourseExploreProgress", handler(self, self.OnNotifyBigWorldCourseExploreProgress))
end

function XBigWorldCourseAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XBigWorldCourseAgency:OnNotifyBigWorldCourseData(data)
    self._Model:UpdateData(data.Data)
end

function XBigWorldCourseAgency:OnNotifyBigWorldCourseTaskCntProgress(data)
    self._Model:UpdateVersionProgress(data.VersionId, data.TotalProgress)
end

function XBigWorldCourseAgency:OnNotifyBigWorldCourseExploreProgress(data)
    self._Model:UpdateExploreProgressData(data.VersionId, data.ExploreId, data.PoiId, data.Count)
end

function XBigWorldCourseAgency:CheckAllAchieved()
    return self:CheckAllTaskAchieved() or self:CheckAllExploreAchieved() or self:CheckAllNewCore()
end

function XBigWorldCourseAgency:CheckVersionAchieved(versionId)
    return self:CheckVersionTaskAchieved(versionId) or self:CheckVersionExploreAchieved(versionId) or
               self:CheckVersionNewCore(versionId)
end

function XBigWorldCourseAgency:CheckAllTaskAchieved()
    return self:CheckAllTaskRewardAchieved() or self:CheckAllTaskProgressRewardAchieved() or self:CheckAllTaskNew()
end

function XBigWorldCourseAgency:CheckVersionTaskAchieved(versionId)
    return self:CheckVersionTaskRewardAchieved(versionId) or self:CheckVersionTaskProgressRewardAchieved(versionId) or
               self:CheckVersionTaskNew(versionId)
end

function XBigWorldCourseAgency:CheckAllTaskRewardAchieved()
    local versionDataMap = self._Model:GetVersionDataMap()

    if not XTool.IsTableEmpty(versionDataMap) then
        for versionId, versionData in pairs(versionDataMap) do
            if self:CheckVersionTaskRewardAchieved(versionId) then
                return true
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckVersionTaskRewardAchieved(versionId)
    local contentId = self._Model:GetContentIdByVersionIdAndType(versionId, XEnumConst.BWCourse.ContentType.Task)

    if not XTool.IsNumberValid(contentId) then
        return false
    end

    local taskIds = self._Model:GetTaskIdsByContentId(contentId)

    if not XTool.IsTableEmpty(taskIds) then
        for _, taskId in pairs(taskIds) do
            if self._Model:CheckTaskUnlock(taskId) and XMVCA.XBigWorldService:CheckTaskAchieved(taskId) then
                return true
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckAllTaskNew()
    local versionDataMap = self._Model:GetVersionDataMap()

    if not XTool.IsTableEmpty(versionDataMap) then
        for versionId, versionData in pairs(versionDataMap) do
            if self:CheckVersionTaskNew(versionId) then
                return true
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckVersionTaskNew(versionId)
    local contentId = self._Model:GetContentIdByVersionIdAndType(versionId, XEnumConst.BWCourse.ContentType.Task)

    if not XTool.IsNumberValid(contentId) then
        return false
    end

    local taskIds = self._Model:GetTaskIdsByContentId(contentId)

    if not XTool.IsTableEmpty(taskIds) then
        for _, taskId in pairs(taskIds) do
            if self._Model:CheckTaskUnlock(taskId) and not self._Model:GetTaskRecord(taskId) then
                return true
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckAllTaskProgressRewardAchieved()
    local versionDataMap = self._Model:GetVersionDataMap()

    if not XTool.IsTableEmpty(versionDataMap) then
        for versionId, versionData in pairs(versionDataMap) do
            if self:CheckVersionTaskProgressRewardAchieved(versionId) then
                return true
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckVersionTaskProgressRewardAchieved(versionId)
    local contentId = self._Model:GetContentIdByVersionIdAndType(versionId, XEnumConst.BWCourse.ContentType.Task)

    if not XTool.IsNumberValid(contentId) then
        return false
    end

    local versionData = self._Model:GetVersionData(versionId)

    if versionData then
        local progressIds = self._Model:GetTaskProgressIdsByContentId(contentId)
        local currentProgress = versionData.TaskData.TotalProgress

        if not XTool.IsTableEmpty(progressIds) then
            for _, progressId in pairs(progressIds) do
                local progress = self._Model:GetBigWorldCourseTaskProgressRewardProgressById(progressId)

                if progress <= currentProgress and not versionData.TaskData:IsRewardAcquired(progressId) then
                    return true
                end
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckAllExploreAchieved()
    local versionDataMap = self._Model:GetVersionDataMap()

    if not XTool.IsTableEmpty(versionDataMap) then
        for versionId, versionData in pairs(versionDataMap) do
            if self:CheckVersionExploreAchieved(versionId) then
                return true
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckVersionExploreAchieved(versionId)
    local contentId = self._Model:GetContentIdByVersionIdAndType(versionId, XEnumConst.BWCourse.ContentType.Explore)

    if not XTool.IsNumberValid(contentId) then
        return false
    end

    local versionData = self._Model:GetVersionData(versionId)

    if versionData then
        if versionData.ExploreData.IsRewardComplete then
            return false
        end

        local exploreIds = self._Model:GetExploreIdsByContentId(contentId)

        if not XTool.IsTableEmpty(exploreIds) then
            for _, exploreId in pairs(exploreIds) do
                if self:CheckExploreAchieved(versionId, exploreId) then
                    return true
                end
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckVersionTotalExploreAchieved(versionId)
    local contentId = self._Model:GetContentIdByVersionIdAndType(versionId, XEnumConst.BWCourse.ContentType.Explore)

    if not XTool.IsNumberValid(contentId) then
        return false
    end

    local versionData = self._Model:GetVersionData(versionId)

    if versionData then
        if versionData.ExploreData.IsRewardComplete then
            return false
        end

        local exploreIds = self._Model:GetExploreIdsByContentId(contentId)

        if not XTool.IsTableEmpty(exploreIds) then
            for _, exploreId in pairs(exploreIds) do
                if not self:CheckExploreAchieved(versionId, exploreId) then
                    return false
                end
            end
        end

        return true
    end

    return false
end

function XBigWorldCourseAgency:CheckExploreAchieved(versionId, exploreId)
    local versionData = self._Model:GetVersionData(versionId)

    if versionData then
        if versionData.ExploreData:IsExploreAcquired(exploreId) then
            return false
        end

        local poiIds = self._Model:GetBigWorldCourseExplorePOIIdsByExploreId(exploreId)

        if not XTool.IsTableEmpty(poiIds) then
            for _, poiId in pairs(poiIds) do
                local poiCount = versionData.ExploreData:GetPOICount(exploreId, poiId)
                local totalCount = self._Model:GetBigWorldCourseExplorePOITotalProgressById(poiId)

                if poiCount < totalCount then
                    return false
                end
            end

            return true
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckAllNewCore()
    local versionDataMap = self._Model:GetVersionDataMap()

    if not XTool.IsTableEmpty(versionDataMap) then
        for versionId, versionData in pairs(versionDataMap) do
            if self:CheckVersionNewCore(versionId) then
                return true
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckVersionNewCore(versionId)
    local contentId = self._Model:GetContentIdByVersionIdAndType(versionId, XEnumConst.BWCourse.ContentType.Core)

    if not XTool.IsNumberValid(contentId) then
        return false
    end

    local coreIds = self._Model:GetCoreIdsByContentId(contentId)

    if not XTool.IsTableEmpty(coreIds) then
        for _, coreId in pairs(coreIds) do
            if self:CheckVersionCoreNewElements(versionId, coreId) then
                return true
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:CheckVersionCoreNewElements(versionId, coreId)
    local versionData = self._Model:GetVersionData(versionId)

    if versionData then
        local elementIds = self._Model:GetBigWorldCourseCoreElementIdsByCoreId(coreId)

        if not XTool.IsTableEmpty(elementIds) then
            for _, elementId in pairs(elementIds) do
                if not versionData.CoreData:IsElementBrowsed(elementId) then
                    return true
                end
            end
        end
    end

    return false
end

function XBigWorldCourseAgency:GetCourseTotalTaskProgress()
    local cur, total = 0, 0
    local tasks = self._Model:GetBigWorldCourseTaskConfigs()
    for taskId, _ in pairs(tasks) do
        if XMVCA.XBigWorldService:CheckTaskFinish(taskId) then
            cur = cur + 1
        end
        total = total + 1
    end
    return cur, total
end

return XBigWorldCourseAgency
