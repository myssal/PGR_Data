---@class XAnniversaryPreHeatingControl : XControl
---@field private _Model XAnniversaryPreHeatingModel
local XAnniversaryPreHeatingControl = XClass(XControl, "XAnniversaryPreHeatingControl", true)
local XAnniversaryPreHeatingEnumConst = require("XModule/XAnniversaryPreHeating/XAnniversaryPreHeatingEnumConst")

local ClientConfigKey = {
    RemainTime = "RemainTime",
    WatchTimes = "WatchTimes",
    GroupUnlockTips = "GroupUnlockTips",
    BannerInterval = "BannerInterval",
    TextScrollSpeed = "TextScrollSpeed",
    TextScrollWait = "TextScrollWait",
}

local TableKey = {
    AnniversaryPreHeatingClientConfig = {
        DirPath = XConfigUtil.DirectoryType.Client,
        ReadFunc = XConfigUtil.ReadType.String,
        Identifier = "Key",
    },
    AnniversaryPreHeatingContent = {
        DirPath = XConfigUtil.DirectoryType.Share,
        ReadFunc = XConfigUtil.ReadType.Int,
        Identifier = "Id",
    },
}

function XAnniversaryPreHeatingControl:OnInit()
    self:InitConfigByTabKey("MiniActivity/AnniversaryPreHeating", TableKey)
end

function XAnniversaryPreHeatingControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XAnniversaryPreHeatingControl:RemoveAgencyEvent()

end

function XAnniversaryPreHeatingControl:OnRelease()
end

---@return table<number, XTableAnniversaryPreHeatingContent>
function XAnniversaryPreHeatingControl:GetContentConfigs()
    return self:GetAllConfigByTabKey(TableKey.AnniversaryPreHeatingContent) or {}
end

---@return XTableAnniversaryPreHeatingContent
function XAnniversaryPreHeatingControl:GetContentConfigById(id, noTips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.AnniversaryPreHeatingContent, id, noTips)
end

---@return XTableAnniversaryPreHeatingContent[]
function XAnniversaryPreHeatingControl:GetContentConfigsByGroupId(groupId)
    if not XTool.IsNumberValid(groupId) then
        return {}
    end

    local groupConfig = self:GetAgency():GetGroupConfigById(groupId, true)
    if not groupConfig or XTool.IsTableEmpty(groupConfig.ContentIds) then
        return {}
    end

    local configs = {}
    for _, contentId in ipairs(groupConfig.ContentIds) do
        if contentId > 0 then
            local config = self:GetContentConfigById(contentId)
            if config then
                configs[#configs + 1] = config
            end
        end
    end

    return configs
end

function XAnniversaryPreHeatingControl:GetActivityId()
    return self._Model:GetActivityId()
end

function XAnniversaryPreHeatingControl:IsActivityInTime()
    return self:GetAgency():IsActivityInTime(self:GetActivityId())
end

function XAnniversaryPreHeatingControl:GetRemainTimeText()
    local activityId = self:GetActivityId()
    local activityConfig = self:GetAgency():GetActivityConfigById(activityId, true)
    if not activityConfig then
        return ""
    end

    local endTime = XFunctionManager.GetEndTimeByTimeId(activityConfig.TimeId)
    local remainTime = math.max(endTime - XTime.GetServerNowTimestamp(), 0)
    local remainTimeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
    return XUiHelper.FormatText(self:_GetClientConfigText(ClientConfigKey.RemainTime), remainTimeText)
end

function XAnniversaryPreHeatingControl:GetWatchTimesText(readCount, totalCount)
    return XUiHelper.FormatText(self:_GetClientConfigText(ClientConfigKey.WatchTimes), "<color=#60AAFF>"..readCount.."</color>", totalCount)
end

function XAnniversaryPreHeatingControl:GetBannerInterval()
    local interval = tonumber(self:_GetClientConfigText(ClientConfigKey.BannerInterval))
    return interval and interval > 0 and interval or 5
end

function XAnniversaryPreHeatingControl:GetTextScrollSpeed()
    local speed = tonumber(self:_GetClientConfigText(ClientConfigKey.TextScrollSpeed))
    return speed and speed > 0 and speed or 30
end

function XAnniversaryPreHeatingControl:GetTextScrollWait()
    local waitSeconds = tonumber(self:_GetClientConfigText(ClientConfigKey.TextScrollWait))
    return waitSeconds and waitSeconds >= 0 and waitSeconds or 2
end

---@return XTableAnniversaryPreHeatingGroup[]
function XAnniversaryPreHeatingControl:GetGroupConfigsByActivityId(activityId)
    return self:GetAgency():GetGroupConfigsByActivityId(activityId)
end

function XAnniversaryPreHeatingControl:IsGroupInTime(groupId)
    return self:GetAgency():IsGroupInTime(groupId)
end

function XAnniversaryPreHeatingControl:GetGroupUnlockTips(groupId)
    local groupConfig = self:GetAgency():GetGroupConfigById(groupId)
    local startTime = XFunctionManager.GetStartTimeByTimeId(groupConfig.TimeId)
    local remainTime = math.max(startTime - XTime.GetServerNowTimestamp(), 0)
    local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.DEFAULT)
    return XUiHelper.FormatText(self:_GetClientConfigText(ClientConfigKey.GroupUnlockTips), timeText)
