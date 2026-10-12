
local XRegression4EnumConst = require("XModule/XRegression4/XRegression4EnumConst")
local XUiGridRegression4Quest = require("XUi/XUiRegression4/XUiGrid/XUiGridRegression4Quest")

---@class XUiPanelRegression4Boost: XUiNode
local XUiPanelRegression4Boost = XClass(XUiNode, "XUiPanelRegression4Boost")

--- MainTaskTabControl 表中勤务页签的 TagType
local CanLiverTabTagType = 6

--- 与主界面 XUiGridSubMenuItem 的跳转方式保持一致
local SubMenuJumpType = {
    Web = 1,
    Game = 2,
}

--region   ------------------生命周期 start-------------------
function XUiPanelRegression4Boost:OnStart()
    self.RootUi = self.Parent
    self.ViewModel = self._Control:GetMainViewModel()
    self:InitCb()
    self:InitUi()
end

function XUiPanelRegression4Boost:OnEnable()
    self:RefreshView()
end

function XUiPanelRegression4Boost:UpdateTime()
end
--endregion------------------生命周期 finish-------------------

--region   ------------------初始化 start-------------------
function XUiPanelRegression4Boost:InitCb()
    self.Item1 = XTool.InitUiObjectByUi({}, self.GridItem1)
    self.Item2 = XTool.InitUiObjectByUi({}, self.GridItem2)
    self.Item1.BtnGo:AddEventListener(handler(self, self.OnBtnGo1Click))
    self.Item2.BtnGo:AddEventListener(handler(self, self.OnBtnGo2Click))
    self.BtnStrategy:AddEventListener(handler(self, self.OnBtnStrategyClick))
    self.BtnTeam:AddEventListener(handler(self, self.OnBtnTeamClick))
end

function XUiPanelRegression4Boost:InitUi()
    local surveyIds = self._Control:GetSurveyCfgIds() or {}
    local questUis = { self.GridQuest1, self.GridQuest2 }
    for i, surveyId in ipairs(surveyIds) do
        if questUis[i] then
            local cfg = self._Control:GetSurveyCfgById(surveyId)
            XUiGridRegression4Quest.New(questUis[i], self, cfg)
        end
    end

    --双倍次数：属性绑定，服务端推送到达时自动刷新
    self.RootUi:BindViewModelPropertyToObj(self.ViewModel, function()
        self:RefreshDoubleItem()
    end, "_DoubleUsedTimes")
end
--endregion------------------初始化 finish-------------------

--region   ------------------数据刷新 start-------------------
function XUiPanelRegression4Boost:RefreshView()
    self:RefreshDoubleItem()
    self:RefreshCanLiverItem()
    self:RefreshStrategyTeam()
end

function XUiPanelRegression4Boost:RefreshDoubleItem()
    local maxTimes = 0
    local doubleList = self._Control:GetDoubleList(self.ViewModel:GetProperty("_Id")) or {}
    for _, cfg in ipairs(doubleList) do
        maxTimes = math.max(maxTimes, cfg.DoubleTimes)
    end
    local usedTimes = self.ViewModel:GetDoubleUsedTimes(XRegression4EnumConst.DoubleType.RepeatChallengeMultiReward)
    local leftTimes = math.max(0, maxTimes - usedTimes)

    self.Item1.TxtName.text = self._Control:GetClientConfigValue("BoostDoubleTitle", 1) or ""
    self.Item1.TxtNum.text = leftTimes .. "/" .. maxTimes
    self:RefreshGoButton(self.Item1.BtnGo, leftTimes <= 0, "BoostDoubleEndText")
end

function XUiPanelRegression4Boost:RefreshCanLiverItem()
    local finishCount, totalCount = self:GetCanLiverTaskCount()
    
    self.Item2.TxtName.text = self._Control:GetClientConfigValue("BoostCanLiverTitle", 1) or ""
    self.Item2.TxtNum.text = finishCount .. "/" .. totalCount
    self:RefreshGoButton(self.Item2.BtnGo, finishCount >= totalCount, "BoostCanLiverEndText")
end

