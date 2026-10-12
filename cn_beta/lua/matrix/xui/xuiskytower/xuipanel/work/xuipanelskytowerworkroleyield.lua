---@class XUiPanelSkyTowerWorkRoleYield : XUiNode 安排角色
---@field Parent XUiSkyTowerWork
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerWorkRoleYield = XClass(XUiNode, "XUiPanelSkyTowerWorkRoleYield")

--region 生命周期
function XUiPanelSkyTowerWorkRoleYield:OnStart()
    ---@type UiObject[] 技能加成条
    self._AdditionList = {}
    ---@type UiObject[] 制作台材料消耗格复用池
    self._NeedList = {}
    -- TODO: TxtModel 的展示用途确认后再接入，当前连同 TxtModelSu 保持隐藏
    self.TxtModel.gameObject:SetActiveEx(false)
    self.TxtActiveDec.requestImage = XMVCA.XSkyTower.RichTextImageCallBack
    self:RegisterUiEvents()
end

function XUiPanelSkyTowerWorkRoleYield:OnEnable()
    self:RefreshView()
end
--endregion

--region 界面刷新
function XUiPanelSkyTowerWorkRoleYield:RefreshView()
    self._FloorId = self.Parent:GetFloorId()
    self._Index = self.Parent:GetIndex()
    local override, previewRatios = self.Parent:RefreshWorkPosPreview()
    local workInfo = self.Parent:GetWorkInfo()
    self._WorkType = workInfo.WorkType
    self._ProductId = workInfo.ProductId
    self._CharacterId = workInfo.CharacterId

    if not XTool.IsNumberValid(self._ProductId) or not XTool.IsNumberValid(self._CharacterId) then
        return
    end

    self:RefreshProduct()
    self:RefreshStaff()
    self:RefreshAddition(override, previewRatios)
    self:RefreshRate(override, previewRatios)
    self:RefreshSkillEffect(override, previewRatios)
    self:RefreshPredict(override ~= nil)
    self:RefreshButton(override ~= nil)
end

function XUiPanelSkyTowerWorkRoleYield:RefreshProduct()
    self.ImgTitleRole:SetSprite(self._Control:GetClientConfigValue("WorkTypeIcon", self._WorkType))
    self.TxtTitle.text = self._Control:GetClientConfigValue("WorkTypeName", self._WorkType)
    self.ImgQualityBg:SetSprite(self._Control:GetProductQualityIcon(self._WorkType, self._ProductId))
    self.RImgIcon:SetRawImageEx(self._Control:GetProductIcon(self._WorkType, self._ProductId))
    self.TxtProductName.text = self._Control:GetProductName(self._WorkType, self._ProductId)
    self.TxTinventoryNumber.text = self._Control:GetProductCountDesc(self._WorkType, self._ProductId, 2, true)
    local count = self._Control:GetProductCount(self._WorkType, self._ProductId)
    local limit = self._Control:GetProductLimit(self._WorkType, self._ProductId)
    self.ImgProgress.fillAmount = math.min(XUiHelper.GetFillAmountValue(count, limit), 1)
end

function XUiPanelSkyTowerWorkRoleYield:RefreshStaff()
    self.BtnHead:SetRawImageEx(self._Control:GetCharacterPortrait(self._CharacterId))
    self.TxtName.text = self._Control:GetCharacterName(self._CharacterId)
    -- 通用角色等级恒为1且不能培养
    local isUniversal = self._Control:GetCharacterIsUniversal(self._CharacterId)
    self.TxtLevel.gameObject:SetActiveEx(not isUniversal)
    self.BtnLevelUp.gameObject:SetActiveEx(not isUniversal)
    if not isUniversal then
        self.TxtLevel.text = self._Control:GetWorkRoleLevelText(self._Control:GetCurCharacterLevel(self._CharacterId))
    end
end

-- 只列他人光环覆盖过来的加成，本人技能在技能描述区展示
function XUiPanelSkyTowerWorkRoleYield:RefreshAddition(override, previewRatios)
    local list = self._Control:GetWorkPosAdditionDescList(self._FloorId, self._Index, override, previewRatios)
    self.PanelAddition.gameObject:SetActiveEx(not XTool.IsTableEmpty(list))
    XUiHelper.RefreshUiObjectList(self._AdditionList, self.ContentAddition, self.GridAddition, #list, function(index, grid)
        local item = list[index]
        grid.TxtName.text = item.Name
        grid.TxtAddition.text = item.AdditionText
        grid.ImgIcon:SetSprite(self._Control:GetClientConfigValue("SkillTypeIcon", item.IconType))
    end)
