local XUiReformBalancePanelSide = require("XUi/XUiReform2nd/Balance/XUiReformBalancePanelSide")
local XUiReformBalancePanelMiddle = require("XUi/XUiReform2nd/Balance/XUiReformBalancePanelMiddle")
local XUiReformBalanceBubbleDetail = require("XUi/XUiReform2nd/Balance/XUiReformBalanceBubbleDetail")
local XUiReformBalanceBubbleRecommend = require("XUi/XUiReform2nd/Balance/XUiReformBalanceBubbleRecommend")
local XUiReformBalancePreSelectDetail = require("XUi/XUiReform2nd/Balance/XUiReformBalancePreSelectDetail")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalance : XLuaUi
---@field _Control XReformControl
---@field BtnHelp XUiComponent.XUiButton
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field BtnEnvironment XUiComponent.XUiButton
---@field BtnCloseBubble XUiComponent.XUiButton
---@field TextEnvironmentName UnityEngine.UI.Text
---@field PanelLeft UiObject
---@field PanelRight UiObject
---@field PanelMiddle UiObject
---@field PanelBubbleDetail UiObject
---@field PanelBubbleRecommendTips UiObject
---@field PreSelectDetailLeft UiObject
---@field PreSelectDetailRight UiObject
-- ======== AUTO FIELDS END ========
--- 4.9 天平配平主界面
--- 三大区：左愿望砝码列表 / 中天平主体 / 右代价砝码列表
--- 砝码选择变更统一走 OnWeightChanged，各面板直接回调刷新（同界面内不用事件）
--- 封存时随 Balance 天平功能一并删除
local XUiReformBalance = XLuaUiManager.Register(XLuaUi, "UiReformBalance")

function XUiReformBalance:OnAwake()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "ReformHelp")
    self.BtnEnvironment:AddEventListener(handler(self, self.OnBtnEnvironmentClick))
    self.BtnCloseBubble:AddEventListener(handler(self, self.OnBtnCloseBubbleClick))
    self:InitChildUis()
end

function XUiReformBalance:InitChildUis()
    local Side = self._Control:GetBalanceControl().Side
    ---@type XUiReformBalancePanelSide
    self._PanelLeft = XUiReformBalancePanelSide.New(self.PanelLeft, self, Side.Wish)
    ---@type XUiReformBalancePanelSide
    self._PanelRight = XUiReformBalancePanelSide.New(self.PanelRight, self, Side.Cost)
    ---@type XUiReformBalancePanelMiddle
    self._PanelMiddle = XUiReformBalancePanelMiddle.New(self.PanelMiddle, self)
    ---@type XUiReformBalanceBubbleDetail
    self._BubbleDetail = XUiReformBalanceBubbleDetail.New(self.PanelBubbleDetail, self)
    ---@type XUiReformBalanceBubbleRecommend
    self._BubbleRecommend = XUiReformBalanceBubbleRecommend.New(self.PanelBubbleRecommendTips, self)
    ---@type XUiReformBalancePreSelectDetail 词缀预选气泡左右各一份，按点击的列表侧显示
    self._PreSelectDetailLeft = XUiReformBalancePreSelectDetail.New(self.PreSelectDetailLeft, self)
    ---@type XUiReformBalancePreSelectDetail
    self._PreSelectDetailRight = XUiReformBalancePreSelectDetail.New(self.PreSelectDetailRight, self)

    self._BubbleDetail:Close()
    self._BubbleRecommend:Close()
    self._PreSelectDetailLeft:Close()
    self._PreSelectDetailRight:Close()
end

---@param stage XReform2ndStage
function XUiReformBalance:OnStart(stage)
    self._Stage = stage
    local stageId = stage:GetId()
    self._Control:GetBalanceControl():EnterMainUI(stageId)
    self._PanelLeft:Refresh(stageId)
    self._PanelRight:Refresh(stageId)
    self:RefreshEnvironment()
    self:RefreshAll()

    XLuaUiManager.Open("UiReformEnterTips")
end

function XUiReformBalance:OnDestroy()
    self._Control:GetBalanceControl():ExitMainUI()
end

function XUiReformBalance:RefreshEnvironment()
    self.BtnEnvironment:SetName(self._Control:GetStageEnvironmentName(self._Stage))
end

--region 刷新驱动

--- 砝码选择变更后的统一刷新入口（各子面板调）
function XUiReformBalance:OnWeightChanged()
    self._Control:GetBalanceControl():RefreshBalanceResult()
    self:RefreshAll()
end

function XUiReformBalance:RefreshAll()
    local balanceControl = self._Control:GetBalanceControl()
    -- 词缀列表可能因羁绊解锁新增条目，需重建后再刷状态
    self._PanelLeft:RefreshAffixList()
    self._PanelRight:RefreshAffixList()
    self._PanelLeft:RefreshCellState(balanceControl)
    self._PanelRight:RefreshCellState(balanceControl)
    self._PanelMiddle:Refresh()
end

--endregion

--region 气泡

--- 词缀进入预选态时显示详情气泡
---@param cell XUiReformBalanceAffixCell
function XUiReformBalance:OnAffixPreSelect(cell)
    local detail = self._PreSelectDetailLeft
    if cell.Parent:IsCostSide() then
        detail = self._PreSelectDetailRight
    end
    detail:ShowAffix(cell:GetAffixId(), cell.Transform)
end

function XUiReformBalance:OnAffixPreSelectClear()
    self._PreSelectDetailLeft:Close()
    self._PreSelectDetailRight:Close()
end

--- 收起临时浮层：词缀预选气泡 + 难度详情气泡
function XUiReformBalance:CloseTransientPanels()
    self._PanelLeft:ClearPreSelect()
    self._PanelRight:ClearPreSelect()
    self._BubbleDetail:Close()
end

function XUiReformBalance:ShowBubbleDetail()
    self._BubbleDetail:Refresh()
    self._BubbleDetail:Open()
end

--- 难度详情气泡的内容标识
---@return number
function XUiReformBalance:GetBubbleDetailContentKey()
    return self._BubbleDetail:GetContentKey()
end

---@param desc string
function XUiReformBalance:ShowRecommendBubble(desc)
    self._BubbleRecommend:ShowTips(desc)
end

--endregion

--- 点击空白：收起预选态与难度详情气泡（需求 §2③）
function XUiReformBalance:OnBtnCloseBubbleClick()
    self:CloseTransientPanels()
end

function XUiReformBalance:OnBtnEnvironmentClick()
    self:CloseTransientPanels()
    self._Control:OpenUiEnvironment(self._Stage)
end

return XUiReformBalance
