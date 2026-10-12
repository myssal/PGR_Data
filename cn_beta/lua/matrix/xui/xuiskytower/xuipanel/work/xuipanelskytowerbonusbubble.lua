---@class XUiPanelSkyTowerBonusBubble : XUiNode 加成明细气泡
---@field _Control XSkyTowerControl
---@field Parent XUiSkyTowerWork
local XUiPanelSkyTowerBonusBubble = XClass(XUiNode, "XUiPanelSkyTowerBonusBubble")

--region 生命周期
function XUiPanelSkyTowerBonusBubble:OnStart()
    ---@type UiObject[] 加成条复用池
    self._GridList = {}
    self:RegisterUiEvents()
end
--endregion

--region 界面刷新
---@param bonusList {Icon:string, Desc:string, Value:string}[]
function XUiPanelSkyTowerBonusBubble:Show(bonusList)
    if XTool.IsTableEmpty(bonusList) then
        self:Close()
        return
    end
    self:Open()
    self:RefreshView(bonusList)
end

function XUiPanelSkyTowerBonusBubble:RefreshView(bonusList)
    if XTool.UObjIsNil(self.GridBonus) then
        return
    end
    XUiHelper.RefreshUiObjectList(self._GridList, self.GridBonus.parent, self.GridBonus, #bonusList, function(index, grid)
        local bonus = bonusList[index]
        grid.IconBonus:SetSprite(bonus.Icon)
        grid.TxtDesc.text = bonus.Desc
        grid.TxtBonus.text = bonus.Value
    end)
end
--endregion

--region 按钮
function XUiPanelSkyTowerBonusBubble:RegisterUiEvents()
    self.BtnDetailClose:AddEventListener(handler(self, self.OnBtnDetailCloseClick))
end

function XUiPanelSkyTowerBonusBubble:OnBtnDetailCloseClick()
    self:Close()
end
--endregion

return XUiPanelSkyTowerBonusBubble
