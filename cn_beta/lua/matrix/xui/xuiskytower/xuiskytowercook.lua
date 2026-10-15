local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local XUiCommonRollingNumber = require("XUi/XUiCommon/XUiCommonRollingNumber")
local XUiGridSkyTowerSkillItem = require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerSkillItem")
local XUiGridSkyTowerCookRole = require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerCookRole")

---@class XUiSkyTowerCook : XLuaUi 角色弹窗
---@field private _Control XSkyTowerControl
---@field BtnUp XUiComponent.XUiButton
---@field PanelTabCharacter XUiButtonGroup
local XUiSkyTowerCook = XLuaUiManager.Register(XLuaUi, "UiSkyTowerCook")

--region 生命周期
function XUiSkyTowerCook:OnAwake()
    self.GridRole.gameObject:SetActiveEx(false)
    self.BtnTabSkill.gameObject:SetActiveEx(false)
    self.GridSkill.gameObject:SetActiveEx(false)
    self.GridArea.gameObject:SetActiveEx(false)
    self.BtnTabFilter.gameObject:SetActiveEx(false)
    self.BtnTab.gameObject:SetActiveEx(false)
    self.TxtSkillDesc.requestImage = XMVCA.XSkyTower.RichTextImageCallBack
    self:RegisterUiEvents()
end

---@param characterId number 可为空
function XUiSkyTowerCook:OnStart(characterId)
    self.LocateCharacterId = characterId

    ---@type UiObject[]
    self.FloorGridList = {}
    ---@type XUiGridSkyTowerSkillItem[]
    self.SkillGridList = {}
    ---@type XUiComponent.XUiButton[]
    self.SkillBtnList = {}

    self.CurSelectFloorGroupTabIndex = 0
    self.CurSelectSkillTagIndex = 0

    self.CurSelectSkillBtnIndex = 0
    self.CurSelectSkillId = 0

    ---@type XUiGridSkyTowerCookRole
    self.CurSelectRoleGrid = nil
    self.CurSelectRoleId = 0
    self._DetailCharacterId = 0

    -- 缓存等级文本原色，退出预览态时还原
    self.TxtLvColor = self.TxtLv.color

    self:InitDynamicTable()
    self:InitFloorGroupTab()
    self:InitSkillTab()

    self._Control:RequestSettleToNow()
end

function XUiSkyTowerCook:OnEnable()
    if XTool.IsNumberValid(self.CurSelectFloorGroupTabIndex) then
        self:SetupDynamicTable()
    else
        local floorGroupId = 1
        if XTool.IsNumberValid(self.LocateCharacterId) then
            floorGroupId = self._Control:GetCharacterFloorGroup(self.LocateCharacterId)
        end
        self.PanelTabArea:SelectIndex(floorGroupId)
    end
end

function XUiSkyTowerCook:OnDisable()
    self:ResetLongClick()
    self:StopLevelRoll()
end

function XUiSkyTowerCook:OnDestroy()
    self.LevelRoll = nil
    if self.LongClick then
        self.LongClick:Destroy()
        self.LongClick = nil
    end
end
--endregion

--region 事件
function XUiSkyTowerCook:OnGetLuaEvents()
    return {
        XEventId.EVENT_SKY_TOWER_STAFF_CHANGE,
        XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE,
        XEventId.EVENT_SKY_TOWER_DATA_CHANGE,
        XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE,
    }
end

function XUiSkyTowerCook:OnNotify(event)
    if event == XEventId.EVENT_SKY_TOWER_STAFF_CHANGE then
        self:RefreshSelectGrid()
        self:RefreshDetails()
    elseif event == XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE then
        self:RefreshDetails()
    else
        -- 升级券数量变化只影响消耗文本颜色与能否升级
        if self.PendingLevel and self.PendingLevel > self.CurCharacterLevel then
            --活动结算可能在长按期间到达，保留已累计的目标等级
            self:RefreshConsumeText(self.PendingLevel)
        else
            self:RefreshDetails()
        end
    end
