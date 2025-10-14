---@class XUiGridMainLineExhibitionModule
---@field UiPanelExhibition XUiPanelMainLineExhibition
---@field ChapterList XUiGridMainLineExhibitionChapter[]
local XUiGridMainLineExhibitionModule = XClass(nil, "XUiGridMainLineExhibitionModule")

function XUiGridMainLineExhibitionModule:Ctor(uiPanelExhibition, ui, moduleId, index)
    self.UiPanelExhibition = uiPanelExhibition
    XUiHelper.InitUiClass(self, ui)
    self.RectTransform = self.Transform:GetComponent("RectTransform")
    self.ModuleId = moduleId
    self.Index = index

    self:InitChapterList()
    self:IniModuleName()
end

function XUiGridMainLineExhibitionModule:OnEnable()
    for _, chapter in pairs(self.ChapterList) do
        chapter:OnEnable()
    end
end

function XUiGridMainLineExhibitionModule:OnDisable()
    for _, chapter in pairs(self.ChapterList) do
        chapter:OnDisable()
    end
end

function XUiGridMainLineExhibitionModule:Release()
    for _, chapter in pairs(self.ChapterList) do
        chapter:OnRelease()
    end
    self.ChapterList = nil
    
    self.UiPanelExhibition = nil
    self.GameObject = nil
    self.Transform = nil
end

function XUiGridMainLineExhibitionModule:InitChapterList()
    self.ChapterList = {}
    local XUiGridMainLineExhibitionChapter = require("XUi/XUiFuben/MainLine/XUiGridMainLineExhibitionChapter")
    local moduleConfig = XMVCA.XMainLine2:GetConfigExhibitionModule(self.ModuleId)
    for i, chapterId in ipairs(moduleConfig.ChapterIds) do
        local chapterGo = self.Transform:Find("Chapter" .. i)
        if chapterGo then
            local gridChapter = XUiGridMainLineExhibitionChapter.New(self, self.UiPanelExhibition, chapterGo, chapterId, i)
            table.insert(self.ChapterList, gridChapter)
        else
            XLog.Error(string.format("预制体UiMainLineExhibitionMain，缺少节点PanelModule/Module%s/Chapter%s!", self.ModuleId, i))
        end
    end
end

function XUiGridMainLineExhibitionModule:IniModuleName()
    local moduleConfig = XMVCA.XMainLine2:GetConfigExhibitionModule(self.ModuleId)
    self.TxtName.text = moduleConfig.Name
    self.TxtName2.text = moduleConfig.Name
end

-- 切换章节详情UI
function XUiGridMainLineExhibitionModule:SwitchDetailUi()
    self.PanelTitle.gameObject:SetActiveEx(false)
    self.PanelTitle2.gameObject:SetActiveEx(true)
    for _, chapter in pairs(self.ChapterList) do
        chapter:SwitchDetailUi()
    end
end

-- 切换章节简略UI
function XUiGridMainLineExhibitionModule:SwitchBriefUi()
    self.PanelTitle.gameObject:SetActiveEx(true)
    self.PanelTitle2.gameObject:SetActiveEx(false)
    local currentProgress, maxProgress = XMVCA.XMainLine2:GetExhibitionModuleProgress(self.ModuleId)
    self.TxtProgress.text = math.floor(currentProgress / maxProgress * 100) .. "%"

    for _, chapter in pairs(self.ChapterList) do
        chapter:SwitchBriefUi()
    end
end

function XUiGridMainLineExhibitionModule:GetChapterList()
    return self.ChapterList
end

function XUiGridMainLineExhibitionModule:GetGridChapter(index)
    return self.ChapterList[index]
end

function XUiGridMainLineExhibitionModule:GetModuleId()
    return self.ModuleId
end

function XUiGridMainLineExhibitionModule:GetLocalPosition()
    return self.Transform.localPosition
end

function XUiGridMainLineExhibitionModule:GetWidth()
    return self.RectTransform.rect.width
end

function XUiGridMainLineExhibitionModule:GetLine(index)
    return self.Transform:Find("Line/Line" .. index)
end

return XUiGridMainLineExhibitionModule