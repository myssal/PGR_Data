---Model部分类，此处用于注册和处理与配置表直接关联的读取接口
---@type XSkyTowerModel
local XSkyTowerModel = XClassPartial('XSkyTowerModel')

local TableKey = {
    -- 活动总控
    SkyTowerActivity = { CacheType = XConfigUtil.CacheType.Normal },
    -- 活动配置（键值表，按Key索引）
    SkyTowerConfig = { CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
    -- 通天塔等级
    SkyTowerLv = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "Lv" },
    -- 员工信息
    SkyTowerCharacter = {},
    -- 员工技能
    SkyTowerCharacterSkill = {},
    -- 技能类型
    SkyTowerSkillType = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type" },
    -- 员工等级
    SkyTowerCharacterLv = {},
    -- 仓库配置
    SkyTowerStorage = {},
    -- 客户端配置
    SkyTowerClientConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
    -- 食材配置
    SkyTowerIngredient = {},
    -- 食物配置
    SkyTowerFood = {},
    -- 订单角色模型
    SkyTowerOrderModel = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 顾客信息
    SkyTowerCustomer = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 员工模型
    SkyTowerCharacterModel = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "CharacterId" },
    -- 工作台位置
    SkyTowerWorkPos = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 通天塔特效
    SkyTowerEffect = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 通天塔角色
    SkyTowerNpc = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 气泡对话
    SkyTowerDialog = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 聊天对话
    SkyTowerTalk = {},
    -- 聊天剧情
    SkyTowerStory = {},
    -- 聊天演出
    SkyTowerPerform = {},
    -- 演员信息
    SkyTowerPerformer = { DirPath = XConfigUtil.DirectoryType.Client },
    -- 楼层（floorId->GroupId映射等）
    SkyTowerFloor = { CacheType = XConfigUtil.CacheType.Normal },
    -- 楼层区间
    SkyTowerFloorGroup = {},
    -- 舞台等级（楼层升级的收益与消耗）
    SkyTowerDance = {},
    -- 道具
    SkyTowerItem = {},
}

local GuideGroupIds = {}

function XSkyTowerModel:OnInitConfig()
    self._ConfigUtil:InitConfigByTableKey("SkyTower", TableKey)
    if XMain.IsWindowsEditor then
        self._ConfigUtil:AddCheckerByTableKey(TableKey.SkyTowerStory, function(_, templates)
            self:CheckStoryTalkRepeat(templates)
        end)
    end

    self._SkillAddDict = {}
    self._StorageWorkTypeTemplate = {}
    self._StorageTemplateInited = false
end

function XSkyTowerModel:ConfigClearPrivate()
    self._SkillAddDict = {}
    self._StorageWorkTypeTemplate = {}
    self._StorageTemplateInited = false
    self._IndentFoodInfo = nil
    self._TabMenuList = nil
    self._AllPerformIds = nil
    self._AllIndentIds = nil
    self._GroupFloorIdsDict = nil
    self._WorkbenchPosInfo = nil
    self._AllCharacterIds = nil
end

function XSkyTowerModel:ConfigResetAll()

end

--region SkyTowerActivity表（活动时间与任务）

---@return XTableSkyTowerActivity
function XSkyTowerModel:GetActivityConfig(activityId)
    if not XTool.IsNumberValid(activityId) then
        return
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerActivity, activityId)
end

function XSkyTowerModel:GetActivityTimeId()
    local config = self:GetActivityConfig(self:GetActivityId())
    return config and config.TimeId or 0
end

function XSkyTowerModel:GetActivityShopId()
    local config = self:GetActivityConfig(self:GetActivityId())
    return config and config.ShopId or 0
end

function XSkyTowerModel:IsActivityInTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XSkyTowerModel:GetActivityEndTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XSkyTowerModel:GetActivityTimeLimitTaskIds()
    local config = self:GetActivityConfig(self:GetActivityId())
    return config and config.TimeLimitTaskIds or table.empty
end

function XSkyTowerModel:IsOpen()
    if not XTool.IsNumberValid(self._ActivityId) then
        return false
    end
    return self:IsActivityInTime()
end
--endregion

--region SkyTowerConfig表（活动配置，键值表）
---@return XTableSkyTowerConfig
function XSkyTowerModel:GetSkyTowerConfig(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerConfig, key)
end

---@return string
function XSkyTowerModel:GetConfigValue(key, index)
    if not index then
        index = 1
    end
    local config = self:GetSkyTowerConfig(key)
    return config and config.Values[index] or ""
end

