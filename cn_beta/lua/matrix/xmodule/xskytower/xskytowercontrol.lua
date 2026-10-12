---@class XSkyTowerControl : XEntityControl
---@field private _Model XSkyTowerModel
local XSkyTowerControl = XClass(XEntityControl, "XSkyTowerControl", true)

--region 部分类初始化
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlConfig", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlNetwork", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlScene", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlGrowth", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlProduct", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlPerform", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlOperation", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlRedPoint", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlStaff", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlSkill", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlPerformData", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlBusiness", "XSkyTowerControl")
XClassPartialRequire("XModule/XSkyTower/XControlPartial/XSkyTowerControlTask", "XSkyTowerControl")
--endregion

function XSkyTowerControl:OnInit()
    self._UiCommonSortingOrder = 0
    XMVCA.XSkyTower:SetInActivity(true)
    self:InitScene()
    self:InitStaff()
    self:InitTask()
    self:InitBusiness()
end

function XSkyTowerControl:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_ENTER_ROOM, self.EnterRoom, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.OnBusinessDataChange, self)
    -- 工位布局与技能激活态都会改变光环覆盖关系，索引须重建
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE, self.ClearSkillShareIndex, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_FLOOR_CHANGE, self.ClearSkillShareIndex, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE, self.ClearSkillShareIndex, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_STAFF_CHANGE, self.ClearSkillShareIndex, self)
    --生产速率由工位、技能和已解锁分区共同决定，库存变更只刷新数量
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_FLOOR_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_STAFF_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE, self.InvalidateProductionCounts, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_REBUILD, self.UpdateTaskSchedule, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_TASK_ADD_COMMAND, self.AddTaskCommand, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.UpdateTaskSchedule, self)
end

function XSkyTowerControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_ENTER_ROOM, self.EnterRoom, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.OnBusinessDataChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE, self.ClearSkillShareIndex, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_FLOOR_CHANGE, self.ClearSkillShareIndex, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE, self.ClearSkillShareIndex, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_STAFF_CHANGE, self.ClearSkillShareIndex, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_FLOOR_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_STAFF_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE, self.InvalidateProductionStatistics, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE, self.InvalidateProductionCounts, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_REBUILD, self.UpdateTaskSchedule, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_TASK_ADD_COMMAND, self.AddTaskCommand, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.UpdateTaskSchedule, self)
end

function XSkyTowerControl:OnRelease()
    self:ExitRoomClearRes()
    self:ReleaseConfig()
    self:ReleaseRequest()
    self:ReleaseSkill()
    self:ReleaseStaff()
    self:ReleaseScene()
    self:ReleaseBusiness()
    XMVCA.XSkyTower:SetInActivity(false)
end

---当前所在楼层Id
---@return number
function XSkyTowerControl:GetCurFloorId()
    return self._CurFloorId or 0
end

---当前所在楼层区间Id
---@return number
function XSkyTowerControl:GetCurFloorGroupId()
    return self._Model:GetFloorGroupIdByFloorId(self:GetCurFloorId())
end

function XSkyTowerControl:OnActivityEnd()
    self._Model:ResetActivity()
end

function XSkyTowerControl:GetFloorValue(value, digital)
    local decimal = math.pow(10, digital)
    return math.floor(value * decimal) / decimal
end

function XSkyTowerControl:IsIngredientArea(workType)
    return workType == XMVCA.XSkyTower.WorkType.Ingredient
end

function XSkyTowerControl:IsCookArea(workType)
    return workType == XMVCA.XSkyTower.WorkType.Food
end

function XSkyTowerControl:IsSaleArea(workType)
    return workType == XMVCA.XSkyTower.WorkType.Sale
end

function XSkyTowerControl:IsZero(num)
    return math.abs(num) <= XMVCA.XSkyTower.Inaccurate
end

function XSkyTowerControl:OpenTask()
    XLuaUiManager.Open("UiSkyTowerTask")
end

function XSkyTowerControl:OpenUnlockTip(title, datas, isShowTip, cb)
    XLuaUiManager.Open("UiSkyTowerUnlockFood", title, datas, isShowTip, cb)
