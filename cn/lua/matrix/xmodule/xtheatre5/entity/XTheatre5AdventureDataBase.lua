--region 类型定义

--- 商店
---@class XTheatre5ShopData
---@field ShopId
---@field Goods XTheatre5Goods[]
---@field UnlockGridsNum
---@field RefreshCnt

--- 商品
---@class XTheatre5Goods
---@field ItemInfo XTheatre5Item
---@field IsSpecialPrice
---@field IsSoldOut
---@field IsFreeze

--- 物品
---@class XTheatre5Item
---@field InstanceId
---@field ItemId
---@field ItemType

--- 背包
---@class XTheatre5BagData
---@field BagItemDict table<number, XTheatre5Item>
---@field SkillDict table<number, XTheatre5Item>
---@field RuneDict table<number, XTheatre5Item>
---@field BagGridsNum
---@field SkillGridsNum
---@field RuneGridsNum
---@field RoundNumWithoutGridUnlock

--- 技能三选一
---@class Theatre5SkillChoiceData
---@field SkillGroups XTheatre5Goods[]

--endregion

--- 局内数据基类
---@class XTheatre5AdventureDataBase
---@field Version number
---@field CharacterId number
---@field Status number
---@field RoundNum number
---@field GoldNum number
---@field Health number
---@field IdSequence number
---@field ShopData XTheatre5ShopData
---@field BagData XTheatre5BagData
---@field SkillChoiceData Theatre5SkillChoiceData
---@field CheckFailTimes number
local XTheatre5AdventureDataBase = XClass(nil, 'XTheatre5AdventureDataBase')

--region 基础信息

--- 更新金币数（局内）
function XTheatre5AdventureDataBase:UpdateGoldNum(goldNum)
    if type(goldNum) == 'number' then
        self.GoldNum = goldNum
    end
end

--- 更新生命值（局内）
function XTheatre5AdventureDataBase:UpdateHealth(health)
    self.Health = health
end

function XTheatre5AdventureDataBase:UpdateRoundNum(roundNum)
    self.RoundNum = roundNum
end

--- 更新游玩状态
function XTheatre5AdventureDataBase:UpdateCurPlayStatus(status)
    if status then
        self.Status = status
    end
end

--- 更新校验失败次数
function XTheatre5AdventureDataBase:UpdateCheckFailTimes(failTimes)
    self.CheckFailTimes = failTimes
end

function XTheatre5AdventureDataBase:GetGoldNum()
    return self.GoldNum or 0
end

function XTheatre5AdventureDataBase:GetHealth()
    return self.Health or 0
end

function XTheatre5AdventureDataBase:GetCharacterId()
    return self.CharacterId
end

function XTheatre5AdventureDataBase:GetRoundNum()
    return self.RoundNum or 0
end

function XTheatre5AdventureDataBase:GetCurPlayStatus()
    return self.Status
end

--- 校验失败次数
function XTheatre5AdventureDataBase:GetCheckFailTimes()
    return self.CheckFailTimes or 0
end

--endregion

--region 背包信息

--- 背包数据全量更新（局内）
function XTheatre5AdventureDataBase:UpdateFullBagData(bagData)
    if XMain.IsEditorDebug then
        if self.BagData then
            self.BagData.IsObsolete = true

            if not XTool.IsTableEmpty(self.BagData.BagItemDict) then
                for i, v in pairs(self.BagData.BagItemDict) do
                    v.IsObsolete = true
                end
            end

            if not XTool.IsTableEmpty(self.BagData.SkillDict) then
                for i, v in pairs(self.BagData.SkillDict) do
                    v.IsObsolete = true
                end
            end

            if not XTool.IsTableEmpty(self.BagData.RuneDict) then
                for i, v in pairs(self.BagData.RuneDict) do
                    v.IsObsolete = true
                end
            end
        end
    end

    self.BagData = bagData
    self.HasData = true
    
    self:SetNeedUpdateAdds()
end

function XTheatre5AdventureDataBase:GetBagSkillGridsNum()
    return self.BagData and self.BagData.SkillGridsNum or 0
end

function XTheatre5AdventureDataBase:GetBagRuneGridsNum()
    return self.BagData and self.BagData.RuneGridsNum or 0
end

