---@class XUiGridJourneyReward : XUiNode
local XUiGridJourneyReward = XClass(XUiNode, "XUiGridJourneyReward")

function XUiGridJourneyReward:OnStart()
    self.Btn.CallBack = function() self:OnBtnClick()  end
end

function XUiGridJourneyReward:GetCurDrawId()
    local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(self.Parent.Data:GetId())
    local drawId = drawInfo.Id
    return drawId
end

function XUiGridJourneyReward:Refresh(rewardId, index)
    self.RewardId = rewardId
    self.Index = index
    local drawId = self:GetCurDrawId()

    local rewardDatas = XRewardManager.GetRewardList(rewardId) or {}
    ---@type XUiGridCommon
    local grid = XUiHelper.XUiGridCommon(self.Parent.Parent, self.Grid256New)
    grid:Refresh(rewardDatas[1])

    local num = self.Parent.CurCanLiverRewardCfg.Schedules[index]
    self.Btn:SetNameByGroup(0, num)

    -- 当总Count大于等于当前num且 服务端侧的Schedules数据里的已领取的奖励下标RewardIndex不存在当前下标，则为可领取状态需要红点
    local scheduleData = XDataCenter.DrawManager.GetScheduleDataByDrawId(drawId)
    local isShowRed = scheduleData and scheduleData.DrawCount >= num and not (table.contains(scheduleData.RewardIndex, index - 1)) -- RewardIndex里的下标是csharp的
    self.Btn:ShowReddot(isShowRed)
    grid:SetBtnActive(not isShowRed)
end

function XUiGridJourneyReward:OnBtnClick()
    local drawId = self:GetCurDrawId()
    local scheduleData = XDataCenter.DrawManager.GetScheduleDataByDrawId(drawId)
    local num = self.Parent.CurCanLiverRewardCfg.Schedules[self.Index]
    local isShowRed = scheduleData and scheduleData.DrawCount >= num and not (table.contains(scheduleData.RewardIndex, self.Index - 1))
    if not isShowRed then
        return
    end

    -- index偏移量csharp
    XDataCenter.DrawManager.DrawCanLiverRewardRequest(drawId, self.Index - 1, function(rewardGoodsList)
        local horizontalNormalizedPosition = 0
        XUiManager.OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)
        self.Parent:RefreshJourneyRewardDynamicTable()
    end)
end

return XUiGridJourneyReward