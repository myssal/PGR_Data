local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")

--- 4.9 天平选人界面代理：可选实体限定为已选中的角色砝码（自有角色与试玩机器人两版）
---@class XUiReformBalanceRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiReformBalanceRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiReformBalanceRoleDetail")

--- 排序键
---@param entityId number
---@return number
local function GetSortKey(entityId)
    if XRobotManager.CheckIsRobotId(entityId) then
        return XRobotManager.GetCharacterId(entityId) * 2
    end
    return entityId * 2 + 1
end

--- 角色 id 降序，同 id 时自机排在试玩机器人前
---@param idA number
---@param idB number
---@return boolean
local function IsEntityIdBigger(idA, idB)
    return GetSortKey(idA) > GetSortKey(idB)
end

local function CheckSortAlwaysApply()
    return true
end

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

--- 覆写角色列表排序
--- 本页面没配 SortTagList，筛选器会走默认的 等级/战力/… 排序，逐个接管掉
function XUiReformBalanceRoleDetail:GetFilterSortOverrideFunTable()
    local overrideTable = { CheckFunList = {}, SortFunList = {} }
    local defaultSortTypes = {
        CharacterSortFunType.Level,
        CharacterSortFunType.Ability,
        CharacterSortFunType.GeneralElement,
        CharacterSortFunType.Quality,
        CharacterSortFunType.Priority,
    }
    for index = 1, #defaultSortTypes do
        local sortType = defaultSortTypes[index]
        overrideTable.CheckFunList[sortType] = CheckSortAlwaysApply
        overrideTable.SortFunList[sortType] = IsEntityIdBigger
    end
    return overrideTable
end

--- 恒 false：不让筛选器按「是否已进编队」置顶
---@param team XTeam
---@param entityId number
---@return boolean
function XUiReformBalanceRoleDetail:CheckInTeam(team, entityId)
    return false
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
