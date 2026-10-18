---@class XUiSkyTowerWork : XLuaUi 分配工作界面
---@field _Control XSkyTowerControl
local XUiSkyTowerWork = XLuaUiManager.Register(XLuaUi, "UiSkyTowerWork")

--region 生命周期
function XUiSkyTowerWork:OnAwake()
    self:RegisterUiEvents()
end

---@param workType number 工作类型
---@param index number 工位下标
---@param floorId number 工位所在楼层，不传取当前楼层
function XUiSkyTowerWork:OnStart(workType, index, floorId)
    self._Index = index
    self._FloorId = XTool.IsNumberValid(floorId) and floorId or self._Control:GetCurFloorId()
    self._AppointWorkType = self._Control:GetFloorAppointWorkByIndex(self._FloorId, index)
    -- 已开工的工位打开时直接落到详情页，此时以工位上真实的工作类型为准
    self._IsRunningOnOpen = self._Control:IsRunning(self._FloorId, self._Index)
    if self._IsRunningOnOpen then
        self._WorkType = self._Control:GetWorkType(self._FloorId, self._Index)
    else
        self._WorkType = workType or XMVCA.XSkyTower.WorkType.Ingredient
    end
    self._WorkPosOverride = nil
    self:InitView()
    self:InitTab()
    -- SelectIndex的回调会被OnTabClick的同值判断吃掉，首屏得自己显示一次
    if self._IsRunningOnOpen then
        self:ShowMakeSureView()
    else
        self:ShowTabView()
    end
end

function XUiSkyTowerWork:OnEnable()
    self._WorkRefreshEnabled = true
    self:RefreshWorkView()
end

function XUiSkyTowerWork:OnDisable()
    self._WorkRefreshEnabled = false
    self:CancelWorkRefresh()
end
--endregion

--region 事件
function XUiSkyTowerWork:OnGetLuaEvents()
    return {
        XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE,
        XEventId.EVENT_SKY_TOWER_DATA_CHANGE,
        XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE,
        XEventId.EVENT_SKY_TOWER_STAFF_CHANGE,
        XEventId.EVENT_SKY_TOWER_FLOOR_CHANGE,
        XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE,
        XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE,
        XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE,
        XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_UPDATE,
        XEventId.EVENT_SKY_TOWER_DAILY_RESET,
    }
end

function XUiSkyTowerWork:OnNotify(event, ...)
    if event == XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_UPDATE then
        self._PanelOrder:RefreshView()
        return
    end
    self:RequestWorkRefresh()
end

-- 合并到下一帧后再读取最终数据
function XUiSkyTowerWork:RequestWorkRefresh()
    if not self._WorkRefreshEnabled or self._WorkRefreshTimer then
        return
    end
    self._WorkRefreshCb = self._WorkRefreshCb or handler(self, self.OnWorkRefresh)
    self._WorkRefreshTimer = XScheduleManager.ScheduleNextFrame(self._WorkRefreshCb)
end

function XUiSkyTowerWork:OnWorkRefresh()
    self._WorkRefreshTimer = nil
    if self._WorkRefreshEnabled and not XTool.UObjIsNil(self.GameObject) then
        self:RefreshWorkView()
    end
end

function XUiSkyTowerWork:CancelWorkRefresh()
    if self._WorkRefreshTimer then
        XScheduleManager.UnSchedule(self._WorkRefreshTimer)
        self._WorkRefreshTimer = nil
    end
end

function XUiSkyTowerWork:RefreshWorkView()
    self:RefreshBonus()
    -- 订单无数据时会关闭，仍需刷新才能在新订单到来时重新显示
    self._PanelOrder:RefreshView()
    if self._IsTabView then
        self._TabPanels[self._WorkType]:RefreshData()
    end
    if self._PanelRole:IsNodeShow() then
        self._PanelRole:RefreshData()
    end
    if self._PanelRoleYield:IsNodeShow() then
        self._PanelRoleYield:RefreshView()
    end
end
--endregion