--不装备的格子数量
function XTheatre5AdventureDataBase:GetBagGridsNum()
    return self.BagData and self.BagData.BagGridsNum or 0
end

function XTheatre5AdventureDataBase:GetTempBagGrids()
    return self.BagData and self.BagData.TempItemDict
end

function XTheatre5AdventureDataBase:HasTempBagGrid()
    if self.BagData and not XTool.IsTableEmpty(self.BagData.TempItemDict) then
        return true
    end
    return false    
end

--- 获取背包栏指定位置的物品数据
function XTheatre5AdventureDataBase:GetItemInBagByIndex(index)
    if self.BagData and self.BagData.BagItemDict then
        return self.BagData.BagItemDict[index]
    end
end

--- 获取临时背包栏指定位置的物品数据
function XTheatre5AdventureDataBase:GetItemInTempBagByIndex(index)
    if self.BagData and self.BagData.TempItemDict then
        return self.BagData.TempItemDict[index]
    end
end

--获得一个背包的空位索引
function XTheatre5AdventureDataBase:GetEmptyBagIndex()
    local totalCount = self:GetBagGridsNum()
    if not XTool.IsNumberValid(totalCount) then
        return
    end
    if not self.BagData or XTool.IsTableEmpty(self.BagData.BagItemDict) then
        return
    end
    for i = 1, totalCount do
        if not self.BagData.BagItemDict[i] then
            return i
        end    
    end 
end

--- 判断背包是否有空位
function XTheatre5AdventureDataBase:CheckHasEmptyBagSlot()
    local index = self:GetEmptyBagIndex()
    
    return XTool.IsNumberValid(index)
end

--获得一个技能的空位索引
function XTheatre5AdventureDataBase:GetEmptyBagSkillIndex()
    local totalCount = self:GetBagSkillGridsNum()
    if not XTool.IsNumberValid(totalCount) then
        return
    end
    if not self.BagData or XTool.IsTableEmpty(self.BagData.SkillDict) then
        return 1
    end
    local hasCount = XTool.GetTableCount(self.BagData.SkillDict)
    if totalCount == hasCount then
        return
    end    
    for i = 1, totalCount do
        if not self.BagData.SkillDict[i] then
            return i
        end    
    end 
end

--- 判断技能栏是否有空位
function XTheatre5AdventureDataBase:CheckHasEmptySkillSlot()
    local index = self:GetEmptyBagSkillIndex()
    
    return XTool.IsNumberValid(index)
end

--获得一个装备(宝珠)的空位索引
function XTheatre5AdventureDataBase:GetEmptyBagRuneIndex()
    local totalCount = self:GetBagRuneGridsNum()
    if not XTool.IsNumberValid(totalCount) then
        return
    end
    if not self.BagData or XTool.IsTableEmpty(self.BagData.RuneDict) then
        return 1
    end
    local hasCount = XTool.GetTableCount(self.BagData.RuneDict)
    if totalCount == hasCount then
        return
    end    
    for i = 1, totalCount do
        if not self.BagData.RuneDict[i] then
            return i
        end    
    end 
end

function XTheatre5AdventureDataBase:GetRuneDict()
    if self.BagData then
        return self.BagData.RuneDict
    end
end

--- 判断装备栏是否有空位
function XTheatre5AdventureDataBase:CheckHasEmptyRuneSlot()
    local index = self:GetEmptyBagRuneIndex()

    return XTool.IsNumberValid(index)
end

--- 获取技能栏指定位置的物品数据
function XTheatre5AdventureDataBase:GetItemInSkillListByIndex(index)
    if self.BagData and self.BagData.SkillDict then
        return self.BagData.SkillDict[index]
    end
end

--- 获取玩家自身的技能Id列表
function XTheatre5AdventureDataBase:GetSkillIdsInSkillList()
    -- 转换成有序列表
    local skillIds = {}

    for i = 1, self.BagData.SkillGridsNum do

        local skillData = self:GetItemInSkillListByIndex(i)

        if skillData then
            table.insert(skillIds, skillData.ItemId)
        end
    end

    return skillIds
end

--- 获取宝珠栏指定位置的物品数据
function XTheatre5AdventureDataBase:GetItemInRuneListByIndex(index)
    if self.BagData and self.BagData.RuneDict then
        return self.BagData.RuneDict[index]
    end
