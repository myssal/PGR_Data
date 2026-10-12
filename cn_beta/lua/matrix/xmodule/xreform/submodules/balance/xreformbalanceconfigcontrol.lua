---@type XReformBalanceControl config 分部
--- 4.9 天平 config 分部（7 张 Balance 表 TableKey 注册 + accessor）
--- partial of XReformBalanceControl（同 select / slot / calc 分部）；配置表载入本 Control 实例状态
--- 生命周期：本分部不 override 基类 OnInit/OnRelease，改由主文件 XReformBalanceControl:OnInit 调 InitBalanceConfig
--- 封存时随 Balance 夹一并删除
local XReformBalanceControl = XClassPartial("XReformBalanceControl")

-- ReformBalanceMass / ReformBalanceBond 按整表遍历取用（GetAllConfigByTabKey），用 IntAll 读
local TableKey = {
    ReformBalanceAffix       = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int,    Identifier = "Id" },
    ReformBalanceAffixGroup  = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int,    Identifier = "Id" },
    ReformBalanceBond        = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.IntAll, Identifier = "Id" },
    ReformBalanceCharacter   = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int,    Identifier = "CharacterId" },
    ReformBalanceConfig      = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
    ReformBalanceMass        = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    ReformBalanceRecommend   = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int,   Identifier = "StageId" },
    ReformBalanceTargetGroup = { DirPath = XConfigUtil.DirectoryType.Share,  ReadFunc = XConfigUtil.ReadType.Int,   Identifier = "Id" },
}

local WeightType = {
    Character = 1,
    Monster = 2,
    MyAffix = 3,
    EnemyAffix = 4,
}

local AffixType = {
    My = 1,
    Enemy = 2,
}

function XReformBalanceControl:InitBalanceConfig()
    self:InitConfigByTabKey("Fuben/Reform", TableKey)
end

--region Balance 单行 accessor

---@return XTableReformBalanceAffix
function XReformBalanceControl:GetBalanceAffix(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.ReformBalanceAffix, id, notips)
end

---@return XTableReformBalanceAffixGroup
function XReformBalanceControl:GetBalanceAffixGroup(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.ReformBalanceAffixGroup, id, notips)
end

---@return XTableReformBalanceBond
function XReformBalanceControl:GetBalanceBond(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.ReformBalanceBond, id, notips)
end

---@return XTableReformBalanceCharacter
function XReformBalanceControl:GetBalanceCharacter(characterId, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.ReformBalanceCharacter, characterId, notips)
end

---@return XTableReformBalanceConfig
function XReformBalanceControl:GetBalanceConfigByKey(key, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.ReformBalanceConfig, key, notips)
end

---@return XTableReformBalanceMass
function XReformBalanceControl:GetBalanceMass(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.ReformBalanceMass, id, notips)
end

