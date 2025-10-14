---@class XUiLottoStoryTreeMode : XUiNode
local XUiLottoStoryTreeMode = XClass(XUiNode, "XUiLottoStoryTreeMode")

function XUiLottoStoryTreeMode:OnStart()
    self:InitStageList()
end

function XUiLottoStoryTreeMode:InitStageList()
    local storyObj = self.PaneStageTree
    XTool.InitUiObjectByInstance(storyObj, self) -- 将line的UiObjet引用加进来

    local stageActivityId = XLottoConfigs.GetLottoStageActivity(self.Parent._LottoGroupData:GetId())
    local festivalActivity = XFestivalActivityConfig.GetFestivalById(stageActivityId)
    local XStageItem = require("XUi/XUiEpicFashionGacha/Grid/XStageItem")

    ---@type XStageItem[]
    self._StageGridList = {}
    self._StageIndexDir = {}

    for i, stageId in pairs(festivalActivity.StageId) do
        local stageTransform = self.PanelStageContent:GetChild(i - 1)
        if stageTransform then
            self._StageGridList[i] = XStageItem.New(self, stageTransform)
            self._StageIndexDir[stageId] = i
        end
    end
end

function XUiLottoStoryTreeMode:RefreshStageList()
    self.PaneStageTree.gameObject:SetActiveEx(true)
    for stageId, index in pairs(self._StageIndexDir) do
        local activityId = XLottoConfigs.GetLottoStageActivity(self.Parent._LottoGroupData:GetId())
        local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(activityId, stageId)
        local isOpen, _ = fStage:GetCanOpen()
        local stageTransform = self.PanelStageContent:GetChild(index - 1)
        if isOpen then
            if stageTransform then
                stageTransform.gameObject:SetActiveEx(true)
            end
            self._StageGridList[index].GameObject:SetActiveEx(true)
            self._StageGridList[index]:UpdateNode(activityId, stageId)
        else
            if stageTransform then
                stageTransform.gameObject:SetActiveEx(false)
            end
            self._StageGridList[index].GameObject:SetActiveEx(false)
        end
    end
end

function XUiLottoStoryTreeMode:UpdateNodesSelect(stageId)
    for gridStageId, index in pairs(self._StageIndexDir) do
        self._StageGridList[index]:SetNodeSelect(gridStageId == stageId)
        if gridStageId == stageId then
            self._LastOpenStage = index
        end
    end
end

function XUiLottoStoryTreeMode:OpenStageDetails(stageId)
    XLuaUiManager.Open("UiEpicFashionGachaStageDetail", stageId)
end

function XUiLottoStoryTreeMode:MoveIntoStage(stageIndex)
end

return XUiLottoStoryTreeMode