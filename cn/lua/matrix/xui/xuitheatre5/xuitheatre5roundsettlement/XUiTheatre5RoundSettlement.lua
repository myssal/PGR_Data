--- 回合结算
---@class XUiTheatre5RoundSettlement: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5RoundSettlement = XLuaUiManager.Register(XLuaUi, 'UiTheatre5RoundSettlement')
local XUiPanelTheatre5SettleTopInfo = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiPanelTheatre5SettleTopInfo')
local XUiPanelTheatre5SettleSummary = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiPanelTheatre5SettleSummary')

function XUiTheatre5RoundSettlement:OnAwake()
    self.BtnShop:AddEventListener(handler(self, self.OnBtnShopClickEvent))
    self.BtnEnd:AddEventListener(handler(self, self.OnBtnEndClickEvent))
end

---@param resultData XDlcFightSettleData
function XUiTheatre5RoundSettlement:OnStart(resultData, summaryData)
    self.SummaryData = summaryData
    self.ResultData = resultData
    ---@type XUiPanelTheatre5SettleTopInfo
    self.PanelTop = XUiPanelTheatre5SettleTopInfo.New(self.PanelTop, self)
    self.PanelTop:ShowBattleResult(self.ResultData.ResultData.IsPlayerWin)
    self.PanelTop:RefreshAll()

    self.BtnShop.gameObject:SetActiveEx(not resultData.XAutoChessGameplayResult.IsFinish)
    self.BtnEnd.gameObject:SetActiveEx(resultData.XAutoChessGameplayResult.IsFinish)
    
    ---@type XUiPanelTheatre5SettleSummary
    self.PanelSummary = XUiPanelTheatre5SettleSummary.New(self.PanelLeft, self, self.SummaryData)
    self.PanelSummary:RefreshAllShow()
end

--region 事件回调

function XUiTheatre5RoundSettlement:OnBtnShopClickEvent()
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameModel.PVP then
        XMVCA.XTheatre5:RequestTheatre5EnterShop(function(success)
            if success then
                CsXUiManager.Instance:SetRevertAndReleaseLock(true)
                XLuaUiManager.CloseWithCallback('UiTheatre5RoundSettlement', function()
                    CS.StatusSyncFight.XFightClient.RequestExitFight()
                    XLuaUiManager.OpenWithCallback('UiTheatre5BattleShop', function()
                        CsXUiManager.Instance:SetRevertAndReleaseLock(false)
                    end)
                end)
            end
        end)
    else
        CsXUiManager.Instance:SetRevertAndReleaseLock(true)
        XLuaUiManager.CloseWithCallback('UiTheatre5RoundSettlement', function()
            CS.StatusSyncFight.XFightClient.RequestExitFight()
            XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_BATTLE_RESULT_EXIT, self.ResultData)
        end)
    end    
   
end

function XUiTheatre5RoundSettlement:OnBtnEndClickEvent()
    CsXUiManager.Instance:SetRevertAndReleaseLock(true)
    XLuaUiManager.CloseWithCallback('UiTheatre5RoundSettlement', function()
        CS.StatusSyncFight.XFightClient.RequestExitFight()
        XLuaUiManager.OpenWithCallback('UiTheatre5Settlement', function()
            CsXUiManager.Instance:SetRevertAndReleaseLock(false)
        end, self.ResultData)
    end)
end

--endregion



return XUiTheatre5RoundSettlement