---@class XUiGridBwQuestTitle : XUiNode
---@field Parent XUiPanelBWTaskGroup
---@field _Control XBigWorldQuestControl
local XUiGridBwQuestTitle = XClass(XUiNode, "XUiGridBwQuestTitle")

function XUiGridBwQuestTitle:RefreshView(typeId)
    self:Open()
    self.Bg.color = XUiHelper.Hexcolor2Color(self._Control:GetQuestTypeColorStr(typeId))
    self.TxtTitle.text = self._Control:GetQuestTypeName(typeId)
    self.ImgIcon:SetSprite(self._Control:GetQuestTypeIcon(typeId))
end

---@class XUiPanelBWTaskGroup : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldTaskMain
---@field _Control XBigWorldQuestControl
local XUiPanelBWTaskGroup = XClass(XUiNode, "XUiPanelBWTaskGroup")

function XUiPanelBWTaskGroup:OnStart(typeId, selectQuestId)
    -- typeId 可能为0
    self._TypeId = typeId
    self._SelectQuestId = selectQuestId
    self._QuestId2BtnIndex = {}
    self:InitCb()
    self:InitView()
end

function XUiPanelBWTaskGroup:OnEnable()
    self:RefreshView()
end

function XUiPanelBWTaskGroup:OnDisable()
    self._TabIndex = nil
end

function XUiPanelBWTaskGroup:OnDestroy()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_RED_POINT_REFRESH, self.RefreshRedPoint, self)
end

function XUiPanelBWTaskGroup:InitCb()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_RED_POINT_REFRESH, self.RefreshRedPoint, self)
end

function XUiPanelBWTaskGroup:InitView()
    self._GridTitles = {}
    local typeId = self._TypeId
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    self._ReceiveQuestIds = self._Control:GetReceiveQuestIds()
    if typeId == XMVCA.XBigWorldQuest.QuestType.All then
        self:InitMultiTypeGroupBtn()
    else
        self:InitSingleTypeGroupBtn()
    end
end

function XUiPanelBWTaskGroup:InitSingleTypeGroupBtn()
    local typeId = self._TypeId
    local btnList = {}
    local btnData = {}

    self:InitTypeGroupBtn(1, typeId, btnData, btnList, 0)

    self._TabData = btnData
    self.PanelTitleBtnGroup:Init(btnList, function(tabIndex)
        self:OnSelectTab(tabIndex)
    end)
end

function XUiPanelBWTaskGroup:InitMultiTypeGroupBtn()
    local typeIds = self._Control:GetQuestTypeIds()

    local btnList = {}
    local btnData = {}
    local btnIndex = 0
    for index, typeId in ipairs(typeIds) do
        btnIndex = self:InitTypeGroupBtn(index, typeId, btnData, btnList, btnIndex)
    end
    self._TabData = btnData
    self.PanelTitleBtnGroup:Init(btnList, function(tabIndex)
        self:OnSelectTab(tabIndex)
    end)
end

function XUiPanelBWTaskGroup:InitTypeGroupBtn(typeIndex, typeId, btnData, btnList, btnIndex)
    local groupIds = self._Control:GetGroupIdsByTypeId(typeId)
    local receiveQuestIds = self._ReceiveQuestIds
    local titleGrid = self:GetTitleGrid(typeIndex)
    titleGrid:Close()
    --local color = XUiHelper.Hexcolor2Color(self._Control:GetQuestTypeColorStr(typeId))
    for _, groupId in ipairs(groupIds) do
        local questIds = self._Control:GetQuestIdsByGroupId(groupId, receiveQuestIds)
        local isCreateParent = not XTool.IsTableEmpty(questIds)
        if not isCreateParent then
            goto continue
        end
        titleGrid:RefreshView(typeId)
        local btn = self:GetTabBtn(true)
        btn:SetNameByGroup(0, self._Control:GetGroupName(groupId))
        btn:ShowReddot(self:CheckRedPoint(true, groupId))
        local groupIcon = self._Control:GetGroupIcon(groupId)
        local validIcon = not string.IsNilOrEmpty(groupIcon)
        ---@type XUiComponent.XUiComponentGroup
        local componentGroup = btn.gameObject:GetComponent(typeof(CS.XUiComponent.XUiComponentGroup))
        if componentGroup then
            componentGroup:SetVisibleWithGroup(0, validIcon)
            if validIcon then
                componentGroup:SetRawImageWithGroup(0, groupIcon)
            end
        end

        btnIndex = btnIndex + 1
        btnList[btnIndex] = btn
        btnData[btnIndex] = self:GetBtnData(true, groupId, btn)

        local firstIndex = btnIndex
        for _, questId in ipairs(questIds) do
            local btnChild = self:GetTabBtn(false)
            btnChild:SetNameByGroup(0, self._Control:GetQuestName(questId))
            btnChild:SetSprite(self._Control:GetQuestIcon(questId))
            btnChild:ShowReddot(self:CheckRedPoint(false, questId))
            ---@type XUiComponent.XUiComponentGroup
            componentGroup = btnChild.gameObject:GetComponent(typeof(CS.XUiComponent.XUiComponentGroup))
            if componentGroup then
                componentGroup:SetVisibleWithGroup(0, validIcon)
                componentGroup:SetVisibleWithGroup(1, XMVCA.XBigWorldQuest:IsTrackQuest(questId))
                if validIcon then
                    componentGroup:SetRawImageWithGroup(0, groupIcon)
                end
            end
            
            btnChild.SubGroupIndex = firstIndex
            btnIndex = btnIndex + 1
            btnList[btnIndex] = btnChild
            btnData[btnIndex] = self:GetBtnData(false, questId, btnChild)
            if questId == self._SelectQuestId then
                self.Parent:SetGroupSelectIndex(btnIndex)
            end
            self._QuestId2BtnIndex[questId] = btnIndex
            local quest = XMVCA.XBigWorldQuest:GetQuestData(questId)
            local step = quest:GetActiveStepData()
            local location
            if step then
                location = self._Control:GetStepLocation(step:GetId())
            end
            if string.IsNilOrEmpty(location) then
                if componentGroup then
                    componentGroup:SetVisibleWithGroup(0, false)
                end
            else
                btnChild:SetNameByGroup(1, location)
                if componentGroup then
                    componentGroup:SetVisibleWithGroup(0, true)
                end
            end
            
        end

        :: continue ::
    end
    return btnIndex