function XSkyTowerModel:GetIntConfigValue(key, index)
    local value = self:GetConfigValue(key, index)
    return value and tonumber(value) or 0
end

function XSkyTowerModel:GetConfigAccelerateUseLimit(index)
    return self:GetIntConfigValue("AccelerateUseLimit", index)
end
--endregion

--region SkyTowerLv表（通天塔等级）
---@return XTableSkyTowerLv
function XSkyTowerModel:GetLvConfig(level)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerLv, level)
end

function XSkyTowerModel:GetLvUnlockIngredient(level)
    if not level then
        level = self:GetSkyTowerLv()
    end
    local template = self:GetLvConfig(level)
    return template and template.UnlockIngredient or table.empty
end

function XSkyTowerModel:GetLvUnlockFood(level)
    if not level then
        level = self:GetSkyTowerLv()
    end
    local template = self:GetLvConfig(level)
    return template and template.UnlockFood or table.empty
end

function XSkyTowerModel:GetLvCustomerLimit(level)
    if not level then
        level = self:GetSkyTowerLv()
    end
    local template = self:GetLvConfig(level)
    return template and template.CustomerLimit or 0
end

function XSkyTowerModel:GetLvUpgradeConsume(level)
    if not level then
        level = self:GetSkyTowerLv()
    end
    local template = self:GetLvConfig(level)
    return template and template.NeedGoldCount or 0
end
--endregion

--region SkyTowerCharacter表（员工角色）
---@return XTableSkyTowerCharacter[]
function XSkyTowerModel:GetCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SkyTowerCharacter)
end

---@return XTableSkyTowerCharacter
function XSkyTowerModel:GetCharacterConfig(characterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerCharacter, characterId)
end

--- 配置表里全部员工Id
---@return number[]
function XSkyTowerModel:GetAllCharacterIds()
    if self._AllCharacterIds then
        return self._AllCharacterIds
    end
    local list = {}
    for id in pairs(self:GetCharacterConfigs()) do
        table.insert(list, id)
    end
    table.sort(list)
    self._AllCharacterIds = list
    return list
end

---@return string[]
function XSkyTowerModel:GetCharacterTextList(characterId, workType)
    local config = self:GetCharacterConfig(characterId)
    local dialogId = config and config.DialogIds[workType] or 0
    if not XTool.IsNumberValid(dialogId) then
        return table.empty
    end
    return self:GetDialogTextList(dialogId)
end
--endregion

--region SkyTowerCharacterLv表（员工等级）
function XSkyTowerModel:GetCharacterLvConfigId(characterId, level)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(level) then
        return 0
    end
    return characterId * XMVCA.XSkyTower.StaffLevelBase + level
end

---@return XTableSkyTowerCharacterLv
function XSkyTowerModel:GetCharacterLvConfig(characterId, level, noTips)
    local configId = self:GetCharacterLvConfigId(characterId, level)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerCharacterLv, configId, noTips)
end

--- 角色最大等级
---@param characterId number
function XSkyTowerModel:GetCharacterLvMaxLevel(characterId)
    local minLevel = XMVCA.XSkyTower.StaffLevelMin
    for level = XMVCA.XSkyTower.StaffLevelSearchMax, minLevel, -1 do
        if self:GetCharacterLvConfig(characterId, level, true) then
            return level
        end
    end
    return minLevel
end
--endregion

--region SkyTowerCharacterSkill表（员工技能）
---@return XTableSkyTowerCharacterSkill
function XSkyTowerModel:GetCharacterSkillConfig(skillId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerCharacterSkill, skillId)
end
--endregion

--region SkyTowerSkillType表（技能类型）
---@return XTableSkyTowerSkillType
function XSkyTowerModel:GetSkillTypeConfig(workType)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerSkillType, workType)
end
--endregion

--region SkyTowerIngredient表（食材）
---@return XTableSkyTowerIngredient[]
function XSkyTowerModel:GetIngredientConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SkyTowerIngredient)
end

---@param productId number 食材id
---@return XTableSkyTowerIngredient
function XSkyTowerModel:GetIngredientConfig(productId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerIngredient, productId)
end

--- 食材基础生产时间
---@param productId number 食材id
---@return number
function XSkyTowerModel:GetIngredientBaseProduceSpeed(productId)
    local template = self:GetIngredientConfig(productId)
    return template and template.ProduceNeedTime or 0
end

--- 食材图标
---@param productId number 食材id
---@return string
function XSkyTowerModel:GetIngredientIcon(productId)
    local template = self:GetIngredientConfig(productId)
    return template and template.Icon or ""
end

