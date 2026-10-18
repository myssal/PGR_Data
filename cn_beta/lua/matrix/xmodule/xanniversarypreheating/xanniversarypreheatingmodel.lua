---@class XAnniversaryPreHeatingModel : XModelBase
local XAnniversaryPreHeatingModel = XClass(XModelBase, "XAnniversaryPreHeatingModel")

function XAnniversaryPreHeatingModel:OnInit()
    self:ResetAll()
end

function XAnniversaryPreHeatingModel:ClearPrivate()
end

function XAnniversaryPreHeatingModel:ResetAll()
    self._ActivityId = 0
    self._GroupDataMap = {}
end

---@param data XAnniversaryPreHeatingDataDb
function XAnniversaryPreHeatingModel:SetServerData(data)
    self._ActivityId = data and data.ActivityId or 0
    self._GroupDataMap = {}

    if not data or not data.AnniversaryPreHeatingGroupDatas then
        return
    end

    for _, groupData in ipairs(data.AnniversaryPreHeatingGroupDatas) do
        local groupId = groupData.GroupId or 0
        if groupId > 0 then
            self._GroupDataMap[groupId] = {
                GroupId = groupId,
                ReadContentIds = groupData.ReadContentIds or {},
                RewardReceived = groupData.RewardReceived,
            }
        end
    end
end

function XAnniversaryPreHeatingModel:GetActivityId()
    return self._ActivityId
end

function XAnniversaryPreHeatingModel:HasActivityData()
    return self._ActivityId > 0
end

function XAnniversaryPreHeatingModel:GetGroupDataById(groupId)
    return self._GroupDataMap[groupId]
end

-- 用表中的contentid与服务端下发的contentid判断，判断这条content有没有被读
function XAnniversaryPreHeatingModel:IsContentRead(groupId, contentId)
    local groupData = self:GetGroupDataById(groupId)
    return groupData and table.contains(groupData.ReadContentIds, contentId) or false
end

function XAnniversaryPreHeatingModel:SetContentRead(groupId, contentId)
    local groupData = self:_GetOrCreateGroupData(groupId)
    if table.contains(groupData.ReadContentIds, contentId) then
        return
    end

    table.insert(groupData.ReadContentIds, contentId)
    return
end

function XAnniversaryPreHeatingModel:IsGroupRewardReceived(groupId)
    local groupData = self:GetGroupDataById(groupId)
    return groupData and groupData.RewardReceived or false
end

function XAnniversaryPreHeatingModel:SetGroupRewardReceived(groupId)
    local groupData = self:_GetOrCreateGroupData(groupId)
    groupData.RewardReceived = true
end

--endregion ----------public end----------

--region ----------private start----------

function XAnniversaryPreHeatingModel:_GetOrCreateGroupData(groupId)
    local groupData = self._GroupDataMap[groupId]
    if not groupData then
        groupData = {
            GroupId = groupId,
            ReadContentIds = {},
            RewardReceived = false,
        }
        self._GroupDataMap[groupId] = groupData
    end

    return groupData
end

--endregion ----------private end----------


return XAnniversaryPreHeatingModel