end
--endregion

--region 页签
-- 分区页签
function XUiSkyTowerCook:InitFloorGroupTab()
    self.FloorGroupIds = {}
    for groupId = 1, self._Control:GetMaxFloorGroupId() do
        table.insert(self.FloorGroupIds, groupId)
    end
    if XTool.IsTableEmpty(self.FloorGroupIds) then
        -- 楼层表未配置时至少保留当前所在分区，避免整个列表打不开
        table.insert(self.FloorGroupIds, self._Control:GetCurFloorGroupId())
    end
    local btnList = {}
    for index, groupId in ipairs(self.FloorGroupIds) do
        local btn = XUiHelper.Instantiate(self.BtnTab, self.PanelTabArea.transform)
        btn:SetNameByGroup(0, self._Control:GetFloorGroupName(groupId))
        btn.gameObject:SetActiveEx(true)
        btnList[index] = btn
    end
    self.PanelTabArea:Init(btnList, handler(self, self.OnSelectFloorGroupTab))
end

-- 标签筛选页签
function XUiSkyTowerCook:InitSkillTab()
    local btnList = {}
    for tagType = 1, XMVCA.XSkyTower.SkillFilterMaxTagCount do
        local btn = XUiHelper.Instantiate(self.BtnTabFilter, self.PanelTabCharacter.transform)
        btn:SetNameByGroup(0, self._Control:GetSkillTypeName(tagType))
        btn.gameObject:SetActiveEx(true)
        btnList[tagType] = btn
    end
    self.PanelTabCharacter:Init(btnList, handler(self, self.OnSelectSkillTag))
    self.PanelTabCharacter:CancelSelect()
end

function XUiSkyTowerCook:OnSelectFloorGroupTab(tabIndex)
    if self.CurSelectFloorGroupTabIndex == tabIndex then
        return
    end
    self.CurSelectFloorGroupTabIndex = tabIndex
    self:SetupDynamicTable()
end

function XUiSkyTowerCook:OnSelectSkillTag(tabIndex)
    self.CurSelectSkillTagIndex = self.CurSelectSkillTagIndex ~= tabIndex and tabIndex or 0
    self:SetupDynamicTable()
end
--endregion

--region 成员列表
function XUiSkyTowerCook:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEmploymentList)
    self.DynamicTable:SetProxy(XUiGridSkyTowerCookRole, self, handler(self, self.OnSelectRole))
    self.DynamicTable:SetDelegate(self)
end

function XUiSkyTowerCook:GetCharacterDataList()
    self.CurSelectFloorGroupTabIndex = self.CurSelectFloorGroupTabIndex or 1
    local groupId = self.FloorGroupIds and self.FloorGroupIds[self.CurSelectFloorGroupTabIndex] or 0
    local characterIds = self._Control:GetUnlockCharacterIds()
    local list = {}
    -- 排序键预先取好
    local keys = {}
    for _, characterId in ipairs(characterIds) do
        if self._Control:IsCharacterInFloorGroup(characterId, groupId) and self._Control:IsCharacterHasSkillTag(characterId, self.CurSelectSkillTagIndex) then
            table.insert(list, characterId)
            keys[characterId] = {
                IsUniversal = self._Control:GetCharacterIsUniversal(characterId),
                Level = self._Control:GetCurCharacterLevel(characterId),
                Priority = self._Control:GetCharacterPriority(characterId),
            }
        end
    end
    -- 常规角色在前（等级高在前），通用角色在后
    table.sort(list, function(a, b)
        local keyA, keyB = keys[a], keys[b]
        if keyA.IsUniversal ~= keyB.IsUniversal then
            return keyB.IsUniversal
        end
        if keyA.Level ~= keyB.Level then
            return keyA.Level > keyB.Level
        end
        if keyA.Priority ~= keyB.Priority then
            return keyA.Priority < keyB.Priority
        end
        return a < b
    end)
    return list
end

