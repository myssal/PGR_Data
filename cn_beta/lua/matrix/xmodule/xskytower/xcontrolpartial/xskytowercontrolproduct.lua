---Control部分类，此处用于产品（食材/料理/售卖）的产能、库存与预览文本计算
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

--- 已解锁产品个数
---@param workType number
---@return number
function XSkyTowerControl:GetUnlockProductListCount(workType)
    return self:GetUnlockProductCount(workType)
end

--- 是否是急需食材
---@param workType number
---@param productId number
---@return boolean
function XSkyTowerControl:IsUrgentProduct(workType, productId)
    return self:IsGroupUrgentProduct(self:GetCurFloorGroupId(), workType, productId)
end

--- 获取产品的生产总速
---@param workType number 产品类型
---@param productId number
---@param timeUnit number
---@return number
function XSkyTowerControl:GetProduceTotalSpeed(workType, productId, timeUnit)
    if not XTool.IsNumberValid(productId) then
        return 0
    end
    timeUnit = timeUnit or XMVCA.XSkyTower.TimeUnit.Hour
    return self:GetGroupProduceTotalSpeed(self:GetCurFloorGroupId(), workType, productId, timeUnit)
end

--- 获取产品的消耗总体速度
---@param workType number 产品类型
---@param productId number
---@param timeUnit number
---@return number
function XSkyTowerControl:GetConsumeTotalSpeed(workType, productId, timeUnit)
    if not XTool.IsNumberValid(productId) then
        return 0
    end
    timeUnit = timeUnit or XMVCA.XSkyTower.TimeUnit.Hour
    return self:GetGroupConsumeTotalSpeed(self:GetCurFloorGroupId(), workType, productId, timeUnit)
end

--- 产品库存数量
---@param workType number
---@param productId number
---@return number
function XSkyTowerControl:GetProductCount(workType, productId)
    local groupId = self:GetCurFloorGroupId()
    local productType = self:IsIngredientArea(workType) and XMVCA.XSkyTower.ProductType.Ingredient or XMVCA.XSkyTower.ProductType.Food
    return self:GetStorageProductCount(groupId, productType, productId)
end

--- 产品仓库剩余容量
---@param workType number
---@param productId number
---@return number
function XSkyTowerControl:GetProductFreeCapacity(workType, productId)
    local groupId = self:GetCurFloorGroupId()
    local productType = self:IsIngredientArea(workType) and XMVCA.XSkyTower.ProductType.Ingredient or XMVCA.XSkyTower.ProductType.Food
    return self:GetFreeCapacity(groupId, productType, productId)
end

--- 产品库存上限
---@param workType number
---@param productId number
---@return number
function XSkyTowerControl:GetProductLimit(workType, productId)
    local groupId = self:GetCurFloorGroupId()
    local productType = self:GetProductTypeByWorkType(workType)
    return self:GetStorageProductLimit(groupId, productType, productId)
end

--- 产品库存是否已满
---@return boolean
function XSkyTowerControl:IsProductFull(workType, productId)
    return self:GetProductCount(workType, productId) >= self:GetProductLimit(workType, productId)
end

--- 产品库存描述
---@param index number 配置表下标
---@param showLimit boolean 是否展示上限
---@return string
function XSkyTowerControl:GetProductCountDesc(workType, productId, index, showLimit)
    local desc = self:GetStorageCountText(index)
    if showLimit then
        return string.format(desc, self:GetProductCount(workType, productId), self:GetProductLimit(workType, productId))
    end
    return string.format(desc, self:GetProductCount(workType, productId))
end

