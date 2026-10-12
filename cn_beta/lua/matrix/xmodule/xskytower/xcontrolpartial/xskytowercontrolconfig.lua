---Control部分类，此处用于注册和处理与配置表直接关联的读取接口
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

function XSkyTowerControl:ReleaseConfig()
    self._FloorGroupProductListDict = nil
    self._SkillAdditionListDict = nil
    self._SkillShareOffsetListDict = nil
    self._SkillConditionOffsetListDict = nil
end

--region SkyTowerClientConfig表（客户端参数，键值表）
--- 获取配置在ClientConfig里的文本
function XSkyTowerControl:GetClientConfigText(key, index, ...)
    local words = self:GetClientConfigValue(key, index)
    return string.format(words, ...)
end

function XSkyTowerControl:GetClientConfigValues(key)
    return self._Model:GetClientConfigValues(key)
end

function XSkyTowerControl:GetClientConfigValue(key, index)
    return self._Model:GetClientConfigValue(key, index)
end

function XSkyTowerControl:GetIntClientConfigValue(key, index)
    return self._Model:GetIntClientConfigValue(key, index)
end

function XSkyTowerControl:GetCommonQualityIcon(is3d)
    return self._Model:GetCommonQualityIcon(is3d)
end

function XSkyTowerControl:Get3DGridOffset(index)
    local value = self._Model:GetClientConfigValue("Ui3DOffset", index)
    if string.IsNilOrEmpty(value) then
        return Vector3.zero
    end
    return XMVCA.XSkyTower:StrPos2Vector3(value)
end

function XSkyTowerControl:GetSkyTowerNotInBusinessText()
    return self._Model:GetClientConfigValue("SkyTowerNotInBusiness", 1)
end

function XSkyTowerControl:GetCommonUnlockText(index)
    return self._Model:GetClientConfigValue("CommonUnlockText", index)
end

---舞台加成已移除，角色技能与光环加成统一显示单箭头
---@param bonusCount number 生效中的增益个数
---@return string 图标路径，无增益返回空串
function XSkyTowerControl:GetMenuBonusIcon(bonusCount)
    if not XTool.IsNumberValid(bonusCount) then
        return ""
    end
    return self._Model:GetClientConfigValue("MenuBonus", 1)
end

function XSkyTowerControl:GetUpOrDownArrowIcon(index)
    return self._Model:GetClientConfigValue("RImgUpgradeIcon", index)
end

function XSkyTowerControl:GetSkillAdditionUnit(workType)
    local index = self:IsSaleArea(workType) and 2 or 1
    return self._Model:GetClientConfigValue("ProduceTimeUnit", index)
end

function XSkyTowerControl:GetWorkPauseReason(index)
    return self._Model:GetClientConfigValue("WorkPauseReason", index)
end

function XSkyTowerControl:GetProduceDesc(index)
    return self._Model:GetClientConfigValue("ProduceDesc", index)
end

--- 制作台的材料清单标题
function XSkyTowerControl:GetProductionNeedText(productName)
    return self:GetClientConfigText("ProductionNeedText", 1, productName)
end

--- 页签选中产品的速率文本
---@param workType number
---@param productId number
---@return string
function XSkyTowerControl:GetProductSpeedText(workType, productId)
    if self:IsSaleArea(workType) then
        return self:GetClientConfigText("SaleSpeedText", 1, self:GetFoodSaleNeedTime(productId))
    end
    if self:IsIngredientArea(workType) then
        return self:GetClientConfigText("ProductSpeedText", 1, self:GetIngredientProduceNeedTime(productId))
    end
    return self:GetClientConfigText("ProductSpeedText", 1, self:GetFoodProduceNeedTime(productId))
end

function XSkyTowerControl:GetTaskDescText(index)
    return self._Model:GetClientConfigValue("TaskDescText", index)
end

function XSkyTowerControl:GetStatisticsUnit(index)
    return self._Model:GetClientConfigValue("StatisticsUnit", index)
end

function XSkyTowerControl:GetStatisticsTip(workType, index)
    local key = self:IsIngredientArea(workType) and "IngredientStatisticsTip" or "FoodStatisticsTip"
    return self._Model:GetClientConfigValue(key, index)
end

function XSkyTowerControl:GetStaffStateBtnText(index)
    return self._Model:GetClientConfigValue("StaffStateBtnText", index)
end

function XSkyTowerControl:GetSkyTowerLvUpConditionText(index)
    return self._Model:GetClientConfigValue("SkyTowerLvUpConditionText", index)
end

---长按升级的激活时间（毫秒），即按下多久开始连续升级
---@return number
function XSkyTowerControl:GetLevelUpLongPressDelay()
    local value = self._Model:GetIntClientConfigValue("FloorLevelUpLongPress", 1)
    return value > 0 and value or XScheduleManager.SECOND
end

---长按升级的速度（每秒升级次数）
---@return number
function XSkyTowerControl:GetLevelUpLongPressSpeed()
    local value = self._Model:GetIntClientConfigValue("FloorLevelUpLongPress", 2)
    return value > 0 and value or 1