function XUiSkyTowerCook:SetupDynamicTable()
    self.CharacterDataList = self:GetCharacterDataList()
    self.CurSelectRoleGrid = nil
    local isEmpty = XTool.IsTableEmpty(self.CharacterDataList)
    if self.PanelDetails then
        self.PanelDetails.gameObject:SetActiveEx(not isEmpty)
    end
    if self.EmptyState then
        self.EmptyState.gameObject:SetActiveEx(isEmpty)
    end
    if isEmpty then
        self.DynamicTable:Clear()
        self:ClearDetails()
        return
    end

    -- 打开时定位到外部指定的角色（只生效一次）
    if XTool.IsNumberValid(self.LocateCharacterId) and self:IsCharacterInList(self.LocateCharacterId) then
        self.CurSelectRoleId = self.LocateCharacterId
    end
    self.LocateCharacterId = 0

    self.DynamicTable:SetDataSource(self.CharacterDataList)
    self.DynamicTable:ReloadDataSync(self:GetSelectIndex())
end

---@param grid XUiGridSkyTowerCookRole
function XUiSkyTowerCook:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local characterId = self.CharacterDataList[index]
        grid:Refresh(characterId)
        local isSelect = self.CurSelectRoleId == characterId
        grid:SetSelect(isSelect)
        if isSelect then
            self.CurSelectRoleGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:RefreshDetails()
    end
end

---@param grid XUiGridSkyTowerCookRole
function XUiSkyTowerCook:OnSelectRole(grid)
    local characterId = grid.CharacterId
    if not XTool.IsNumberValid(characterId) or characterId == self.CurSelectRoleId then
        return
    end

    if self.CurSelectRoleGrid then
        self.CurSelectRoleGrid:SetSelect(false)
    end
    grid:SetSelect(true)

    self:PlayAnimation("QieHuan")
    self.CurSelectRoleGrid = grid
    self.CurSelectRoleId = characterId

    self:RefreshDetails()
    self.PanelLbEx.horizontalNormalizedPosition = 0
end

-- 刷新当前选中的成员格子
function XUiSkyTowerCook:RefreshSelectGrid()
    if not self.CurSelectRoleGrid or not XTool.IsNumberValid(self.CurSelectRoleId) then
        return
    end
    if not self:IsCharacterInList(self.CurSelectRoleId) then
        return
    end
    self.CurSelectRoleGrid:Refresh(self.CurSelectRoleId)
end

-- 选中角色在列表中的下标，无选中时定位到首个
function XUiSkyTowerCook:GetSelectIndex()
    if not XTool.IsNumberValid(self.CurSelectRoleId) then
        self.CurSelectRoleId = self.CharacterDataList[1]
        return 1
    end
    for index, characterId in ipairs(self.CharacterDataList) do
        if characterId == self.CurSelectRoleId then
            return index
        end
    end
    self.CurSelectRoleId = self.CharacterDataList[1]
    return 1
end

function XUiSkyTowerCook:IsCharacterInList(characterId)
    if XTool.IsTableEmpty(self.CharacterDataList) then
        return false
    end
    for _, id in pairs(self.CharacterDataList) do
        if id == characterId then
            return true
        end
    end
    return false
end
--endregion

--region 角色信息
function XUiSkyTowerCook:ClearDetails()
    self:ResetLongClick()
    self.PendingLevel = nil
    self._DetailCharacterId = 0
    self.CurSelectRoleId = 0
    self.CurSelectSkillBtnIndex = 0
    self.CurSelectSkillId = 0
    self:HideAllGrids(self.FloorGridList)
    self:HideAllGrids(self.SkillBtnList)
    self:HideAllGrids(self.SkillGridList)

    self.PanelDishes.gameObject:SetActiveEx(false)
    self.PanelHead.gameObject:SetActiveEx(false)
    self.PanelTabSkill.gameObject:SetActiveEx(false)
    self.ImgSkillDescBg.gameObject:SetActiveEx(false)
    self.BtnUp.gameObject:SetActiveEx(false)
    self.BtnPreview.gameObject:SetActiveEx(false)

    -- 列表被筛空时清掉上一个角色的残留信息
    self.TxtName.text = ""