end

function XUiPanelBWTaskGroup:RefreshView()
    local selectIndex = self.Parent:GetGroupSelectIndex()
    local data = self._TabData[selectIndex]
    if data then
        self.PanelTitleBtnGroup:SelectIndex(selectIndex)
    else
        self.Parent:RefreshTaskContent(false, nil, nil)
    end
end

function XUiPanelBWTaskGroup:OnSelectTab(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end

    self._TabIndex = tabIndex
    local data = self._TabData[self._TabIndex]
    if not data then
        return
    end
    if not data.IsGroup then
        XMVCA.XBigWorldQuest:MarkQuestRedPoint(data.Id)
    end
    self:RefreshRedPoint()
    self.Parent:PlayAnimation("ContentQieHuan")
    self.Parent:RefreshTaskContent(data.IsGroup, data.Id, tabIndex)
end

function XUiPanelBWTaskGroup:RefreshButton()
    if XTool.IsTableEmpty(self._TabData) then
        return
    end
    for _, data in pairs(self._TabData) do
        if not data.IsGroup then
            local btn = data.Tab
            local componentGroup = btn.gameObject:GetComponent(typeof(CS.XUiComponent.XUiComponentGroup))
            if componentGroup then
                componentGroup:SetVisibleWithGroup(1, XMVCA.XBigWorldQuest:IsTrackQuest(data.Id))
            end
        end
    end
end

---@return XUiComponent.XUiButton
function XUiPanelBWTaskGroup:GetTabBtn(isFirst)
    local prefab = isFirst and self.BtnFirst or self.BtnSecond
    local btn = XUiHelper.Instantiate(prefab, self.PanelTitleBtnGroup.transform)
    btn.gameObject:SetActiveEx(true)
    return btn
end

function XUiPanelBWTaskGroup:GetBtnData(isGroup, id, btn)
    return {
        IsGroup = isGroup,
        Id = id,
        Tab = btn
    }
end

function XUiPanelBWTaskGroup:CheckRedPoint(isGroup, id)
    if isGroup then
        for _, questId in pairs(self._ReceiveQuestIds) do
            local groupId = self._Control:GetGroupIdByQuestId(questId)
            if groupId == id and XMVCA.XBigWorldQuest:CheckQuestRedWithQuestId(questId) then
                return true
            end
        end
    else
        return XMVCA.XBigWorldQuest:CheckQuestRedWithQuestId(id)
    end
    return false
end

function XUiPanelBWTaskGroup:RefreshRedPoint()
    if XTool.IsTableEmpty(self._TabData) then
        return
    end
    
    for _, data in pairs(self._TabData) do
        local btn = data.Tab
        btn:ShowReddot(self:CheckRedPoint(data.IsGroup, data.Id))
    end
end

---@return XUiGridBwQuestTitle
function XUiPanelBWTaskGroup:GetTitleGrid(index)
    local grid = self._GridTitles[index]
    if not grid then
        local ui = index == 1 and self.PanelTitle or XUiHelper.Instantiate(self.PanelTitle, self.Transform)
        grid = XUiGridBwQuestTitle.New(ui, self)

        self._GridTitles[index] = grid
    end
    return grid
end

function XUiPanelBWTaskGroup:GetIndexByQuestId(questId)
    local index = self._QuestId2BtnIndex[questId]
    return index and index or 1
end

return XUiPanelBWTaskGroup