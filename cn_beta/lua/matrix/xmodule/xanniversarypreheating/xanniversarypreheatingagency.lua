---@class XAnniversaryPreHeatingAgency : XAgency
---@field private _Model XAnniversaryPreHeatingModel
local XAnniversaryPreHeatingAgency = XClass(XAgency, "XAnniversaryPreHeatingAgency", false)

local TableKey = {
    AnniversaryPreHeatingActivity = {
        DirPath = XConfigUtil.DirectoryType.Share,
        ReadFunc = XConfigUtil.ReadType.Int,
        Identifier = "Id",
    },
    AnniversaryPreHeatingGroup = {
        DirPath = XConfigUtil.DirectoryType.Share,
        ReadFunc = XConfigUtil.ReadType.Int,
        Identifier = "Id",
    },
}

function XAnniversaryPreHeatingAgency:OnInit()
    self:InitConfigByTabKey("MiniActivity/AnniversaryPreHeating", TableKey)
    self.EnumConst = require("XModule/XAnniversaryPreHeating/XAnniversaryPreHeatingEnumConst")
end

function XAnniversaryPreHeatingAgency:InitRpc()
    self:AddRpc("NotifyAnniversaryPreHeatingData", handler(self, self.NotifyAnniversaryPreHeatingData))
end

function XAnniversaryPreHeatingAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region 读表相关 ，封装了XAgency的读表方法


function XAnniversaryPreHeatingAgency:NotifyAnniversaryPreHeatingData(notifyData)
    self._Model:SetServerData(notifyData.Data)
end

---@return table<number, XTableAnniversaryPreHeatingActivity>
function XAnniversaryPreHeatingAgency:GetActivityConfigs()
    return self:GetAllConfigByTabKey(TableKey.AnniversaryPreHeatingActivity) or {}
end

---@return XTableAnniversaryPreHeatingActivity
function XAnniversaryPreHeatingAgency:GetActivityConfigById(id, noTips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.AnniversaryPreHeatingActivity, id, noTips)
end

---@return table<number, XTableAnniversaryPreHeatingGroup>
function XAnniversaryPreHeatingAgency:GetGroupConfigs()
    return self:GetAllConfigByTabKey(TableKey.AnniversaryPreHeatingGroup) or {}
end

---@return XTableAnniversaryPreHeatingGroup
function XAnniversaryPreHeatingAgency:GetGroupConfigById(id, noTips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.AnniversaryPreHeatingGroup, id, noTips)
end

---@return XTableAnniversaryPreHeatingGroup[]
function XAnniversaryPreHeatingAgency:GetGroupConfigsByActivityId(activityId)
    local activityConfig = self:GetActivityConfigById(activityId)
    if not activityConfig or XTool.IsTableEmpty(activityConfig.GroupIds) then
        return {}
    end

    local configs = {}
    for _, groupId in ipairs(activityConfig.GroupIds) do
        if groupId > 0 then
            local config = self:GetGroupConfigById(groupId)
            if config then
                configs[#configs + 1] = config
            end
        end
    end

    return configs
end

function XAnniversaryPreHeatingAgency:IsGroupInTime(groupId)
    local groupConfig = self:GetGroupConfigById(groupId, true)
    if not groupConfig then
        return false
    end
    
    return XFunctionManager.CheckInTimeByTimeId(groupConfig.TimeId, false)
end

function XAnniversaryPreHeatingAgency:IsActivityInTime(activityId)
    activityId = activityId or self._Model:GetActivityId()
    if not XTool.IsNumberValid(activityId) then
        return false
    end

    local activityConfig = self:GetActivityConfigById(activityId, true)
    if not activityConfig then
        return false
    end
    
    return XFunctionManager.CheckInTimeByTimeId(activityConfig.TimeId, false)
end

--endregion 读表相关 ，封装了XAgency的读表方法

function XAnniversaryPreHeatingAgency:OpenMainUi()
    if not self:IsActivityInTime() then
        XUiManager.TipText("ActivityBranchNotOpen")
        return false
    end
    XLuaUiManager.Open("UiAnniversaryPreHeating")
    return true
end

-- 活动入口红点
function XAnniversaryPreHeatingAgency:CheckEntranceRedPoint()
    local activityId = self._Model:GetActivityId()
    if not self:IsActivityInTime(activityId) then
        return false
    end

    local groupConfigs = self:GetGroupConfigsByActivityId(activityId)
    for _, groupConfig in ipairs(groupConfigs) do
        local groupId = groupConfig.Id
        if self:IsGroupInTime(groupId) then
            if not self:IsGroupAllContentRead(groupId)
                or self:GetGroupWatchRewardState(groupId) == self.EnumConst.WatchRewardState.CanReceive then
                return true
            end
        end
    end

    return false
end

function XAnniversaryPreHeatingAgency:IsGroupAllContentRead(groupId)
    -- 读表的数据
    local groupConfig = self:GetGroupConfigById(groupId)
    if not groupConfig or XTool.IsTableEmpty(groupConfig.ContentIds) then
        return false
    end

    -- 表的数据与服务端的数据比较，判断是否有未读的
    for _, contentId in ipairs(groupConfig.ContentIds) do
        if not self._Model:IsContentRead(groupId, contentId) then
            return false
        end
    end

    return true
end

function XAnniversaryPreHeatingAgency:GetGroupWatchRewardState(groupId)
    if self._Model:IsGroupRewardReceived(groupId) then
        return self.EnumConst.WatchRewardState.Received
    end

    if self:IsGroupAllContentRead(groupId) then
        return self.EnumConst.WatchRewardState.CanReceive
    end

    return self.EnumConst.WatchRewardState.NotReceived
end

--endregion ----------public end----------

--region ----------private start----------


--endregion ----------private end----------

return XAnniversaryPreHeatingAgency
