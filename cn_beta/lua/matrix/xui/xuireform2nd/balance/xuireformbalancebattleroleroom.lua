local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")

--- 4.9 天平编队界面代理：可上阵实体限定为已选中的角色砝码
---@class XUiReformBalanceBattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiReformBalanceBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiReformBalanceBattleRoleRoom")

function XUiReformBalanceBattleRoleRoom:GetAutoCloseInfo()
    local endTime = XMVCA.XReform:GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            XMVCA.XReform:HandleActivityEndTime()
        end
    end
end

function XUiReformBalanceBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiReform2nd/Balance/XUiReformBalanceRoleDetail")
end

function XUiReformBalanceBattleRoleRoom:GetValidEntityIdList()
    return XMVCA.XReform:GetBalanceEntityIds()
end

--- 天平关卡角色由砝码决定，禁用预设队伍
---@param ui XUiBattleRoleRoom
function XUiReformBalanceBattleRoleRoom:AOPOnStartAfter(ui)
    ui.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

--- 进界面即按砝码顺序自动上阵
--- 放在 OnStartBefore：后续 OnStart 的效应刷新才能看到正确队伍
---@param ui XUiBattleRoleRoom
function XUiReformBalanceBattleRoleRoom:AOPOnStartBefore(ui)
    local autoEntityIds = XMVCA.XReform:GetBalanceAutoEntityIds()
    if #autoEntityIds == 0 then
        return
    end
    ---@type XTeam
    local team = ui.Team
    team:Clear()
    team:UpdateEntityIds(autoEntityIds)
end

function XUiReformBalanceBattleRoleRoom:CheckShowAnimationSet()
    return false
end

return XUiReformBalanceBattleRoleRoom