---@param stageId number
---@param weightType number
---@return number[]
function XReformBalanceControl:GetBalanceMassIds(stageId, weightType)
    local stageConfig = self._Model:GetStageConfigById(stageId)
    if not stageConfig then
        return table.empty
    end

    local targetIds = {}
    local targetIdMap = {}
    local function addTargetId(targetId)
        if targetId and targetId > 0 and not targetIdMap[targetId] then
            targetIdMap[targetId] = true
            targetIds[#targetIds + 1] = targetId
        end
    end

    if weightType == WeightType.Character then
        local groupId = stageConfig.UseCharaGroup
        if groupId and groupId > 0 then
            local groupConfig = self._Model:GetReformUseCharaGroup(groupId)
            for _, characterId in ipairs(groupConfig and groupConfig.CharacterIds or table.empty) do
                addTargetId(characterId)
            end
        end
    elseif weightType == WeightType.Monster then
        -- 天平代价侧怪物取 ReformBalanceTargetGroup（天平专用组），不走ReformEnemyGroup
        local groupId = stageConfig.EnemyGroupId
        if groupId and groupId > 0 then
            local groupConfig = self:GetBalanceTargetGroup(groupId, true)
            for _, enemyId in ipairs(groupConfig and groupConfig.TargetIds or table.empty) do
                addTargetId(enemyId)
            end
        end
        for _, enemyId in ipairs(stageConfig.FixedEnemyIds or table.empty) do
            addTargetId(enemyId)
        end
    elseif weightType == WeightType.MyAffix or weightType == WeightType.EnemyAffix then
        local groupId = stageConfig.AffixGroupId
        if groupId and groupId > 0 then
            local groupConfig = self:GetBalanceAffixGroup(groupId, true)
            if groupConfig then
                local targetAffixType = weightType == WeightType.MyAffix and AffixType.My or AffixType.Enemy
                for _, affixId in ipairs(groupConfig.AffixIds) do
                    local affixConfig = self:GetBalanceAffix(affixId)
                    if affixConfig.AffixType == targetAffixType then
                        addTargetId(affixId)
                    end
                end
            end
        end
    end

    -- 同一 TargetId 在 ReformBalanceMass 中按普通/困难各配一行，须按关卡难度取对应那行
    local difficulty = stageConfig.Difficulty
    
    -- 遍历targetId
    local result = {}
    for _, targetId in ipairs(targetIds) do
        -- 构建id前缀
        local idPrefix = self:GetCfgBalanceMassIdPrefix(weightType, difficulty, targetId)

        local cfg = self:GetCfgBalanceMassByCombineIdAndTarget(idPrefix, targetId)

        if cfg then
            -- 缓存id
            table.insert(result, cfg.Id)
        end
    end
    
    return result
end

---@return XTableReformBalanceRecommend
function XReformBalanceControl:GetBalanceRecommend(stageId, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.ReformBalanceRecommend, stageId, notips)
end

--- 天平怪物目标组
---@return XTableReformBalanceTargetGroup
function XReformBalanceControl:GetBalanceTargetGroup(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.ReformBalanceTargetGroup, id, notips)
end

--- 按砝码类型 + 目标id + 关卡难度反查 massId
---@param weightType number
---@param targetId number
---@param difficulty number XEnumConst.REFORM.DIFFICULTY
---@return number|nil
function XReformBalanceControl:GetBalanceMassIdByTarget(weightType, targetId, difficulty)
    -- 计算id前缀
    local idPrefix = self:GetCfgBalanceMassIdPrefix(weightType, difficulty, targetId)
    
    local cfg = self:GetCfgBalanceMassByCombineIdAndTarget(idPrefix, targetId)
    
    return cfg and cfg.Id or nil
end

--- 敌方怪物配置
---@return XTableReformEnemyTarget
function XReformBalanceControl:GetBalanceMob(id)
    return self._Model:GetMob(id)
end

--endregion

--- 获取Mass表Id构成中的targetId
function XReformBalanceControl:GetHashMassTargetId(targetId)
    local hash = ((targetId >> 20) + ((targetId >> 10) & 0x3FF) + (targetId & 0x3FF)) % 1000
    
    return hash
end

--- 获取Mass表Id前缀（不包括哈希链索引
function XReformBalanceControl:GetCfgBalanceMassIdPrefix(weightType, difficulty, targetId)
    local idPrefix = weightType * 10000000 + difficulty * 100000 + self:GetHashMassTargetId(targetId) * 100
    
    return idPrefix
end

--- 获取质量配置，id只算出来前缀，需要结合已知targetId进行逐个查找
function XReformBalanceControl:GetCfgBalanceMassByCombineIdAndTarget(idPrefix, targetId)
    local beginId = idPrefix + 1
    local cfg = self:GetBalanceMass(beginId, true)

    if not cfg then
        return nil
    end

    if cfg.TargetId == targetId then
        return cfg
    end

    -- 哈希冲突：主位不是目标配置，沿哈希链继续找
    for i = 2, 99 do
        local id = idPrefix + i
        cfg = self:GetBalanceMass(id, true)

        if cfg then
            if cfg.TargetId == targetId then
                return cfg
            end
        else
            -- 索引必连续，断开表示终止
            break
        end
    end

    return nil
end

return XReformBalanceControl
�着哈希链找到对应的配置
    for i = 2, 99 do
        local id = idPrefix + i

        -- 探索查找，可能为空，不报错
        cfg = self:GetBalanceMass(id, true)

        if cfg then
            if cfg.TargetId == targetId then
                -- 查找成功
                return cfg
            end
        else
            -- 索引必连续，断开表示终止
            break
        end
    end
    
    return nil
end

return XReformBalanceControl