end

function XSkyTowerControl:GetShopBuyLimitColor(index)
    return self._Model:GetClientConfigValue("ShopBuyLimitColor", index)
end

function XSkyTowerControl:GetShopBuyTxtColor(index)
    return self._Model:GetClientConfigValue("ShopBuyTxtColor", index)
end

function XSkyTowerControl:GetShopRewardId()
    local value = self._Model:GetClientConfigValue("ShopRewardId", 1)
    if string.IsNilOrEmpty(value) then
        return 0
    end
    return tonumber(value)
end

function XSkyTowerControl:GetSkyTowerInfoText(index)
    return self._Model:GetClientConfigValue("SkyTowerInfo", index)
end

function XSkyTowerControl:GetBubbleProperty()
    return tonumber(self._Model:GetClientConfigValue("BubbleProperty", 1))
end

function XSkyTowerControl:GetShopTimeTxt(timeStr)
    return string.format(self._Model:GetClientConfigValue("ShopTimeTxt", 1), timeStr)
end

--- 演出类型标题
function XSkyTowerControl:GetPerformTypeTitle(performId)
    return self._Model:GetClientConfigValue("PerformTypeTitle", self:GetPerformType(performId))
end

--- 演出类型标题图标
function XSkyTowerControl:GetPerformTypeTitleIcon(performId)
    --key拼写Iocn为配置表既有拼写，保持一致
    return self._Model:GetClientConfigValue("PerformTypeTitleIocn", self:GetPerformType(performId))
end

---离线时长文案
function XSkyTowerControl:GetSubTimeTip(subTime)
    return string.format(self._Model:GetClientConfigValue("OfflineBillText", 1), XUiHelper.GetTime(subTime, XUiHelper.TimeFormatType.TO_A_MINUTE))
end

--- 员工等级文本
---@param level number
---@return string
function XSkyTowerControl:GetWorkRoleLevelText(level)
    return self:GetClientConfigText("WorkRoleLevelDesc", 2, level)
end

--- 员工名带等级
---@param level number
---@return string
function XSkyTowerControl:GetWorkRoleNameLevelText(name, level)
    return self:GetClientConfigText("WorkRoleLevelDesc", 1, name, level)
end

function XSkyTowerControl:GetStorageCountText(index)
    return self._Model:GetStorageCountText(index)
end
--endregion

--region SkyTowerActivity表（活动时间与任务）
function XSkyTowerControl:GetActivityEndTime()
    return self._Model:GetActivityEndTime()
end

function XSkyTowerControl:GetActivityTimeLimitTaskIds()
    return self._Model:GetActivityTimeLimitTaskIds()
end
--endregion

--region SkyTowerConfig表（活动配置，键值表）
function XSkyTowerControl:GetIntConfigValue(key, index)
    return self._Model:GetIntConfigValue(key, index)
end

--- 加速道具使用限制
function XSkyTowerControl:GetConfigAccelerateUseLimit()
    return self._Model:GetConfigAccelerateUseLimit()
end

--- 物品急需时间
function XSkyTowerControl:GetConfigUrgentTime()
    return self:GetIntConfigValue("UrgentTime")
end
--endregion

--region SkyTowerLv表（通天塔等级）
function XSkyTowerControl:GetLvPerformIds(level)
    local template = self._Model:GetLvConfig(level)
    return template and template.PerformIds or table.empty
end

function XSkyTowerControl:GetLvUpgradeConsume(level)
    return self._Model:GetLvUpgradeConsume(level)
end

function XSkyTowerControl:GetLvConfig(level)
    return self._Model:GetLvConfig(level)
end

function XSkyTowerControl:GetLvNeedGoldCount(level)
    local template = self._Model:GetLvConfig(level)
    return template and template.NeedGoldCount or 0
end

function XSkyTowerControl:GetLvUnlockIngredient(level)
    return self._Model:GetLvUnlockIngredient(level)
end

function XSkyTowerControl:GetLvUnlockFood(level)
    return self._Model:GetLvUnlockFood(level)
end

function XSkyTowerControl:GetLvUnlockCharacter(level)
    local template = self._Model:GetLvConfig(level)
    return template and template.UnlockCharacter or table.empty
end

function XSkyTowerControl:GetLvUnlockWorkNum(level)
    local template = self._Model:GetLvConfig(level)
    return template and template.UnlockWorkNum or 0
end

function XSkyTowerControl:GetLvOfflineBillAdd(level)
    local template = self._Model:GetLvConfig(level)
    return template and template.OfflineBillAdd or 0
end

function XSkyTowerControl:GetLvConditionId(level)
    local template = self._Model:GetLvConfig(level)
    return template and template.ConditionId or 0
end

--- 该等级对应的楼层Id
function XSkyTowerControl:GetLvFloorId(level)
    local config = self._Model:GetLvConfig(level)
    return config and config.FloorId or 0
