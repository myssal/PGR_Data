---@type XReformBalanceControl 配平计算分部
--- 取配置 + 组装入参 + 调 XReformBalanceLogic + 写 ViewModel；算法本体不在此层（Logic 是无状态纯函数）
--- 选择态变更后由 caller 调 RefreshBalanceResult，UI 从 ViewModel 读结果
local XReformBalanceControl = XClassPartial("XReformBalanceControl")

-- ReformBalanceConfig 表的 Key（Value 列为字符串数组，取 [1] 再 tonumber）
local ConfigKey = {
    PerfectBalanceMassBonusRate = "PerfectBalanceMassBonusRate",       -- 完美配平质量加成（百分数，如 10 表示 +10%）
    NormalBalanceMassDifferenceRate = "NormalBalanceMassDifferenceRate", -- 普通配平差异阈值（百分数，如 10 表示 10%）
    SevereMassDifferenceRate = "SevereMassDifferenceRate",             -- 大幅倾斜差异阈值（百分数）
    SpineTweenTime = "SpineTweenTime",                                 -- 天平倾斜动效过渡时长（秒）
    MinSelectCharacterCount = "MinSelectCharacterCount",               -- 最少选择角色数
    MinSelectEnemyCount = "MinSelectEnemyCount",                       -- 最少选择敌人数
}
XReformBalanceControl.BalanceConfigKey = ConfigKey

--region 配置取值

--- 读 ReformBalanceConfig 的数值参数
--- Value 列定义为 Type1ValueTypestring（字符串数组），取首元素转数值
---@param key string ConfigKey.Xxx
---@return number
function XReformBalanceControl:GetBalanceConfigNumber(key)
    local config = self:GetBalanceConfigByKey(key)
    if not config or not config.Value then
        return 0
    end
    return tonumber(config.Value[1]) or 0
end

--- 读百分数参数并归一化为 0~1（Logic 的阈值入参要求小数）
---@param key string ConfigKey.Xxx
---@return number
function XReformBalanceControl:GetBalanceConfigRate(key)
    return self:GetBalanceConfigNumber(key) / 100
end

--endregion

--region 配平计算

--- 重算配平结果并写入 ViewModel（选择态每次变更后调）
function XReformBalanceControl:RefreshBalanceResult()
    local logic = self:GetBalanceLogic()
    local wishTotal = logic:SumMass(self:GetSelectedMassValues(self.Side.Wish))
    local costTotal = logic:SumMass(self:GetSelectedMassValues(self.Side.Cost))

    local normalThreshold = self:GetBalanceConfigRate(ConfigKey.NormalBalanceMassDifferenceRate)
    local balanceResult = logic:JudgeBalance(wishTotal, costTotal, normalThreshold)
    local difficultyResult = logic:JudgeDifficulty(costTotal, self:_GetStageConfig().DifficultyMassThresholds)
    local tiltResult = logic:JudgeTilt(wishTotal, costTotal, normalThreshold,
        self:GetBalanceConfigRate(ConfigKey.SevereMassDifferenceRate))

    local viewModel = self:GetBalanceViewModel()
    viewModel.Data.WishTotal = wishTotal
    viewModel.Data.CostTotal = costTotal
    viewModel.Data.BalanceResult = balanceResult
    viewModel.Data.DifficultyResult = difficultyResult
    viewModel.Data.TiltResult = tiltResult

    self:RefreshSpecialAffix()
end

--- 天平倾斜动效的过渡时长（秒）
---@return number
function XReformBalanceControl:GetSpineTweenTime()
    return self:GetBalanceConfigNumber(ConfigKey.SpineTweenTime)
end

--- 完美配平的额外愿望质量
--- 仅困难关走质量加成，普通关的完美配平给的是战斗 buff
---@return number
function XReformBalanceControl:GetPerfectBonusMass()
    local viewModelData = self:GetBalanceViewModel().Data
    if viewModelData.BalanceResult ~= self:GetBalanceLogic().BalanceResult.Perfect
        or self:GetStageDifficulty() ~= XEnumConst.REFORM.DIFFICULTY.HARD then
        return 0
    end
    local wishTotal = viewModelData.WishTotal
    local boostRate = self:GetBalanceConfigRate(ConfigKey.PerfectBalanceMassBonusRate)
    return math.floor(self:GetBalanceLogic():ApplyPerfectBoost(wishTotal, boostRate) - wishTotal)
end

--- 当前愿望质量是否达关卡最低目标（进关条件之一）
---@return boolean
function XReformBalanceControl:IsMinQualityMet()
    local viewModel = self:GetBalanceViewModel()
    return self:GetBalanceLogic():IsMinQualityMet(viewModel.Data.WishTotal, self:GetMinQuality())
end

--- 关卡最低愿望质量目标
---@return number
function XReformBalanceControl:GetMinQuality()
    return self:_GetStageConfig().MinQuality or 0
end

--- 角色/敌人砝码是否已达最低选择数量（进关条件之一）
---@return boolean isMet
---@return number needCharacterCount
---@return number needEnemyCount
function XReformBalanceControl:IsMinSelectCountMet()
    local needCharacterCount = self:GetBalanceConfigNumber(ConfigKey.MinSelectCharacterCount)
    local needEnemyCount = self:GetBalanceConfigNumber(ConfigKey.MinSelectEnemyCount)
    local isMet = self:GetSelectedCharacterAmount() >= needCharacterCount
        and self:GetSelectedEnemyAmount() >= needEnemyCount
    return isMet, needCharacterCount, needEnemyCount
