local XUiTheatre5ShopPanel = require("XUi/XUiTheatre5/XUiTheatre5RewardShop/XUiTheatre5ShopPanel")
local XUiTheatre5TaskPanel = require("XUi/XUiTheatre5/XUiTheatre5RewardShop/XUiTheatre5TaskPanel")
local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
---@class XUiTheatre5RewardShop : XLuaUi
local XUiTheatre5RewardShop = XLuaUiManager.Register(XLuaUi, "UiTheatre5RewardShop")

function XUiTheatre5RewardShop:OnAwake()
    self.TabIndexDic = {}
    self.TabBtns = {}
    self.SelectIndex = nil
    self._TimerId = nil
    self:RegisterClickEvent(self.BtnBack, self.Close, true)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick, true)

end

function XUiTheatre5RewardShop:OnStart()
    self:InitTags()
    self:RefreshResourceBar()
    self.UiTheatre5ShopPanel = XUiTheatre5ShopPanel.New(self.PanelItemList, self)
    self.UiTheatre5TaskPanel = XUiTheatre5TaskPanel.New(self.PanelTaskStory, self)
    local shopIdList = self._Control:GetValidShopIdlist()
    if XTool.IsTableEmpty(shopIdList) then
        self.BtnTabGroup:SelectIndex(self.SelectIndex, true)
    else  
        XShopManager.GetShopInfoList(shopIdList, function()
            self.BtnTabGroup:SelectIndex(self.SelectIndex, true)
        end, XShopManager.ActivityShopType.Theatre5Shop, true)
    end    
end

function XUiTheatre5RewardShop:OnEnable()
    self:UpdateAssetPanel()
end

function XUiTheatre5RewardShop:RefreshResourceBar()
    self._ResourceBarCoins = self._Control:GetTheatre5CoinIds()      
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(self._ResourceBarCoins, handler(self, self.UpdateAssetPanel), self.AssetActivityPanel)  
end

function XUiTheatre5RewardShop:InitTags()
    local firstTags = {XMVCA.XTheatre5.EnumConst.TaskShopType.Shop, XMVCA.XTheatre5.EnumConst.TaskShopType.Task}
    self.TabIndexDic = {}
    self.TabBtns = {}
    local btnIndex = 0

    --一级标题
    for _, taskShopType in pairs(firstTags) do
        local secondTagCfgs = self._Control:GetValidShopOrTaskList(taskShopType)
        if not XTool.IsTableEmpty(secondTagCfgs) then
            local btn = XUiHelper.Instantiate(self.BtnTab1, self.BtnTab1.transform.parent)
            btn.gameObject:SetActiveEx(true)
            btn:SetName(self._Control:GetTaskShopTagName(taskShopType))

            local uiButton = btn:GetComponent("XUiButton")
            table.insert(self.TabBtns, uiButton)
            btnIndex = btnIndex + 1

            --二级标题
            local firstIndex = btnIndex
            for _, taskShopCfg in ipairs(secondTagCfgs) do
                    local tmpBtn = XUiHelper.Instantiate(self.BtnChild01, self.BtnChild01.transform.parent)
                    tmpBtn:SetName(taskShopCfg.Name)
                    tmpBtn.gameObject:SetActiveEx(true)

                    local tmpUiButton = tmpBtn:GetComponent("XUiButton")
                    tmpUiButton.SubGroupIndex = firstIndex
                    table.insert(self.TabBtns, tmpUiButton)
                    btnIndex = btnIndex + 1

                self.TabIndexDic[btnIndex] = taskShopCfg
            end
        end    
    end
    self.BtnTab1.gameObject:SetActiveEx(false)
    self.BtnChild01.gameObject:SetActiveEx(false)
    self.BtnTabGroup:Init(self.TabBtns, function(index) self:OnSelectedTag(index) end)
    self.SelectIndex = 1
end

function XUiTheatre5RewardShop:RemoveTag(taskShopId)
    for btnIndex, taskShopCfg in pairs(self.TabIndexDic) do
        if taskShopCfg.Id == taskShopId then
            local uiButtonList = self.BtnTabGroup:RemoveButton(btnIndex)
            if uiButtonList then
                for _, uiButton in pairs(uiButtonList) do
                    uiButton.gameObject:SetActiveEx(false)
                end
            end    
        end    
    end
end

function XUiTheatre5RewardShop:OnSelectedTag(index)
    self.SelectIndex = index
    local taskShopCfg = self.TabIndexDic[index]
    if not taskShopCfg then
        return
    end
    self.UiTheatre5ShopPanel:SetVisible(taskShopCfg.Type == XMVCA.XTheatre5.EnumConst.TaskShopType.Shop)
    self.UiTheatre5TaskPanel:SetVisible(taskShopCfg.Type == XMVCA.XTheatre5.EnumConst.TaskShopType.Task)
    if taskShopCfg.Type == XMVCA.XTheatre5.EnumConst.TaskShopType.Shop then
        local shopId
        if XFunctionManager.CheckInTimeByTimeId(taskShopCfg.TimeLimitId, true) then
            shopId = taskShopCfg.ShopId
        end
        self.UiTheatre5ShopPanel:UpdateShopShow(shopId)    
    else
        local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(taskShopCfg.TaskTimeLimitId)
        if taskTimeLimitCfg then
            local taskIds = XFunctionManager.CheckInTimeByTimeId(taskShopCfg.TimeLimitId, true) and taskTimeLimitCfg.TaskId or {}
            self.UiTheatre5TaskPanel:UpdateTaskShow(taskIds)
        end    
    end
    self:StartTimer(taskShopCfg)         
end

function XUiTheatre5RewardShop:StartTimer(taskShopCfg)
    self:StopTimer()
    if not XTool.IsNumberValid(taskShopCfg.TimeLimitId) then
        self.TxtTime.gameObject:SetActiveEx(false)
        return
    end

    if not XFunctionManager.CheckInTimeByTimeId(taskShopCfg.TimeLimitId) then
        self.TxtTime.gameObject:SetActiveEx(false)
        return
    end
    self.TxtTime.gameObject:SetActiveEx(true)
    self:UpdateTime(taskShopCfg)    
    self._TimerId = XScheduleManager.ScheduleForever(function()
        self:UpdateTime(taskShopCfg)
    end, XScheduleManager.SECOND)
end

function XUiTheatre5RewardShop:StopTimer()
    if self._TimerId then
        XScheduleManager.UnSchedule(self._TimerId)
        self._TimerId = nil
    end
end

function XUiTheatre5RewardShop:UpdateTime(taskShopCfg)
    local endTime = XFunctionManager.GetEndTimeByTimeId(taskShopCfg.TimeLimitId)

    if endTime <= 0 then
        XLog.Error('商店结束时间异常，结束时间：'..tostring(endTime)..' TimeId:'..tostring(self._TimerId))
        self:StopTimer()
        return
    end
    
    local now = XTime.GetServerNowTimestamp()
    local leftTime = math.max(endTime - now, 0)

    if self.TxtTime then
        self.TxtTime.text = XUiHelper.FormatText(self._Control:GetClientConfigTaskShopTimeLabel(), 
        XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    end    
    if leftTime <= 0 then
        self:StopTimer()
        --刷新下
        self:OnSelectedTag(self.SelectIndex)    
    end
end

function XUiTheatre5RewardShop:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(self._ResourceBarCoins)
end

function XUiTheatre5RewardShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTheatre5RewardShop:OnDestroy()
    self:StopTimer()
    self.TabIndexDic = nil
    self.TabBtns = nil
    self.SelectIndex = nil
    self._TimerId = nil
end

return XUiTheatre5RewardShop