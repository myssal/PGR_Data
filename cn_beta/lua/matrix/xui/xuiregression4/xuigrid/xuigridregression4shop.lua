local XRegression4EnumConst = require("XModule/XRegression4/XRegression4EnumConst")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

local XUiGridRegression4Shop = XClass(nil, "XUiGridRegression4Shop")

--- 颜色枚举
---@field EnoughNormal      金币足够且解锁
---@field EnoughLock        金币足够且未解锁
---@field NotEnoughNormal   金币不足解锁
---@field NotEnoughLock     金币不足未解锁
local ColorEnum = {
    EnoughNormal = CS.UnityEngine.Color.white,
    EnoughLock =  XUiHelper.Hexcolor2Color("c7c7c7"),
    NotEnoughNormal = XUiHelper.Hexcolor2Color("ff4425ff"),
    NotEnoughLock = XUiHelper.Hexcolor2Color("ff442599"),
    LimitNormal = XUiHelper.Hexcolor2Color("34AFF8")
}

function XUiGridRegression4Shop:Ctor(ui, parent, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.Parent = parent
    self.RootUi = rootUi
    self.GridCommon = XUiGridCommon.New(rootUi, self.Grid256New)
    self.GridCommon:SetClickCallback(handler(self, self.OnBtnInfoClick))
    self.BtnBuy.CallBack = handler(self, self.OnBtnClick)
    self.TxtSaleRate = self.TxtSaleRate or self.Transform:Find("PanelLabel/TxtSaleRate"):GetComponent(typeof(CS.UnityEngine.UI.Text))
end

function XUiGridRegression4Shop:Refresh(data)
    self.Data = data
    self:RefreshGoodsData()
    self:RefreshSellOut()
    self:RefreshOnSales()
    self:RefreshCondition()
    self:RefreshPrice()
    self:RemoveTimer()
    self:RefreshBuyCount()
    self:RefreshTimer()
end

function XUiGridRegression4Shop:RefreshGoodsData()
    self.GridCommon:Refresh(self.Data.RewardGoods)
end

function XUiGridRegression4Shop:RefreshSellOut()
    local buyTimeLimit = self.Data.BuyTimesLimit
    local totalBuyTime = self.Data.TotalBuyTimes
    self.IsSellOut = buyTimeLimit > 0 and totalBuyTime >= buyTimeLimit
    self.ImgSellOut.gameObject:SetActiveEx(self.IsSellOut)
end

function XUiGridRegression4Shop:RefreshOnSales()
    self.OnSales = {}
    local onSalesList = {}
    XTool.LoopMap(self.Data.OnSales, function(key, sales) 
        self.OnSales[key] = sales
        table.insert(onSalesList, sales)
    end)
    
    self.Sales = 100

    if #onSalesList ~= 0 then
        local sortedKeys = {}
        for k, _ in pairs(self.OnSales) do
            table.insert(sortedKeys, k)
        end
        table.sort(sortedKeys)

        for i = 1, #sortedKeys do
            if self.Data.TotalBuyTimes >= sortedKeys[i] - 1 then
                self.Sales = self.OnSales[sortedKeys[i]]
            end
        end
    end

    if not self.TxtSaleRate then
        return
    end
    
    local tag = self.Data.Tags
    local hideSales = false
    if tag == XShopManager.ShopTags.DisCount then
        if self.Sales < 100 then
            -- 折扣显示 区分海外国服
            self.TxtSaleRate.text = XUiHelper.GetDiscountText(self.Sales)
            --self.TxtSaleRate.text = self.Sales / 10 .. CS.XTextManager.GetText("Snap")
        else
            hideSales = true
        end

    elseif tag == XShopManager.ShopTags.TimeLimit then
        self.TxtSaleRate.text = CS.XTextManager.GetText("TimeLimit")
    elseif tag == XShopManager.ShopTags.Recommend then
        self.TxtSaleRate.text = CS.XTextManager.GetText("Recommend")
    elseif tag == XShopManager.ShopTags.HotSale then
        self.TxtSaleRate.text = CS.XTextManager.GetText("HotSell")
    end

    if tag == XShopManager.ShopTags.Not or hideSales then
        self.TxtSaleRate.transform.parent.gameObject:SetActiveEx(false)
    else
        self.TxtSaleRate.transform.parent.gameObject:SetActiveEx(true)
    end
    
end

function XUiGridRegression4Shop:RefreshCondition()
    local conditions = self.Data.ConditionIds
    self.IsLock = false
    
    for _, conditionId in pairs(conditions) do
        if conditionId > 0 then
            local ret, _ = XConditionManager.CheckCondition(conditionId)
            if not ret then
                self.IsLock = true
                self.IsSellOut = false
                self.ImgSellOut.gameObject:SetActiveEx(self.IsSellOut)
                local template = XConditionManager.GetConditionTemplate(conditionId)
                local params = template.Params
                self.RImgUnlockIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XRegression4EnumConst.Regression4CoinId))
                self.TxtUnlockPrice.text = params[1]
                break
            end
        end
    end
    self.PanelNormal.gameObject:SetActiveEx(not self.IsLock)
    self.PanelLock.gameObject:SetActiveEx(self.IsLock)
    
