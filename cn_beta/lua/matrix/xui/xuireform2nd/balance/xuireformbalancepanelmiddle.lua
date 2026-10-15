local XUiReformBalanceWeightGrid = require("XUi/XUiReform2nd/Balance/XUiReformBalanceWeightGrid")
local XUiReformBalanceInfoGrid = require("XUi/XUiReform2nd/Balance/XUiReformBalanceInfoGrid")

-- 秤盘第一行最多摆的格数，超出部分放第二行
local WEIGHT_SLOT_ROW_CAPACITY = 4

-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformBalancePanelMiddle : XUiNode
---@field private _Control XReformControl
---@field TxtHopeWeightLeft UnityEngine.UI.Text
---@field TxtHopeWeightRight UnityEngine.UI.Text
---@field TxtPlus UnityEngine.UI.Text
---@field TagPerfect UnityEngine.RectTransform
---@field TagCompleted UnityEngine.RectTransform
---@field TagIncomplete UnityEngine.RectTransform
---@field GridWeightLeft UnityEngine.RectTransform
---@field GridWeightLeft2rd UnityEngine.RectTransform
---@field GridWeightRight UnityEngine.RectTransform
---@field GridWeightEnemy2rd UnityEngine.RectTransform
---@field TxtTips UnityEngine.UI.Text
---@field PanelBottomTipsLow UnityEngine.RectTransform
---@field PanelBottomTipsMiddle UnityEngine.RectTransform
---@field PanelBottomTipsHigh UnityEngine.RectTransform
---@field PanelBottomTipsEnemy UnityEngine.RectTransform
---@field PanelBottomTipsFail UnityEngine.RectTransform
---@field BtnInfo XUiComponent.XUiButton
---@field BtnBalanceInfo XUiComponent.XUiButton
---@field BtnSave XUiComponent.XUiButton
---@field BtnReset XUiComponent.XUiButton
---@field BtnRecommend XUiComponent.XUiButton
---@field PanelInfoDetail UnityEngine.RectTransform
---@field GridBalanceInfo UnityEngine.RectTransform
---@field GridBalanceInfoEnemy UnityEngine.RectTransform
---@field Collapsed UnityEngine.RectTransform
---@field Expanded UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- 4.9 天平主体（秤盘 + 配平状态 + 底部提示 + 操作按钮）
--- 天平倾斜表现、飘字动效由美术提供，程序侧只算档位与显隐
---@field Parent XUiReformBalance
local XUiReformBalancePanelMiddle = XClass(XUiNode, "XUiReformBalancePanelMiddle")

function XUiReformBalancePanelMiddle:OnStart()
    -- 秤盘四组格子：愿望一行/二行、代价一行/二行
    ---@type XUiReformBalanceWeightGrid[]
    self._WeightGridsLeft = {}
    ---@type XUiReformBalanceWeightGrid[]
    self._WeightGridsLeft2rd = {}
    ---@type XUiReformBalanceWeightGrid[]
    self._WeightGridsRight = {}
    ---@type XUiReformBalanceWeightGrid[]
    self._WeightGridsRight2rd = {}
    ---@type XUiReformBalanceInfoGrid[] 详情模式的愿望侧汇总
    self._InfoGridsWish = {}
    ---@type XUiReformBalanceInfoGrid[] 详情模式的代价侧汇总
    self._InfoGridsEnemy = {}
    local Side = self._Control:GetBalanceControl().Side
    ---@type number[]
    self._InfoGridDataWish = { Side.Wish }
    ---@type number[]
    self._InfoGridDataEnemy = { Side.Cost }
    self:RegisterComponentListeners()
    self:SetInfoDetailExpanded(false)
end

function XUiReformBalancePanelMiddle:RegisterComponentListeners()
    self.BtnSave:AddEventListener(handler(self, self.OnBtnSaveClick))
    self.BtnReset:AddEventListener(handler(self, self.OnBtnResetClick))
    self.BtnRecommend:AddEventListener(handler(self, self.OnBtnRecommendClick))
    self.BtnBalanceInfo:AddEventListener(handler(self, self.OnBtnBalanceInfoClick))
    self.BtnInfo:AddEventListener(handler(self, self.OnBtnInfoClick))
