
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridRegression4CheckIn = require("XUi/XUiRegression4/XUiGrid/XUiGridRegression4CheckIn")

---@class XUiPanelRegression4CheckIn: XUiNode
local XUiPanelRegression4CheckIn = XClass(XUiNode, "XUiPanelRegression4CheckIn")

local TeamMemberCount = 3
local TeamHideDuration = 0.3            -- 小人躲开动画时长
local TeamReturnDelay = XScheduleManager.SECOND * 2  -- 停止点击后返回的延迟
local TeamHideOffsetX = -2000           -- 躲出屏幕外的 X 偏移

function XUiPanelRegression4CheckIn:OnStart()
    self.RootUi = self.Parent
    self.ViewModel = self._Control:GetMainViewModel()
    self:InitCb()
    self:InitUi()
end

function XUiPanelRegression4CheckIn:OnEnable()
    self:RefreshView()
end

function XUiPanelRegression4CheckIn:InitCb()
    self.BtnPlot:AddEventListener(handler(self, self.OnBtnPlotClick))
    self.BtnGift:AddEventListener(handler(self, self.OnBtnGiftClick))
end

function XUiPanelRegression4CheckIn:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList)
    self.DynamicTable:SetProxy(XUiGridRegression4CheckIn, self)
    self.DynamicTable:SetDelegate(self)
    self.GridDaily.gameObject:SetActiveEx(false)
    self:InitTeamMembers()
end

--- 灰鸦小队彩蛋：点击小人躲出屏幕，停止点击 2 秒后返回，各成员独立
function XUiPanelRegression4CheckIn:InitTeamMembers()
    self.TeamMembers = {}
    for i = 1, TeamMemberCount do
        local indexStr = string.format("%02d", i)
        local btn = self["BtnMember" .. indexStr]
        if btn and not XTool.UObjIsNil(btn) then
            self.TeamMembers[i] = { Btn = btn, Hiding = false, Timer = nil }
            btn:AddEventListener(handler(self, self["OnBtnMember" .. i .. "Click"]))
        end
    end
end

function XUiPanelRegression4CheckIn:OnBtnMember1Click()
    self:HideTeamMember(1)
end

function XUiPanelRegression4CheckIn:OnBtnMember2Click()
    self:HideTeamMember(2)
end

function XUiPanelRegression4CheckIn:OnBtnMember3Click()
    self:HideTeamMember(3)
end

--- 先这么写，之后应该会直接接动效，不需要代码操控
function XUiPanelRegression4CheckIn:HideTeamMember(index)
    local member = self.TeamMembers[index]
    if not member or member.Hiding then
        return
    end
    -- ImgMember 为 BtnMember 下的子节点，无需 UiObject 绑定
    if not member.Img then
        member.Img = XUiHelper.TryGetComponent(member.Btn.transform, "ImgMember" .. string.format("%02d", index))
        if member.Img then
            member.OriginPos = member.Img.transform.localPosition
        end
    end
    member.Hiding = true
    if member.Timer then
        XScheduleManager.UnSchedule(member.Timer)
    end
    if member.Img then
        local hidePos = member.OriginPos + CS.UnityEngine.Vector3(TeamHideOffsetX, 0, 0)
        member.Img.transform:DOLocalMove(hidePos, TeamHideDuration)
    end
    member.Timer = XScheduleManager.ScheduleOnce(function()
        member.Timer = nil
        member.Hiding = false
        if member.Img then
            member.Img.transform:DOLocalMove(member.OriginPos, TeamHideDuration)
        end
    end, TeamReturnDelay)
end

function XUiPanelRegression4CheckIn:RefreshView()
    if not self._Control:CheckSignLocalRedPointData() then
        self._Control:MarkSignLocalRedPointData()
    end
    self:SetupDynamicTable()
    self:UpdateTime()
end

function XUiPanelRegression4CheckIn:SetupDynamicTable()
    local signViewModel = self.ViewModel:GetSignViewModel()
    self.SignList = signViewModel:GetSignInfos()
    self.DynamicTable:SetDataSource(self.SignList)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPanelRegression4CheckIn:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.SignList[index])
    end
end

--- 回归剧情重播
function XUiPanelRegression4CheckIn:OnBtnPlotClick()
    XDataCenter.MovieManager.PlayMovie(self.ViewModel:GetStoryId())
end

--- 回归赠礼：复用通用获得弹窗
function XUiPanelRegression4CheckIn:OnBtnGiftClick()
    local rewardId = self._Control:GetTriggerRewardId(self.ViewModel:GetProperty("_Id"))
    local rewardList = XRewardManager.GetRewardList(rewardId)
    if XTool.IsTableEmpty(rewardList) then
        return
    end
    XUiManager.OpenUiObtain(rewardList)
end

--- 领取当前页所有可领取的签到奖励（协议仅支持单个领取，循环请求；每个请求各自弹一次获得弹窗）
function XUiPanelRegression4CheckIn:RequestAllCanReceive()
    local signViewModel = self.ViewModel:GetSignViewModel()
    local signInfos = self.SignList or signViewModel:GetSignInfos()
    local cb = handler(self, self.RefreshGrids)
    for _, signData in ipairs(signInfos) do
        if not signViewModel:CheckIsReceive(signData.Id) and signViewModel:CheckIsSign(signData.Days) then
            self._Control:RequestSignIn(signData.Id, cb)
        end
    end
end

function XUiPanelRegression4CheckIn:RefreshGrids()
    for index, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:Refresh(self.SignList[index])
    end
end

function XUiPanelRegression4CheckIn:UpdateTime()
end

return XUiPanelRegression4CheckIn