end

--- 获取宝珠栏宝珠Id的列表（合并同类宝珠）
function XTheatre5AdventureDataBase:GetRuneIdsInSkillList(ignoreSame)
    -- 转换成有序列表
    local runeIds = {}

    for i = 1, self.BagData.RuneGridsNum do
        local runeData = self:GetItemInRuneListByIndex(i)

        if runeData then
            if ignoreSame then
                table.insert(runeIds, runeData.ItemId)
            else
                if not runeIds[runeData.ItemId] then
                    runeIds[runeData.ItemId] = i
                end
            end
        end
    end

    return runeIds
end

--- 判断玩家是否穿戴宝珠
function XTheatre5AdventureDataBase:CheckHasEquipGem()
    return not XTool.IsTableEmpty(self.BagData.RuneDict)
end


--- 判断玩家是否穿戴技能
function XTheatre5AdventureDataBase:CheckHasEquipSkill()
    return not XTool.IsTableEmpty(self.BagData.SkillDict)
end


--- 检查背包指定容器是否已经有物品
function XTheatre5AdventureDataBase:CheckHasItemByContainerTypeAndIndex(containerType, index)
    if containerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.BagBlock then
        return self:GetItemInBagByIndex(index) and true or false
    elseif containerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.EquipBlock then
        return self:GetItemInRuneListByIndex(index) and true or false
    elseif containerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillBlock then
        return self:GetItemInSkillListByIndex(index) and true or false
    elseif containerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock then
        return self:GetItemInTempBagByIndex(index) and true or false
    else
        return false
    end    
end

--检查是否有装备或技能
function XTheatre5AdventureDataBase:CheckHasEquipOrSkill(itemType, itemId)
    if not self.BagData then
        return false
    end
    local has = self:_CheckHasEquipOrSkillByContainer(self.BagData.BagItemDict, itemType, itemId)    
    if has then
        return true
    end
    has = self:_CheckHasEquipOrSkillByContainer(self.BagData.RuneDict, itemType, itemId)    
    if has then
        return true
    end
    has = self:_CheckHasEquipOrSkillByContainer(self.BagData.SkillDict, itemType, itemId)    
    if has then
        return true
    end
    has = self:_CheckHasEquipOrSkillByContainer(self.BagData.TempItemDict, itemType, itemId)    
    if has then
        return true
    end
    return false    
end

function XTheatre5AdventureDataBase:_CheckHasEquipOrSkillByContainer(container, itemType, itemId)
    if XTool.IsTableEmpty(container) then
       return false
    end
    for k, theatre5Item in pairs(container) do
        if theatre5Item.ItemType == itemType and theatre5Item.ItemId == itemId then
            return true
        end    
    end
    return false
end

--- 获取背包栏已有物品数
function XTheatre5AdventureDataBase:GetBagListItemCount()
    return XTool.GetTableCount(self.BagData.BagItemDict)
end

--- 获取未进行背包格子解锁的回合数
function XTheatre5AdventureDataBase:GetRoundNumWithoutGridUnlock()
    return self.BagData and self.BagData.RoundNumWithoutGridUnlock or 0
end

