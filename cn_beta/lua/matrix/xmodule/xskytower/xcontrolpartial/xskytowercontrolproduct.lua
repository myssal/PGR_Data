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
    timeUnit = timeUnit or XMVCA.XSkyTower.TimeUnit.Hour
    local isSale = self:IsSaleArea(workType)
    -- 售卖与手作共用成品库存，补货来自手作工位，而非售卖工位自身。
    local produceWorkType = isSale and XMVCA.XSkyTower.WorkType.Food or workType
    local produce = self:GetProduceTotalSpeed(produceWorkType, productId, timeUnit)
    local consume = self:GetConsumeTotalSpeed(workType, productId, timeUnit)
    if produce == 0 and consume == 0 then
        return true, ""
    end
    local tip
    local subSpeed = produce - consume
    local isBalanced = self:IsZero(subSpeed)
    local freeCount = subSpeed > 0 and self:GetProductFreeCapacity(workType, productId) or self:GetProductCount(workType, productId)
    if self:IsIngredientArea(workType) or isSale then
        local configKey = isSale and "StoragePreviewTip3" or "StoragePreviewTip1"
        if isBalanced then
            -- 产消平衡时使用无占位符的持续产出文案。
            tip = self:GetClientConfigValue(configKey, 3)
        else
            local index = subSpeed > 0 and 1 or 2
            local desc = self:GetClientConfigValue(configKey, index)
            local time = math.abs(freeCount / subSpeed)
            tip = string.format(desc, self:GetFloorValue(time, XMVCA.XSkyTower.Digital.One))
        end
        return not isBalanced and subSpeed > 0, tip
    elseif self:IsCookArea(workType) then
        -- 平衡时成品不会耗尽或满仓，但仍需检查材料；除法前判零，避免 0/0。
        local stop = math.huge
        if not isBalanced then
            stop = freeCount / math.abs(subSpeed)
        end
        local list = self:GetFoodConsumes(productId)
        if XTool.IsTableEmpty(list) then
            --没有配方需求的食物，只看自身产销差
            return subSpeed > 0, ""
        end
        --取所有配方材料里最先见底的那个
        local cStop = stop
        for _, need in ipairs(list) do
            -- 库存非负，零时刻已是最早事件；仅精确为零时跳过后续查询。
            if cStop == 0 then
                break
            end
            local materialProduce = self:GetProduceTotalSpeed(need.WorkType, need.Id, timeUnit)
            local materialConsume = self:GetConsumeTotalSpeed(need.WorkType, need.Id, timeUnit)
            local netConsume = materialConsume - materialProduce
            if netConsume > 0 and not self:IsZero(netConsume) then
                local materialStop = self:GetProductCount(need.WorkType, need.Id) / netConsume
                cStop = math.min(cStop, materialStop)
            end
        end
        local increase = not isBalanced and subSpeed > 0 and stop <= cStop
        if cStop == math.huge then
            tip = self:GetClientConfigValue("StoragePreviewTip2", 4)
        else
            local index
            --生产速度 > 消耗速度 && 食材库存足够
            if increase then
                index = 1
            elseif stop > cStop then
                -- 材料先于成品耗尽或满仓
                index = 3
            else
                -- 成品先耗尽，或与材料同时耗尽
                index = 2
            end
            local desc = self:GetClientConfigValue("StoragePreviewTip2", index)
            tip = string.format(desc, self:GetFloorValue(cStop, XMVCA.XSkyTower.Digital.One))
        end
        return increase, tip
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