end

function XUiSkyTowerCook:RefreshDetails()
    if not XTool.IsNumberValid(self.CurSelectRoleId) then
        return
    end

    -- 点击角色或筛选后自动换人时才重置；同一角色升级、列表重刷保留技能页签
    if self._DetailCharacterId ~= self.CurSelectRoleId then
        self:ResetLongClick()
        self._DetailCharacterId = self.CurSelectRoleId
        self.CurSelectSkillBtnIndex = 0
        self.CurSelectSkillId = 0
        self.IsUpgradePreview = false
    end

    self.CurCharacterLevel = self._Control:GetCurCharacterLevel(self.CurSelectRoleId)
    self.MaxCharacterLevel = self._Control:GetCharacterLvMaxLevel(self.CurSelectRoleId)
    self.IsUniversal = self._Control:GetCharacterIsUniversal(self.CurSelectRoleId)

    self.TxtName.text = self._Control:GetCharacterName(self.CurSelectRoleId)
    self.TxtCode.text = self._Control:GetCharacterIntro(self.CurSelectRoleId)
    self.RImgHead:SetRawImageEx(self._Control:GetCharacterPortrait(self.CurSelectRoleId))
    self.PanelHead.gameObject:SetActiveEx(true)

    -- 先决定预览态（满级时会被强制关闭），再刷等级与加成
    self:RefreshPreviewToggle()
    self:RefreshUpgrade()
    self:RefreshLevelText(false)
    self:RefreshAreaLabels()
    self:RefreshSkillBtnList()
end

-- 刷新名称后的等级文本
---@param isRoll boolean 是否数字滚动
function XUiSkyTowerCook:RefreshLevelText(isRoll)
    local targetLevel = self:GetDisplayLevel()
    local previewColor = self._Control:GetClientConfigValue("CharacterLevelPreviewColor")
    self.TxtLv.color = targetLevel > self.CurCharacterLevel and XUiHelper.Hexcolor2Color(previewColor) or self.TxtLvColor

    local startValue = self.LevelTextValue or self.CurCharacterLevel
    self:StopLevelRoll()
    if not isRoll or startValue == targetLevel then
        self:SetLevelText(targetLevel)
        return
    end

    -- 滚动实例按需创建，仅在预览开关切换时使用
    if not self.LevelRoll then
        self.LevelRoll = XUiCommonRollingNumber.New(nil, function(value)
            self:SetLevelText(value)
        end)
    end
    -- 整数等级由滚动刷新写入，结束回调不再回写，避免Kill时跳到终值
    self:SetLevelText(startValue)
    self.LevelRoll:Play(startValue, targetLevel, XMVCA.XSkyTower.StaffRollDuration)
end

function XUiSkyTowerCook:SetLevelText(level)
    if XTool.UObjIsNil(self.TxtLv) then
        return
    end
    self.LevelTextValue = level
    self.TxtLv.text = string.format("%s%s", self._Control:GetSkyTowerInfoText(1), level)
end

function XUiSkyTowerCook:StopLevelRoll()
    if self.LevelRoll then
        self.LevelRoll:Kill()
    end
end

-- 刷新能力标签
function XUiSkyTowerCook:RefreshAreaLabels()
    self:HideAllGrids(self.FloorGridList)
    local skillTypes = self._Control:GetCharacterSkillTypes(self.CurSelectRoleId)
    for index, skillType in ipairs(skillTypes) do
        local grid = self.FloorGridList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridArea, self.PanelArea)
            self.FloorGridList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtName").text = self._Control:GetSkillTypeName(skillType)
        grid:GetObject("ImgBg"):SetSprite(self._Control:GetSkillTypeSmallIcon(skillType))
    end
end
--endregion

