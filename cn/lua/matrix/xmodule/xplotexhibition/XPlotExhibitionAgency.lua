---@class XPlotExhibitionAgency : XAgency
---@field private _Model XPlotExhibitionModel
local XPlotExhibitionAgency = XClass(XAgency, "XPlotExhibitionAgency")
function XPlotExhibitionAgency:OnInit()
    self._Speedrun = {}
end

function XPlotExhibitionAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XPlotExhibitionAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XPlotExhibitionAgency:OpenRoleDetail(characterId)
    XLuaUiManager.Open("UiPlotExhibitionDetail", characterId)
end

--此记录仅在当次登录期间保存，重登游戏时，清除上一次登录的本地记录，所有勾选状态切换回【取消】状态
function XPlotExhibitionAgency:SetIsSpeedrun(stageId, value)
    local groupId = self._Model:GetStageGroupId(stageId)
    if groupId then
        self._Speedrun[groupId] = value
    else
        XLog.Error("[XPlotExhibitionAgency] 找不到stageId对应的groupId", stageId)
    end
end

function XPlotExhibitionAgency:GetIsSpeedrun(stageId)
    local groupId = self._Model:GetStageGroupId(stageId)
    if groupId then
        return self._Speedrun[groupId]
        --else
        --    XLog.Error("[XPlotExhibitionAgency] 找不到stageId对应的groupId", stageId)
    end
end

function XPlotExhibitionAgency:AddSpeedrunRobots(stageId, entities)
    local config = self._Model:GetStageSpeedrunConfig(stageId)
    if config then
        for _, robotId in pairs(config.RobotId) do
            local robot = XRobotManager.GetRobotById(robotId)
            if robot then
                table.insert(entities, robot)
            else
                XLog.Error("XPlotExhibitionAgency:AddSpeedrunRobots robotId not exist:" .. tostring(robotId))
            end
        end
    end
end

function XPlotExhibitionAgency:GetSpeedrunStageId(stageId)
    local groupId = self._Model:GetStageGroupId(stageId)
    if groupId then
        if self._Speedrun[groupId] then
            local config = self._Model:GetStageSpeedrunConfig(stageId)
            if config then
                XLog.Debug("关卡:" .. tostring(stageId) .. "替换为速通关卡:" .. config.StageId)
                return config.StageId
            end
        end
    end
end

function XPlotExhibitionAgency:IsShowSpeedrunToggle(stageId)
    local config = self._Model:GetStageSpeedrunConfig(stageId)
    if config then
        return true
    end
    return false
end

---@return XTablePlotExhibitionStoryLine[]
function XPlotExhibitionAgency:GetStoryLineConfigs()
    return self._Model:GetStoryLineConfigs()
end

function XPlotExhibitionAgency:OpenMain()
    local functionId = XFunctionManager.FunctionName.PlotExhibition
    if XFunctionManager.DetectionFunction(functionId) then
        XLuaUiManager.Open("UiPlotExhibitionMain")
    end
end

return XPlotExhibitionAgency