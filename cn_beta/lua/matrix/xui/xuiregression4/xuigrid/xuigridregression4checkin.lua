
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiGridRegression4CheckIn: XUiNode
local XUiGridRegression4CheckIn = XClass(XUiNode, "XUiGridRegression4CheckIn")

function XUiGridRegression4CheckIn:OnStart()
    self.RootUi = self.Parent.RootUi
    self.BtnClaim:AddEventListener(handler(self, self.OnBtnClaimClick))
    self.RewardContent = self.Grid256New.transform.parent
    self.RewardItems = {}
end

function XUiGridRegression4CheckIn:Refresh(signData)
    if not signData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.Data = signData

    local signViewModel = self:GetSignViewModel()
    local isReceived = signViewModel:CheckIsReceive(signData.Id)
    local isCanReceive = not isReceived and signViewModel:CheckIsSign(signData.Days)

    self.TxtNum.text = string.format("%02d", signData.Days)
    self:RefreshRewards(XRewardManager.GetRewardList(signData.RewardId), isReceived, isCanReceive)
end

function XUiGridRegression4CheckIn:RefreshRewards(rewardList, isReceived, isCanReceive)
    rewardList = rewardList or table.empty
    self.CurRewardList = rewardList
    self.CurIsReceived = isReceived
    self.CurIsCanReceive = isCanReceive
    self.RewardItems = XUiHelper.RefreshUiObjectList(self.RewardItems, self.RewardContent, self.Grid256New, #rewardList, handler(self, self.OnRewardItemRefresh))
end

function XUiGridRegression4CheckIn:OnRewardItemRefresh(index, item)
    if not item.GridCommon then
        item.GridCommon = XUiGridCommon.New(self.RootUi, item.GameObject)
        -- 可领取时点击奖励图标 = 领取当前页全部可领取，其余状态点击走默认物品详情弹窗
        item.GridCommon:SetProxyClickFunc(handler(self, self.OnRewardGridClick))
        -- ImgReceived / ImgCanReceive 为页面在 Grid256New 实例下单独添加的节点
        item.ImgReceived = XUiHelper.TryGetComponent(item.GameObject.transform, "ImgReceived")
        item.ImgCanReceive = XUiHelper.TryGetComponent(item.GameObject.transform, "ImgCanReceive")
    end
    item.GridCommon:Refresh(self.CurRewardList[index])
    if item.ImgReceived then
        item.ImgReceived.gameObject:SetActiveEx(self.CurIsReceived)
    end
    if item.ImgCanReceive then
        item.ImgCanReceive.gameObject:SetActiveEx(self.CurIsCanReceive)
    end
end

function XUiGridRegression4CheckIn:GetSignViewModel()
    return self._Control:GetMainViewModel():GetSignViewModel()
end

function XUiGridRegression4CheckIn:CheckCanReceive()
    local signViewModel = self:GetSignViewModel()
    return not signViewModel:CheckIsReceive(self.Data.Id) and signViewModel:CheckIsSign(self.Data.Days)
end

--- 领取本格奖励
function XUiGridRegression4CheckIn:OnBtnClaimClick()
    if not self:CheckCanReceive() then
        return
    end
    self._Control:RequestSignIn(self.Data.Id, handler(self, self.OnSignResult))
end

--- 奖励图标点击：可领取状态拦截默认详情弹窗，改为领取当前页全部可领取
function XUiGridRegression4CheckIn:OnRewardGridClick()
    if not self:CheckCanReceive() then
        return true
    end
    self.Parent:RequestAllCanReceive()
    return false
end

function XUiGridRegression4CheckIn:OnSignResult()
    self:Refresh(self.Data)
end

return XUiGridRegression4CheckIn
