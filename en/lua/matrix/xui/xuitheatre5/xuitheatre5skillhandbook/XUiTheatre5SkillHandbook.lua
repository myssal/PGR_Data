local XUiTheatre5SkillHandbookTabGrid = require("XUi/XUiTheatre5/XUiTheatre5SkillHandbook/XUiTheatre5SkillHandbookTabGrid")
local XUiTheatre5SkillHandbookTag = require("XUi/XUiTheatre5/XUiTheatre5SkillHandbook/XUiTheatre5SkillHandbookTag")

---@class XUiTheatre5SkillHandbook : XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5SkillHandbook = XLuaUiManager.Register(XLuaUi, "UiTheatre5SkillHandbook")

function XUiTheatre5SkillHandbook:OnAwake()
    ---@type XUiTheatre5SkillHandbookTabGrid[]
    self._Tabs = {}
    ---@type XUiTheatre5SkillHandbookTag[]
    self._Tags = {}
    self:BindExitBtns()

    self._TimerDelayInit = false

    ---@type UnityEngine.UI.ScrollRect
    self.PanelItemList = self.PanelItemList or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelItemList", "ScrollRect")

    self._Index = 0
end

function XUiTheatre5SkillHandbook:OnStart()
    self.PanelBtnTab:Init({
        self.BtnTab1,
        self.BtnTab2,
    }, function(index)
        if self._TimerDelaySelectTab then
            XScheduleManager.UnSchedule(self._TimerDelaySelectTab)
            self._TimerDelaySelectTab = nil
        end
        self:OnSelectTab(index)
    end)
    
    -- 延迟一秒播放, 让玩家看到动画
    self._TimerDelaySelectTab = XScheduleManager.ScheduleOnce(function()
        self._TimerDelaySelectTab = nil
        self.PanelBtnTab:SelectIndex(1)
    end, 500)
end

function XUiTheatre5SkillHandbook:OnEnable()
    self:Update()
end

function XUiTheatre5SkillHandbook:OnDisable()
end

function XUiTheatre5SkillHandbook:OnDestroy()
    if self._TimerDelayInit then
        XScheduleManager.UnSchedule(self._TimerDelayInit)
        self._TimerDelayInit = nil
    end
    if self._TimerDelaySelectTab then
        XScheduleManager.UnSchedule(self._TimerDelaySelectTab)
        self._TimerDelaySelectTab = nil
    end
end

function XUiTheatre5SkillHandbook:Update()
end

function XUiTheatre5SkillHandbook:OnSelectTab(index)
    if index == self._Index then
        return
    end
    
    -- 第一次不播放切换动画，相同的index不播放切换动画
    if self._Index > 0 then
        self:PlayAnimation("QieHuan")
    end
    self._Index = index

    -- 切换页签后，滚到0的位置
    self.PanelItemList.verticalNormalizedPosition = 1
    if index == 1 then
        local type = XMVCA.XTheatre5.EnumConst.ItemType.Skill
        local datas = self._Control:GetDataHandBook(type)
        XTool.UpdateDynamicItemLazy(self._Tabs, datas, self.Panel, XUiTheatre5SkillHandbookTabGrid, self, 1, 24)
        -- 默认选中第一个
        if datas and #datas > 0 and datas[1].Items and #datas[1].Items > 0 then
            self:OnSelectItem(datas[1].Items[1])
        else
            XLog.Error("[XUiTheatre5SkillHandbook] default select fail")
        end
        return
    end
    if index == 2 then
        local type = XMVCA.XTheatre5.EnumConst.ItemType.Equip
        local datas = self._Control:GetDataHandBook(type)
        XTool.UpdateDynamicItemLazy(self._Tabs, datas, self.Panel, XUiTheatre5SkillHandbookTabGrid, self, 1, 24)
        -- 默认选中第一个
        if datas and #datas > 0 and datas[1].Items and #datas[1].Items > 0 then
            self:OnSelectItem(datas[1].Items[1])
        else
            XLog.Error("[XUiTheatre5SkillHandbook] default select fail")
        end
        return
    end
end

---@param data XUiTheatre5SkillHandbookItemGridData
function XUiTheatre5SkillHandbook:OnSelectItem(data)
    self.TxtStory.text = data.Desc
    self.RImgIcon:SetRawImage(data.Icon)
    self.TxtName.text = data.Name
    if data.Quality == 0 then
        self.ImgQuality.gameObject:SetActiveEx(false)
    else
        self.ImgQuality.gameObject:SetAxctiveEx(true)
        XUiHelper.SetQualityIcon(self, self.ImgQuality, data.Quality)
    end

    -- tag
    XTool.UpdateDynamicItem(self._Tags, data.Tags, self.GridTag, XUiTheatre5SkillHandbookTag, self)

    for i, tags in pairs(self._Tabs) do
        tags:UpdateSelectState(data)
    end
end

return XUiTheatre5SkillHandbook