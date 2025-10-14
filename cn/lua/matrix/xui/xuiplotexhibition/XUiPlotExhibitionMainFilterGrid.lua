---@class XUiPlotExhibitionMainFilterGrid : XUiNode
---@field _Control XPlotExhibitionControl
---@field Parent XUiPlotExhibitionMain
local XUiPlotExhibitionMainFilterGrid = XClass(XUiNode, "XUiPlotExhibitionMainFilterGrid")

function XUiPlotExhibitionMainFilterGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end

---@param data XPlotExhibitionControlFilter
function XUiPlotExhibitionMainFilterGrid:Update(data)
    self._Data = data
    if data.IsSelected then
        self.Button:SetButtonState(CS.UiButtonState.Select)
    else
        self.Button:SetButtonState(CS.UiButtonState.Normal)
    end
    self.Button:SetNameByGroup(0, data.Name)
    self.Button:SetRawImage(data.Icon)
end

function XUiPlotExhibitionMainFilterGrid:OnClick()
    self._Control:SetFilterForceSelected(self._Data.Id, not self._Data.IsSelected)
    self.Parent:UpdateByFilter()
end

return XUiPlotExhibitionMainFilterGrid