end

-- 三类区域各有一块速率信息，同一时刻只显示当前区域那块
function XUiPanelSkyTowerWorkRoleYield:RefreshRate(override, previewRatios)
    local isIngredient = self._Control:IsIngredientArea(self._WorkType)
    local isCook = self._Control:IsCookArea(self._WorkType)
    local isSale = self._Control:IsSaleArea(self._WorkType)
    self.PanelProductionRate.gameObject:SetActiveEx(isIngredient)
    self.PanelConsumeSpeed.gameObject:SetActiveEx(isCook)
    self.PanelSell.gameObject:SetActiveEx(isSale)
    if isIngredient then
        self:RefreshIngredientRate(override, previewRatios)
    elseif isCook then
        self:RefreshCookRate(override, previewRatios)
    elseif isSale then
        self:RefreshSaleRate(override, previewRatios)
    end
end

function XUiPanelSkyTowerWorkRoleYield:RefreshIngredientRate(override, previewRatios)
    local baseRate, addition = self:GetHourlyRateAndAddition(override, previewRatios)
    self.TxtReteSu.text = baseRate
    self.TxtRateSuAdd.gameObject:SetActiveEx(addition > 0)
    if addition > 0 then
        self.TxtRateSuAdd.text = string.format("+%s", addition)
        self.TxtRateSuAdd.color = XMVCA.XSkyTower.StaffColor.AdditionUp
    end
end

function XUiPanelSkyTowerWorkRoleYield:RefreshCookRate(override, previewRatios)
    local baseRate, addition = self:GetHourlyRateAndAddition(override, previewRatios)
    self.TxtSpeedSu.text = baseRate
    self.TxtSpeedSuAdd.gameObject:SetActiveEx(addition > 0)
    if addition > 0 then
        self.TxtSpeedSuAdd.text = string.format("+%s", addition)
        self.TxtSpeedSuAdd.color = XMVCA.XSkyTower.StaffColor.AdditionUp
    end
    self.TxtConsume.text = self._Control:GetProductionNeedText(self.TxtProductName.text)
    local consumes = self._Control:GetFoodConsumes(self._ProductId)
    local groupId = self._Control:GetFloorGroupIdByFloorId(self.Parent:GetFloorId())
    XUiHelper.RefreshUiObjectList(self._NeedList, self.PanelNeed, self.GridNeed, #consumes, function(index, grid)
        local consume = consumes[index]
        local ownCount = self._Control:GetStorageProductCount(groupId, consume.ProductType, consume.Id)
        grid.RImgIcon:SetRawImageEx(self._Control:GetProductIcon(consume.WorkType, consume.Id))
        grid.TxtCount.text = consume.Count
        grid.TxtCount.color = XUiHelper.Hexcolor2Color(self._Control:GetClientConfigValue("EnoughColor", ownCount >= consume.Count and 1 or 2))
    end)
end

function XUiPanelSkyTowerWorkRoleYield:RefreshSaleRate(override, previewRatios)
    local baseRate, addition = self:GetHourlyRateAndAddition(override, previewRatios)
    self.TxtSellSpeedSu.text = baseRate
    self.TxtSellSpeedSuAdd.gameObject:SetActiveEx(addition > 0)
    if addition > 0 then
        self.TxtSellSpeedSuAdd.text = string.format("+%s", addition)
        self.TxtSellSpeedSuAdd.color = XMVCA.XSkyTower.StaffColor.AdditionUp
    end
    self.TxtSellPriceSu.text = self._Control:GetFoodBaseSellPrice(self._ProductId)
    -- 售卖单价增量仅包含UpProductPrice，不计入产出数量提升
    local upPrice = self._Control:GetFoodPriceAddition(self._FloorId, self._Index, override, previewRatios)
    self.TxtSellPriceSuAdd.gameObject:SetActiveEx(upPrice ~= 0)
    if upPrice ~= 0 then
        self.TxtSellPriceSuAdd.text = string.format("%s%s", upPrice > 0 and "+" or "", upPrice)
        self.TxtSellPriceSuAdd.color = upPrice > 0 and XMVCA.XSkyTower.StaffColor.AdditionUp or XMVCA.XSkyTower.StaffColor.AdditionDown
    end
    self.TxtPriceHour.text = string.format("%s%s", self._Control:GetItemName(XMVCA.XSkyTower.ItemId.SkyTowerCoin), self._Control:GetSkillAdditionUnit(self._WorkType))
