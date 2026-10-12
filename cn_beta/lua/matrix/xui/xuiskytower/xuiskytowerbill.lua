local XUiPanelSkyTowerBillReward = require("XUi/XUiSkyTower/XUiPanel/XUiPanelSkyTowerBillReward")

---@class XUiSkyTowerBill : XLuaUi
---@field private _Control XSkyTowerControl
local XUiSkyTowerBill = XLuaUiManager.Register(XLuaUi, "UiSkyTowerBill")

--region 生命周期
function XUiSkyTowerBill:OnAwake()
    self.BtnReceive.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiSkyTowerBill:OnStart()
    -- 累计收入条目
    ---@type XUiPanelSkyTowerBillReward
    self._PanelAllReward = XUiPanelSkyTowerBillReward.New(self.PanelAllReward, self)
    -- 角色券条目
    ---@type XUiPanelSkyTowerBillReward
    self._PanelAutoReward = XUiPanelSkyTowerBillReward.New(self.PanelAutoReward, self, handler(self, self.OnBtnRewardInfoClick))
end

function XUiSkyTowerBill:OnEnable()
    self:RefreshView()
end

function XUiSkyTowerBill:OnDestroy()
    self._Control:CloseOfflineBill()
end
--endregion

--region 事件
function XUiSkyTowerBill:OnGetLuaEvents()
    return {
        XEventId.EVENT_SKY_TOWER_BILL_CHANGE,
    }
end

function XUiSkyTowerBill:OnNotify(evt)
    if evt == XEventId.EVENT_SKY_TOWER_BILL_CHANGE then
        self:RefreshView()
    end
end
--endregion

--region 界面刷新
function XUiSkyTowerBill:RefreshView()
    self.TxtMassage.text = self._Control:GetSubTimeTip(self._Control:GetOfflineSeconds())
    self:RefreshAllReward()
    self:RefreshAutoReward()
end

-- 离线金币收益，上限截断由服务端在下发前完成，客户端只展示
function XUiSkyTowerBill:RefreshAllReward()
    local count = self._Control:GetOfflineBill()
    if count <= 0 then
        self._PanelAllReward:Close()
        return
    end
    self._PanelAllReward:Open()
    self._PanelAllReward:Refresh(self._Control:GetItemIcon(XMVCA.XSkyTower.ItemId.SkyTowerCoin), count)
end

-- 角色券为服务端下发的离线实际收益，仅展示
function XUiSkyTowerBill:RefreshAutoReward()
    local count = self._Control:GetOfflineCharacterLvUpItemCount()
    if count <= 0 then
        self._PanelAutoReward:Close()
        return
    end
    self._PanelAutoReward:Open()
    self._PanelAutoReward:Refresh(self._Control:GetItemIcon(XMVCA.XSkyTower.ItemId.SkyTowerUpgradeCoin), count)
end
--endregion

--region 按钮
function XUiSkyTowerBill:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnReceive:AddEventListener(handler(self, self.OnBtnReceiveClick))
    self.BtnDetailClose:AddEventListener(handler(self, self.OnBtnDetailCloseClick))
end

function XUiSkyTowerBill:OnBtnCloseClick()
    self:Close()
end

-- 离线收益服务端在下发账单时已直接入账，这里没有领取动作
function XUiSkyTowerBill:OnBtnReceiveClick()
    self:Close()
end

function XUiSkyTowerBill:OnBtnDetailCloseClick()
    self.PanelBubbleDetail.gameObject:SetActiveEx(false)
end

function XUiSkyTowerBill:OnBtnRewardInfoClick()
    local goldBase = self._Control:GetIntConfigValue("GoldTransCharaLvUpItemBase")
    local characterCount = self._Control:GetIntConfigValue("GoldTransCharaLvUpItemNum")
    local iconCoin = self._Control:GetItemIcon(XMVCA.XSkyTower.ItemId.SkyTowerCoin)
    local iconUpgradeCoin = self._Control:GetItemIcon(XMVCA.XSkyTower.ItemId.SkyTowerUpgradeCoin)

    self.RImgIconBonus1:SetRawImageEx(iconCoin)
    self.RImgIconBonus2:SetRawImageEx(iconUpgradeCoin)
    self.TxtTipCost1.text = self._Control:GetClientConfigText("ExamineGoldBubbleText", 1, goldBase)
    self.TxtTipCost2.text = self._Control:GetClientConfigText("ExamineGoldBubbleText", 2, characterCount)

    self.PanelBubbleDetail.gameObject:SetActiveEx(true)
end
--endregion

return XUiSkyTowerBill