---@return number, number 已完成数, 总数
function XUiPanelRegression4Boost:GetCanLiverTaskCount()
    local finishCount, totalCount = 0, 0
    local taskGroupIds = XMVCA.XItemRestrict:GetTaskGroupIdList(XEnumConst.ItemRestrict.Type.DrawCanLiver) or {}
    local finishState = XDataCenter.TaskManager.TaskState.Finish
    for _, groupId in ipairs(taskGroupIds) do
        if XTool.IsNumberValid(groupId) then
            local tasks = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, false) or {}
            for _, task in pairs(tasks) do
                totalCount = totalCount + 1
                if task.State == finishState then
                    finishCount = finishCount + 1
                end
            end
        end
    end
    return finishCount, totalCount
end

function XUiPanelRegression4Boost:RefreshGoButton(btn, isDisable, endTextKey)
    btn:SetDisable(isDisable, not isDisable)
    local textKey = isDisable and endTextKey or "BoostGoText"
    btn:SetNameByGroup(0, self._Control:GetClientConfigValue(textKey, 1) or "")
end

function XUiPanelRegression4Boost:RefreshStrategyTeam()
    local isShow = self:IsOfficialChannel()

    local subMenuList = XDataCenter.NoticeManager.GetMainUiSubMenu() or {}
    self.StrategyData = self:FindSubMenuData(subMenuList, "StrategyMenuId")
    self.TeamData = self:FindSubMenuData(subMenuList, "TeamMenuId")

    -- 未下发对应菜单数据时隐藏入口
    self.BtnStrategy.gameObject:SetActiveEx(isShow and self.StrategyData ~= nil)
    self.BtnTeam.gameObject:SetActiveEx(isShow and self.TeamData ~= nil)
end

function XUiPanelRegression4Boost:IsOfficialChannel()
    local channelId = CS.XHeroSdkAgent.GetChannelId()
    return channelId == XDataCenter.UiPcManager.Channel.Android
        or channelId == XDataCenter.UiPcManager.Channel.IOS
        or channelId == XDataCenter.UiPcManager.Channel.Pc
end

function XUiPanelRegression4Boost:FindSubMenuData(subMenuList, menuIdKey)
    local menuId = tonumber(self._Control:GetClientConfigValue(menuIdKey, 1))
    if not XTool.IsNumberValid(menuId) then
        return
    end
    for _, data in ipairs(subMenuList) do
        if data.Id == menuId then
            return data
        end
    end
end
--endregion------------------数据刷新 finish-------------------

--region   ------------------事件回调 start-------------------
function XUiPanelRegression4Boost:OnBtnGo1Click()
    local skipId = tonumber(self._Control:GetClientConfigValue("BoostDoubleSkipId", 1))
    if XTool.IsNumberValid(skipId) then
        XFunctionManager.SkipInterface(skipId)
    end
end

function XUiPanelRegression4Boost:OnBtnGo2Click()
    local index = self:GetCanLiverTabIndex()
    if XTool.IsNumberValid(index) then
        XLuaUiManager.Open("UiTask", index)
    end
end

---@return number 勤务页签在排序配置中的下标
function XUiPanelRegression4Boost:GetCanLiverTabIndex()
    local tabCfgs = XTaskConfig.GetMainTaskTabControlTemplateSortList() or {}
    for index, cfg in ipairs(tabCfgs) do
        if cfg.TagType == CanLiverTabTagType then
            return index
        end
    end
end

function XUiPanelRegression4Boost:OnBtnStrategyClick()
    self:SkipBySubMenuData(self.StrategyData)
end

function XUiPanelRegression4Boost:OnBtnTeamClick()
    self:SkipBySubMenuData(self.TeamData)
end

function XUiPanelRegression4Boost:SkipBySubMenuData(data)
    if not data or not data.JumpAddr then
        return
    end
    local jumpType = tonumber(data.JumpType)
    if jumpType == SubMenuJumpType.Web then
        CS.UnityEngine.Application.OpenURL(data.JumpAddr)
    elseif jumpType == SubMenuJumpType.Game then
        XFunctionManager.SkipInterface(tonumber(data.JumpAddr))
    end
    XDataCenter.NoticeManager.ChangeSubMenuReadStatus(data.Id)
end
--endregion------------------事件回调 finish-------------------

return XUiPanelRegression4Boost
