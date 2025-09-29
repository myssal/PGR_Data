---@class XUiTheatre5SkillHandbookItemGrid : XUiNode
---@field _Control XTheatre5Control
local XUiTheatre5SkillHandbookItemGrid = XClass(XUiNode, "XUiTheatre5SkillHandbookItemGrid")

function XUiTheatre5SkillHandbookItemGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
    self.RImgBgSelect = self.RImgBgSelect or XUiHelper.TryGetComponent(self.Transform, "PanelItem/RImgBgSelect", "RectTransform")
end

---@param data XUiTheatre5SkillHandbookItemGridData
function XUiTheatre5SkillHandbookItemGrid:Update(data)
    self._Data = data
    self.RImgIcon:SetRawImage(data.Icon)
    self.TxtName.text = data.Name
    if data.Quality == 0 then
        self.ImgQuality.gameObject:SetActiveEx(false)
    else
        self.ImgQuality.gameObject:SetActiveEx(true)
        XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, data.Quality)
    end
end

function XUiTheatre5SkillHandbookItemGrid:OnClick()
    self.Parent.Parent:OnSelectItem(self._Data)
end

function XUiTheatre5SkillHandbookItemGrid:UpdateSelectState(data)
    if self.RImgBgSelect then
        if data == self._Data then
            self.RImgBgSelect.gameObject:SetActiveEx(true)
        else
            self.RImgBgSelect.gameObject:SetActiveEx(false)
        end
    end
end

return XUiTheatre5SkillHandbookItemGrid