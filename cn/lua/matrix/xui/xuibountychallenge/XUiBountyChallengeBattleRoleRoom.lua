local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiBountyChallengeBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiBountyChallengeBattleRoleRoom")

function XUiBountyChallengeBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiBountyChallenge/XUiBountyChallengeBattleRoomRoleDetail")
end

--function XUiBountyChallengeBattleRoleRoom:GetAutoCloseInfo()
--    local endTime = XMVCA.XReform:GetActivityEndTime()
--    return true, endTime, function(isClose)
--        if isClose then
--            XMVCA.XReform:HandleActivityEndTime()
--        end
--    end
--end
--
---- 获取子面板数据，主要用来增加编队界面自身玩法信息，就不用污染通用的预制体
----[[
--    return : {
--        assetPath : 资源路径
--        proxy : 子面板代理
--        proxyArgs : 子面板SetData传入的参数列表
--    }
--]]
--function XUiBountyChallengeBattleRoleRoom:GetChildPanelData()
--    return {
--        assetPath = XUiConfigs.GetComponentUrl("PanelReformBattleRoom"),
--        proxy = XUiReform2ndChildPanel,
--        proxyArgs = { "StageId" }
--    }
--end

---@param ui XUiBattleRoleRoom
function XUiBountyChallengeBattleRoleRoom:AOPOnStartAfter(ui)
    --关卡内可上阵角色有限制时，隐藏预设按钮
    if XMVCA.XBountyChallenge:HasCharactersLimit() then
        ui.BtnTeamPrefab.gameObject:SetActiveEx(false)
    end
end

---@param ui XUiBattleRoleRoom
function XUiBountyChallengeBattleRoleRoom:AOPOnStartBefore(ui)
    local playerAmount = XMVCA.XBountyChallenge:GetCharacterCanSelectAmount()
    local maxAmount = XEnumConst.FuBen.PlayerAmount
    if playerAmount ~= maxAmount then
        ---@type XTeam
        local team = ui.Team
        for i = playerAmount + 1, maxAmount do
            local entityId = team:GetEntityIdByTeamPos(i)
            if entityId ~= 0 then
                team:UpdateEntityTeamPos(0, i, true)
            end

            local btnChar = ui["BtnChar" .. i]
            if btnChar then
                btnChar.gameObject:SetActiveEx(false)
            end

            local uiModelRoot = ui.UiModelGo.transform
            local panelRoleBGEffect = uiModelRoot:FindTransform("PanelRoleEffect" .. i)
            panelRoleBGEffect.gameObject:SetActiveEx(false)

            ---@type XUiButtonLongClick
            local button = ui["XUiButtonLongClick" .. i]
            if button then
                button.GameObject:SetActiveEx(false)
            end
        end
    end
end
--
--function XUiBountyChallengeBattleRoleRoom:GetReformPlayerAmount(ui)
--    if not self._ReformPlayerAmount then
--        if not ui then
--            return XEnumConst.FuBen.PlayerAmount
--        end
--        local playerAmount = XMVCA.XReform:GetStagePlayerAmount(ui.StageId)
--        self._ReformPlayerAmount = playerAmount
--    end
--    return self._ReformPlayerAmount
--end
--
---- 检查是否满足关卡配置的强制性条件
---- return : bool
--function XUiBountyChallengeBattleRoleRoom:CheckStageForceConditionWithTeamEntityId(team, stageId, showTip)
--    if #team > self:GetReformPlayerAmount() then
--        return false
--    end
--    return true
--end
--
function XUiBountyChallengeBattleRoleRoom:CheckIsCanMoveDownCharacter(index)
    local amount = XMVCA.XBountyChallenge:GetCharacterCanSelectAmount()
    if index > amount then
        return false
    end
    return true
end
--
--function XUiBountyChallengeBattleRoleRoom:FilterPresetTeamEntitiyIds(teamData)
--    local amount = self:GetReformPlayerAmount()
--    if amount ~= XEnumConst.FuBen.PlayerAmount then
--        teamData = XTool.Clone(teamData)
--        for pos, characterId in ipairs(teamData.TeamData) do
--            if pos > amount then
--                teamData.TeamData[pos] = 0
--            end
--        end
--    end
--    return teamData
--end
--
--function XUiBountyChallengeBattleRoleRoom:CheckShowAnimationSet()
--    return false
--end

-- 进入战斗
-- team : XTeam
-- stageId : number
--function XUiBountyChallengeBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
--    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
--    XMVCA.XFuben:EnterStageWithRobot(stageConfig, team)
--end

return XUiBountyChallengeBattleRoleRoom