end
--endregion

--region SkyTowerCharacter表（员工角色）
function XSkyTowerControl:GetAllCharacterIds()
    return self._Model:GetAllCharacterIds()
end

function XSkyTowerControl:GetCharacterConfig(characterId)
    return self._Model:GetCharacterConfig(characterId)
end

function XSkyTowerControl:GetCharacterName(characterId)
    local config = self._Model:GetCharacterConfig(characterId)
    return config and config.Name or ""
end

--- 小队名称
function XSkyTowerControl:GetCharacterIntro(characterId)
    local config = self._Model:GetCharacterConfig(characterId)
    return config and config.Intro or ""
end

--- 员工排序优先级
function XSkyTowerControl:GetCharacterPriority(characterId)
    local config = self._Model:GetCharacterConfig(characterId)
    return config and config.Priority or 0
end

function XSkyTowerControl:GetCharacterFloorGroup(charId)
    local config = self._Model:GetCharacterConfig(charId)
    return config and config.FloorGroup or 0
end

function XSkyTowerControl:GetCharacterIsUniversal(charId)
    local config = self._Model:GetCharacterConfig(charId)
    return config and config.IsUniversal or false
end

function XSkyTowerControl:GetCharacterPortrait(charId)
    local config = self._Model:GetCharacterConfig(charId)
    return config and config.Portrait or ""
end

function XSkyTowerControl:GetCharacterSkillTypes(characterId)
    local config = self._Model:GetCharacterConfig(characterId)
    return config and config.SkillTypes or table.empty
end

function XSkyTowerControl:GetCharacterWorkType(characterId)
    local floorGroupId = self:GetCharacterFloorGroup(characterId)
    for _, floorId in ipairs(self:GetFloorIdsByGroupId(floorGroupId)) do
        for index = 1, self:GetFloorWorkNum(floorId) do
            local info = self._Model:GetFloorWorkPosInfo(floorId, index)
            if info and info.CharacterId == characterId then
                return info.WorkType
            end
        end
    end
    return nil
end

--endregion

--region SkyTowerCharacterModel表（员工模型）
--endregion

--region SkyTowerCharacterLv表（员工等级）
function XSkyTowerControl:GetCharacterLvSkillIds(characterId, level)
    local config = self._Model:GetCharacterLvConfig(characterId, level)
    return config and config.SkillId or table.empty
end

function XSkyTowerControl:GetCharacterLvNeedItemCount(characterId, level)
    local config = self._Model:GetCharacterLvConfig(characterId, level)
    return config and config.NeedItemCount or 0
end

function XSkyTowerControl:GetCharacterLvConditionId(characterId, level)
    local config = self._Model:GetCharacterLvConfig(characterId, level)
    return config and config.Condition or 0
end

--- 角色最大等级
function XSkyTowerControl:GetCharacterLvMaxLevel(characterId)
    if self:GetCharacterIsUniversal(characterId) then
        return XMVCA.XSkyTower.StaffLevelMin
    end
    return self._Model:GetCharacterLvMaxLevel(characterId)
end
--endregion