--region 界面刷新
function XUiSkyTowerWork:InitView()
    ---@type XUiComponent.XUiButton[] 页签顺序与UI摆放一致：备材、制作、售卖
    self._TabWorkTypes = {
        [XMVCA.XSkyTower.WorkType.Ingredient] = self.BtnMaterials,
        [XMVCA.XSkyTower.WorkType.Food] = self.BtnProduction,
        [XMVCA.XSkyTower.WorkType.Sale] = self.BtnSell,
    }
    ---@type XUiPanelSkyTowerWorkMaterials 备材
    self._PanelMaterials = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerWorkMaterials").New(self.PanelMaterials, self)
    ---@type XUiPanelSkyTowerWorkProduction 制作
    self._PanelProduction = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerWorkProduction").New(self.PanelProduction, self)
    ---@type XUiPanelSkyTowerWorkSell 销售
    self._PanelSell = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerWorkSell").New(self.PanelSell, self)
    ---@type XUiPanelSkyTowerWorkBaseFood 仓库栏
    self._PanelBaseFood = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerWorkBaseFood").New(self.PanelBaseFood, self)
    ---@type XUiPanelSkyTowerWorkChooseRole 选择角色
    self._PanelRole = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerWorkChooseRole").New(self.PanelRole, self)
    ---@type XUiPanelSkyTowerBonusBubble 加成列表
    self._PanelBubbleDetail = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerBonusBubble").New(self.PanelBubbleDetail, self)
    ---@type XUiPanelSkyTowerWorkRoleYield 确认安排角色
    self._PanelRoleYield = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerWorkRoleYield").New(self.PanelRoleYield, self)
    ---@type XUiPanelSkyTowerWorkOrder 订单
    self._PanelOrder = require("XUi/XUiSkyTower/XUiPanel/Work/XUiPanelSkyTowerWorkOrder").New(self.PanelOrder, self)
    ---@type XUiPanelSkyTowerWorkBase[] 各页签自己那份产品选择面板
    self._TabPanels = {
        [XMVCA.XSkyTower.WorkType.Ingredient] = self._PanelMaterials,
        [XMVCA.XSkyTower.WorkType.Food] = self._PanelProduction,
        [XMVCA.XSkyTower.WorkType.Sale] = self._PanelSell,
    }
end

function XUiSkyTowerWork:InitTab()
    if self._WorkType == XMVCA.XSkyTower.WorkType.None then
        self._WorkType = XMVCA.XSkyTower.WorkType.Ingredient
    end
    self.TabBtnGroup.gameObject:SetActiveEx(true)
    self.TabBtnGroup:Init(self._TabWorkTypes, function(index)
        self:OnTabClick(index)
    end)
    self.TabBtnGroup:SelectIndex(self._WorkType)

    for workType, btn in pairs(self._TabWorkTypes) do
        btn.gameObject:SetActiveEx(workType == self._AppointWorkType or self._AppointWorkType == XMVCA.XSkyTower.WorkType.None)
    end
end

function XUiSkyTowerWork:OnTabClick(workType)
    if workType == self._WorkType then
        return
    end
    self._WorkType = workType
    self:ShowTabView()
end

-- 只在产品选择页显示加成按钮，多个角色技能也只显示一个箭头
function XUiSkyTowerWork:RefreshBonus()
    if XTool.UObjIsNil(self.BtnBonusInfo) then
        return
    end
    self.BonusList = table.empty
    if not self._IsTabView then
        self.BtnBonusInfo.gameObject:SetActiveEx(false)
        self._PanelBubbleDetail:Close()
        return
    end
    for workType, btn in pairs(self._TabWorkTypes) do
        local bonusList = self._Control:GetWorkBonusList(self._FloorId, self._Index, workType)
        local hasBonus = not XTool.IsTableEmpty(bonusList)
        btn:SetSpriteVisible(hasBonus)
        if hasBonus then
            btn:SetSprite(self._Control:GetMenuBonusIcon(1))
        end
        if workType == self._WorkType then
            self.BonusList = bonusList
        end
    end
    local hasBonus = not XTool.IsTableEmpty(self.BonusList)
    self.BtnBonusInfo.gameObject:SetActiveEx(hasBonus)
    if not hasBonus then
        self._PanelBubbleDetail:Close()
        return
    end
    self.BtnBonusInfo:SetSprite(self._Control:GetMenuBonusIcon(1))
    if self._PanelBubbleDetail:IsNodeShow() then
        self._PanelBubbleDetail:RefreshView(self.BonusList)
    end
end

-- 制作页签换了选中产品时，仓库栏要把该配方要用的材料排到前面
function XUiSkyTowerWork:RefreshBaseFood(productId)
    self._PanelBaseFood:SetProductId(productId)
end
--endregion

--region 安排工作流程
function XUiSkyTowerWork:ClearWorkPosPreview()
    self._WorkPosOverride = nil
end

---@return table<number, XSkyTowerWorkPosInfoProtocol> 无待确认安排时为nil
function XUiSkyTowerWork:GetWorkPosOverride()
    return self._WorkPosOverride
end

