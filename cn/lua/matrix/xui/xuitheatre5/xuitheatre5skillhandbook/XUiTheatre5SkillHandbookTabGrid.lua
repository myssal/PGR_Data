local XUiTheatre5SkillHandbookItemGrid = require("XUi/XUiTheatre5/XUiTheatre5SkillHandbook/XUiTheatre5SkillHandbookItemGrid")

---@class XUiTheatre5SkillHandbookTabGrid : XUiNode
---@field _Control XTheatre5Control
local XUiTheatre5SkillHandbookTabGrid = XClass(XUiNode, "XUiTheatre5SkillHandbookTabGrid")

function XUiTheatre5SkillHandbookTabGrid:OnStart()
    self._Grids = {}
end

---@param data XUiTheatre5SkillHandbookTabGridData
function XUiTheatre5SkillHandbookTabGrid:Update(data)
    self.Text.text = data.TagName
    XTool.UpdateDynamicItemLazy(self._Grids, data.Items, self.GridShop, XUiTheatre5SkillHandbookItemGrid, self, 15)
end

function XUiTheatre5SkillHandbookTabGrid:UpdateSelectState(selectedData)
    for i, grid in pairs(self._Grids) do
        grid:UpdateSelectState(selectedData)
    end
end

function XUiTheatre5SkillHandbookTabGrid:OnDisable()
    if self._TimerDelayInit then
        XScheduleManager.UnSchedule(self._TimerDelayInit)
        self:_RemoveTimerIdAndDoCallback(self._TimerDelayInit)
        self._TimerDelayInit = nil
    end
end

return XUiTheatre5SkillHandbookTabGrid