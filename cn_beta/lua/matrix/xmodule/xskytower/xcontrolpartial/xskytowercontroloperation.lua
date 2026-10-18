---Control部分类，此处用于营业状态、加速道具与离线账单
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

--region 经营状态
--- 通天塔是否在营业时间内
---@return boolean
function XSkyTowerControl:IsActivityInTime()
    return self._Model:IsActivityInTime()
end

--- 今日已使用加速次数
---@return number
function XSkyTowerControl:GetAccelerateUseTimes()
    return self._Model:GetAccelerateUseTimes()
end

--- 离线账单收益
---@return number
function XSkyTowerControl:GetOfflineBill()
    return self._Model:GetOfflineBill()
end

--- 离线账单角色券收益
---@return number
function XSkyTowerControl:GetOfflineCharacterLvUpItemCount()
    return self._Model:GetOfflineCharacterLvUpItemCount()
end

--- 离线时长（秒）
---@return number
function XSkyTowerControl:GetOfflineSeconds()
    return self._Model:GetOfflineSeconds()
end

--- 快照本次进入是否要弹账单，弹过之后账单会被清空，故不能每次现算
function XSkyTowerControl:UpdateOfflineRecord()
    self._OfflineRecord = self:IsOfflineBillReady()
end

--- 关掉离线账单
function XSkyTowerControl:CloseOfflineBill()
    self._Model:UpdateAccount(0, 0, 0)
    self:UpdateOfflineRecord()
end

function XSkyTowerControl:IsShowOfflineBill()
    return self._OfflineRecord and true or false
end
--endregion

--region 加速道具
---打开使用加速道具弹窗
function XSkyTowerControl:OpenSpeedUpItemPopup(floorId, workPosId, count)
    XLuaUiManager.Open("UiSkyTowerAcceleratePopup", floorId, workPosId, count or 1)
end

--- 选择数量只受道具与使用额度限制
function XSkyTowerControl:GetSpeedUpSelectableMaxCount()
    local maxCount = math.min(self:GetIntConfigValue("AcceleratePerUseLimit"), self._Model:GetSpeedUpItemCount())
    local dailyLimit = self:GetConfigAccelerateUseLimit()
    if dailyLimit > 0 then
        maxCount = math.min(maxCount, dailyLimit - self:GetAccelerateUseTimes())
    end
    return math.max(0, maxCount)
end

--- 未生效的道具由服务端保留，此处仅展示，不修改余额
function XSkyTowerControl:OpenSpeedUpReturnPopup(returnCount)
    if returnCount <= 0 then
        return
    end
    local itemId = self:GetIntConfigValue("SpeedUpItemId")
    local title = self:GetClientConfigText("AccelerateReturnTip", 1)
    local content = self:GetClientConfigText("AccelerateReturnTip", 2, returnCount, self:GetItemName(itemId))
    self:OpenPopup(title, content, { Icon = self:GetItemIcon(itemId), Count = returnCount }, nil, nil, true)
end

---加速产出的图标：备菜/做菜给产物本身，售卖台给金币
---@param workInfo XSkyTowerWorkPosInfoProtocol
function XSkyTowerControl:GetSpeedUpProductIcon(workInfo)
    if not workInfo then
        return ""
    end
    local WorkType = XMVCA.XSkyTower.WorkType
    if workInfo.WorkType == WorkType.Ingredient then
        return self:GetIngredientIcon(workInfo.ProductId)
    elseif workInfo.WorkType == WorkType.Food then
        return self:GetFoodIcon(workInfo.ProductId)
    elseif workInfo.WorkType == WorkType.Sale then
        return self:GetItemIcon(XMVCA.XSkyTower.ItemId.SkyTowerCoin)
    end
    return ""
end

--- 同一份预估同时给出数量和首个限制原因；两项同时到达时优先展示满仓
---@return number count
---@return boolean isFull
---@return boolean isLack
function XSkyTowerControl:GetSpeedUpProductPreview(floorId, index, workInfo, totalTime)
    if not workInfo or totalTime <= 0 or not self:IsRunning(floorId, index) then
        return 0, false, false
    end
    local singleTime = self:GetProduceSingleTime(floorId, index)
    if singleTime <= 0 then
        return 0, false, false
    end
    --预览使用同一份服务端快照的工时、库存和预扣；显示倒计时不参与收益结算
    local workedSeconds = math.min(singleTime, self:GetWorkedSeconds(floorId, index))
    local timeRounds = math.floor((totalTime + workedSeconds) / singleTime)
    local materialRounds = self:GetSpeedUpProductLimit(floorId, index, workInfo) or math.huge
    local produceRounds = math.min(timeRounds, materialRounds)
    if workInfo.WorkType == XMVCA.XSkyTower.WorkType.Sale then
        return produceRounds * self:GetFoodSinglePrice(floorId, index), false, materialRounds <= timeRounds
    end
    --增产余数是万分比数量，不是时间；按服务端逐轮累计的结果计算整份产出
    local remainder = (workInfo.ProduceRemainder or 0) / XMVCA.XSkyTower.TenThousandRate
    local outputCount = self:GetOutputCount(floorId, index)
    local groupId = self:_GetGroupId(floorId)
    local capacity = self:GetFreeCapacity(groupId, workInfo.ProductType, workInfo.ProductId)
    local produceCount = math.floor(produceRounds * outputCount + remainder)
    local isFull = produceCount >= capacity
    local isLack = not isFull and materialRounds <= timeRounds
    return math.min(produceCount, capacity), isFull, isLack
end

---前置产物最多还能撑几份，没有前置消耗（备菜台）时返回nil表示不限制
---@param workInfo XSkyTowerWorkPosInfoProtocol
function XSkyTowerControl:GetSpeedUpProductLimit(floorId, index, workInfo)
    local WorkType = XMVCA.XSkyTower.WorkType
    local groupId = self:_GetGroupId(floorId)
    --本轮材料在开工时就预扣了，那一份不占库存
    local consumed = self:IsConsume(floorId, index) and 1 or 0
    if workInfo.WorkType == WorkType.Sale then
        --能卖多少看库存里还有多少这道菜
        local stock = self:GetStorageProductCount(groupId, XMVCA.XSkyTower.ProductType.Food, workInfo.ProductId)
        return math.floor(stock) + consumed
    end
    if workInfo.WorkType ~= WorkType.Food then
        return nil
    end
    local consumes = self:GetFoodConsumes(workInfo.ProductId)
    if XTool.IsTableEmpty(consumes) then
        --没有配方需求，只受时间限制
        return nil
    end
    local limit
    for _, consume in ipairs(consumes) do
        if consume.Count > 0 then
            local stock = self:GetStorageProductCount(groupId, consume.ProductType, consume.Id)
            local canMake = math.floor(stock / consume.Count)
            limit = limit and math.min(limit, canMake) or canMake
        end
    end
    return limit and limit + consumed or nil
end
--endregion

return XSkyTowerControl
