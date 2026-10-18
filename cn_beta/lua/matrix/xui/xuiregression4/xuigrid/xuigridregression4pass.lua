
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiGridRegression4Pass: XUiNode
local XUiGridRegression4Pass = XClass(XUiNode, "XUiGridRegression4Pass")

function XUiGridRegression4Pass:OnStart()
    self.RootUi = self.Parent.RootUi
    -- 双轨：GridRewardNormal/GridRewardAdvanced 本身是 Grid256New 实例，状态图标注入在各自实例的 UiObject 上
    self.TrackUis = { self.GridRewardNormal, self.GridRewardAdvanced }
    self.TrackIcons = {}
    self.GridObjs = {}
    self.SlotDatas = {}
    for i, ui in ipairs(self.TrackUis) do
        self.TrackIcons[i] = XTool.InitUiObjectByUi({}, ui)
        local grid = XUiGridCommon.New(self.RootUi, ui)
        self.GridObjs[i] = grid
        -- 首次创建时绑定一次，点击时读取 SlotDatas 决定行为
        local slotIndex = i
        grid:SetClickCallback(function() self:OnSlotClick(slotIndex) end)
    end
end

---@param levelInfo table 挡位配置（Level/TotalExp）
---@param fillAmount number 本格进度条填充比例
function XUiGridRegression4Pass:Refresh(levelInfo, fillAmount)
    if not levelInfo then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)

    self.TxtNotReachedLevel.text = tostring(levelInfo.TotalExp)
    self.ImgProgress.fillAmount = fillAmount
    if self.ImgProgress1 then
        self.ImgProgress1.fillAmount = fillAmount
        if levelInfo.Level == 1 then
            self.ImgProgressBg.gameObject:SetActiveEx(false)
            self.ImgProgressBg1.gameObject:SetActiveEx(true)
        else
            self.ImgProgressBg.gameObject:SetActiveEx(true)
            self.ImgProgressBg1.gameObject:SetActiveEx(false)
        end
    end

    local typeInfos = self:GetPassportViewModel():GetPassportTypeInfos()
    for i, typeInfo in ipairs(typeInfos) do
        self:RefreshTrack(i, typeInfo, levelInfo)
    end
end

function XUiGridRegression4Pass:RefreshTrack(slotIndex, typeInfo, levelInfo)
    local viewModel = self:GetPassportViewModel()
    local rewardInfo = viewModel:GetPassportRewardInfo(typeInfo.Id, levelInfo.Level)
    local rewardList = XRewardManager.GetRewardList(rewardInfo.RewardId)
    local icons = self.TrackIcons[slotIndex]
    local grid = self.GridObjs[slotIndex]

    local isReceived = viewModel:CheckReceive(rewardInfo.Id, typeInfo.Id)
    local isCanReceive = viewModel:CheckAvailable(levelInfo.Level, rewardInfo.Id, typeInfo.Id)

    -- 只更新数据，不重新绑定按钮
    local slotData = self.SlotDatas[slotIndex]
    if not slotData then
        slotData = {}
        self.SlotDatas[slotIndex] = slotData
    end
    slotData.RewardId = rewardInfo.Id
    slotData.IsReceived = isReceived
    slotData.IsCanReceive = isCanReceive

    -- 先刷奖励图标（XUiGridCommon.Refresh 内部 ResetUi 会重置 ImgReceived 等节点），再设置状态图标
    grid:Refresh(rewardList and rewardList[1])

    -- 各状态独立显示（购买高级版后与基础版叠加，互不压制）
    icons.ImgReceived.gameObject:SetActiveEx(isReceived)
    icons.ImgCanReceive.gameObject:SetActiveEx(isCanReceive)
    if not typeInfo.IsFree then
        icons.ImgLock.gameObject:SetActiveEx(not viewModel:IsPassportBuy(typeInfo.Id))
    end
end

--- 点击轨道奖励：可领取则领取，否则走默认的物品详情
function XUiGridRegression4Pass:OnSlotClick(slotIndex)
    local slotData = self.SlotDatas[slotIndex]
    if slotData and not slotData.IsReceived and slotData.IsCanReceive then
        self._Control:RequestSinglePassportReward(slotData.RewardId)
        return
    end
    local grid = self.GridObjs[slotIndex]
    if grid then
        grid:OnBtnClickClick()
    end
end

function XUiGridRegression4Pass:GetPassportViewModel()
    return self._Control:GetMainViewModel():GetPassportViewModel()
end

return XUiGridRegression4Pass