--region 技能信息
function XUiSkyTowerCook:RefreshSkillBtnList()
    self:HideAllGrids(self.SkillBtnList)
    self.SkillIds = self._Control:GetCharacterLvSkillIds(self.CurSelectRoleId, self.CurCharacterLevel)
    local isEmpty = XTool.IsTableEmpty(self.SkillIds)
    self.ImgSkillDescBg.gameObject:SetActiveEx(not isEmpty)
    self.PanelTabSkill.gameObject:SetActiveEx(not isEmpty)
    if isEmpty then
        self.CurSelectSkillBtnIndex = 0
        self.CurSelectSkillId = 0
        self.TxtSkillDesc.text = ""
        self.PanelDishes.gameObject:SetActiveEx(false)
        self:HideAllGrids(self.SkillGridList)
        return
    end

    local tabSkillBtn = {}
    for index, skillId in ipairs(self.SkillIds) do
        local btn = self.SkillBtnList[index]
        if not btn then
            btn = XUiHelper.Instantiate(self.BtnTabSkill, self.PanelTabSkill.transform)
            self.SkillBtnList[index] = btn
        end

        btn.gameObject:SetActiveEx(true)
        local icon = self._Control:GetCharacterSkillIcon(skillId)
        local hasIcon = not string.IsNilOrEmpty(icon)
        btn:SetSpriteVisible(hasIcon)
        if hasIcon then
            btn:SetSprite(icon)
        end
        btn:SetNameByGroup(0, self._Control:GetCharacterSkillName(skillId))
        tabSkillBtn[index] = btn
    end

    -- SelectIndex取不到按钮时会空引用，下标必须落在tabSkillBtn范围内
    local selectIndex = tabSkillBtn[self.CurSelectSkillBtnIndex] and self.CurSelectSkillBtnIndex or 1
    self.PanelTabSkill:Init(tabSkillBtn, handler(self, self.OnSelectSkillBtn))
    self.PanelTabSkill:SelectIndex(selectIndex)

    -- 通用角色无擅长物品列表
    self.PanelDishes.gameObject:SetActiveEx(not self.IsUniversal)
end

function XUiSkyTowerCook:OnSelectSkillBtn(btnIndex)
    self.CurSelectSkillBtnIndex = btnIndex
    self.CurSelectSkillId = self.SkillIds and self.SkillIds[btnIndex] or 0
    self:RefreshSkillInfo()
    self.PanelLbEx.horizontalNormalizedPosition = 0
end

-- 长按累计等级优先于下一级预览；未预览时展示当前等级
---@return number
function XUiSkyTowerCook:GetDisplayLevel()
    if self.PendingLevel and self.PendingLevel > self.CurCharacterLevel then
        return self.PendingLevel
    end
    if self.IsUpgradePreview then
        return math.min(self.CurCharacterLevel + 1, self.MaxCharacterLevel)
    end
    return self.CurCharacterLevel
end

-- 只替换展示用的同槽位技能，保留当前技能作为物品加成对比的基准
---@return number
function XUiSkyTowerCook:GetDisplaySkillId()
    if not XTool.IsNumberValid(self.CurSelectRoleId) then
        return 0
    end
    local level = self:GetDisplayLevel()
    if level == self.CurCharacterLevel then
        return self.CurSelectSkillId
    end
    local skillIds = self._Control:GetCharacterLvSkillIds(self.CurSelectRoleId, level)
    return skillIds[self.CurSelectSkillBtnIndex] or 0
end

function XUiSkyTowerCook:RefreshSkillInfo()
    self.TxtSkillDesc.text = self._Control:GetCharacterSkillDesc(self:GetDisplaySkillId())
    self:RefreshSkillProducts()
end