--region SkyTowerCharacterSkill表（员工技能）
function XSkyTowerControl:GetCharacterSkillName(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    return config and config.Name or ""
end

function XSkyTowerControl:GetCharacterSkillIcon(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    return config and config.Icon or ""
end

function XSkyTowerControl:GetCharacterSkillDesc(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    local desc = config and config.Desc or ""
    local descParms = self:GetCharacterSkillDescParms(skillId)
    if not XTool.IsTableEmpty(descParms) then
        desc = XUiHelper.FormatText(desc, table.unpack(descParms))
    end
    return desc
end

function XSkyTowerControl:GetCharacterSkillDescParms(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    return config and config.DescParms or table.empty
end

function XSkyTowerControl:GetCharacterSkillSectionType(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    return config and config.SectionType or 0
end

function XSkyTowerControl:GetCharacterSkillProductIds(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    return config and config.ProductId or table.empty
end

function XSkyTowerControl:GetCharacterSkillAdditions(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    return config and config.SkillAddition or table.empty
end

function XSkyTowerControl:GetCharacterSkillAdditionTypes(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    return config and config.SkillAdditionType or table.empty
end

function XSkyTowerControl:GetCharacterSkillShareType(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    return config and config.ShareType or table.empty
end

function XSkyTowerControl:GetCharacterSkillConditionType(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    return config and config.ConditionType or 0
end

function XSkyTowerControl:GetCharacterSkillConditionParams(skillId)
    local config = self._Model:GetCharacterSkillConfig(skillId)
    return config and config.ConditionParams or table.empty
end

--- ConditionParams的第index项按数值取
---@param index number 从1开始
function XSkyTowerControl:GetCharacterSkillConditionParam(skillId, index)
    local params = self:GetCharacterSkillConditionParams(skillId)
    local number = tonumber(params[index])
    local value = number and math.tointeger(number)
    return value or XMVCA.XSkyTower.UnlimitedConditionParam
end

--- SkillConditionType.NearbyCharacter的相对坐标偏移列表
--- ConditionParams[1]是需要的角色Id，[2]起每一项都是形如"x_y"的整串坐标（不是两列数字）
---@param skillId number
---@return { OffsetX:number, OffsetY:number }[] 未配坐标时返回空表
function XSkyTowerControl:GetCharacterSkillConditionOffsetList(skillId)
    self._SkillConditionOffsetListDict = self._SkillConditionOffsetListDict or {}
    local cache = self._SkillConditionOffsetListDict[skillId]
    if cache then
        return cache
    end

    local list = {}
    local params = self:GetCharacterSkillConditionParams(skillId)
    for i = 2, #params do
        if not string.IsNilOrEmpty(params[i]) then
            self:_ParseShareTypeOffsets(skillId, params[i], list, "ConditionParams")
        end
    end
    self._SkillConditionOffsetListDict[skillId] = list
    return list
end

--- 技能的加成产品列表,三列长度不齐时截到最短
---@return { Id:number, Addition:number, WorkType:number, AdditionType:number }[]
function XSkyTowerControl:GetCharacterSkillAdditionList(skillId)
    self._SkillAdditionListDict = self._SkillAdditionListDict or {}
    local list = self._SkillAdditionListDict[skillId]
    if list then
        return list
    end

    list = {}
    local productIds = self:GetCharacterSkillProductIds(skillId)
    local additions = self:GetCharacterSkillAdditions(skillId)
    local additionTypes = self:GetCharacterSkillAdditionTypes(skillId)
    local workType = self:GetCharacterSkillSectionType(skillId)
    local count = math.min(#productIds, #additions, #additionTypes)
    if count < #productIds then
        XLog.Error(string.format("角色技能表Id=%s的ProductId与SkillAddition/SkillAdditionType长度不一致，只取前%s项", skillId, count))
    end
    for i = 1, count do
        list[i] = { Id = productIds[i], Addition = additions[i], WorkType = workType, AdditionType = additionTypes[i] }
    end
    self._SkillAdditionListDict[skillId] = list
    return list
end

--- 坐标分量取值：须为整数，负数合法
---@return number 非整数时返回nil
function XSkyTowerControl:_ToOffsetValue(part)
    local number = tonumber(part)
    return number and math.tointeger(number)
end

--- 解析单个ShareType元素为一对坐标并追加到list，逐元素独立解析：某元素配错时只丢这一格
---@param skillId number 仅用于报错定位
---@param str string 单个坐标配置串
---@param list { OffsetX:number, OffsetY:number }[] 输出列表
---@param columnName string 报错时显示的列名，不传按ShareType
function XSkyTowerControl:_ParseShareTypeOffsets(skillId, str, list, columnName)
    columnName = columnName or "ShareType"
    local separator = XMVCA.XSkyTower.ShareTypeSeparator
    local sepIndex = string.find(str, separator, 1, true)
    local offsetX = sepIndex and self:_ToOffsetValue(string.sub(str, 1, sepIndex - 1))
    local offsetY = sepIndex and self:_ToOffsetValue(string.sub(str, sepIndex + #separator))
    -- 一格只认一对坐标
    if not offsetX or not offsetY then
        XLog.Error(string.format("角色技能表Id=%s的%s须配成\"x%sy\"两个整数，实际为：%s", tostring(skillId), columnName, separator, tostring(str)))
        return
    end
    table.insert(list, { OffsetX = offsetX, OffsetY = offsetY })
end

--- 技能生效范围的坐标偏移列表（ShareType按"x_y"配相对偏移，x为工位横坐标差、y为楼层差）
--- 坐标须配整数，负数合法（表示反方向偏移，如"-1_0"为左侧一格）
---@param skillId number
---@return { OffsetX:number, OffsetY:number }[] 未配置时返回空表（调用方按"只对自身生效"处理）
function XSkyTowerControl:GetCharacterSkillShareOffsetList(skillId)
    self._SkillShareOffsetListDict = self._SkillShareOffsetListDict or {}
    local cache = self._SkillShareOffsetListDict[skillId]
    if cache then
        return cache
    end

    local list = {}
    local hasConfig = false
    for _, str in ipairs(self:GetCharacterSkillShareType(skillId)) do
        if not string.IsNilOrEmpty(str) then
            hasConfig = true
            self:_ParseShareTypeOffsets(skillId, str, list)
        end
    end
    -- 配了内容却解析不出任何坐标，静默退化成"只对自身生效"难以排查，故报错
    if hasConfig and XTool.IsTableEmpty(list) then
        XLog.Error(string.format("角色技能表Id=%s的ShareType解析不出任何坐标，坐标分隔符只支持\"%s\"", tostring(skillId), XMVCA.XSkyTower.ShareTypeSeparator))
    end
    self._SkillShareOffsetListDict[skillId] = list
    return list
end

--- 技能是否为光环型（生效范围含非自身工位，对应"光环"标签）
---@param skillId number
---@return boolean
function XSkyTowerControl:IsCharacterSkillAura(skillId)
    local offsetEnum = XMVCA.XSkyTower.ShareOffset
    for _, offset in ipairs(self:GetCharacterSkillShareOffsetList(skillId)) do
        if offset.OffsetX ~= offsetEnum.SelfX or offset.OffsetY ~= offsetEnum.SelfY then
            return true
        end
    end
    return false
end

--- 技能是否为愿望型（配了触发条件，对应"愿望"标签）
---@param skillId number
---@return boolean
function XSkyTowerControl:IsCharacterSkillWish(skillId)
    return XTool.IsNumberValid(self:GetCharacterSkillConditionType(skillId))
end
--endregion

--region SkyTowerSkillType表（技能类型）
function XSkyTowerControl:GetSkillTypeName(type)
    local config = self._Model:GetSkillTypeConfig(type)
    return config and config.Name or ""
end

function XSkyTowerControl:GetSkillTypeSmallIcon(type)
    local config = self._Model:GetSkillTypeConfig(type)
    return config and config.SmallIcon or ""
end
--endregion

--region SkyTowerIngredient表（食材）
function XSkyTowerControl:GetAllIngredientIds()
    return self._Model:GetAllIngredientIds()
end

function XSkyTowerControl:GetIngredientBaseProduceSpeed(productId)
    return self._Model:GetIngredientBaseProduceSpeed(productId)
end

function XSkyTowerControl:GetIngredientConfig(productId)
    return self._Model:GetIngredientConfig(productId)
end

function XSkyTowerControl:GetIngredientIcon(productId)
    return self._Model:GetIngredientIcon(productId)
end

function XSkyTowerControl:GetIngredientName(productId)
    return self._Model:GetIngredientName(productId)
end

function XSkyTowerControl:GetIngredientProduceNeedTime(productId)
    local template = self._Model:GetIngredientConfig(productId)
    return template and template.ProduceNeedTime or 0
end

function XSkyTowerControl:GetIngredientPriority(productId)
    local template = self._Model:GetIngredientConfig(productId)
    return template and template.Priority or 0
end

--endregion

--region SkyTowerFood表（食物）
function XSkyTowerControl:GetAllFoodIds()
    return self._Model:GetAllFoodIds()
end

---食物配方中的食材部分（懒缓存）
---@return table[] {Id, Count, WorkType, ProductType}
function XSkyTowerControl:GetFoodIngredients(foodId)
    self._FoodIngredientsDict = self._FoodIngredientsDict or {}
    local ingredients = self._FoodIngredientsDict[foodId]
    if not ingredients then
        ingredients = {}
        local template = self._Model:GetFoodConfig(foodId)
        if template then
            for i, ingredientId in ipairs(template.ConsumeIngredientIds) do
                table.insert(ingredients, {
                    Id = ingredientId,
                    Count = template.ConsumeIngredientCounts[i],
                    WorkType = XMVCA.XSkyTower.WorkType.Ingredient,
                    ProductType = XMVCA.XSkyTower.ProductType.Ingredient,
                })
            end
        end
        self._FoodIngredientsDict[foodId] = ingredients
    end
    return ingredients
end

---食物完整配方：食材 + 手作（组合道具），食材在前（懒缓存）
---@return table[] {Id, Count, WorkType, ProductType}
function XSkyTowerControl:GetFoodConsumes(foodId)
    self._FoodConsumesDict = self._FoodConsumesDict or {}
    local consumes = self._FoodConsumesDict[foodId]
    if consumes then
        return consumes
    end

    consumes = {}
    for _, ingredient in ipairs(self:GetFoodIngredients(foodId)) do
        table.insert(consumes, ingredient)
    end
    local template = self._Model:GetFoodConfig(foodId)
    if template then
        local counts = template.ConsumeFoodCounts
        for i, consumeFoodId in ipairs(template.ConsumeFoodIds) do
            table.insert(consumes, {
                Id = consumeFoodId,
                Count = counts[i] or 0,
                WorkType = XMVCA.XSkyTower.WorkType.Food,
                ProductType = XMVCA.XSkyTower.ProductType.Food,
            })
        end
    end
    self._FoodConsumesDict[foodId] = consumes
    return consumes
end

function XSkyTowerControl:GetFoodBaseProduceSpeed(productId)
    return self._Model:GetFoodBaseProduceSpeed(productId)
end

function XSkyTowerControl:GetFoodBaseSellPrice(productId)
    return self._Model:GetFoodBaseSellPrice(productId)
end

function XSkyTowerControl:GetFoodBaseSellSpeed(productId)
    return self._Model:GetFoodBaseSellSpeed(productId)
end

function XSkyTowerControl:GetFoodConfig(productId)
    return self._Model:GetFoodConfig(productId)
end

function XSkyTowerControl:GetFoodIcon(productId)
    return self._Model:GetFoodIcon(productId)
end

function XSkyTowerControl:GetFoodName(productId)
    local template = self._Model:GetFoodConfig(productId)
    return template and template.Name or ""
end

function XSkyTowerControl:GetFoodProduceNeedTime(productId)
    local template = self._Model:GetFoodConfig(productId)
    return template and template.ProduceNeedTime or 0
end

function XSkyTowerControl:GetFoodSaleNeedTime(productId)
    local template = self._Model:GetFoodConfig(productId)
    return template and template.SaleNeedTime or 0
end

function XSkyTowerControl:GetFoodPriority(productId)
    local template = self._Model:GetFoodConfig(productId)
    return template and template.Priority or 0
end

--endregion

--region 产品通用（SkyTowerIngredient+SkyTowerFood，按区域类型分派）
--- 技能加成展示文案
---@param additionType number 取XMVCA.XSkyTower.SkillAdditionType
---@return string
function XSkyTowerControl:GetSkillAdditionDescText(addition, workType, additionType)
    if additionType == XMVCA.XSkyTower.SkillAdditionType.UpProduce then
        local percent = math.floor(addition * 100 / XMVCA.XSkyTower.TenThousandRate)
        local percentText = string.format(addition > 0 and "+%s%%" or "%s%%", percent)
        local words = self._Model:GetClientConfigValue("SkillAdditionProduceText", workType)
        return string.IsNilOrEmpty(words) and percentText or string.format(words, percentText)
    end
    local index = additionType == XMVCA.XSkyTower.SkillAdditionType.ReduceTime and 1 or 2
    local words = self._Model:GetClientConfigValue("SkillAdditionText", index)
    return string.IsNilOrEmpty(words) and tostring(addition) or string.format(words, addition)
end

---产品排序优先级
function XSkyTowerControl:GetProductPriority(workType, productId)
    local template
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        template = self._Model:GetIngredientConfig(productId)
    else
        template = self._Model:GetFoodConfig(productId)
    end
    return template and template.Priority or 0
end

---产品名字
function XSkyTowerControl:GetProductName(workType, productId)
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        return self:GetIngredientName(productId)
    end
    return self:GetFoodName(productId)
end

---产品图标
function XSkyTowerControl:GetProductIcon(workType, productId)
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        return self._Model:GetIngredientIcon(productId)
    end
    return self._Model:GetFoodIcon(productId)
end

---产品品质（食材无品质，返回0）
function XSkyTowerControl:GetProductQuality(workType, productId)
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        return 0
    end
    return self._Model:GetFoodQuality(productId)
end

---产品品质图标
---@param is3d boolean 是否3D界面
function XSkyTowerControl:GetProductQualityIcon(workType, productId, is3d)
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        return self._Model:GetCommonQualityIcon(is3d)
    end
    return self._Model:GetFoodQualityIcon(self:GetProductQuality(workType, productId), is3d)
end

---产品基础生产速度
function XSkyTowerControl:GetProductSpeed(workType, productId)
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        return self._Model:GetIngredientBaseProduceSpeed(productId)
    end
    return self._Model:GetFoodBaseProduceSpeed(productId)
end

---产品基础售卖速度（食材不可售，返回0）
function XSkyTowerControl:GetProductSellSpeed(workType, productId)
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        return 0
    end
    return self._Model:GetFoodBaseSellSpeed(productId)
end

--endregion

--region SkyTowerStorage表（仓库）
function XSkyTowerControl:GetStorageLimit(workType, skyTowerLv, productId)
    local template = self._Model:GetStorageConfig(workType, skyTowerLv, productId)
    return template and template.StorageLimit or 0
end
--endregion

--region SkyTowerTalk表（聊天对话）
function XSkyTowerControl:GetTalkConfig(talkId)
    return self._Model:GetTalkConfig(talkId)
end

--endregion

--region SkyTowerStory表（聊天剧情）
--- 演出剧情对话Id列表
function XSkyTowerControl:GetTalkStoryTalkIds(performId)
    return self._Model:GetTalkStoryTalkIds(self:GetPerformStoryId(performId))
end

--- 演出剧情对话时长列表
function XSkyTowerControl:GetTalkStoryDurations(performId)
    return self._Model:GetTalkStoryDurations(self:GetPerformStoryId(performId))
end

--endregion

--region SkyTowerWorkPos表（工位）
function XSkyTowerControl:GetWorkModelUrl(floorId, workType)
    local floorGroupId = self:GetFloorGroupIdByFloorId(floorId)
    local cfg = self._Model:GetWorkPosConfig(floorGroupId, workType)
    return cfg and cfg.Model or ""
end
--endregion

--region SkyTowerNpc表（通用角色）
--endregion

--region SkyTowerCustomer表（顾客信息）

--endregion

--region SkyTowerPerform表（演出）
function XSkyTowerControl:GetAllPerformIds()
    if not self._AllPerformIds then
        self._AllPerformIds = self._Model:GetAllPerformIds()
    end
    return self._AllPerformIds
end

function XSkyTowerControl:GetAllIndentIds()
    if not self._AllIndentIds then
        self._AllIndentIds = self._Model:GetAllIndentIds()
    end
    return self._AllIndentIds
end

--- 演出的任务Id列表
---@return number[]
function XSkyTowerControl:GetPerformTaskIds(performId)
    local template = self._Model:GetPerformConfig(performId)
    return template and template.TaskIds or table.empty
end

--- 演出类型（XMVCA.XSkyTower.PerformType）
function XSkyTowerControl:GetPerformType(performId)
    local template = self._Model:GetPerformConfig(performId)
    return template and template.Type or 0
end

--- 演出所在楼层
function XSkyTowerControl:GetFloorId(performId)
    local template = self._Model:GetPerformConfig(performId)
    return template and template.FloorId or 0
end

--- 演出标题
function XSkyTowerControl:GetPerformTitle(performId)
    local template = self._Model:GetPerformConfig(performId)
    return template and template.Name or ""
end

--- 演出标题（带剧情备注）
function XSkyTowerControl:GetPerformTitleWithStory(performId)
    local title = self:GetPerformTitle(performId)
    return string.format("%s：%s", title, self._Model:GetStoryNote(self:GetPerformStoryId(performId)))
end

--- 演出奖励Id
function XSkyTowerControl:GetPerformRewardId(performId)
    local template = self._Model:GetPerformConfig(performId)
    return template and template.RewardId or 0
end

--- 演出描述
function XSkyTowerControl:GetPerformDescription(performId)
    local template = self._Model:GetPerformConfig(performId)
    return XUiHelper.ReplaceTextNewLine(template and template.Desc or "")
end

--- 演出图标
function XSkyTowerControl:GetPerformIcon(performId)
    local template = self._Model:GetPerformConfig(performId)
    return template and template.Icon or ""
end

--- 演出小图标
function XSkyTowerControl:GetPerformSmallIcon(performId)
    local template = self._Model:GetPerformConfig(performId)
    return template and template.SmallIcon or ""
end

--- 演出剧情Id
function XSkyTowerControl:GetPerformStoryId(performId)
    local template = self._Model:GetPerformConfig(performId)
    return template and template.StoryId or 0
end

function XSkyTowerControl:GetPerformConfig(performId)
    return self._Model:GetPerformConfig(performId)
end

--endregion

--region SkyTowerPerformer表（演出者）

--endregion

--region SkyTowerDance表（舞台等级）
---@param level number
---@return XTableSkyTowerDance
function XSkyTowerControl:GetDanceConfig(level)
    return self._Model:GetDanceConfig(level)
end

---目标等级解锁的影响区域数量
---@param level number
---@return number[]
function XSkyTowerControl:GetDanceUnlockArea(level)
    local template = self:GetDanceConfig(level)
    return template and template.UnlockArea or table.empty
end
--endregion

--region SkyTowerFloor表（楼层）
--- 楼层所属分区Id
function XSkyTowerControl:GetFloorGroupIdByFloorId(floorId)
    return self._Model:GetFloorGroupIdByFloorId(floorId)
end

function XSkyTowerControl:GetFloorWorkNum(floorId)
    local config = self._Model:GetFloorConfig(floorId)
    return config and #config.WorkPosVector or 0
end

function XSkyTowerControl:GetFloorAppointWork(floorId)
    local config = self._Model:GetFloorConfig(floorId)
    return config and config.AppointWork or table.empty
end

--- 工位的逻辑横坐标，与楼层Id共同构成技能光环用的工位坐标(x, y)
--- 0表示该工位无法作为技能坐标偏移的基准，服务端据此直接判定技能不激活
---@param floorId number
---@param index number 工位下标，从1开始
function XSkyTowerControl:GetFloorWorkPosVector(floorId, index)
    local config = self._Model:GetFloorConfig(floorId)
    local vector = config and config.WorkPosVector and config.WorkPosVector[index]
    return XTool.IsNumberValid(vector) and vector or 0
end

--- 分区内的楼层Id列表
---@param groupId number
---@return number[]
function XSkyTowerControl:GetFloorIdsByGroupId(groupId)
    return self._Model:GetFloorIdsByGroupId(groupId)
end

--- 当前已开放的最高分区Id
---@return number
function XSkyTowerControl:GetMaxFloorGroupId()
    local towerLv = self:GetSkyTowerLv()
    local floorId = self:GetLvFloorId(towerLv)
    return self._Model:GetFloorGroupIdByFloorId(floorId)
end

--- 工位被指定的工作类型，0表示该工位不限制工作
---@param floorId number
---@param index number 工位下标，从1开始
---@return number XMVCA.XSkyTower.WorkType
function XSkyTowerControl:GetFloorAppointWorkByIndex(floorId, index)
    local appointWork = self:GetFloorAppointWork(floorId)
    return appointWork[index] or XMVCA.XSkyTower.WorkType.None
end

---是否为只能执行一种工作类型的限定工位
function XSkyTowerControl:IsLimitWork(floorId, index)
    return self:GetFloorAppointWorkByIndex(floorId, index) ~= XMVCA.XSkyTower.WorkType.None
end
--endregion

--region SkyTowerFloorGroup表（楼层分区）
---@return XTableSkyTowerFloorGroup
function XSkyTowerControl:GetFloorGroupConfig(groupId)
    return self._Model:GetFloorGroupConfig(groupId)
end

---分区名称
---@param groupId number
---@return string
function XSkyTowerControl:GetFloorGroupName(groupId)
    local config = self._Model:GetFloorGroupConfig(groupId)
    return config and config.Name or ""
end

--- 分区仓库物品列表，材料在前、物品在后；已解锁物品即使数量为0也展示
---@param groupId number
---@return { WorkType:number, ProductId:number }
function XSkyTowerControl:GetFloorGroupProductList(groupId)
    self._FloorGroupProductListDict = self._FloorGroupProductListDict or {}
    local cache = self._FloorGroupProductListDict[groupId]
    if not cache then
        local config = self._Model:GetFloorGroupConfig(groupId)
        if not config then
            return table.empty
        end
        --只缓存静态配置项，解锁状态随等级和道具变化，在每次读取时判断
        cache = {}
        local workTypeEnum = XMVCA.XSkyTower.WorkType
        self:_AppendFloorGroupProducts(cache, config.IngredientIds, workTypeEnum.Ingredient)
        self:_AppendFloorGroupProducts(cache, config.FoodIds, workTypeEnum.Food)
        self._FloorGroupProductListDict[groupId] = cache
    end

    local list = {}
    for _, data in ipairs(cache) do
        if self:IsProductUnlock(data.WorkType, data.ProductId) then
            table.insert(list, data)
        end
    end
    return list
end

--- 产品是否属于该分区，跨分区搬运的产品会找不到仓库槽位
---@param groupId number
---@param productType number XMVCA.XSkyTower.ProductType
---@param productId number
---@return boolean
function XSkyTowerControl:IsProductInFloorGroup(groupId, productType, productId)
    local config = self._Model:GetFloorGroupConfig(groupId)
    if not config then
        return false
    end
    local productIds = productType == XMVCA.XSkyTower.ProductType.Ingredient and config.IngredientIds or config.FoodIds
    for _, id in ipairs(productIds) do
        if id == productId then
            return true
        end
    end
    return false
end

--- 追加分区仓库物品项
---@param list table[] 输出列表
---@param productIds number[]|nil 产品Id列表
---@param workType number XMVCA.XSkyTower.WorkType
function XSkyTowerControl:_AppendFloorGroupProducts(list, productIds, workType)
    for _, productId in ipairs(productIds) do
        table.insert(list, {
            WorkType = workType,
            ProductId = productId,
        })
    end
end
--endregion

--region 非配表数据（服务端数据与临时桩）
---@param level number 目标等级
---@return number
function XSkyTowerControl:GetGreaterLevelCharacterCount(level)
    return self._Model:GetGreaterLevelCharacterCount(level)
end

function XSkyTowerControl:GetSkyTowerLv()
    return self._Model:GetSkyTowerLv()
end

function XSkyTowerControl:IsAllTaskFinished()
    local timeLimitTaskIds = self:GetActivityTimeLimitTaskIds()
    for _, timeLimitTaskId in ipairs(timeLimitTaskIds) do
        if XTaskConfig.IsTimeLimitTaskInTime(timeLimitTaskId) then
            if XTool.IsNumberValid(timeLimitTaskId) then
                local timeLimitTaskCfg = XTaskConfig.GetTimeLimitTaskCfg(timeLimitTaskId)
                --成就任务
                for _, taskId in ipairs(timeLimitTaskCfg.TaskId) do
                    if not XDataCenter.TaskManager.CheckTaskFinished(taskId) then
                        return false
                    end
                end
            end
        end
    end
    return true
end

---当前已解锁的最高楼层Id
---@return number
function XSkyTowerControl:GetMaxFloorId()
    return self._Model:GetMaxFloorId()
end

---获取舞台所在的楼层
function XSkyTowerControl:GetDanceFloorId()
    --todo
    return self:GetMaxFloorId()
end
--endregion

function XSkyTowerControl:IsSkyTowerItem(itemId)
    return self._Model:IsSkyTowerItem(itemId)
end

function XSkyTowerControl:GetItemName(itemId)
    if self:IsSkyTowerItem(itemId) then
        local itemCfg = self._Model:GetItemConfig(itemId)
        return itemCfg and itemCfg.Name or ""
    end
    return XDataCenter.ItemManager.GetItemName(itemId)
end

function XSkyTowerControl:GetItemIcon(itemId)
    if self:IsSkyTowerItem(itemId) then
        local itemCfg = self._Model:GetItemConfig(itemId)
        return itemCfg and itemCfg.Icon or ""
    end
    return XDataCenter.ItemManager.GetItemIcon(itemId)
end

return XSkyTowerControl
