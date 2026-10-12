local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")

--- 4.9 天平选人界面代理：可选实体限定为已选中的角色砝码（自有角色与试玩机器人两版）
---@class XUiReformBalanceRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiReformBalanceRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiReformBalanceRoleDetail")

---@param stageId number
---@param team XTeam
function XUiReformBalanceRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
end

function XUiReformBalanceRoleDetail:GetStageId()
    return self.StageId
end

function XUiReformBalanceRoleDetail:GetEntities()
    return XMVCA.XReform:GetBalanceEntityList()
end

--- 全是机器人，无需按拥有情况排序
function XUiReformBalanceRoleDetail:SortEntitiesWithTeam(team, entities)
    return entities
end

function XUiReformBalanceRoleDetail:GetAutoCloseInfo()
    local endTime = XMVCA.XReform:GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            XMVCA.XReform:HandleActivityEndTime()
        end
    end
end

return XUiReformBalanceRoleDetail