-- 刷新当前技能的擅长物品加成列表
function XUiSkyTowerCook:RefreshSkillProducts()
    if self.IsUniversal or not XTool.IsNumberValid(self.CurSelectSkillId) then
        self:HideAllGrids(self.SkillGridList)
        return
    end
    self.PanelDishes.gameObject:SetActiveEx(true)
    -- 光环技能对角色本体不生效，其加成物品上要带光环Icon
    local isAura = self._Control:IsCharacterSkillAura(self.CurSelectSkillId)
    local previewMap = self:GetPreviewAdditionMap()
    local isRoll = not (self.PendingLevel and self.PendingLevel > self.CurCharacterLevel)

    local list = self:GetSkillProductList()
    for index, data in ipairs(list) do
        local grid = self.SkillGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridSkill, self.Container)
            grid = XUiGridSkyTowerSkillItem.New(go, self)
            self.SkillGridList[index] = grid
        end
        grid:Open()
        grid:Refresh(data, isAura, previewMap and previewMap[data.Id] or nil, isRoll)
    end
    for index = #list + 1, #self.SkillGridList do
        self.SkillGridList[index]:Close()
    end
end

function XUiSkyTowerCook:GetSkillProductList()
    local list = {}
    for index, data in ipairs(self._Control:GetCharacterSkillAdditionList(self.CurSelectSkillId)) do
        list[index] = data
    end
    -- 已解锁 > 加急 > 配表优先级 > Id
    table.sort(list, function(a, b)
        local aUnlock = self._Control:IsProductUnlock(a.WorkType, a.Id)
        local bUnlock = self._Control:IsProductUnlock(b.WorkType, b.Id)
        if aUnlock ~= bUnlock then
            return aUnlock
        end
        local aUrgent = self._Control:IsUrgentProduct(a.WorkType, a.Id)
        local bUrgent = self._Control:IsUrgentProduct(b.WorkType, b.Id)
        if aUrgent ~= bUrgent then
            return aUrgent
        end
        local aPriority = self._Control:GetProductPriority(a.WorkType, a.Id)
        local bPriority = self._Control:GetProductPriority(b.WorkType, b.Id)
        if aPriority ~= bPriority then
            return aPriority < bPriority
        end
        return a.Id < b.Id
    end)
    return list
end

-- 预览态下"物品Id -> 目标等级加成"的映射，非预览态返回nil
---@return table<number, number>
function XUiSkyTowerCook:GetPreviewAdditionMap()
    if self:GetDisplayLevel() <= self.CurCharacterLevel then
        return nil
    end
    -- 描述和加成使用同一目标等级、同一技能槽位
    local skillId = self:GetDisplaySkillId()
    if not XTool.IsNumberValid(skillId) then
        return nil
    end
    local map = {}
    local skillAdditionList = self._Control:GetCharacterSkillAdditionList(skillId)
    for _, data in ipairs(skillAdditionList) do
        map[data.Id] = data.Addition
    end
    return map
end
--endregion