end

function XAnniversaryPreHeatingControl:IsContentRead(groupId, contentId)
    return self._Model:IsContentRead(groupId, contentId)
end

function XAnniversaryPreHeatingControl:IsGroupAllContentRead(groupId)
    return self:GetAgency():IsGroupAllContentRead(groupId)
end

function XAnniversaryPreHeatingControl:GetGroupWatchRewardState(groupId)
    return self:GetAgency():GetGroupWatchRewardState(groupId)
end

---@param groupId number
---@param contentId number AnniversaryPreHeatingContent表主键
---@param callback fun(groupId:number, contentId:number)|nil
function XAnniversaryPreHeatingControl:AnniversaryPreHeatingReadRequest(groupId, contentId, callback)
    -- 如果选中的Cotent已经读过了就不需要发协议了
    if not self:IsGroupInTime(groupId) or self:IsContentRead(groupId, contentId) then
        return
    end

    local request = {
        GroupId = groupId,
        ContentId = contentId,
    }
    XNetwork.Call("AnniversaryPreHeatingReadRequest", request, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        self._Model:SetContentRead(groupId, contentId)
        if callback then
            callback(groupId, contentId)
        end
    end)
end

---@param groupId number
---@param callback fun(groupId:number, rewardId:number)|nil
function XAnniversaryPreHeatingControl:AnniversaryPreHeatingRewardRequest(groupId, callback)
    if self:GetGroupWatchRewardState(groupId) ~= XAnniversaryPreHeatingEnumConst.WatchRewardState.CanReceive then
        return
    end

    local groupConfig = self:GetAgency():GetGroupConfigById(groupId, true)
    if not groupConfig then
        return
    end

    local request = {
        GroupId = groupId,
    }
    XNetwork.Call("AnniversaryPreHeatingRewardRequest", request, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end

        self._Model:SetGroupRewardReceived(groupId)
        if callback then
            callback(groupId, groupConfig.RewardId)
        end
        XUiManager.OpenUiObtain(response.RewardGoodsList)
    end)
end

function XAnniversaryPreHeatingControl:CheckGroupRedPoint(groupId)
    if not self:IsGroupInTime(groupId) then
        return false
    end

    return not self:IsGroupAllContentRead(groupId)
        or self:GetGroupWatchRewardState(groupId) == XAnniversaryPreHeatingEnumConst.WatchRewardState.CanReceive
end

function XAnniversaryPreHeatingControl:GetGroupReadProgress(groupId)
    local contentConfigs = self:GetContentConfigsByGroupId(groupId)
    local readCount = 0

    for _, contentConfig in ipairs(contentConfigs) do
        if self:IsContentRead(groupId, contentConfig.Id) then
            readCount = readCount + 1
        end
    end

    return readCount, #contentConfigs
end

function XAnniversaryPreHeatingControl:GetRewardList(rewardId)
    if not XTool.IsNumberValid(rewardId) then
        return {}
    end

    return XRewardManager.GetRewardList(rewardId) or {}
end

function XAnniversaryPreHeatingControl:_GetClientConfigText(key, index)
    local config = self:GetConfigByTabKeyAndIdKey(TableKey.AnniversaryPreHeatingClientConfig, key)
    index = index or 1
    return config and config.Params and config.Params[index] or ""
end

return XAnniversaryPreHeatingControl
