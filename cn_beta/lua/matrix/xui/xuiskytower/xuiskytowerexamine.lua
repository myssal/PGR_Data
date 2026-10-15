local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiSkyTowerExamine : XLuaUi
---@field PanelGroup XUiButtonGroup
---@field _Control XSkyTowerControl
local XUiSkyTowerExamine = XLuaUiManager.Register(XLuaUi, "UiSkyTowerExamine")

local ProductType = XMVCA.XSkyTower.ProductType

function XUiSkyTowerExamine:OnAwake()
    self.IsShowBubble = false
    self.TabBtns = {}
    self.Index2FloorGroupId = {}
    self.Index2ProductType = {}
    self.Index2ListData = {}
    self.DefaultIndex = 1
    self:InitProfit()

    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnWndClose:AddEventListener(handler(self, self.Close))
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
    self.BtnRewardInfo:AddEventListener(handler(self, self.OnBtnRewardInfoClick))
    self.BtnDetailClose:AddEventListener(handler(self, self.OnBtnRewardInfoClick))
end

function XUiSkyTowerExamine:OnStart(workType, firstProductId, floorGroupId)
    self.FirstProductId = firstProductId

    self.DynamicTable = XDynamicTableNormal.New(self.PanelFoodList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerStatistics"), self)

    self.GridFoods.gameObject:SetActiveEx(false)
    self.BubbleFormula.gameObject:SetActiveEx(false)
    self:RefreshProfitData()
    self:InitProfitView()
    self:InitTab(workType, floorGroupId)
end

function XUiSkyTowerExamine:OnEnable()
    self._ProfitRefreshEnabled = true
    self:RefreshProfitData()
    self:RefreshProfitView()
end

function XUiSkyTowerExamine:OnDisable()
    self._ProfitRefreshEnabled = false
    self:CancelProfitRefresh()
end

function XUiSkyTowerExamine:OnDestroy()
    self._ProfitRefreshEnabled = false
    self:CancelProfitRefresh()
end

function XUiSkyTowerExamine:OnGetLuaEvents()
    return {
        XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE,
        XEventId.EVENT_SKY_TOWER_FLOOR_CHANGE,
        XEventId.EVENT_SKY_TOWER_STAFF_CHANGE,
        XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE,
        XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE,
        XEventId.EVENT_SKY_TOWER_DATA_CHANGE,
        XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE,
    }
end

function XUiSkyTowerExamine:OnNotify(event, changedGroupId)
    if not self._ProfitRefreshEnabled or self._ProfitRefreshTimer then
        return
    end
    --其他分区的库存变化不影响当前页，切页时会主动读取最新统计
    if event == XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE
        and XTool.IsNumberValid(changedGroupId) and changedGroupId ~= self.FloorGroupId then
        return
    end
    --同帧的库存、工位和技能事件合并，下一帧读取Control的最终统计
    self._ProfitRefreshCb = self._ProfitRefreshCb or handler(self, self.OnProfitRefresh)
    self._ProfitRefreshTimer = XScheduleManager.ScheduleNextFrame(self._ProfitRefreshCb)
end

function XUiSkyTowerExamine:OnProfitRefresh()
    self._ProfitRefreshTimer = nil
    if self._ProfitRefreshEnabled and not XTool.UObjIsNil(self.GameObject) then
        self:RefreshProfitData()
        self:RefreshProfitView()
    end
end

function XUiSkyTowerExamine:CancelProfitRefresh()
    if self._ProfitRefreshTimer then
        XScheduleManager.UnSchedule(self._ProfitRefreshTimer)
        self._ProfitRefreshTimer = nil
    end
end

function XUiSkyTowerExamine:InitProfit()
    self.StatisticsUnit = self._Control:GetStatisticsUnit(1)
    self.StatisticsTitles = {
        [ProductType.Food] = {},
        [ProductType.Ingredient] = {},
    }
    for productType, titles in pairs(self.StatisticsTitles) do
        for index = 1, 3 do
            titles[index] = self._Control:GetStatisticsTip(productType, index)
        end
    end
    self.GoldBase = self._Control:GetIntConfigValue("GoldTransCharaLvUpItemBase")
    self.CharacterCount = self._Control:GetIntConfigValue("GoldTransCharaLvUpItemNum")
end

function XUiSkyTowerExamine:InitProfitView()
    local iconCoin = self._Control:GetItemIcon(XMVCA.XSkyTower.ItemId.SkyTowerCoin)
    local iconUpgradeCoin = self._Control:GetItemIcon(XMVCA.XSkyTower.ItemId.SkyTowerUpgradeCoin)
    self.RImgCoin1:SetRawImage(iconCoin)
    self.RImgCoin2:SetRawImage(iconUpgradeCoin)
    self.RImgIconBonus1:SetRawImage(iconCoin)
    self.RImgIconBonus2:SetRawImage(iconUpgradeCoin)
    self.PanelBubbleDetail.gameObject:SetActiveEx(false)
    self.TxtTipCost1.text = self._Control:GetClientConfigText("ExamineGoldBubbleText", 1, self.GoldBase)
    self.TxtTipCost2.text = self._Control:GetClientConfigText("ExamineGoldBubbleText", 2, self.CharacterCount)
end

function XUiSkyTowerExamine:InitTab(workType, floorGroupId)
    local productType = workType and self._Control:GetProductTypeByWorkType(workType)
    local btnIndex = 0
    local groupId = self._Control:GetMaxFloorGroupId()
    for i = 1, groupId do
        --父页签_分区
        local btn = i == 1 and self.BtnZone or XUiHelper.Instantiate(self.BtnZone, self.BtnZone.transform.parent)
        btn.gameObject:SetActiveEx(true)
        btn:SetName(self._Control:GetFloorGroupName(i))
        btnIndex = btnIndex + 1
        table.insert(self.TabBtns, btn)

        --子页签_手作
        local firstIndex = btnIndex
        local tmpBtn = i == 1 and self.BtnFood or XUiHelper.Instantiate(self.BtnFood, self.BtnFood.transform.parent)
        tmpBtn.gameObject:SetActiveEx(true)
        tmpBtn.SubGroupIndex = firstIndex
        btnIndex = btnIndex + 1
        table.insert(self.TabBtns, tmpBtn)
        self.Index2FloorGroupId[btnIndex] = i
        self.Index2ProductType[btnIndex] = ProductType.Food
        if floorGroupId == i and productType == ProductType.Food then
            self.DefaultIndex = btnIndex
        end

        --子页签_材料
        tmpBtn = i == 1 and self.BtnIngredient or XUiHelper.Instantiate(self.BtnIngredient, self.BtnIngredient.transform.parent)
        tmpBtn.gameObject:SetActiveEx(true)
        tmpBtn.SubGroupIndex = firstIndex
        btnIndex = btnIndex + 1
        table.insert(self.TabBtns, tmpBtn)
        self.Index2FloorGroupId[btnIndex] = i
        self.Index2ProductType[btnIndex] = ProductType.Ingredient
        if floorGroupId == i and productType == ProductType.Ingredient then
            self.DefaultIndex = btnIndex
        end
    end

    self.PanelGroup:Init(self.TabBtns, function(index)
        self:OnSelect(index)
    end)
    self.PanelGroup:SelectIndex(self.DefaultIndex)
end

function XUiSkyTowerExamine:OnSelect(index)
    local groupId = self.Index2FloorGroupId[index]
    if self.TabIndex == index or not groupId then
        return
    end
    self.TabIndex = index
    self.WorkType = self.Index2ProductType[index]
    self.FloorGroupId = groupId
    self:RefreshProfitData()
    self:PlayAnimation("QieHuan")
    self:RefreshTip()
    self:RefreshView()
    self:RefreshProfitView()
end

function XUiSkyTowerExamine:RefreshView()
    self.DataList = self.Index2ListData[self.TabIndex]
    if not self.DataList then
        local isFood = self.WorkType == ProductType.Food
        local cfg = self._Control:GetFloorGroupConfig(self.FloorGroupId)
        self.DataList = isFood and XTool.Clone(cfg.FoodIds) or XTool.Clone(cfg.IngredientIds)
        table.sort(self.DataList, function(a, b)
            local aPriority = isFood and self._Control:GetFoodPriority(a) or self._Control:GetIngredientPriority(a)
            local bPriority = isFood and self._Control:GetFoodPriority(b) or self._Control:GetIngredientPriority(b)
            if aPriority ~= bPriority then
                return aPriority < bPriority
            end
            return a < b
        end)
        self.Index2ListData[self.TabIndex] = self.DataList
    end

    --从物品统计入口进入时，按原有排序定位到目标物品
    self.FirstProductIndex = nil
    if XTool.IsNumberValid(self.FirstProductId) and not self.ShowHighlight and self.TabIndex == self.DefaultIndex then
        for index, productId in ipairs(self.DataList) do
            if productId == self.FirstProductId then
                self.FirstProductIndex = index
                break
            end
        end
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(self.FirstProductIndex)
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.DataList))
end