--- 食材名称
---@param productId number 食材id
---@return string
function XSkyTowerModel:GetIngredientName(productId)
    local template = self:GetIngredientConfig(productId)
    return template and template.Name or ""
end

function XSkyTowerModel:GetAllIngredientIds()
    local list = {}
    local templates = self:GetIngredientConfigs()
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    return list
end
--endregion

--region SkyTowerFood表（食物）
---@return XTableSkyTowerFood[]
function XSkyTowerModel:GetFoodConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SkyTowerFood)
end

---@param productId number 食物id
---@return XTableSkyTowerFood
function XSkyTowerModel:GetFoodConfig(productId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerFood, productId)
end

function XSkyTowerModel:GetAllFoodIds()
    local list = {}
    local templates = self:GetFoodConfigs()
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    return list
end

--- 食物基础生产时间
---@param productId number 食物id
---@return number
function XSkyTowerModel:GetFoodBaseProduceSpeed(productId)
    local template = self:GetFoodConfig(productId)
    return template and template.ProduceNeedTime or 0
end

--- 食物基础出售时间
---@param productId number 食物id
---@return number
function XSkyTowerModel:GetFoodBaseSellSpeed(productId)
    local template = self:GetFoodConfig(productId)
    return template and template.SaleNeedTime or 0
end

--- 食物基础出售价格
---@param productId number 食物id
---@return number
function XSkyTowerModel:GetFoodBaseSellPrice(productId)
    local template = self:GetFoodConfig(productId)
    return template and template.Price or 0
end

--- 食物品质
---@param productId number 食物id
---@return number
function XSkyTowerModel:GetFoodQuality(productId)
    local template = self:GetFoodConfig(productId)
    return template and template.Quality or 0
end

--- 食物图标
---@param productId number 食物id
---@return string
function XSkyTowerModel:GetFoodIcon(productId)
    local template = self:GetFoodConfig(productId)
    return template and template.Icon or ""
end
--endregion

--region SkyTowerStorage表（仓库）
---@return XTableSkyTowerStorage[]
function XSkyTowerModel:GetStorageConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SkyTowerStorage)
end

---@return XTableSkyTowerStorage
function XSkyTowerModel:GetStorageConfig(workType, skyTowerLv, productId)
    if not self._StorageTemplateInited then
        self._StorageTemplateInited = true
        ---@type table<number, XTableSkyTowerStorage>
        local templates = self:GetStorageConfigs()
        for _, template in pairs(templates or table.empty) do
            if not self._StorageWorkTypeTemplate[template.ProductType] then
                self._StorageWorkTypeTemplate[template.ProductType] = {}
            end
            if not self._StorageWorkTypeTemplate[template.ProductType][template.ProductId] then
                self._StorageWorkTypeTemplate[template.ProductType][template.ProductId] = {}
            end
            self._StorageWorkTypeTemplate[template.ProductType][template.ProductId][template.SkyTowerLv] = template
        end
    end
    local datas = self._StorageWorkTypeTemplate[workType][productId]
    if datas then
        for lv = skyTowerLv, 1, -1 do
            if datas[lv] then
                return datas[lv]
            end
        end
    end
    return nil
end
--endregion

--region SkyTowerClientConfig表（客户端配置）
---@return XTableSkyTowerClientConfig
function XSkyTowerModel:GetClientConfig(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerClientConfig, key)
end

---@return string[]
function XSkyTowerModel:GetClientConfigValues(key)
    local config = self:GetClientConfig(key)
    return config.Values
end

---@return string
function XSkyTowerModel:GetClientConfigValue(key, index)
    if not index then
        index = 1
    end
    local config = self:GetClientConfig(key)
    return config and config.Values[index] or ""
end

function XSkyTowerModel:GetIntClientConfigValue(key, index)
    local value = self:GetClientConfigValue(key, index)
    return value and tonumber(value) or 0
end

--- 通用的品质图
---@param is3d boolean 是否在3D界面展示
---@return string
function XSkyTowerModel:GetCommonQualityIcon(is3d)
    local index = is3d and 1 or 2
    return self:GetClientConfigValue("CommonQualityIconUI", index)
end

--- 食物的品质图
---@param quality number 品质等级
---@param is3d boolean 是否在3D界面展示
---@return string
function XSkyTowerModel:GetFoodQualityIcon(quality, is3d)
    local key = is3d and "FoodQualityIcon3DUI" or "FoodQualityIcon2DUI"
    return self:GetClientConfigValue(key, quality)
end

--- 库存描述
---@param index number 描述的下标
---@return string
function XSkyTowerModel:GetStorageCountText(index)
    return self:GetClientConfigValue("StorageCountDesc", index)
