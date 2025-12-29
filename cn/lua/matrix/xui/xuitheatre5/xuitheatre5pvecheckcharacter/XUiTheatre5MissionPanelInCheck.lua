local XUiTheatre5MissionPanel = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiTheatre5MissionPanel')

--- 角色信息查看界面特殊的任务面板
---@class XUiTheatre5MissionPanelInCheck: XUiTheatre5MissionPanel
---@field _Control XTheatre5Control
local XUiTheatre5MissionPanelInCheck = XClass(XUiTheatre5MissionPanel, 'XUiTheatre5MissionPanelInCheck')



--region Overrdie

function XUiTheatre5MissionPanelInCheck:Refresh()
    XUiTheatre5MissionPanel.Refresh(self)
    -- 始终不显示升级按钮
    self.BtnUpgrade.gameObject:SetActiveEx(false)

end

--endregion

return XUiTheatre5MissionPanelInCheck