end

-- 每小时基础件数与加成增加的件数，和界面的件/小时单位保持一致
---@return number, number
function XUiPanelSkyTowerWorkRoleYield:GetHourlyRateAndAddition(override, previewRatios)
    local single = self._Control:GetProduceSingleTime(self._FloorId, self._Index, override, previewRatios)
    local base = self._Control:GetBaseProduceSpeed(self._FloorId, self._Index, override)
    if base <= 0 or single <= 0 then
        return 0, 0
    end
    local hour = XMVCA.XSkyTower.TimeUnit.Hour
    local digital = XMVCA.XSkyTower.Digital.One
    local outputCount = 1
    if self._Control:IsIngredientArea(self._WorkType) or self._Control:IsCookArea(self._WorkType) then
        outputCount = self._Control:GetOutputCount(self._FloorId, self._Index, override, previewRatios)
    end
    local baseRate = self._Control:GetAroundValue(hour / base, digital)
    local rate = self._Control:GetAroundValue(hour / single * outputCount, digital)
    local addition = self._Control:GetAroundValue(math.max(rate - baseRate, 0), digital)
    return baseRate, addition
end

function XUiPanelSkyTowerWorkRoleYield:RefreshSkillEffect(override, previewRatios)
    local _, skillId, state = self._Control:GetStaffSkillEffectList(self._FloorId, self._Index, override, previewRatios)
    local hasSkill = XTool.IsNumberValid(skillId)
    self.SkillEffectActiveUp.gameObject:SetActiveEx(hasSkill)
    if not hasSkill then
        return
    end
    self.TxtActiveDec.text = self._Control:GetSkillEffectStateDesc(skillId, state)
end

-- 暂停原因与产量预测互斥，工位没跑起来时两者都不展示
function XUiPanelSkyTowerWorkRoleYield:RefreshPredict(isPreview)
    local isPause = not isPreview and self._Control:IsPause(self._FloorId, self._Index)
    self.TxtPredictNo.gameObject:SetActiveEx(isPause)
    if isPause then
        self.TxtPredict.gameObject:SetActiveEx(false)
        self.TxtPredictRed.gameObject:SetActiveEx(false)
        self.TxtPredictNo.text = self._Control:GetWorkPauseReason(self:GetPauseReasonIndex())
        return
    end
    local increase, tip
    if not isPreview and self._Control:IsWorking(self._FloorId, self._Index) then
        increase, tip = self._Control:GetWorkBenchPreviewTip(self._WorkType, self._ProductId)
    end
    local show = not string.IsNilOrEmpty(tip)
    self.TxtPredict.gameObject:SetActiveEx(show and increase)
    self.TxtPredictRed.gameObject:SetActiveEx(show and not increase)
    if show then
        local text = increase and self.TxtPredict or self.TxtPredictRed
        text.text = tip
    end
end

function XUiPanelSkyTowerWorkRoleYield:GetPauseReasonIndex()
    local isSale = self._Control:IsSaleArea(self._WorkType)
    if self._Control:GetServerState(self._FloorId, self._Index) == XMVCA.XSkyTower.ServerWorkState.WaitForStorage then
        return isSale and 3 or 4
    end
    return isSale and 2 or 1
end

-- 已开工的工位只能加速或停工，未开工的工位才给确认按钮
function XUiPanelSkyTowerWorkRoleYield:RefreshButton(isPreview)
    local isRunning = not isPreview and self._Control:IsRunning(self._FloorId, self._Index)
    self.BtnConfirm.gameObject:SetActiveEx(not isRunning)
    self.PanelBtnExpedite.gameObject:SetActiveEx(isRunning)
    if not isRunning then
        return
    end
    local canAccelerate = self._Control:CheckCanAccelerate(self._FloorId, self._Index)
    local itemId = XMVCA.XSkyTower.ItemId.SkyTowerAccelerate
    self.BtnExpedite:SetDisable(not canAccelerate, canAccelerate)
    self.BtnExpedite:SetNameByGroup(1, self._Control:GetItemCount(itemId))
    self.BtnExpedite:SetRawImageEx(self._Control:GetItemIcon(itemId))