end

function XSkyTowerModel:GetCustomerProperty()
    local config = self:GetClientConfig("CustomerProperty")
    return tonumber(config.Values[1]), tonumber(config.Values[2])
end
--endregion

--region SkyTowerEffect表（通天塔特效）
---@return XTableSkyTowerEffect
function XSkyTowerModel:GetEffectConfig(effectId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerEffect, effectId)
end

function XSkyTowerModel:GetEffectUrl(effectId)
    local template = self:GetEffectConfig(effectId)
    if not template then
        return ""
    end
    return template.PrefabUrl
end
--endregion

--region SkyTowerDialog表（气泡对话）
---@return XTableSkyTowerDialog
function XSkyTowerModel:GetDialogConfig(dialogId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerDialog, dialogId)
end

---@return string[]
function XSkyTowerModel:GetDialogTextList(dialogId)
    local config = self:GetDialogConfig(dialogId)
    return config and config.Text or table.empty
end
--endregion

--region SkyTowerTalk表（聊天对话）
---@return XTableSkyTowerTalk
function XSkyTowerModel:GetTalkConfig(talkId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerTalk, talkId)
end
--endregion

--region SkyTowerStory表（聊天剧情）
---@return XTableSkyTowerStory
function XSkyTowerModel:GetStoryConfig(storyId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerStory, storyId)
end

function XSkyTowerModel:GetTalkStoryTalkIds(storyId)
    local template = self:GetStoryConfig(storyId)
    return template and template.TalkIds or {}
end

function XSkyTowerModel:GetTalkStoryDurations(storyId)
    local template = self:GetStoryConfig(storyId)
    return template and template.Duration or {}
end

function XSkyTowerModel:GetStoryNote(storyId)
    local template = self:GetStoryConfig(storyId)
    return template and template.Note or ""
end

---@param templates table<number, XTableSkyTowerStory>
function XSkyTowerModel:CheckStoryTalkRepeat(templates)
    local dict = {}
    for id, template in pairs(templates) do
        for index, talkId in ipairs(template.TalkIds) do
            if dict[talkId] then
                local log = string.format("对话内容重复, StoryId = %s, TalkId = %s, 下标 = %s", id, talkId, index)
                XLog.Error(log)
            end
            dict[talkId] = true
        end
    end
end
--endregion

--region SkyTowerWorkPos表（工位）
---@return XTableSkyTowerWorkPos
function XSkyTowerModel:GetWorkPosConfig(floorGroupId, workType)
    --Id=FloorGroup*10+Type
    local id = floorGroupId * 10 + workType
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerWorkPos, id)
end
--endregion

--region SkyTowerNpc表（通用角色）
---@return XTableSkyTowerNpc
function XSkyTowerModel:GetNpcConfig(npcId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerNpc, npcId)
end

function XSkyTowerModel:GetNpcModelUrl(npcId)
    local template = self:GetNpcConfig(npcId)
    return template and template.ModelUrl or ""
end

function XSkyTowerModel:GetNpcControllerUrl(npcId)
    local template = self:GetNpcConfig(npcId)
    return template and template.ControllerUrl or ""
end
--endregion

--region SkyTowerCustomer表（顾客信息）
---@return XTableSkyTowerCustomer[]
function XSkyTowerModel:GetCustomerConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SkyTowerCustomer)
end

function XSkyTowerModel:GetCustomerIds()
    local list = {}

    local templates = self:GetCustomerConfigs()
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    return list
end

---@return XTableSkyTowerCustomer
function XSkyTowerModel:GetCustomerConfig(customerId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerCustomer, customerId)
end

function XSkyTowerModel:GetCustomerTextList(customerId)
    local template = self:GetCustomerConfig(customerId)
    --DialogId允许不配置，此时不查对话表，也不显示气泡。
    if not template or not XTool.IsNumberValid(template.DialogId) then
        return table.empty
    end
    return self:GetDialogTextList(template.DialogId)
end

function XSkyTowerModel:GetCustomerNpcId(customerId)
    local template = self:GetCustomerConfig(customerId)
    return template and template.NpcId or 0
end
--endregion

--region SkyTowerCharacterModel表（员工模型）
---@return XTableSkyTowerCharacterModel
function XSkyTowerModel:GetCharacterModelConfig(charId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerCharacterModel, charId)
end
--endregion

---@return XTableSkyTowerOrderModel
function XSkyTowerModel:GetOrderModelConfig(orderId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerOrderModel, orderId)
end
--endregion

