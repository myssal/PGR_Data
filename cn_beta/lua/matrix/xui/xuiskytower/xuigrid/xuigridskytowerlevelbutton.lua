---@class XUiGridSkyTowerLevelButton : XUiNode
---@field _Control XSkyTowerControl
local XUiGridSkyTowerLevelButton = XClass(XUiNode, "XUiGridSkyTowerLevelButton")

function XUiGridSkyTowerLevelButton:OnStart(onClick)
    self.OnClick = onClick

    self.BtnLevel.CallBack = function()
        self:OnBtnLevelClick()
    end
end

function XUiGridSkyTowerLevelButton:Refresh(level, curLevel, isUnlock, disable, levelStr, selectLevel)
    self.Level = level
    self.CurLevel = curLevel
    self.IsUnlock = isUnlock
    self.Disable = disable
    if not XTool.UObjIsNil(self.PanelDisable) then
        self.PanelDisable.gameObject:SetActiveEx(disable)
    end
    self.BtnLevel:SetNameByGroup(0, levelStr)
    self:SetSelect(selectLevel == level)
    self:Open()
    
    self.GameObject.name = string.format("BtnLevel%d", level)
end

function XUiGridSkyTowerLevelButton:SetSelect(select)
    self.IsSelect = select

    --新 Ui
    if self.SelectDisable then
        self.SelectDisable.gameObject:SetActiveEx(select and self.Disable)
        self.ImgNormal.gameObject:SetActiveEx(not select and not self.Disable)
        self.ImgSelect.gameObject:SetActiveEx(select and not self.Disable)
        self.NormalDisable.gameObject:SetActiveEx(not select and self.Disable)
    else
        self.ImgNormal.gameObject:SetActiveEx(not select)
        self.ImgSelect.gameObject:SetActiveEx(select)
    end
end

function XUiGridSkyTowerLevelButton:OnBtnLevelClick()
    if self.IsSelect then
        return
    end
    self:SetSelect(true)
    if self.OnClick then self.OnClick(self) end
end

return XUiGridSkyTowerLevelButton