-- 页签页/选人页/确认页三者互斥，全部经这里统一设置显隐，漏关一块就会叠在别的页上
---@param isTab boolean 停在备材/制作/销售页签页
---@param showRole boolean 显示选择角色页
---@param showRoleYield boolean 显示确认安排页
function XUiSkyTowerWork:RefreshViewState(isTab, showRole, showRoleYield)
    self._IsTabView = isTab
    self._PanelBubbleDetail:Close()
    self.TabBtnGroup.gameObject:SetActiveEx(isTab)
    self._PanelMaterials:SetVisible(isTab and self._WorkType == XMVCA.XSkyTower.WorkType.Ingredient)
    self._PanelBaseFood:SetVisible(isTab and self._WorkType == XMVCA.XSkyTower.WorkType.Food)
    self._PanelProduction:SetVisible(isTab and self._WorkType == XMVCA.XSkyTower.WorkType.Food)
    self._PanelSell:SetVisible(isTab and self._WorkType == XMVCA.XSkyTower.WorkType.Sale)
    self._PanelRole:SetVisible(showRole)
    self._PanelRoleYield:SetVisible(showRoleYield)
    self:RefreshBonus()
end

-- 显示备材/制作/销售界面
function XUiSkyTowerWork:ShowTabView()
    self:RefreshViewState(true, false, false)
end

-- 显示选择角色界面
function XUiSkyTowerWork:ShowSelectRole()
    self:RefreshViewState(false, true, false)
end

-- 显示确认角色界面
---@param characterId number 本轮选中的员工，直入详情时不传，取工位上已有的
function XUiSkyTowerWork:ShowMakeSureView(characterId)
    local productId = self:GetSelectProductId()
    local workInfo = self._Control:GetWorkPos(self._FloorId, self._Index)
    self:ClearWorkPosPreview()
    -- 直入详情或选择未变时仍展示真实工位
    if characterId and (not workInfo or workInfo.WorkType ~= self._WorkType or workInfo.ProductId ~= productId or workInfo.CharacterId ~= characterId) then
        self._WorkPosOverride = self._Control:MakeStaffPreviewOverride(characterId, self._FloorId, self._Index, self._WorkType, productId)
    end
    self:RefreshViewState(false, false, true)
end

-- 每次刷新从最新真实布局重建，避免角色原岗位变动或升级后继续复用旧预览索引
---@return table, table<number, table<number, number>> 布局override、对应技能条件系数
function XUiSkyTowerWork:RefreshWorkPosPreview()
    if not self._WorkPosOverride then
        return nil, nil
    end
    local workInfo = self:GetWorkInfo()
    self._WorkPosOverride = self._Control:MakeStaffPreviewOverride(workInfo.CharacterId, self._FloorId, self._Index, workInfo.WorkType, workInfo.ProductId)
    return self._WorkPosOverride, self._Control:BuildPreviewSkillRatios(self._WorkPosOverride)
end

function XUiSkyTowerWork:OnAssignWorkSuccess()
    self:ClearWorkPosPreview()
    self:Close()
end
--endregion

--region 工位信息
---@return XSkyTowerWorkPosInfoProtocol
function XUiSkyTowerWork:GetWorkInfo()
    if self._WorkPosOverride then
        return self._WorkPosOverride[self._Control:MakeWorkPosKey(self._FloorId, self._Index)]
    end
    return self._Control:GetWorkPos(self._FloorId, self._Index)
end

function XUiSkyTowerWork:GetFloorId()
    return self._FloorId
end

function XUiSkyTowerWork:GetIndex()
    return self._Index
end

function XUiSkyTowerWork:GetWorkType()
    return self._WorkType
end

-- 当前页签上选中的产品，直入详情时页签没被点过，退回工位上已有的
function XUiSkyTowerWork:GetSelectProductId()
    local panel = self._TabPanels[self._WorkType]
    local productId = panel and panel:GetSelectProductId()
    if XTool.IsNumberValid(productId) then
        return productId
    end
    local workInfo = self:GetWorkInfo()
    return workInfo and workInfo.ProductId or 0
end
--endregion

--region 按钮
function XUiSkyTowerWork:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnWndClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnBonusInfo:AddEventListener(handler(self, self.OnBtnBonusInfoClick))
end

function XUiSkyTowerWork:OnBtnCloseClick()
    self:Close()
end

function XUiSkyTowerWork:OnBtnBonusInfoClick()
    if not self._IsTabView or XTool.IsTableEmpty(self.BonusList) then
        return
    end
    if self._PanelBubbleDetail:IsNodeShow() then
        self._PanelBubbleDetail:Close()
        return
    end
    self._PanelBubbleDetail:Show(self.BonusList)
end
--endregion

return XUiSkyTowerWork
