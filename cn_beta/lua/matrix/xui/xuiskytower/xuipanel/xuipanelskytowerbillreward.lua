---@class XUiPanelSkyTowerBillReward : XUiNode 离线账单的一条收益条目
---@field private _Control XSkyTowerControl
local XUiPanelSkyTowerBillReward = XClass(XUiNode, "XUiPanelSkyTowerBillReward")

function XUiPanelSkyTowerBillReward:OnStart(onInfoClick)
    self.OnInfoClick = onInfoClick
    self:RegisterUiEvents()
end

---@param icon string 道具图标
---@param count number 数量
function XUiPanelSkyTowerBillReward:Refresh(icon, count)
    self.RImgIcon:SetRawImageEx(icon)
    self.TxtCount.text = math.floor(count)
end

function XUiPanelSkyTowerBillReward:RegisterUiEvents()
    if self.BtnRewardInfo then
        self.BtnRewardInfo:AddEventListener(handler(self, self.OnBtnRewardInfoClick))
    end
end

function XUiPanelSkyTowerBillReward:OnBtnRewardInfoClick()
    if self.OnInfoClick then
        self.OnInfoClick()
    end
end

return XUiPanelSkyTowerBillReward