end

function XSkyTowerControl:OpenMenu(tabId, ...)
    if not self._Model:IsOpen() then
        return
    end
    XLuaUiManager.Open("UiSkyTowerMenu", tabId, ...)
end

function XSkyTowerControl:OpenStatistics(workType, firstProductId, floorGroupId)
    local uiName = "UiSkyTowerExamine"
    if XLuaUiManager.IsUiLoad(uiName) then
        XLuaUiManager.Remove(uiName)
    end
    XLuaUiManager.Open(uiName, workType, firstProductId, floorGroupId)
end

function XSkyTowerControl:OpenPopup(title, content, itemData, cancelCb, confirmCb, isHideBtnCancel)
    local uiName = "UiSkyTowerPopup"
    if XLuaUiManager.IsUiLoad(uiName) then
        XLuaUiManager.Remove(uiName)
    end
    XLuaUiManager.Open(uiName, title, content, itemData, cancelCb, confirmCb, isHideBtnCancel)
end

--通天塔通用奖励弹窗
function XSkyTowerControl:OpenCommonObtain(rewardGoodsList, title, closeCallback, sureCallback)
    if XUiManager.IsTableAsyncLoading() then
        XUiManager.WaitTableLoadComplete(function()
            XLuaUiManager.Open("UiSkyTowerObtain", rewardGoodsList, title, closeCallback, sureCallback)
        end)
        return
    end
    XLuaUiManager.Open("UiSkyTowerObtain", rewardGoodsList, title, closeCallback, sureCallback)
end

function XSkyTowerControl:OpenPerformUi(performId, isHidePost)
    --事件解锁即进行中，按尚未保存的剧情选项决定是否进入对话
    if self:IsPerform(performId) and self:IsOnGoing(performId) then
        local record = self:GetPerformStoryInfo(performId) or table.empty
        for _, talkId in ipairs(self:GetTalkStoryTalkIds(performId)) do
            if self:GetTalkConfig(talkId).Type == XMVCA.XSkyTower.MessageType.Select and not record[talkId] then
                XLuaUiManager.Open("UiSkyTowerPopupChat", performId)
                return
            end
        end
    end
    XLuaUiManager.Open("UiSkyTowerPopupStory", performId, isHidePost)
end

function XSkyTowerControl:GetCommonSortingOrder()
    return self._UiCommonSortingOrder
end

function XSkyTowerControl:SetCommonSortingOrder(value)
    self._UiCommonSortingOrder = value
end

function XSkyTowerControl:GetSetting(key)
    return self._Model:GetSetting(key)
end

function XSkyTowerControl:SaveSetting(key, value)
    self._Model:SaveSetting(key, value)
end

---活动内货币读取协议余额，其余道具沿用通用背包数量
function XSkyTowerControl:GetItemCount(itemId)
    return self._Model:GetItemCount(itemId)
end

---@return XUiPanelSkyTowerActivityAsset
function XSkyTowerControl:NewPanelActivityAsset(itemIds, panelGo, parent)
    ---@type XUiPanelSkyTowerActivityAsset
    local assetActivityPanel = require("XUi/XUiSkyTower/XUiPanel/XUiPanelSkyTowerActivityAsset").New(panelGo, parent)
    assetActivityPanel:Open()
    for _, id in pairs(itemIds) do
        if not self:IsSkyTowerItem(id) then
            XDataCenter.ItemManager.AddCountUpdateListener(id, function()
                assetActivityPanel:RefreshCurrentAssets()
            end, assetActivityPanel)
        end
    end
    assetActivityPanel:Refresh(itemIds)
    return assetActivityPanel
end

return XSkyTowerControl
    XDataCenter.ItemManager.AddCountUpdateListener(id, function()
                assetActivityPanel:RefreshCurrentAssets()
            end, assetActivityPanel)
        end
    end
    assetActivityPanel:Refresh(itemIds)
    return assetActivityPanel
end

return XSkyTowerControl
