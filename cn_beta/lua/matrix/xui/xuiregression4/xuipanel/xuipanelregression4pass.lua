
local XRegression4EnumConst = require("XModule/XRegression4/XRegression4EnumConst")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridRegression4Pass = require("XUi/XUiRegression4/XUiGrid/XUiGridRegression4Pass")

---@class XUiPanelRegression4Pass: XUiNode
---@field TxtTips XUiComponent.XUiRichTextCustomRender
local XUiPanelRegression4Pass = XClass(XUiNode, "XUiPanelRegression4Pass")

local OneMinSeconds = 60

--region   ------------------生命周期 start-------------------
function XUiPanelRegression4Pass:OnStart()
    self.RootUi = self.Parent
    self.ViewModel = self._Control:GetMainViewModel()
    self.PassportViewModel = self.ViewModel:GetPassportViewModel()
    self.MaxShownIndex = 0
    self._ShownIndexDic = {}
    self:InitCb()
    self:InitUi()
end

function XUiPanelRegression4Pass:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_REGRESSION4_PASSPORT_STATUS_CHANGE, self.OnPassportStatusChange, self)
    self:RefreshView()
end

function XUiPanelRegression4Pass:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_REGRESSION4_PASSPORT_STATUS_CHANGE, self.OnPassportStatusChange, self)
end

function XUiPanelRegression4Pass:UpdateTime()
end

function XUiPanelRegression4Pass:OnDestroy()
    self.TxtTips.requestImage = nil
end
--endregion------------------生命周期 finish-------------------

--region   ------------------初始化 start-------------------
function XUiPanelRegression4Pass:InitCb()
    self.BtnGet:AddEventListener(handler(self, self.OnBtnGetClick))
    self.BtnPay:AddEventListener(handler(self, self.OnBtnPayClick))
    -- 必须先于 TxtTips.text 赋值：set text 立刻触发解析，回调为空会漏图
    self.TxtTips.requestImage = handler(self, self.OnTxtTipsRequestImage)
end

function XUiPanelRegression4Pass:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridRegression4Pass, self)
    self.DynamicTable:SetDelegate(self)
    self.Grid01.gameObject:SetActiveEx(false)
    -- 大奖预览：GridPreview 与 Grid01 结构相同，复用同一个 Grid 类
    self.PreviewGrid = XUiGridRegression4Pass.New(self.GridPreview, self)
end
--endregion------------------初始化 finish-------------------

--region   ------------------数据刷新 start-------------------
function XUiPanelRegression4Pass:RefreshView()
    if not self._Control:CheckPassportLocalRedPointData() then
        self._Control:MarkPassportLocalRedPointData()
    end
    self.MaxShownIndex = 0
    self._ShownIndexDic = {}
    self.TxtTips.text = self._Control:GetClientConfigValue("PassTips", 1) or ""

    --支付按钮
    self:RefreshPayButton()

    --拥有BP积分：属性绑定，经验推送到达时自动刷新
    self.RootUi:BindViewModelPropertyToObj(self.PassportViewModel, function(points)
        self.TxtNum.text = tostring(points)
    end, "_Accumulated")

    --战令任务自动领取的奖励：登录时积压的与推送到达的都在此弹窗
    self.RootUi:BindViewModelPropertyToObj(self.PassportViewModel, function(rewards)
        if XTool.IsTableEmpty(rewards) then
            return
        end
        XUiManager.OpenUiObtain(rewards)
        self.PassportViewModel:ClearAutoGetRewards()
    end, "_AutoGetRewards")

    --挡位列表
    self:SetupDynamicTable()
end

function XUiPanelRegression4Pass:RefreshPayButton()
    local payTypeInfo = self.PassportViewModel:GetPayPassportTypeInfo()
    local isDisable = XTool.IsTableEmpty(payTypeInfo)
    --已购买置灰不可点；未购买显示货币图标与所需数量
    self.BtnPay:SetDisable(isDisable, not isDisable)
    if isDisable then
        return
    end
    self.BtnPay:SetNameByGroup(1, payTypeInfo.CostItemCount)
    self.BtnPay:SetRawImage(XDataCenter.ItemManager.GetItemIcon(payTypeInfo.CostItemId))