---@param grid XUiGridSkyTowerStatistics
function XUiSkyTowerExamine:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self:GetProductProfitData(self.FloorGroupId, self.WorkType, self.DataList[index])
        local title = self.StatisticsTitles[self.WorkType]
        grid:Refresh(self.DataList[index], self.WorkType, data, title, self.StatisticsUnit)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self.FirstProductIndex and not self.ShowHighlight then
            ---@type XUiGridSkyTowerStatistics
            local dynamicGrid = self.DynamicTable:GetGridByIndex(self.FirstProductIndex)
            if dynamicGrid and dynamicGrid.ProductId == self.FirstProductId and dynamicGrid.WorkType == self.WorkType then
                self.ShowHighlight = true
                dynamicGrid:ShowEffect()
            end
        end
    end
end

function XUiSkyTowerExamine:RefreshProfitData()
    --与主界面仓库共用统计缓存，收益读取实际速率，产销读取理论速率；库存变化不重新计算工位速率
    self.ProfitData = self._Control:GetProductionStatistics()
end

---@return table 只读统计记录
function XUiSkyTowerExamine:GetProductProfitData(groupId, productType, productId)
    local groupData = self.ProfitData[groupId]
    local products = groupData and groupData.Products[productType]
    return products and products[productId]
end

function XUiSkyTowerExamine:RefreshProfitView()
    local groupData = self.ProfitData[self.FloorGroupId]
    local goldSpeed = self._Control:GetFloorValue(groupData and groupData.GoldSpeed or 0, XMVCA.XSkyTower.Digital.One)
    local characterSpeed = self._Control:GetFloorValue(groupData and groupData.CharacterSpeed or 0, XMVCA.XSkyTower.Digital.One)
    if self._GoldSpeed ~= goldSpeed then
        self._GoldSpeed = goldSpeed
        if self.TxtReward1 then
            self.TxtReward1.text = goldSpeed .. "/h"
        end
    end
    if self._CharacterSpeed ~= characterSpeed then
        self._CharacterSpeed = characterSpeed
        if self.TxtReward2 then
            self.TxtReward2.text = characterSpeed .. "/h"
        end
    end

    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        -- 切页异步复用格子期间，只刷新与当前分类相符的格子
        if grid.WorkType == self.WorkType then
            grid:RefreshProfit(self:GetProductProfitData(self.FloorGroupId, grid.WorkType, grid.ProductId))
        end
    end
end

function XUiSkyTowerExamine:OnBtnRewardInfoClick()
    self.PanelBubbleDetail.gameObject:SetActiveEx(not self.PanelBubbleDetail.gameObject.activeSelf)
end

function XUiSkyTowerExamine:OnBtnHelpClick()
    self.IsShowBubble = not self.IsShowBubble
    self.BubbleFormula.gameObject:SetActiveEx(self.IsShowBubble)
    if not self.IsShowBubble then
        return
    end
    self:RefreshTip()
end

function XUiSkyTowerExamine:RefreshTip()
    if not self.IsShowBubble then
        return
    end
    local titles = self.StatisticsTitles[self.WorkType]
    if not titles then
        return
    end
    self.TxtProduce.text = titles[1]
    self.TxtConsume.text = titles[2]
    self.TxtResult.text = titles[3]
    self.TxtResultDetail.text = titles[3]
end

return XUiSkyTowerExamine