--- 获取当前背包格子解锁费用扣除量(派生类重写）
function XTheatre5AdventureDataBase:GetCurRoundGridUnlockCostReduce()
    return 0
end

--装备初始格子数
function XTheatre5AdventureDataBase:GetRuneGridInitCount()
    return 0
end
--endregion

--region 商店信息

--- 商店数据全量更新（局内）
function XTheatre5AdventureDataBase:UpdateFullShopData(shopData)
    if XMain.IsEditorDebug then
        if self.ShopData then
            self.ShopData.IsObsolete = true

            if not XTool.IsTableEmpty(self.ShopData.Goods) then
                for i, v in pairs(self.ShopData.Goods) do
                    v.IsObsolete = true
                    v.ItemInfo.IsObsolete = true
                end
            end
        end
    end

    self.ShopData = shopData
    self.HasData = true
end

function XTheatre5AdventureDataBase:GetShopId()
    return self.ShopData and self.ShopData.ShopId or 0
end

function XTheatre5AdventureDataBase:GetShopUnlockGridsNum()
    return self.ShopData and self.ShopData.UnlockGridsNum or 0
end

function XTheatre5AdventureDataBase:GetShopRefreshTimes()
    return self.ShopData and self.ShopData.RefreshCnt or 0
end

function XTheatre5AdventureDataBase:GetShopGoods()
    return self.ShopData and self.ShopData.Goods or nil
end

function XTheatre5AdventureDataBase:GetShopGoodsByIndex(index)
    if self.ShopData and self.ShopData.Goods then
        return self.ShopData.Goods[index]
    end
end

function XTheatre5AdventureDataBase:GetShopGoodsByItemInstanceId(instanceId)
    if self.ShopData and self.ShopData.Goods then
        for i, v in pairs(self.ShopData.Goods) do
            if v.ItemInfo.InstanceId == instanceId then
                return v
            end
        end
    end
end

--- 判断是否所有商品都冻结
function XTheatre5AdventureDataBase:CheckAllGoodsIsFreeze()
    if not XTool.IsTableEmpty(self.ShopData.Goods) then
        local anyGoodsNoSoldOut = false;
        
        for i, v in pairs(self.ShopData.Goods) do
            if not v.IsSoldOut then
                anyGoodsNoSoldOut = true

                if not v.IsFreeze then
                    return false
                end
            end
        end

        if anyGoodsNoSoldOut then
            return true
        else
            return false
        end
    else
        return false
    end
end

--- 判断是否有空的商品格
function XTheatre5AdventureDataBase:CheckHasAnyGoodsIsSellOut()
    if not XTool.IsTableEmpty(self.ShopData.Goods) then
        for i, v in pairs(self.ShopData.Goods) do
            if  v.IsSoldOut then
                return true
            end
        end

        return false
    else
        return true
    end
end

--- 判断是否所有商品都卖出
function XTheatre5AdventureDataBase:CheckAllGoodsAreSellOut()
    if not XTool.IsTableEmpty(self.ShopData.Goods) then
        for i, v in pairs(self.ShopData.Goods) do
            if not v.IsSoldOut then
                return false
            end
        end

        return true
    else
        return true
    end
end
--endregion

--region 技能三选一

--- 技能三选一数据全量更新
function XTheatre5AdventureDataBase:UpdateFullSkillChoiceData(skillChoiceData)
    if XMain.IsEditorDebug then
        if self.SkillChoiceData then
            self.SkillChoiceData.IsObsolete = true

            if not XTool.IsTableEmpty(self.SkillChoiceData.SkillGroups) then
                for i, v in pairs(self.SkillChoiceData.SkillGroups) do
                    v.IsObsolete = true
                end
            end
        end
    end

    self.SkillChoiceData = skillChoiceData
    self.HasData = true
end

function XTheatre5AdventureDataBase:GetSkillChoiceSkillGroup()
    return self.SkillChoiceData and self.SkillChoiceData.SkillGroups or nil
end

--endregion

--region 角色属性加成
function XTheatre5AdventureDataBase:UpdateCharacterStatusAdds(addsMap)
    self._AttrAddsMap = addsMap
    self._AttrAddsNeedUpdate = false
end

function XTheatre5AdventureDataBase:GetAttrAddsByAttrType(attrType)
    if not XTool.IsTableEmpty(self._AttrAddsMap) then
        return self._AttrAddsMap[attrType] or 0
    end
    return 0
end

function XTheatre5AdventureDataBase:SetNeedUpdateAdds()
    self._AttrAddsNeedUpdate = true
end

function XTheatre5AdventureDataBase:GetIsNeedUpdateAdds()
    return self._AttrAddsNeedUpdate
end

--endregion

--region 敌人数据

function XTheatre5AdventureDataBase:GetEnemySkillIds()

end

--- 获取敌人宝珠栏宝珠Id的列表（合并同类宝珠）
function XTheatre5AdventureDataBase:GetEnemyRuneIds()

end

function XTheatre5AdventureDataBase:GetEnemyCharacterId()

end

--endregion

function XTheatre5AdventureDataBase:ClearData()
    self.HasData = false
    self.ShopData = nil
    self.BagData = nil
    self.SkillChoiceData = nil
end

return XTheatre5AdventureDataBase