end

function XUiPanelRegression4Pass:SetupDynamicTable()
    self.LevelInfos = self:GetSortedLevelInfos()
    self.DynamicTable:SetDataSource(self.LevelInfos)
    self.DynamicTable:ReloadDataSync(1)
    self:RefreshPreview()
end

function XUiPanelRegression4Pass:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.LevelInfos[idx], self:CalcFillAmount(idx))
        self._ShownIndexDic[idx] = true
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        self._ShownIndexDic[idx] = nil
    else
        return
    end
    self:RefreshPreviewByShownRange()
end

function XUiPanelRegression4Pass:RefreshPreviewByShownRange()
    local maxIndex = 0
    for index in pairs(self._ShownIndexDic) do
        if index > maxIndex then
            maxIndex = index
        end
    end
    if maxIndex == self.MaxShownIndex then
        return
    end
    self.MaxShownIndex = maxIndex
    self:RefreshPreview()
end

function XUiPanelRegression4Pass:OnPassportStatusChange()
    for index, grid in pairs(self.DynamicTable:GetGrids() or table.empty) do
        if grid then
            grid:Refresh(self.LevelInfos[index], self:CalcFillAmount(index))
        end
    end
    self:RefreshPayButton()
    self:RefreshPreview()
end
--endregion------------------数据刷新 finish-------------------

--region   ------------------进度与预览 start-------------------
---挡位列表（过滤无效挡位，按积分升序）
function XUiPanelRegression4Pass:GetSortedLevelInfos()
    local levelInfos = {}
    local infos = self.PassportViewModel:GetPassportLevelInfos() or {}
    for _, info in ipairs(infos) do
        if XTool.IsNumberValid(info.TotalExp) and info.TotalExp > 0 then
            table.insert(levelInfos, info)
        end
    end
    table.sort(levelInfos, function(a, b)
        return a.TotalExp < b.TotalExp
    end)
    return levelInfos
end

---单格进度条：挡位中位(0.5)=该挡位所需总积分；首格特殊——前半 [0,S1]，后半 [S1,S1+公差/2]；其余格前后半各为相邻挡位公差的一半
function XUiPanelRegression4Pass:CalcFillAmount(index)
    local levelInfos = self.LevelInfos
    local cur = levelInfos[index]
    local points = self.PassportViewModel:GetProperty("_Accumulated")
    local s = cur.TotalExp
    if s <= 0 then
        return 0
    end

    if index <= 1 then
        if points <= s then
            return 0.5 * points / s
        end
        local nextS = levelInfos[2] and levelInfos[2].TotalExp or s * 2
        local half = (nextS - s) / 2
        if half <= 0 then
            return 1
        end
        return math.min(1, 0.5 + 0.5 * (points - s) / half)
    end

    local prevS = levelInfos[index - 1].TotalExp
    local half = (s - prevS) / 2
    if half <= 0 then
        return points >= s and 1 or 0
    end
    if points <= s then
        return math.max(0, 0.5 * (points - (s - half)) / half)
    end
    return math.min(1, 0.5 + 0.5 * (points - s) / half)
end

---大奖预览：显示滚动可视范围外下一个含大奖的挡位，全部展示后显示最后一个
function XUiPanelRegression4Pass:RefreshPreview()
    local primeIndex = self:GetNextPrimeIndex()
    if not primeIndex then
        return
    end
    self.PreviewGrid:Refresh(self.LevelInfos[primeIndex], self:CalcFillAmount(primeIndex))
end

---@return number|nil 可视范围外下一个含大奖的挡位；全部展示后为最后一个大奖挡位
function XUiPanelRegression4Pass:GetNextPrimeIndex()
    local count = #self.LevelInfos
    if count <= 0 then
        return nil
    end
    for i = self.MaxShownIndex + 1, count do
        if self:IsPrimeLevel(i) then
            return i
        end
    end
    for i = count, 1, -1 do
        if self:IsPrimeLevel(i) then
            return i
        end
    end
end