end

--- 当前已触发的羁绊（特殊词缀候选）
---@return table[] [{ BondId, UpgradedAffixIds, UnlockedAffixIds }]
function XReformBalanceControl:GetTriggeredBonds()
    return self:GetBalanceLogic():JudgeBonds(
        self:_GetBondRows(),
        self:GetSelectedCharacterIdSet(),
        self:GetSelectedAffixIdSet()
    )
end

--- 本关可触发的羁绊配置
---@return table[]
function XReformBalanceControl:_GetBondRows()
    if self._BondRowsStageId ~= self._StageId then
        local bondRows = {}
        for _, bondId in ipairs(self:_GetStageConfig().BalanceBondIds or table.empty) do
            local bondConfig = self:GetBalanceBond(bondId)
            if bondConfig then
                bondRows[#bondRows + 1] = bondConfig
            end
        end
        self._BondRows = bondRows
        self._BondRowsStageId = self._StageId
    end
    return self._BondRows
end

--endregion

--- 代价总质量是否超出预设
---@return boolean
function XReformBalanceControl:IsCostMassExceed()
    local costMassLimit = self:GetCostMassLimit()
    if costMassLimit <= 0 then
        return false
    end
    return self:GetBalanceViewModel().Data.CostTotal > costMassLimit
end

--- 代价质量预设上限
---@return number
function XReformBalanceControl:GetCostMassLimit()
    local thresholds = self:_GetStageConfig().DifficultyMassThresholds
    if not thresholds or #thresholds == 0 then
        return 0
    end
    return thresholds[#thresholds]
end

--region 特殊词缀（羁绊触发）

--- 刷新当前触发的特殊词缀
---   UnlockedAffixIds = 新增类
---   UpgradedAffixIds = 自身强化类
function XReformBalanceControl:RefreshSpecialAffix()
    local specialAffixIdSet = {}
    local unlockedAffixIds = {}
    local enhanceAffixIdSet = {}
    local hits = self:GetTriggeredBonds()
    for index = 1, #hits do
        local hit = hits[index]
        self:_MarkSpecialAffix(specialAffixIdSet, hit.UpgradedAffixIds)
        self:_MarkSpecialAffix(specialAffixIdSet, hit.UnlockedAffixIds, unlockedAffixIds)
        -- 强化箭头只给被强化词缀
        self:_MarkSpecialAffix(enhanceAffixIdSet, hit.UpgradedAffixIds)
    end
    self._SpecialAffixIdSet = specialAffixIdSet
    self._UnlockedAffixIds = unlockedAffixIds
    self._EnhanceAffixIdSet = enhanceAffixIdSet
end

--- 该砝码是否展示强化箭头（只有我方词缀会亮）
function XReformBalanceControl:IsWeightBondEnhanced(massId)
    local massConfig = self:GetBalanceMass(massId)
    if massConfig.WeightType ~= self.WeightType.MyAffix then
        return false
    end
    return (self._EnhanceAffixIdSet or table.empty)[massConfig.TargetId] == true
end

--- 羁绊解锁的新增词缀 id（需插入词缀列表首位）
---@return number[]
function XReformBalanceControl:GetUnlockedAffixIds()
    return self._UnlockedAffixIds or table.empty
end

---@return table<number, boolean>
function XReformBalanceControl:GetSpecialAffixIdSet()
    return self._SpecialAffixIdSet or table.empty
end

--- 某侧当前应显示的词缀砝码列表
---@param weightType number WeightType.MyAffix / WeightType.EnemyAffix
---@return number[] massId 列表
function XReformBalanceControl:GetDisplayAffixMassIds(weightType)
    local stageMassIds = self:GetBalanceMassIds(self._StageId, weightType)
    local unlockedAffixIds = self:GetUnlockedAffixIds()
    if #unlockedAffixIds == 0 then
        return stageMassIds
    end

    local massIds = {}
    local addedMassIdSet = {}
    local difficulty = self:GetStageDifficulty()
    for index = 1, #unlockedAffixIds do
        local massId = self:GetBalanceMassIdByTarget(weightType, unlockedAffixIds[index], difficulty)
        if massId and not addedMassIdSet[massId] then
            addedMassIdSet[massId] = true
            massIds[#massIds + 1] = massId
        end
    end
    for index = 1, #stageMassIds do
        local massId = stageMassIds[index]
        if not addedMassIdSet[massId] then
            addedMassIdSet[massId] = true
            massIds[#massIds + 1] = massId
        end
    end
    return massIds
end

---@param affixId number
---@return boolean
function XReformBalanceControl:IsSpecialAffix(affixId)
    return self:GetSpecialAffixIdSet()[affixId] == true
end

--- 词缀要展示的标签
---@param affixId number
---@return string[]
function XReformBalanceControl:GetAffixTags(affixId)
    return self:GetBalanceAffix(affixId).Label or table.empty
end

---@param collectIds number[]|nil 传入时额外按顺序收集
function XReformBalanceControl:_MarkSpecialAffix(affixIdSet, affixIds, collectIds)
    if not affixIds then
        return
    end
    for index = 1, #affixIds do
        local affixId = affixIds[index]
        if affixId and affixId > 0 then
            if collectIds and not affixIdSet[affixId] then
                collectIds[#collectIds + 1] = affixId
            end
            affixIdSet[affixId] = true
        end
    end
end

--endregion

return XReformBalanceControl
