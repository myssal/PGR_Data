---Control部分类，此处用于玩法内红点的检测与标记
---注意：XSkyTowerAgency.lua 中有同名的 CheckTaskRedPoint/CheckPerformRedPoint 等方法，
---那是提供给外部（红点管理器）的入口层，与本文件不是同一个东西，勿混淆
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

--region 红点
function XSkyTowerControl:CheckTaskRedPoint()
    return XMVCA.XSkyTower:CheckTaskRedPoint()
end

function XSkyTowerControl:CheckMenuSingTabRedPoint(tabId)
    local recordCount = self._Model:GetMenuRedPointMarkCount(tabId)
    local count = self:GetMenuTabUnlockCount(tabId)

    return recordCount ~= count
end

function XSkyTowerControl:CheckMenuRedPoint(tabId)
    if XTool.IsNumberValid(tabId) then
        return self:CheckMenuSingTabRedPoint(tabId)
    end

    for _, menuId in pairs(XMVCA.XSkyTower.MenuTabType) do
        if self:CheckMenuSingTabRedPoint(menuId) then
            return true
        end
    end
    return false
end

--- 菜单页签当前已解锁的数量
---@param tabId number
---@return number
function XSkyTowerControl:GetMenuTabUnlockCount(tabId)
    local performType = XMVCA.XSkyTower.PerformType
    if tabId == XMVCA.XSkyTower.MenuTabType.Perform then
        return self:GetUnlockPerformCount(performType.Event) + self:GetUnlockPerformCount(performType.FloorGroup)
    elseif tabId == XMVCA.XSkyTower.MenuTabType.Indent then
        return self:GetUnlockPerformCount(performType.Indent)
    elseif tabId == XMVCA.XSkyTower.MenuTabType.Food then
        return self:GetUnlockProductListCount(XMVCA.XSkyTower.WorkType.Food)
    end
    return 0
end

--- 已解锁（非未开始状态）的演出/订单数量
---@param performType number XMVCA.XSkyTower.PerformType
function XSkyTowerControl:GetUnlockPerformCount(performType)
    local infos = self._Model:GetPerformInfos()
    if XTool.IsTableEmpty(infos) then
        return 0
    end
    local count = 0
    local PerformState = XMVCA.XSkyTower.PerformState
    for _, info in pairs(infos) do
        if info.Type == performType then
            if info.State == PerformState.OnGoing and self:IsPerformShow(info.PerformId) then
                count = count + 1
            elseif info.State == PerformState.Finish then
                count = count + 1
            end
        end
    end
    return count
end

--- 标记菜单页签为已读（把当前解锁数写进存档，红点随之熄灭）
function XSkyTowerControl:MarkMenuRedPoint(tabId)
    local recordCount = self._Model:GetMenuRedPointMarkCount(tabId)
    local count = self:GetMenuTabUnlockCount(tabId)
    if recordCount == count then
        return
    end
    self._Model:SaveMenuRedPointMarkCount(tabId, count)
end

function XSkyTowerControl:CheckPerformRedPoint(performId)
    if not XTool.IsNumberValid(performId) then
        return false
    end
    if not self:IsFinish(performId) then
        return false
    end
    if not self._Model:IsPerformRedPointMarked(performId) then
        return true
    end
    return false
end

function XSkyTowerControl:MarkPerformRedPoint(performId)
    if not XTool.IsNumberValid(performId) then
        return false
    end
    if not self:IsFinish(performId) then
        return false
    end
    if self._Model:IsPerformRedPointMarked(performId) then
        return
    end
    self._Model:MarkPerformRedPoint(performId)
end

function XSkyTowerControl:MarkPerformListRedPoint(performIds)
    for _, id in ipairs(performIds) do
        self:MarkPerformRedPoint(id)
    end
end

--- 工位红点：有空闲员工且存在空工位
---@param index number 工位下标，不传则检查该区域全部工位
---@param floorId number 不传取当前楼层
---@return boolean
function XSkyTowerControl:CheckWorkBenchRedPoint(index, floorId)
    if not self:IsWorkPosFree(floorId, index) then
        return false
    end
    return self:HasFreeCharacter()
end

function XSkyTowerControl:CheckAchievementTaskRedPoint()
    return XMVCA.XSkyTower:CheckAchievementTaskRedPoint()
end

function XSkyTowerControl:CheckDailyTaskRedPoint()
    return XMVCA.XSkyTower:CheckDailyTaskRedPoint()
end

--endregion

function XSkyTowerControl:GetEntranceTime()
    return self._Model:GetEntranceTime()
end

function XSkyTowerControl:UpdateEntranceTime()
    self._Model:UpdateEntranceTime()
end

return XSkyTowerControl