--region 下一级预览
function XUiSkyTowerCook:RefreshPreviewToggle()
    -- 已满级（含通用角色）隐藏勾选项
    local show = XTool.IsNumberValid(self.CurSelectRoleId) and self.CurCharacterLevel < self.MaxCharacterLevel
    self.BtnPreview.gameObject:SetActiveEx(show)
    if not show then
        self.IsUpgradePreview = false
    end
    self.BtnPreview:SetButtonState(self.IsUpgradePreview and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiSkyTowerCook:CancelUpgradePreview()
    if not self.IsUpgradePreview then
        return
    end
    -- 只取消勾选，保留升级展示直到累计刷新或请求结束
    self.IsUpgradePreview = false
    self:RefreshPreviewToggle()
end
--endregion

--region 升级
function XUiSkyTowerCook:RefreshUpgrade()
    if not XTool.IsNumberValid(self.CurSelectRoleId) then
        return
    end
    -- 长按累计的相关字段先复位
    self.UpgradeLimitLevel = self.CurCharacterLevel
    self.PendingLevel = self.CurCharacterLevel

    -- 通用角色无升级相关UI
    self.BtnUp.gameObject:SetActiveEx(not self.IsUniversal)
    if self.IsUniversal then
        return
    end

    local nextLevel = self.CurCharacterLevel + 1
    local isMax = nextLevel > self.MaxCharacterLevel
    local isPass, conditionDesc = true, ""
    if not isMax then
        isPass, conditionDesc = self._Control:CheckCharacterUpLevelCondition(self.CurSelectRoleId, nextLevel)
    end
    if isMax then
        self.UpgradeState = XMVCA.XSkyTower.StaffUpgradeState.Max
    elseif not isPass then
        self.UpgradeState = XMVCA.XSkyTower.StaffUpgradeState.Lock
    else
        self.UpgradeState = XMVCA.XSkyTower.StaffUpgradeState.Normal
    end

    -- 条件未满足时不显示代币需求，改显示条件描述
    local isLock = self.UpgradeState == XMVCA.XSkyTower.StaffUpgradeState.Lock
    self.PanelPrice.gameObject:SetActiveEx(self.UpgradeState == XMVCA.XSkyTower.StaffUpgradeState.Normal)
    self.TxtUnLockTips.gameObject:SetActiveEx(isLock)
    self.UnlockTip = isLock and conditionDesc or nil
    if isLock then
        self.TxtUnLockTips.text = self.UnlockTip
    end

    local btnText = self._Control:GetStaffStateBtnText(isMax and 3 or 1)
    if not string.IsNilOrEmpty(btnText) then
        self.BtnUp:SetNameByGroup(0, btnText)
    end
    if self.UpgradeState ~= XMVCA.XSkyTower.StaffUpgradeState.Normal then
        -- 满级不可用；条件未满足时也置灰，但仍可点击弹提示
        self.BtnUp:SetDisable(true)
        return
    end

    -- 长按累计的上限：受升级券与逐级条件双重限制
    self.UpgradeLimitLevel = self._Control:GetCharacterUpLevelLimit(self.CurSelectRoleId)

    local coinId = XMVCA.XSkyTower.ItemId.SkyTowerUpgradeCoin
    self.RImgCoinIcon:SetRawImageEx(self._Control:GetItemIcon(coinId))
    self:RefreshConsumeText(nextLevel)
    self.BtnUp:SetButtonState(CS.UiButtonState.Normal)
end

-- 从当前等级升到目标等级的总消耗
function XUiSkyTowerCook:GetLevelUpCost(targetLevel)
    local price = 0
    for level = self.CurCharacterLevel + 1, targetLevel do
        price = price + self._Control:GetCharacterLvNeedItemCount(self.CurSelectRoleId, level)
    end
    return price
end

-- 刷新消耗文本，长按累计时按累计到的目标等级显示总消耗
---@param targetLevel number 目标等级
function XUiSkyTowerCook:RefreshConsumeText(targetLevel)
    local coinId = XMVCA.XSkyTower.ItemId.SkyTowerUpgradeCoin
    local price = self:GetLevelUpCost(targetLevel)
    local ownCount = self._Control:GetItemCount(coinId)
    self.TxtConsume.text = ownCount
    local color = self._Control:GetClientConfigValue("StaffUpgradeCoinEnoughColor", ownCount >= price and 1 or 2)
    self.TxtConsume.color = XUiHelper.Hexcolor2Color(color)
    self.TxtPrice.text = "/" .. price
end

---@return boolean
function XUiSkyTowerCook:CheckLevelUpAndTip()
    if not XTool.IsNumberValid(self.CurSelectRoleId) then
        return false
    end
    if self.UpgradeState == XMVCA.XSkyTower.StaffUpgradeState.Lock then
        if not string.IsNilOrEmpty(self.UnlockTip) then
            XMVCA.XSkyTower:TipMsg(self.UnlockTip)
        end
        return false
    end
    if self.UpgradeState ~= XMVCA.XSkyTower.StaffUpgradeState.Normal then
        return false
    end
    return true
end

---@param targetLevel number
function XUiSkyTowerCook:RequestLevelUp(targetLevel)
    self._Control:RequestLevelUpStaff(self.CurSelectRoleId, targetLevel, nil, handler(self, self.RefreshDetails))
end
--endregion

--region 工具
-- 隐藏容器内所有格子
function XUiSkyTowerCook:HideAllGrids(container)
    if XTool.IsTableEmpty(container) then
        return
    end
    for _, grid in pairs(container) do
        if grid.Close then
            grid:Close()
        else
            grid.gameObject:SetActiveEx(false)
        end
    end
end
--endregion

--region 按钮
function XUiSkyTowerCook:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnWndClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnPreview:AddEventListener(handler(self, self.OnBtnPreviewClick))
    self:InitLongClick()
end

-- 升级按钮的短按与长按
function XUiSkyTowerCook:InitLongClick()
    -- Interval是毫秒（每tick累计一级），TriggerOffset是秒
    local interval = self._Control:GetIntClientConfigValue("StaffUpgradeLongPressInterval")
    local activeTime = self._Control:GetIntClientConfigValue("StaffUpgradeLongPressActiveTime")
    -- onlyOneCallback为true，短按只走OnBtnDetermineClick；noAutoUp为true，避免按钮置灰时被组件强制抬起
    ---@type XUiButtonLongClick
    self.LongClick = XUiButtonLongClick.New(self.BtnUp, interval, self, self.OnBtnDetermineClick, self.OnBtnDetermineLongClick, self.OnBtnDetermineLongClickUp, false, nil, true, true, activeTime)
end

function XUiSkyTowerCook:ResetLongClick()
    if self.LongClick then
        self.LongClick:Reset()
        -- Reset的默认指针-1也是鼠标左键，清空后才会忽略旧手势的抬起事件
        self.LongClick.PointerId = nil
    end
end

function XUiSkyTowerCook:OnBtnCloseClick()
    self:Close()
end

function XUiSkyTowerCook:OnBtnPreviewClick()
    self.IsUpgradePreview = self.BtnPreview:GetToggleState()
    self:RefreshLevelText(true)
    self:RefreshSkillInfo()
end

function XUiSkyTowerCook:OnBtnDetermineClick()
    self:ResetLongClick()
    self:CancelUpgradePreview()
    if self:CheckLevelUpAndTip() then
        self:RequestLevelUp(self.CurCharacterLevel + 1)
    else
        self:RefreshDetails()
    end
end

-- 长按期间只累计目标等级并刷新预览
---@return boolean isExit 结束本次按压
---@return boolean isLongClickCallback 抑制松手时回落到单击
function XUiSkyTowerCook:OnBtnDetermineLongClick()
    if self.LongClick then
        if not self.LongClick.IsPressing or CS.UnityEngine.Time.time - self.LongClick.DownTime < self.LongClick.Offset then
            return
        end
    end
    if not XTool.IsNumberValid(self.CurSelectRoleId) then
        return true, true
    end
    self:CancelUpgradePreview()
    if self.UpgradeState ~= XMVCA.XSkyTower.StaffUpgradeState.Normal then
        -- 结束本次按压，由松手入口统一检查和提示，避免重复提示
        return true, true
    end
    local pendingLevel = (self.PendingLevel or self.CurCharacterLevel) + 1
    if pendingLevel > (self.UpgradeLimitLevel or self.CurCharacterLevel) then
        -- 已到升级券或升级条件的上限，停在上限继续等抬手
        return
    end
    self.PendingLevel = pendingLevel
    self:RefreshConsumeText(pendingLevel)
    -- 停止原有等级滚动，描述和物品加成同步预览累计等级
    self:RefreshLevelText(false)
    self:RefreshSkillInfo()
end

-- 抬手时直接一次性升级到累计目标等级
function XUiSkyTowerCook:OnBtnDetermineLongClickUp()
    self:ResetLongClick()
    self:CancelUpgradePreview()
    if not self:CheckLevelUpAndTip() then
        self:RefreshDetails()
        return
    end
    -- 未累计时仍按单击升一级，已累计时保留预览直到请求结束
    local targetLevel = math.max(self.PendingLevel or self.CurCharacterLevel, self.CurCharacterLevel + 1)
    self:RequestLevelUp(targetLevel)
end
--endregion

return XUiSkyTowerCook