end

--- 全量刷新（砝码选择变更后由 MainView 驱动）
function XUiReformBalancePanelMiddle:Refresh()
    local balanceControl = self._Control:GetBalanceControl()
    local viewModelData = balanceControl:GetBalanceViewModel().Data

    self:RefreshMassText(balanceControl, viewModelData)
    self:RefreshWeightSlots(balanceControl)
    self:RefreshBalanceTag(balanceControl, viewModelData)
    self:RefreshBottomTips(balanceControl)
    self:RefreshInfoReddot()
    self:RefreshButtonState(balanceControl)
    self:RefreshInfoDetail()
end

--- 两侧质量数值：左"当前愿望/关卡最低"，右"当前代价"
function XUiReformBalancePanelMiddle:RefreshMassText(balanceControl, viewModelData)
    self.TxtHopeWeightLeft.text = XUiHelper.GetText("ReformBalanceWishMass", viewModelData.WishTotal, balanceControl:GetMinQuality())
    self.TxtHopeWeightRight.text = viewModelData.CostTotal

    local bonusMass = balanceControl:GetPerfectBonusMass()
    self.TxtPlus.gameObject:SetActiveEx(bonusMass > 0)
    if bonusMass > 0 then
        self.TxtPlus.text = "+" .. bonusMass
    end
end

--- 秤盘格按关卡槽位数克隆；超过第一行容量摆到第二行
function XUiReformBalancePanelMiddle:RefreshWeightSlots(balanceControl)
    local Side = balanceControl.Side
    self:RefreshWeightSlotsOneSide(balanceControl:GetSlotState(Side.Wish),
        self._WeightGridsLeft, self.GridWeightLeft, self._WeightGridsLeft2rd, self.GridWeightLeft2rd)
    self:RefreshWeightSlotsOneSide(balanceControl:GetSlotState(Side.Cost),
        self._WeightGridsRight, self.GridWeightRight, self._WeightGridsRight2rd, self.GridWeightEnemy2rd)
end