--region SkyTowerPerform表（演出）
---@return XTableSkyTowerPerform[]
function XSkyTowerModel:GetPerformConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SkyTowerPerform)
end

---@return XTableSkyTowerPerform
function XSkyTowerModel:GetPerformConfig(performId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerPerform, performId)
end

function XSkyTowerModel:GetAllIndentIds()
    if self._AllIndentIds then
        return self._AllIndentIds
    end
    self:InitPerformIds()
    return self._AllIndentIds
end

function XSkyTowerModel:InitPerformIds()
    local PerformType = XMVCA.XSkyTower.PerformType
    ---@type table<number, XTableSkyTowerPerform>
    local templates = self:GetPerformConfigs()
    local indentList, performList = {}, {}
    for id, template in pairs(templates) do
        if template.Type == PerformType.Event or template.Type == PerformType.FloorGroup then
            table.insert(performList, id)
        elseif template.Type == PerformType.Indent then
            table.insert(indentList, id)
        end
    end

    self._AllIndentIds = indentList
    self._AllPerformIds = performList
end

function XSkyTowerModel:GetAllPerformIds()
    if self._AllPerformIds then
        return self._AllPerformIds
    end
    self:InitPerformIds()
    return self._AllPerformIds
end

function XSkyTowerModel:GetPerformBehaviourId(performId, state)
    local template = self:GetPerformConfig(performId)
    if not template then
        return
    end
    return template.BehaviourIds[state]
end
--endregion


--region SkyTowerPerformer表（演出者）
---@return XTableSkyTowerPerformer
function XSkyTowerModel:GetPerformerConfig(performerId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerPerformer, performerId)
end

function XSkyTowerModel:GetPerformerNpcId(performerId)
    local template = self:GetPerformerConfig(performerId)
    return template and template.NpcId or 0
end
--endregion

--region SkyTowerCondition表（玩法内部条件）

--region SkyTowerFloor表（楼层）
---@return XTableSkyTowerFloor[]
function XSkyTowerModel:GetFloorConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SkyTowerFloor)
end

---@return XTableSkyTowerFloor
function XSkyTowerModel:GetFloorConfig(floorId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerFloor, floorId)
end

--- 楼层Id->区间Id，读SkyTowerFloor表的GroupId字段
function XSkyTowerModel:GetFloorGroupIdByFloorId(floorId)
    if not XTool.IsNumberValid(floorId) then
        return 0
    end
    local config = self:GetFloorConfig(floorId)
    return config and config.GroupId or 0
end

--- 区间内的楼层Id列表（按SkyTowerFloor表GroupId归组，保持表序）
---@param groupId number 区间Id
---@return number[]
function XSkyTowerModel:GetFloorIdsByGroupId(groupId)
    if not self._GroupFloorIdsDict then
        self._GroupFloorIdsDict = {}
        ---@type table<number, XTableSkyTowerFloor>
        local templates = self:GetFloorConfigs()
        for _, template in pairs(templates) do
            local list = self._GroupFloorIdsDict[template.GroupId]
            if not list then
                list = {}
                self._GroupFloorIdsDict[template.GroupId] = list
            end
            table.insert(list, template.Id)
        end
        for _, list in pairs(self._GroupFloorIdsDict) do
            table.sort(list)
        end
    end
    return self._GroupFloorIdsDict[groupId] or table.empty
end
--endregion

--region SkyTowerFloorGroup表（楼层分区）
---@return XTableSkyTowerFloorGroup
function XSkyTowerModel:GetFloorGroupConfig(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerFloorGroup, groupId)
end
--endregion

--region SkyTowerDance表（舞台等级）
---按舞台等级取配置，等级与通天塔等级一致
---@param level number
---@return XTableSkyTowerDance
function XSkyTowerModel:GetDanceConfig(level)
    if not level then
        level = self:GetSkyTowerLv()
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerDance, level)
end
--endregion

--region 非配表数据（运行时逻辑）
function XSkyTowerModel:CheckGuideAllFinish()
    for _, guideId in ipairs(GuideGroupIds) do
        if not XDataCenter.GuideManager.CheckIsGuide(guideId) then
            return false
        end
    end
    return true
end

function XSkyTowerModel:GetEnterWorkType()
    if not self:IsOpen() then
        return XMVCA.XSkyTower.WorkType.Sale
    end

    if self:CheckGuideAllFinish() then
        return XMVCA.XSkyTower.WorkType.Sale
    end
    return XMVCA.XSkyTower.WorkType.Food
end
--endregion

---@return XTableSkyTowerItem
function XSkyTowerModel:GetItemConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SkyTowerItem, id)
end

return XSkyTowerModel
