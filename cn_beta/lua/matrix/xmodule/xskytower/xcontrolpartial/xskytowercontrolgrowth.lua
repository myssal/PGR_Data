---Control部分类，此处用于员工数量统计与通天塔等级解锁相关的查询接口
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

--- 获取已解锁的员工Id
---@return number[]
function XSkyTowerControl:GetUnlockCharacterIds()
    local list = {}
    local infos = self._Model:GetCharacterInfos()
    if XTool.IsTableEmpty(infos) then
        return list
    end
    for characterId in pairs(infos) do
        table.insert(list, characterId)
    end
    table.sort(list)
    return list
end

--- 已解锁员工数
---@return number
function XSkyTowerControl:GetUnlockCharacterCount()
    return self._Model:GetUnlockCharacterCount()
end

---是否有空闲员工
function XSkyTowerControl:HasFreeCharacter()
    local infos = self._Model:GetCharacterInfos()
    if XTool.IsTableEmpty(infos) then
        return false
    end
    local workPosInfos = self._Model:GetAllWorkPosInfos()
    if XTool.IsTableEmpty(workPosInfos) then
        return true
    end
    local busy = self:GetWorkingCharacterIdSet()
    for characterId in pairs(infos) do
        if not busy[characterId] then
            return true
        end
    end
    return false
end

---已解锁员工里正被安排在工位上的Id集合
---@return table<number, boolean>
function XSkyTowerControl:GetWorkingCharacterIdSet()
    local infos = self._Model:GetCharacterInfos()
    if XTool.IsTableEmpty(infos) then
        return table.empty
    end
    local workPosInfos = self._Model:GetAllWorkPosInfos()
    if XTool.IsTableEmpty(workPosInfos) then
        return table.empty
    end
    -- 通用角色可同时占多个工位
    local set = {}
    for _, workPos in pairs(workPosInfos) do
        local characterId = workPos.CharacterId
        if XTool.IsNumberValid(characterId) and infos[characterId] then
            set[characterId] = true
        end
    end
    return set
end

--- 升级条件列表
---@return string[]
function XSkyTowerControl:GetSkyTowerUnlockConditionList(data)
    local list = {}

    local staffNumber = data.TotalStaffNumber
    if staffNumber > 0 then
        local text = string.format(self:GetSkyTowerLvUpConditionText(1), staffNumber)
        local unlockCount = self:GetUnlockCharacterCount()
        local finish = unlockCount >= staffNumber
        table.insert(list, {
            Text = text,
            Finish = finish,
            Type = XMVCA.XSkyTower.LvUpConditionType.Precondition,
        })
    end

    local level, count = data.SeniorCharacterLv, data.TotalSeniorCharacter
    if level > 0 and count > 0 then
        local text = string.format(self:GetSkyTowerLvUpConditionText(2), count, self:GetWorkRoleLevelText(level))
        local greaterCount = self:GetGreaterLevelCharacterCount(level)
        local finish = greaterCount >= count
        table.insert(list, {
            Text = text,
            Finish = finish,
            Type = XMVCA.XSkyTower.LvUpConditionType.Precondition,
        })
    end

    for _, consume in ipairs(data.ConsumeData) do
        local need = consume.Count
        local has = self:GetItemCount(consume.ItemId)
        table.insert(list, {
            Text = has .. "/" .. need,
            Finish = has >= need,
            Type = XMVCA.XSkyTower.LvUpConditionType.Consume
        })
    end

    return list
end

--region 楼层升级预览
---楼层升级到目标等级的解锁条件，无条件时视为已满足
---@param level number 目标等级
---@return boolean, string 是否满足、未满足时的条件描述
function XSkyTowerControl:GetFloorUnlockCondition(level)
    local conditionId = self:GetLvConditionId(level)
    if not XTool.IsNumberValid(conditionId) then
        return true, ""
    end
    return XConditionManager.CheckCondition(conditionId)
end

---楼层升级前置条件关联的演出Id
---@param level number 目标等级
---@return number
function XSkyTowerControl:GetFloorUnlockPerformId(level)
    local conditionId = self:GetLvConditionId(level)
    if not XTool.IsNumberValid(conditionId) then
        return 0
    end
    local condition = XConditionManager.GetConditionTemplate(conditionId)
    if not condition or condition.Type ~= 23504 then
        return 0
    end
    return condition.Params and condition.Params[1] or 0
end

---楼层升级金币是否足够
---@param level number 目标等级
---@return boolean, number, number 是否足够、持有数量、需要数量
function XSkyTowerControl:CheckFloorGoldEnough(level)
    local need = self:GetLvNeedGoldCount(level)
    local has = self._Model:GetGoldCount()
    return has >= need, has, need
end

---从当前等级升到目标等级的累计金币消耗
---@param targetLv number 目标等级
---@return number
function XSkyTowerControl:GetFloorLevelUpTotalGold(targetLv)
    local total = 0
    for lv = self:GetSkyTowerLv() + 1, targetLv do
        total = total + self:GetLvNeedGoldCount(lv)
    end
    return total
end

---升到目标等级的累计金币是否足够，长按连升与协议校验都按累计判定
---@param targetLv number 目标等级
---@return boolean, number, number 是否足够、持有数量、累计需要数量
function XSkyTowerControl:CheckFloorGoldEnoughToLv(targetLv)
    local need = self:GetFloorLevelUpTotalGold(targetLv)
    local has = self._Model:GetGoldCount()
    return has >= need, has, need
end

---楼层是否已满级
---@param level number 不传时取当前等级
---@return boolean
function XSkyTowerControl:IsFloorMaxLevel(level)
    if not level then
        level = self:GetSkyTowerLv()
    end
    return level >= XMVCA.XSkyTower.MaxLv
end

---楼层升级的所有条件是否满足
---@param level number 目标等级
---@return boolean
function XSkyTowerControl:CheckFloorLevelUpEnable(level)
    if self:IsFloorMaxLevel(level - 1) then
        return false
    end
    if not self:CheckFloorGoldEnough(level) then
        return false
    end
    local isUnLock, _ = self:GetFloorUnlockCondition(level)
    return isUnLock
end
--endregion

--region 楼层新内容与新工位
---@return number,number 楼层，工位索引
function XSkyTowerControl:GetLastUnlockedWork()
    local lastWorkInfo = self._Model:GetLastUnlockedWork()
    if not lastWorkInfo then
        return nil, nil
    end
    -- WorkPosIndex = FloorId × 10 + Index（Index从0开始）
    return lastWorkInfo.FloorId, lastWorkInfo.WorkPosIndex % 10 + 1
end

--- 楼层升级带来的新解锁内容落库
---@param newCharacterIds number[]
---@param newPerformIds number[]
function XSkyTowerControl:UpdateLevelUpUnlock(newCharacterIds, newPerformIds)
    if not XTool.IsTableEmpty(newCharacterIds) then
        for _, characterId in ipairs(newCharacterIds) do
            -- 只补本地没有的
            if not self._Model:GetCharacterInfo(characterId) then
                self._Model:UnlockCharacter(characterId, XMVCA.XSkyTower.StaffLevelMin)
            end
        end
    end
    if not XTool.IsTableEmpty(newPerformIds) then
        self:RequestPerformData()
    end
end
--endregion

return XSkyTowerControl