---@param slotStates table[] GetSlotState 结果
---@param gridsRow1 XUiReformBalanceWeightGrid[]
---@param templateRow1 UnityEngine.RectTransform
---@param gridsRow2 XUiReformBalanceWeightGrid[]
---@param templateRow2 UnityEngine.RectTransform
function XUiReformBalancePanelMiddle:RefreshWeightSlotsOneSide(slotStates, gridsRow1, templateRow1, gridsRow2, templateRow2)
    local rowStates = {}
    local rowStates2nd = {}
    for index = 1, #slotStates do
        if index <= WEIGHT_SLOT_ROW_CAPACITY then
            rowStates[#rowStates + 1] = slotStates[index]
        else
            rowStates2nd[#rowStates2nd + 1] = slotStates[index]
        end
    end
    XTool.UpdateDynamicItem(gridsRow1, rowStates, templateRow1, XUiReformBalanceWeightGrid, self)
    XTool.UpdateDynamicItem(gridsRow2, rowStates2nd, templateRow2, XUiReformBalanceWeightGrid, self)
end

--- 配平状态飘字；两侧天平都有砝码才显示
function XUiReformBalancePanelMiddle:RefreshBalanceTag(balanceControl, viewModelData)
    local Side = balanceControl.Side
    local hasWeightOnBothSides = #balanceControl:GetSelectedMassIds(Side.Wish) > 0
        and #balanceControl:GetSelectedMassIds(Side.Cost) > 0
    local BalanceResult = balanceControl:GetBalanceLogic().BalanceResult
    local balanceResult = viewModelData.BalanceResult
    self:SetBalanceTagActive(self.TagPerfect, hasWeightOnBothSides and balanceResult == BalanceResult.Perfect)
    self:SetBalanceTagActive(self.TagCompleted, hasWeightOnBothSides and balanceResult == BalanceResult.Normal)
    self:SetBalanceTagActive(self.TagIncomplete, hasWeightOnBothSides and balanceResult == BalanceResult.Unbalanced)
end

---@param tagNode UnityEngine.RectTransform
---@param isActive boolean
function XUiReformBalancePanelMiddle:SetBalanceTagActive(tagNode, isActive)
    tagNode.gameObject:SetActiveEx(false)
    tagNode.gameObject:SetActiveEx(isActive)
end

--- 底部提示五态互斥：数量不足 → 质量不足 → 低/中/高难度
function XUiReformBalancePanelMiddle:RefreshBottomTips(balanceControl)
    local isCountMet, needCharacterCount, needEnemyCount = balanceControl:IsMinSelectCountMet()
    if not isCountMet then
        -- 五个提示里只有数量提示需要运行时填文字（X/Y 是变数）
        self.TxtTips.text = XUiHelper.GetText("ReformBalanceNeedWeightCount", needCharacterCount, needEnemyCount)
        self:SetBottomTipsPanel(self.PanelBottomTipsEnemy)
        self.BtnInfo.gameObject:SetActiveEx(false)
        return
    end

    if not balanceControl:IsMinQualityMet() then
        self:SetBottomTipsPanel(self.PanelBottomTipsFail)
        self.BtnInfo.gameObject:SetActiveEx(false)
        return
    end

    -- 未配平的代价按最高档提示，即便难度判定只到低/中档
    local BalanceResult = balanceControl:GetBalanceLogic().BalanceResult
    local DifficultyResult = balanceControl:GetBalanceLogic().DifficultyResult
    local viewModelData = balanceControl:GetBalanceViewModel().Data
    local isHighestLevel = viewModelData.BalanceResult == BalanceResult.Unbalanced
        or viewModelData.DifficultyResult == DifficultyResult.Nightmare
    if isHighestLevel then
        self:SetBottomTipsPanel(self.PanelBottomTipsHigh)
    elseif viewModelData.DifficultyResult == DifficultyResult.Hard then
        self:SetBottomTipsPanel(self.PanelBottomTipsMiddle)
    else
        self:SetBottomTipsPanel(self.PanelBottomTipsLow)
    end
    self.BtnInfo.gameObject:SetActiveEx(true)
end

---@param activePanel UnityEngine.RectTransform
function XUiReformBalancePanelMiddle:SetBottomTipsPanel(activePanel)
    self.PanelBottomTipsLow.gameObject:SetActiveEx(activePanel == self.PanelBottomTipsLow)
    self.PanelBottomTipsMiddle.gameObject:SetActiveEx(activePanel == self.PanelBottomTipsMiddle)
    self.PanelBottomTipsHigh.gameObject:SetActiveEx(activePanel == self.PanelBottomTipsHigh)
    self.PanelBottomTipsEnemy.gameObject:SetActiveEx(activePanel == self.PanelBottomTipsEnemy)
    self.PanelBottomTipsFail.gameObject:SetActiveEx(activePanel == self.PanelBottomTipsFail)
end

--- BtnInfo 红点：气泡内容变了就亮，点过即消
function XUiReformBalancePanelMiddle:RefreshInfoReddot()
    local contentKey = self.Parent:GetBubbleDetailContentKey()
    if self._LastInfoContentKey ~= contentKey then
        self._LastInfoContentKey = contentKey
        self._IsInfoReddotOn = true
    end
    self.BtnInfo:ShowReddot(self._IsInfoReddotOn == true)
end

--- 进关按钮达标才可点；重置按钮无选中时置灰
function XUiReformBalancePanelMiddle:RefreshButtonState(balanceControl)
    local canEnter = balanceControl:IsMinSelectCountMet() and balanceControl:IsMinQualityMet()
    self.BtnSave:SetButtonState(canEnter and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnReset:SetButtonState(balanceControl:HasSelectedWeight() and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

--region 按钮回调

function XUiReformBalancePanelMiddle:OnBtnSaveClick()
    self.Parent:CloseTransientPanels()
    local balanceControl = self._Control:GetBalanceControl()

    local isCountMet, needCharacterCount, needEnemyCount = balanceControl:IsMinSelectCountMet()
    if not isCountMet then
        XUiManager.TipMsg(XUiHelper.GetText("ReformBalanceNeedWeightCount", needCharacterCount, needEnemyCount))
        return
    end
    if not balanceControl:IsMinQualityMet() then
        XUiManager.TipMsg(XUiHelper.GetText("ReformBalanceWishMassNotEnough"))
        return
    end

    -- 中/极高难度二次确认
    local DifficultyResult = balanceControl:GetBalanceLogic().DifficultyResult
    local difficultyResult = balanceControl:GetBalanceViewModel().Data.DifficultyResult
    if difficultyResult == DifficultyResult.Hard or difficultyResult == DifficultyResult.Nightmare then
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("ReformBalanceHighDifficultyConfirm"),
            XUiManager.DialogType.Normal, nil, handler(self, self.EnterBattleRoleRoom))
        return
    end
    self:EnterBattleRoleRoom()
end

function XUiReformBalancePanelMiddle:EnterBattleRoleRoom()
    self._Control:GetBalanceControl():EnterBattleRoleRoom()
end

function XUiReformBalancePanelMiddle:OnBtnResetClick()
    self.Parent:CloseTransientPanels()
    local balanceControl = self._Control:GetBalanceControl()
    if not balanceControl:HasSelectedWeight() then
        return
    end
    balanceControl:ClearSelectedWeights()
    self.Parent:OnWeightChanged()
    self.Parent:PlayAnimation("TabZero")
end

--- 莱亚的直觉：一键应用策划配置的保底方案
function XUiReformBalancePanelMiddle:OnBtnRecommendClick()
    self.Parent:CloseTransientPanels()
    local balanceControl = self._Control:GetBalanceControl()
    if balanceControl:IsRecommendApplied() then
        self.Parent:ShowRecommendBubble(XUiHelper.GetText("ReformBalanceRecommendSameTip"))
        return
    end

    if not balanceControl:HasSelectedWeight() then
        self:ApplyRecommend()
        return
    end

    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("ReformBalanceRecommendResetConfirm"),
        XUiManager.DialogType.Normal, nil, handler(self, self.ApplyRecommend))
end

function XUiReformBalancePanelMiddle:ApplyRecommend()
    self._Control:GetBalanceControl():ApplyRecommend()
    self.Parent:OnWeightChanged()
    self.Parent:ShowRecommendBubble(XUiHelper.GetText("ReformBalanceRecommendAppliedTip"))
end

function XUiReformBalancePanelMiddle:OnBtnBalanceInfoClick()
    self.Parent:CloseTransientPanels()
    self:SetInfoDetailExpanded(not self._IsInfoDetailExpanded)
end

--- 展开态与收起态互斥
---@param isExpanded boolean
function XUiReformBalancePanelMiddle:SetInfoDetailExpanded(isExpanded)
    self._IsInfoDetailExpanded = isExpanded
    self.PanelInfoDetail.gameObject:SetActiveEx(isExpanded)
    self.Collapsed.gameObject:SetActiveEx(not isExpanded)
    self.Expanded.gameObject:SetActiveEx(isExpanded)
    if isExpanded then
        self:RefreshInfoDetail()
    end
end

--- 详情内容：愿望/代价各一份汇总（展开时仍可选砝码，故随全量刷新更新）
function XUiReformBalancePanelMiddle:RefreshInfoDetail()
    if not self._IsInfoDetailExpanded then
        return
    end
    XTool.UpdateDynamicItem(self._InfoGridsWish, self._InfoGridDataWish, self.GridBalanceInfo, XUiReformBalanceInfoGrid, self)
    XTool.UpdateDynamicItem(self._InfoGridsEnemy, self._InfoGridDataEnemy, self.GridBalanceInfoEnemy, XUiReformBalanceInfoGrid, self)
end

--- 底部难度详情气泡
function XUiReformBalancePanelMiddle:OnBtnInfoClick()
    self.Parent:CloseTransientPanels()
    self._IsInfoReddotOn = false
    self.BtnInfo:ShowReddot(false)
    self.Parent:ShowBubbleDetail()
end

--endregion

return XUiReformBalancePanelMiddle
