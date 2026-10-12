local XUiPanelSkyTowerLevelUp = require("XUi/XUiSkyTower/XUiPanel/XUiPanelSkyTowerLevelUp")

---@class XUiPanelSkyTowerCondition : XUiPanelSkyTowerLevelUp
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerCondition = XClass(XUiPanelSkyTowerLevelUp, "XUiPanelSkyTowerCondition")

function XUiPanelSkyTowerCondition:Refresh(list, level, curLevel)
    self.Level = level
    self.CurLevel = curLevel
    local filter = {}
    for _, data in ipairs(list or {}) do
        if data.Type == 1 then
            table.insert(filter, data)
        end
    end
    self.Super.Refresh(self, filter)
end

function XUiPanelSkyTowerCondition:GetTxtEmpty()
    if self.Level <= self.CurLevel and self.Level ~= XMVCA.XSkyTower.MaxLv then
        return self._Control:GetSkyTowerLvUpConditionText(3)
    elseif self.CurLevel >= XMVCA.XSkyTower.MaxLv then
        return self._Control:GetSkyTowerLvUpConditionText(4)
    else
        return self._Control:GetSkyTowerLvUpConditionText(6)
    end
end

return XUiPanelSkyTowerCondition