---@return boolean 该挡位是否配置了大奖奖励（IsPrimeReward）
function XUiPanelRegression4Pass:IsPrimeLevel(index)
    local levelInfo = self.LevelInfos[index]
    local freeTypeInfo, payTypeInfo = self:GetTypeInfos()
    local typeInfos = { freeTypeInfo, payTypeInfo }
    for _, typeInfo in ipairs(typeInfos) do
        if typeInfo then
            local rewardInfo = self.PassportViewModel:GetPassportRewardInfo(typeInfo.Id, levelInfo.Level)
            if rewardInfo and rewardInfo.IsPrimeReward then
                return true
            end
        end
    end
    return false
end

---@return table, table 免费版类型, 付费版类型
function XUiPanelRegression4Pass:GetTypeInfos()
    local freeTypeInfo, payTypeInfo
    local typeInfos = self.PassportViewModel:GetPassportTypeInfos()
    for _, info in ipairs(typeInfos or table.empty) do
        if info.IsFree then
            freeTypeInfo = info
        else
            payTypeInfo = info
        end
    end
    return freeTypeInfo, payTypeInfo
end
--endregion------------------进度与预览 finish-------------------

--region   ------------------事件回调 start-------------------
---跳转任务页签
function XUiPanelRegression4Pass:OnBtnGetClick()
    self.RootUi:SelectTabByActivityType(XRegression4EnumConst.ActivityType.Task)
end

---解锁付费版（照老逻辑：时间拦截→已购拦截→货币检查→确认弹窗→购买）
function XUiPanelRegression4Pass:OnBtnPayClick()
    local passportViewModel = self.PassportViewModel
    local leftTime = self.ViewModel:GetLeftTime()
    local earlyEndTime = passportViewModel:GetBuyPassPortEarlyEndTime()

    --活动结束前配置秒数，禁止购买
    if leftTime < earlyEndTime then
        XUiManager.TipMsg(self._Control:GetClientConfigValue("StopPayPassportTips", 1))
        return
    end

    local payTypeInfo = passportViewModel:GetPayPassportTypeInfo()
    if XTool.IsTableEmpty(payTypeInfo) then
        XUiManager.TipText("AlreadyBuy")
        return
    end

    local owned = XDataCenter.ItemManager.GetCount(payTypeInfo.CostItemId)
    if owned < payTypeInfo.CostItemCount then
        if payTypeInfo.CostItemId == XDataCenter.ItemManager.ItemId.HongKa then
            XUiHelper.OpenPurchaseBuyHongKaCountTips()
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
        elseif payTypeInfo.CostItemId == XDataCenter.ItemManager.ItemId.PaidGem then
            XUiManager.TipText("ShopItemPaidGemNotEnough")
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
        end
        return
    end

    local title = XUiHelper.GetText("BuyConfirmTipsTitle")
    local desc = XUiHelper.ReplaceTextNewLine(string.format(payTypeInfo.BuyDesc, payTypeInfo.CostItemCount, math.floor(earlyEndTime / OneMinSeconds)))

    local index = string.find(desc, "\n")
    local content, subContent
    if index and index > 0 then
        content = string.sub(desc, 1, index)
        subContent = string.sub(desc, index + 1)
    else
        content = desc
        subContent = ""
    end
    XLuaUiManager.Open("UiRegression4Tips", payTypeInfo.RewardId, payTypeInfo.PreviewRewardId, title, content, subContent, handler(self, self.OnBuyPassport))
end

function XUiPanelRegression4Pass:OnBuyPassport()
    local payTypeInfo = self.PassportViewModel:GetPayPassportTypeInfo()
    self._Control:RequestBuyPassport(payTypeInfo.Id, handler(self, self.OnBuyPassportResult))
end

function XUiPanelRegression4Pass:OnBuyPassportResult()
    self:RefreshPayButton()
end

function XUiPanelRegression4Pass:OnTxtTipsRequestImage(key, img)
    local itemId = tonumber(key)
    if not XTool.IsNumberValid(itemId) then
        XLog.Error("Regression4ClientConfig 的 PassTips 富文本图标标签需填道具Id，当前 key = " .. tostring(key))
        return
    end
    local icon = XDataCenter.ItemManager.GetItemIcon(itemId)
    if string.IsNilOrEmpty(icon) then
        return
    end
    img:SetSprite(icon)
end
--endregion------------------事件回调 finish-------------------

return XUiPanelRegression4Pass