end
--endregion

--region 按钮
function XUiPanelSkyTowerWorkRoleYield:RegisterUiEvents()
    self.BtnChange:AddEventListener(handler(self, self.OnBtnChangeClick))
    self.BtnHead:AddEventListener(handler(self, self.OnBtnHeadClick))
    self.BtnLevelUp:AddEventListener(handler(self, self.OnBtnLevelUpClick))
    self.BtnStatistics:AddEventListener(handler(self, self.OnBtnStatisticsClick))
    self.BtnSuspend:AddEventListener(handler(self, self.OnBtnSuspendClick))
    self.BtnExpedite:AddEventListener(handler(self, self.OnBtnExpediteClick))
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
end

function XUiPanelSkyTowerWorkRoleYield:OnBtnChangeClick()
    self.Parent:ShowTabView()
end

function XUiPanelSkyTowerWorkRoleYield:OnBtnHeadClick()
    self.Parent:ShowSelectRole()
end

function XUiPanelSkyTowerWorkRoleYield:OnBtnLevelUpClick()
    XLuaUiManager.Open("UiSkyTowerCook", self._CharacterId)
end

function XUiPanelSkyTowerWorkRoleYield:OnBtnStatisticsClick()
    self._Control:OpenStatistics(self._WorkType, self._ProductId, self._Control:GetFloorGroupIdByFloorId(self._FloorId))
end

function XUiPanelSkyTowerWorkRoleYield:OnBtnSuspendClick()
    local title, content = self._Control:GetStopTipTitleAndContent(self._FloorId, self._Index)
    self._Control:OpenPopup(title, content, nil, nil, function()
        self._Control:RequestStopWorkPos(self._FloorId, self._Index, function()
            self.Parent:ClearWorkPosPreview()
            self.Parent:ShowTabView()
        end)
    end)
end

function XUiPanelSkyTowerWorkRoleYield:OnBtnExpediteClick()
    if not self._Control:CheckCanAccelerate(self._FloorId, self._Index) then
        return
    end
    self._Control:OpenSpeedUpItemPopup(self._FloorId, self._Index, 1)
end

function XUiPanelSkyTowerWorkRoleYield:OnBtnConfirmClick()
    local request = handler(self, self.RequestAssignWork)
    local title, content = self:GetConfirmTitleAndContent()
    -- 备材台没配材料不足的二次确认文案，取不到就直接下发
    if string.IsNilOrEmpty(title) then
        request()
        return
    end
    self._Control:OpenPopup(title, content, nil, nil, request)
end

-- 满仓/材料不足时需要二次确认，其余情况不弹窗
---@return string, string
function XUiPanelSkyTowerWorkRoleYield:GetConfirmTitleAndContent()
    local override = self.Parent:GetWorkPosOverride()
    if self._Control:IsFull(self._FloorId, self._Index, override) then
        return self._Control:GetFullTitleAndContent(self._FloorId, self._Index, override)
    end
    if self._Control:IsInsufficient(self._FloorId, self._Index, override) then
        return self._Control:GetInsufficientTitleAndContent(self._FloorId, self._Index, override)
    end
    return nil, nil
end

function XUiPanelSkyTowerWorkRoleYield:RequestAssignWork()
    self._Control:RequestAssignWork(self._FloorId, self._Index, self._WorkType, self._ProductId, self._CharacterId, function()
        local desc = self._Control:GetProduceDesc(self._WorkType)
        local characterName = self._Control:GetCharacterName(self._CharacterId)
        local productName = self._Control:GetProductName(self._WorkType, self._ProductId)
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_SHOW_ASSIGN_WORK, string.format(desc, characterName, productName))
        self.Parent:OnAssignWorkSuccess()
    end)
end
--endregion

return XUiPanelSkyTowerWorkRoleYield