--- 工作台预览提示
---@param workType number
---@param productId number
---@param timeUnit number
---@return boolean, string
function XSkyTowerControl:GetWorkBenchPreviewTip(workType, productId, timeUnit)
    local produce = self:GetProduceTotalSpeed(workType, productId, timeUnit)
    local consume = self:GetConsumeTotalSpeed(workType, productId, timeUnit)
    if produce == 0 and consume == 0 then
        return true, ""
    end
    local tip
    local subSpeed = produce - consume
    local freeCount = subSpeed > 0 and self:GetProductFreeCapacity(workType, productId) or self:GetProductCount(workType, productId)
    if self:IsIngredientArea(workType) then
        if self:IsZero(subSpeed) and not self:IsZero(produce) then
            tip = self:GetClientConfigValue("StoragePreviewTip1", 1)
        else
            local index = subSpeed > 0 and 1 or 2
            local desc = self:GetClientConfigValue("StoragePreviewTip1", index)
            local time = math.abs(freeCount / subSpeed)
            tip = string.format(desc, self:GetAroundValue(time, XMVCA.XSkyTower.Digital.One))
        end
        return subSpeed > 0, tip
    elseif self:IsCookArea(workType) then
        --消耗完毕或者满仓速度
        local stop = freeCount / math.abs(produce - consume)
        local list = self:GetFoodConsumes(productId)
        if XTool.IsTableEmpty(list) then
            --没有配方需求的食物，只看自身产销差
            return subSpeed > 0, ""
        end
        --取所有配方材料里最先见底的那个
        local cStop = stop
        for _, need in ipairs(list) do
            local cSpeed = self:GetProductCount(need.WorkType, need.Id) / self:GetConsumeTotalSpeed(need.WorkType, need.Id, timeUnit)
            cStop = math.min(cStop, cSpeed)
        end
        local increase = subSpeed > 0 and stop <= cStop
        local isZero = self:IsZero(cStop) and self:IsZero(subSpeed)
        if isZero then
            tip = self:GetClientConfigValue("StoragePreviewTip2", 4)
        else
            local index
            --生产速度 > 消耗速度 && 食材库存足够
            if increase then
                index = 1
            elseif stop > cStop then
                --食材消耗 > 售卖
                index = 3
            else
                --食材消耗 < 售卖
                index = 2
            end
            local desc = self:GetClientConfigValue("StoragePreviewTip2", index)
            tip = string.format(desc, self:GetAroundValue(cStop, XMVCA.XSkyTower.Digital.One))
        end
        return increase, tip
    elseif self:IsSaleArea(workType) then
        -- 售卖区没有容量上限，只预测存货卖完的时间
        if self:IsZero(consume) then
            return false, ""
        end
        local consumeTime = self:GetProductCount(workType, productId) / consume
        local desc = self:GetClientConfigValue("StoragePreviewTip3", 2)
        return false, string.format(desc, self:GetAroundValue(consumeTime, XMVCA.XSkyTower.Digital.One))
    end
end

---工位当前生效的增益列表（安排工作弹窗的加成气泡用）
---只按工位覆盖范围与工作区域判断，不受当前选择的产品影响
---@return {Icon:string, Desc:string, Value:string}[]
function XSkyTowerControl:GetWorkBonusList(floorId, index, workType)
    local WorkType = XMVCA.XSkyTower.WorkType
    if workType ~= WorkType.Ingredient and workType ~= WorkType.Food and workType ~= WorkType.Sale then
        return table.empty
    end
    local list = {}
    local sharedSkills = self:_GetSkillShareIndex()[self._Model:MakeWorkPosKey(floorId, index)]
    for _, shared in ipairs(sharedSkills or table.empty) do
        if self:GetCharacterSkillSectionType(shared.SkillId) == workType then
            self:_AppendWorkBonusItems(list, shared, workType)
        end
    end
    return list
end

---同一技能对多个产品提供相同加成时合并展示，不同加成则标出对应产品
---@param shared XSkyTowerSharedSkill 覆盖到该工位的技能
function XSkyTowerControl:_AppendWorkBonusItems(list, shared, workType)
    local skillId = shared.SkillId
    local multiplier = shared.Ratio / XMVCA.XSkyTower.TenThousandRate
    local groups, groupDict = {}, {}
    local AdditionType = XMVCA.XSkyTower.SkillAdditionType
    for _, item in ipairs(self:GetCharacterSkillAdditionList(skillId)) do
        local addition = math.floor((item.Addition or 0) * multiplier)
        local additionType = item.AdditionType
        if XTool.IsNumberValid(item.Id) and addition > 0
            and (additionType == AdditionType.ReduceTime or additionType == AdditionType.UpProduce or additionType == AdditionType.UpProductPrice) then
            local value = self:GetSkillAdditionDescText(addition, workType, additionType)
            local key = additionType .. "_" .. value
            local group = groupDict[key]
            if not group then
                group = { Value = value, ProductNames = {} }
                groupDict[key] = group
                groups[#groups + 1] = group
            end
            group.ProductNames[#group.ProductNames + 1] = self:GetProductName(workType, item.Id)
        end
    end
    if #groups == 0 then
        return
    end
    local skillName = self:IsCharacterSkillAura(skillId) and self:GetSkillTypeName(XMVCA.XSkyTower.SkillTabType.Aura) or self:GetCharacterSkillName(skillId)
    local desc = string.format("%s：%s", skillName, self:GetCharacterName(shared.FromCharacterId))
    local icon = self:GetMenuBonusIcon(1)
    for _, group in ipairs(groups) do
        list[#list + 1] = {
            Icon = icon,
            Desc = #groups > 1 and string.format("%s（%s）", desc, table.concat(group.ProductNames, "、")) or desc,
            Value = group.Value,
        }
    end
end

return XSkyTowerControl