end

function XUiGridRegression4Shop:RefreshPrice()
    for _, consume in pairs(self.Data.ConsumeList or table.empty) do
        local coinIcon = XDataCenter.ItemManager.GetItemIcon(consume.Id)
        if coinIcon ~= nil then
            self.RImgCoinIcon:SetRawImage(coinIcon)
        end
        local needCount = math.floor(consume.Count * self.Sales / 100)
        self.EnoughCoin = needCount <= XDataCenter.ItemManager.GetCount(consume.Id)
        self.TxtPrice.text = needCount
        local color
        if self.EnoughCoin then
            color = self.IsLock and ColorEnum.EnoughLock or ColorEnum.EnoughNormal
        else
            color = self.IsLock and ColorEnum.NotEnoughLock or ColorEnum.NotEnoughNormal
        end
        self.TxtPrice.color = color
        break
    end
end

function XUiGridRegression4Shop:RefreshBuyCount()
    local limit = self.Data.BuyTimesLimit > 0
    self.TxtLimit.gameObject:SetActiveEx(limit)
    if not limit then
        return
    end
    local limitLabel = XShopConfigs.GetBuyLimitLabel(self.Data.AutoResetClockId)
    local desc = string.format("%s/%s", self.Data.TotalBuyTimes, self.Data.BuyTimesLimit)
    self.TxtLimit.text = string.format(limitLabel, desc)
    self.TxtLimit.color = self.IsLock and ColorEnum.EnoughLock or ColorEnum.LimitNormal
end

function XUiGridRegression4Shop:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGridRegression4Shop:RefreshTimer()
    --local time = self.Data.SelloutTime
    local leftTime = self._Control:GetMainViewModel():GetLeftTime()
    local showLeft = leftTime > 0
    self.TxtLeftTime = self.IsLock and self.TxtLockLeftTime or self.TxtNormalLeftTime
    self.TxtLeftTime.gameObject:SetActiveEx(showLeft)
    if not showLeft then
        return
    end
    
    
    local doRefresh = function() 
        if self.GameObject == nil or self.GameObject:Exist() == false then
            self:RemoveTimer()
            return
        end
        
        leftTime = leftTime > 0 and leftTime or 0
        local dataTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtLeftTime.text = XUiHelper.GetText("TimeSoldOut", dataTime)

        if leftTime <= 0 then
            self:RemoveTimer()
            self.IsSellOut = true
            self.ImgSellOut.gameObject:SetActiveEx(true)
        end
    end
    
    doRefresh()
    
    self.Timer = XScheduleManager.ScheduleForever(function() 
        leftTime = leftTime - 1
        doRefresh()
    end, XScheduleManager.SECOND)
end

function XUiGridRegression4Shop:OnBtnClick()
    if not self:CheckBuy() then
        return
    end
    
    XLuaUiManager.Open("UiShopItem",self.Parent, self.Data, function() 
        
        self:RefreshSellOut()
        self:RefreshCondition()
        self:RefreshPrice()
        self:RefreshBuyCount()
    end)
end

function XUiGridRegression4Shop:CheckBuy()

    if self.IsSellOut then
        XUiManager.TipMsg(self._Control:GetClientConfigValue("ShopSellOutTips", 1))
        return false
    end
    
    if self.IsLock then
        XUiManager.TipText("NotUnlock")
        return false
    end

    if not self.EnoughCoin then
        XUiManager.TipText("CommonCoinNotEnough")
        return false
    end

    local timeOfNow = XTime.GetServerNowTimestamp()
    if timeOfNow >= self.Data.OnSaleTime then
        if self.Data.SelloutTime <= 0 then
            return true
        end
        return timeOfNow <= self.Data.SelloutTime
    end
    return false
end

function XUiGridRegression4Shop:OnBtnInfoClick()
    if self.IsSellOut then
        XUiManager.TipMsg(self._Control:GetClientConfigValue("ShopSellOutTips", 1))
        return
    end
    
    self.GridCommon:OnBtnClickClick()
end

return XUiGridRegression4Shop