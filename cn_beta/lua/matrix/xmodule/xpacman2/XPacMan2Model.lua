local TableKey = {
    PacMan2Entity = { DirPath = XConfigUtil.DirectoryType.Client },
    PacMan2GameConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key", },
    PacMan2Activity = { CacheType = XConfigUtil.CacheType.Normal },
    PacMan2Stage = { CacheType = XConfigUtil.CacheType.Normal },
    PacMan2StageEvent = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "StageId", },
    PacMan2EventRule = { DirPath = XConfigUtil.DirectoryType.Client },
    PacMan2EventGroup = { DirPath = XConfigUtil.DirectoryType.Client },
    PacMan2AtomicEvent = { DirPath = XConfigUtil.DirectoryType.Client },
    PacMan2StageTips = { DirPath = XConfigUtil.DirectoryType.Client },
}

---@class XPacMan2Model : XModel
local XPacMan2Model = XClass(XModel, "XPacMan2Model")
function XPacMan2Model:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/PacMan2", TableKey)

    self._ActivityId = 0
    self._StageRecords = false
    self.IsPlaying = false

    -- 同一局内，通过暂停菜单重新进入关卡的累计次数。
    -- 保留在Model中，不随Game界面的销毁而清空。
    self._RestartTimes = 0
end

function XPacMan2Model:ClearPrivate()
    self.IsPlaying = false
end

function XPacMan2Model:ResetAll()
    self._ActivityId = 0
    self._StageRecords = false
    self.IsPlaying = false
    self._RestartTimes = 0
end

function XPacMan2Model:SetDataFromServer(data)
    self._ActivityId = data.ActivityId
    self._StageRecords = data.StageRecords
end

function XPacMan2Model:SetStageData(stageData)
    if not stageData then
        XLog.Error("[XPacMan2Model] SetStageData stageData is nil")
        return
    end
    if not self._StageRecords then
        self._StageRecords = {}
    end
    for i = 1, #self._StageRecords do
        local stageId = self._StageRecords[i].StageId
        if stageId == stageData.StageId then
            self._StageRecords[i] = stageData
            return
        end
    end
    table.insert(self._StageRecords, stageData)
end

---@return XTablePacMan2Activity
function XPacMan2Model:GetActivityConfig()
    local activityId = self._ActivityId
    if not activityId or activityId == 0 then
        return nil
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PacMan2Activity, activityId, true)
    return config
end

---@return table<number, XTablePacMan2Activity>
function XPacMan2Model:GetAllActivityConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.PacMan2Activity)
end

function XPacMan2Model:GetStageConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.PacMan2Stage)
    return configs
end

---@return XTablePacMan2Stage
function XPacMan2Model:GetStageConfig(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PacMan2Stage, stageId, true)
    return config
end

function XPacMan2Model:IsStagePassed(stageId)
    if self._StageRecords then
        local star = self:GetStageStar(stageId)
        if star > 0 then
            return true
        end
    end
    return false
end

function XPacMan2Model:GetStageStar(stageId)
    if not self._StageRecords then
        return 0
    end
    for _, record in ipairs(self._StageRecords) do
        if record.StageId == stageId then
            return self:CalculateStageStar(stageId, record.HighestScore)
        end
    end
    return 0
end

function XPacMan2Model:GetGameConfig()
    local config = self._ConfigUtil:GetByTableKey(TableKey.PacMan2GameConfig)
    return config
end

function XPacMan2Model:GetEntityConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PacMan2Entity, id, true)
    return config
end

function XPacMan2Model:GetToggleTouch()
    return self._SaveUtil:GetData("ToggleTouchV2", false)
end

function XPacMan2Model:SetToggleTouch(value)
    self._SaveUtil:SaveData("ToggleTouchV2", value)
end

---@return XTablePacMan2StageEvent|nil
function XPacMan2Model:GetStageEventConfig(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PacMan2StageEvent, stageId, true)
end

---@return table<number, XTablePacMan2EventRule>
function XPacMan2Model:GetEventRuleConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.PacMan2EventRule) or table.empty
end

---@return XTablePacMan2EventGroup|nil
function XPacMan2Model:GetEventGroupConfig(eventGroupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PacMan2EventGroup, eventGroupId, true)
end

---@return XTablePacMan2AtomicEvent|nil
function XPacMan2Model:GetAtomicEventConfig(atomicEventId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PacMan2AtomicEvent, atomicEventId, true)
end

---获取全部主界面点击提示配置。
---@return table<number, XTablePacMan2StageTips>
function XPacMan2Model:GetStageTipConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.PacMan2StageTips) or table.empty
end

---记录一次游戏界面的进入。
---暂停菜单重开延续当前局并累加次数；
---普通进入、结算再来一局、下一关和重新选关均开始新局。
---@param isRestart boolean
function XPacMan2Model:RecordGameEntry(isRestart)
    if isRestart then
        self._RestartTimes = self._RestartTimes+1
    else
        self._RestartTimes = 0
    end
end

function XPacMan2Model:GetRestartTimes()
    return self._RestartTimes
end

---按给定分数计算星级，不读取历史记录。
---保持原GetStageStar的判断方式：从高星级向低星级查找。
---@param stageId number
---@param score number
---@return number
function XPacMan2Model:CalculateStageStar(stageId,score)
    local stageConfig = self:GetStageConfig(stageId)
    if not stageConfig then
        return 0
    end
    for star = #stageConfig.Star, 1, -1 do
        if score >= stageConfig.Star[star] then
            return star
        end
    end
    return 0
end

return XPacMan2Model