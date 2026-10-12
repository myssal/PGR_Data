---@class XSkyTowerClientRunModel:XModel 客户端运行时数据
---@field _MainModel XSkyTowerModel
local XSkyTowerClientRunModel = XClass(XModel, "XSkyTowerClientRunModel")

function XSkyTowerClientRunModel:OnInit()
    self._UnlockFoodIdDict = nil
    --已解锁产品
    self._UnlockIngredientIdDict = nil
end

function XSkyTowerClientRunModel:ClearPrivate()

end

function XSkyTowerClientRunModel:ResetAll()

end

--- 更新已经解锁的产品, 游戏初始化/升级时调用
function XSkyTowerClientRunModel:UpdateUnlockProduct()
    local level = self._MainModel:GetSkyTowerLv()

    self._UnlockIngredientIdDict = self:GetUnlockProductDict(level, handler(self._MainModel, self._MainModel.GetLvUnlockIngredient))
    self._UnlockFoodIdDict = self:GetUnlockProductDict(level, handler(self._MainModel, self._MainModel.GetLvUnlockFood))
end

function XSkyTowerClientRunModel:GetUnlockProductDict(level, func)
    local dict = {}
    for lv = 1, level do
        local list = func(lv)
        for _, id in ipairs(list) do
            dict[id] = true
        end
    end
    return dict
end

--- 解锁道具是否已集齐
function XSkyTowerClientRunModel:CheckFoodUnlockItem(foodId)
    local config = self._MainModel:GetFoodConfig(foodId)
    local unlockItemIds = config.UnlockItemIds
    if XTool.IsTableEmpty(unlockItemIds) then
        return true
    end
    for index, unlockItemId in ipairs(unlockItemIds) do
        local need = config.UnlockItemCounts[index] or 0
        if self._MainModel:GetItemCount(unlockItemId) < need then
            return false
        end
    end
    return true
end

--- 食物解锁需同时满足三步：1塔等级已开放 2解锁道具已集齐 3消耗的食材全部已解锁
function XSkyTowerClientRunModel:CheckFoodUnlock(foodId)
    if not self:CheckFoodUnlockLv(foodId) then
        return false
    end
    if not self:CheckFoodUnlockItem(foodId) then
        return false
    end
    local template = self._MainModel:GetFoodConfig(foodId)
    local consumeIds = template.ConsumeIngredientIds
    if not XTool.IsTableEmpty(consumeIds) then
        for _, ingredientId in ipairs(consumeIds) do
            -- 对应的食材未解锁
            if not self:CheckIngredientUnlock(ingredientId) then
                return false
            end
        end
    end
    return true
end

--- 塔等级是否已开放该食物
function XSkyTowerClientRunModel:CheckFoodUnlockLv(foodId)
    if not self._UnlockFoodIdDict then
        return false
    end
    return self._UnlockFoodIdDict[foodId]
end

function XSkyTowerClientRunModel:CheckIngredientUnlock(ingredientId)
    if not self._UnlockIngredientIdDict then
        return false
    end
    return self._UnlockIngredientIdDict[ingredientId]
end

return XSkyTowerClientRunModel
