---@type XReformBalanceControl 选择态分部
--- 记"选了哪些砝码"、上限校验、按侧汇出算法入参；选择态持于 Control 实例（页面态，不入 Model）
--- 词缀预选态不上秤不计质量，属界面中间态，由 UI 层自持，不在此层
local XReformBalanceControl = XClassPartial("XReformBalanceControl")

-- 砝码类型（对齐 ReformBalanceMass.WeightType，与 XReformBalanceConfigControl 内同名局部表一致）
local WeightType = {
    Character = 1,
    Monster = 2,
    MyAffix = 3,
    EnemyAffix = 4,
}
XReformBalanceControl.WeightType = WeightType

-- 级联卸下羁绊解锁词缀的不动点迭代上限（防异常配置致无限循环；词缀只减不增必收敛）
local MaxCascadeLoop = 16

-- 选择失败原因（UI 据此决定弹哪条 toast）
local SelectFailReason = {
    None = 0,
    SideFull = 1,        -- 单侧槽位已满 → "愿望/代价砝码已添加到上限"
    CharacterFull = 2,   -- 我方角色数达阵容上限 → "最多添加X个角色砝码"
    Fixed = 3,           -- 关卡固定怪不可卸下
}
XReformBalanceControl.SelectFailReason = SelectFailReason

-- 建当前关卡选择态（ApplyInitSelect 调；与 InitBalanceSlots 同期）
function XReformBalanceControl:InitBalanceSelect()
    self:_ResetSelectedMassIds()
    -- 固定怪进关即占槽且锁定，直接计入代价侧已选（参与质量与详情展示）
    local fixedMassIds = self:GetFixedSlotMassIds()
    for index = 1, #fixedMassIds do
        local selected = self._SelectedMassIds[self.Side.Cost]
        selected[#selected + 1] = fixedMassIds[index]
    end
end

--- 已选 massId 列表（按侧分，保持添加顺序）；两侧 key 必须都在，UI 刷新时会直接索引
function XReformBalanceControl:_ResetSelectedMassIds()
    self._SelectedMassIds = {
        [self.Side.Wish] = {},
        [self.Side.Cost] = {},
    }
end

--- 该侧固定槽内的 massId（按槽位顺序）
---@return number[]
function XReformBalanceControl:GetFixedSlotMassIds()
    local massIds = {}
    local slots = self._Slots and self._Slots[self.Side.Cost]
    if not slots then
        return massIds
    end
    for index = 1, #slots do
        if slots[index].IsFixed and XTool.IsNumberValid(slots[index].WeightId) then
            massIds[#massIds + 1] = slots[index].WeightId
        end
    end
    return massIds
end

--- 是否为关卡固定怪（固定槽，不可卸）
---@param massId number
---@return boolean
function XReformBalanceControl:IsFixedWeight(massId)
    local massIds = self:GetFixedSlotMassIds()
    for index = 1, #massIds do
        if massIds[index] == massId then
            return true
        end
    end
    return false
end

--region 选择读写

--- 砝码所属侧（我方角色/我方词缀→愿望侧，敌方怪物/敌方词缀→代价侧）
---@param weightType number
---@return number XReformBalanceControl.Side
function XReformBalanceControl:GetWeightSide(weightType)
    if weightType == WeightType.Monster or weightType == WeightType.EnemyAffix then
        return self.Side.Cost
    end
    return self.Side.Wish
end

--- 该砝码是否已选中
---@param massId number
---@return boolean
function XReformBalanceControl:IsWeightSelected(massId)
    local side = self:_GetSideByMassId(massId)
    if not side then
        return false
    end
    return self:_IndexOfSelectedMassId(side, massId) ~= nil
end

---@param side number
---@param massId number
---@return number|nil  砝码在该侧选择列表中的序号
function XReformBalanceControl:_IndexOfSelectedMassId(side, massId)
    local selected = self._SelectedMassIds[side]
    for index = 1, #selected do
        if selected[index] == massId then
            return index
        end
    end
    return nil
end

--- 能否选中该砝码（不改状态，供 UI 预先判断/决定 toast）
---@param massId number
---@return boolean canSelect
---@return number XReformBalanceControl.SelectFailReason
function XReformBalanceControl:CanSelectWeight(massId)
    local side = self:_GetSideByMassId(massId)
    if not side then
        return false, SelectFailReason.None
    end
    if self:IsSideFull(side) then
        return false, SelectFailReason.SideFull
    end
    -- 我方角色额外受阵容上限约束
    local massConfig = self:GetBalanceMass(massId)
    if massConfig.WeightType == WeightType.Character
        and self:GetSelectedCharacterAmount() >= self:GetCharacterAmountLimit() then
        return false, SelectFailReason.CharacterFull
    end
    return true, SelectFailReason.None
end

--- 选中砝码（上秤 + 记入选择态）
---@param massId number
---@return boolean success
---@return number XReformBalanceControl.SelectFailReason
function XReformBalanceControl:SelectWeight(massId)
    -- 已在秤上（含固定怪）则幂等返回，避免占两格
    if self:IsWeightSelected(massId) then
        return true, SelectFailReason.None
    end
    local canSelect, reason = self:CanSelectWeight(massId)
    if not canSelect then
        return false, reason
    end
    local side = self:_GetSideByMassId(massId)
    if not self:PlaceWeight(side, massId) then
        return false, SelectFailReason.SideFull
    end
    local selected = self._SelectedMassIds[side]
    selected[#selected + 1] = massId
    return true, SelectFailReason.None
end

--- 取消选中砝码（下秤 + 移出选择态）；固定怪拒卸，返回 Fixed 供 UI 弹提示
---@param massId number
---@return boolean success
---@return number XReformBalanceControl.SelectFailReason
function XReformBalanceControl:UnSelectWeight(massId)
    local success, reason = self:_RemoveWeightInternal(massId)
    if not success then
        return false, reason
    end
    -- 取消砝码可能断羁绊 → 级联卸下已放置但不再被羁绊解锁的 SelfAffix 词缀
    -- （不动点迭代，防词缀→词缀链式 bond 漏卸）
    self:_CascadeRemoveUnlockedAffixes()
    return true, SelectFailReason.None
end

-- 内部移除（下秤 + 移出选择态，不级联），供 UnSelectWeight 与级联循环复用
---@param massId number
---@return boolean success
---@return number XReformBalanceControl.SelectFailReason
function XReformBalanceControl:_RemoveWeightInternal(massId)
    local side = self:_GetSideByMassId(massId)
    if not side then
        return false, SelectFailReason.None
    end
    if self:IsFixedWeight(massId) then
        return false, SelectFailReason.Fixed
    end
    local slotIndex = self:_FindWeightSlotIndex(side, massId)
    if not slotIndex or not self:CanRemoveWeight(side, slotIndex) then
        return false, SelectFailReason.None
    end
    self:RemoveWeight(side, slotIndex)
    table.remove(self._SelectedMassIds[side], self:_IndexOfSelectedMassId(side, massId))
    return true, SelectFailReason.None
end

-- 级联卸下"已放置在秤上但不再被羁绊解锁的 SelfAffix 词缀"
-- 取消角色/词缀可能使某 bond 不再触发 → 其解锁的词缀不再有效 → 应从秤上移除
-- 不动点：移除词缀可能再断别的 bond（词缀→词缀链），重复至稳定；词缀只减不增必收敛
function XReformBalanceControl:_CascadeRemoveUnlockedAffixes()
    local guard = 0
    while guard < MaxCascadeLoop do
        guard = guard + 1
        self:RefreshSpecialAffix()
        local displayMassIds = self:GetDisplayAffixMassIds(WeightType.MyAffix)
        local displaySet = {}
        for index = 1, #displayMassIds do
            displaySet[displayMassIds[index]] = true
        end
        local wishMassIds = self._SelectedMassIds[self.Side.Wish]
        local toRemove = {}
        for index = 1, #wishMassIds do
            local massId = wishMassIds[index]
            local massConfig = self:GetBalanceMass(massId)
            if massConfig and massConfig.WeightType == WeightType.MyAffix and not displaySet[massId] then
                toRemove[#toRemove + 1] = massId
            end
        end
        if #toRemove == 0 then
            break
        end
        for index = 1, #toRemove do
            self:_RemoveWeightInternal(toRemove[index])
        end
    end
end

--- 清空所有已选砝码（重置按钮用）；固定怪由 InitBalanceSlots 重建
function XReformBalanceControl:ClearSelectedWeights()
    local stageConfig = self:_GetStageConfig()
    self:InitBalanceSlots(self._Stage, stageConfig.WishWeightSlotNum, stageConfig.CostWeightSlotNum, self:GetFixedEnemyMassIds())
    self:InitBalanceSelect()
end

--- 当前是否有任何已选砝码（重置按钮置灰用）
---@return boolean
function XReformBalanceControl:HasSelectedWeight()
    -- 固定怪恒在选中态，不计入"玩家是否选过"（否则重置按钮永远可点）
    return self:GetPlayerSelectedAmount() > 0
end

--- 玩家主动选择的砝码数（不含固定怪）
---@return number
function XReformBalanceControl:GetPlayerSelectedAmount()
    return self:_GetPlayerSelectedAmountOnSide(self.Side.Wish)
        + self:_GetPlayerSelectedAmountOnSide(self.Side.Cost)
end

---@param side number
---@return number
function XReformBalanceControl:_GetPlayerSelectedAmountOnSide(side)
    local selected = self._SelectedMassIds[side]
    local amount = 0
    for index = 1, #selected do
        if not self:IsFixedWeight(selected[index]) then
            amount = amount + 1
        end
    end
    return amount
end

---@param side number XReformBalanceControl.Side
---@return number[] massId 列表（添加顺序）
function XReformBalanceControl:GetSelectedMassIds(side)
    return self._SelectedMassIds[side] or table.empty
end

--endregion

--region 汇出给算法层的入参

--- 单个砝码的质量（统一取值口径：走 Logic 的 ResolveMass 支持莱亚成长）
---@param massId number
---@return number
function XReformBalanceControl:GetWeightMass(massId)
    local massConfig = self:GetBalanceMass(massId)
    -- 已通关关卡集合由 GetSatisfiedMassConditions 实时收集（通关数据流已落地，#3 un-stub）
    return self:GetBalanceLogic():ResolveMass(massConfig, self:GetSatisfiedMassConditions())
end

--- 该侧已选砝码的质量数组（喂 Logic:SumMass）
---@param side number XReformBalanceControl.Side
---@return number[]
function XReformBalanceControl:GetSelectedMassValues(side)
    local massIds = self:GetSelectedMassIds(side)
    local massValues = {}
    for index = 1, #massIds do
        massValues[index] = self:GetWeightMass(massIds[index])
    end
    return massValues
end

--- 已选我方角色 id 集合（喂 Logic:JudgeBonds）
---@return table<number, boolean>
function XReformBalanceControl:GetSelectedCharacterIdSet()
    return self:_GetSelectedTargetIdSet(self.Side.Wish, WeightType.Character)
end

--- 已选我方词缀 id 集合（喂 Logic:JudgeBonds）
---@return table<number, boolean>
function XReformBalanceControl:GetSelectedAffixIdSet()
    return self:_GetSelectedTargetIdSet(self.Side.Wish, WeightType.MyAffix)
end

--- 已选我方角色数量（阵容上限校验用）
---@return number
function XReformBalanceControl:GetSelectedCharacterAmount()
    return #self:_GetSelectedCharacterConfigs()
end

--- 砝码图标
---@param massId number
---@return string
function XReformBalanceControl:GetWeightIcon(massId)
    local massConfig = self:GetBalanceMass(massId)
    local weightType = massConfig.WeightType
    if weightType == WeightType.Character then
        return self:GetCharacterShowHeadIcon(self:GetBalanceCharacter(massConfig.TargetId))
    end
    if weightType == WeightType.Monster then
        return self:GetBalanceMob(massConfig.TargetId).HeadIcon
    end
    return self:GetBalanceAffix(massConfig.TargetId).Icon
end

--- 砝码名称（角色名 / 怪物名 / 词缀名）
---@param massId number
---@return string
function XReformBalanceControl:GetWeightName(massId)
    local massConfig = self:GetBalanceMass(massId)
    local weightType = massConfig.WeightType
    if weightType == WeightType.Character then
        local characterConfig = self:GetBalanceCharacter(massConfig.TargetId)
        return XMVCA.XCharacter:GetCharacterLogName(XRobotManager.GetCharacterId(characterConfig.RobotId))
    end
    if weightType == WeightType.Monster then
        return self:GetBalanceMob(massConfig.TargetId).Name
    end
    return self:GetBalanceAffix(massConfig.TargetId).AffixName
end

--- 关卡固定怪转 massId：
---@return number[]
function XReformBalanceControl:GetFixedEnemyMassIds()
    local stageConfig = self:_GetStageConfig()
    local fixedEnemyIds = stageConfig.FixedEnemyIds
    if not fixedEnemyIds or #fixedEnemyIds == 0 then
        return table.empty
    end
    local massIds = {}
    for index = 1, #fixedEnemyIds do
        local massId = self:GetBalanceMassIdByTarget(WeightType.Monster, fixedEnemyIds[index], stageConfig.Difficulty)
        if massId then
            massIds[#massIds + 1] = massId
        end
    end
    return massIds
end

--- 已选角色砝码的可上阵实体
---@return number[]
function XReformBalanceControl:GetSelectedEntityIds()
    local entityIds = {}
    local characterConfigs = self:_GetSelectedCharacterConfigs()
    for index = 1, #characterConfigs do
        local characterConfig = characterConfigs[index]
        if XMVCA.XCharacter:IsOwnCharacter(characterConfig.CharacterId) then
            entityIds[#entityIds + 1] = characterConfig.CharacterId
        end
        if XTool.IsNumberValid(characterConfig.RobotId) then
            entityIds[#entityIds + 1] = characterConfig.RobotId
        end
    end
    return entityIds
end

--- 自动上阵实体，按砝码选择顺序
---@return number[]
function XReformBalanceControl:GetAutoDeployEntityIds()
    local entityIds = {}
    local characterConfigs = self:_GetSelectedCharacterConfigs()
    for index = 1, #characterConfigs do
        local entityId = self:GetStrongerEntityId(characterConfigs[index])
        if entityId then
            entityIds[#entityIds + 1] = entityId
        end
    end
    return entityIds
end

--- 已选敌人数量（最低选择数校验用）
---@return number
function XReformBalanceControl:GetSelectedEnemyAmount()
    local massIds = self:GetSelectedMassIds(self.Side.Cost)
    local amount = 0
    for index = 1, #massIds do
        if self:GetBalanceMass(massIds[index]).WeightType == WeightType.Monster then
            amount = amount + 1
        end
    end
    return amount
end

--- 我方角色阵容上限--- 天平砝码系统独立于老怪物词缀联动（XReformAgency:GetStagePlayerAmount 依赖 MobList），此处只取关卡默认值
---@return number
function XReformBalanceControl:GetCharacterAmountLimit()
    local limit = self:_GetStageConfig().PlayerAmountLimitDefault
    if limit and limit > 0 then
        return limit
    end
    return XEnumConst.FuBen.PlayerAmount
end

--endregion

--region 莱亚的直觉（策划预配的保底方案）

--- 保底方案对应的 massId 列表
---@return number[]
function XReformBalanceControl:GetRecommendMassIds()
    local recommendConfig = self:GetBalanceRecommend(self._StageId, true)
    if not recommendConfig then
        return table.empty
    end
    local massIds = {}
    self:_CollectRecommendMassIds(massIds, recommendConfig.CharacterId, WeightType.Character)
    self:_CollectRecommendMassIds(massIds, recommendConfig.MobId, WeightType.Monster)
    -- 推荐词缀未区分敌我，按两类分别查，命中哪个用哪个
    self:_CollectRecommendMassIds(massIds, recommendConfig.AffixId, WeightType.MyAffix)
    self:_CollectRecommendMassIds(massIds, recommendConfig.AffixId, WeightType.EnemyAffix)
    return massIds
end

--- 当前已选是否与保底方案完全一致
---@return boolean
function XReformBalanceControl:IsRecommendApplied()
    -- 固定怪进关即占槽，不计入玩家选择；推荐表里却配了它，两边都要剔除才能比
    local matchCount = 0
    local recommendMassIds = self:GetRecommendMassIds()
    for index = 1, #recommendMassIds do
        local massId = recommendMassIds[index]
        if not self:IsFixedWeight(massId) then
            if not self:IsWeightSelected(massId) then
                return false
            end
            matchCount = matchCount + 1
        end
    end
    return self:GetPlayerSelectedAmount() == matchCount
end

--- 应用保底方案（先清空再依次选中）
function XReformBalanceControl:ApplyRecommend()
    self._UsedRecommend = true
    self:ClearSelectedWeights()
    local recommendMassIds = self:GetRecommendMassIds()
    for index = 1, #recommendMassIds do
        self:SelectWeight(recommendMassIds[index])
    end
    self:RefreshBalanceResult()
end

--- 本次界面内是否用过一键配平
---@return boolean
function XReformBalanceControl:IsRecommendUsed()
    return self._UsedRecommend == true
end

--region 本关选择的本地缓存

--- 缓存关卡砝码选择（剔除关卡固定怪）
function XReformBalanceControl:SaveSelectedWeightsCache()
    local massIds = {}
    for _, side in ipairs({ self.Side.Wish, self.Side.Cost }) do
        for _, massId in ipairs(self._SelectedMassIds[side]) do
            if not self:IsFixedWeight(massId) then
                massIds[#massIds + 1] = massId
            end
        end
    end
    self._Model:SetBalanceSelectCache(self._StageId, massIds)
end

--- 取出砝码缓存选择
function XReformBalanceControl:ApplySelectedWeightsCache()
    local massIds = self._Model:GetBalanceSelectCache(self._StageId) or table.empty
    for index = 1, #massIds do
        self:SelectWeight(massIds[index])
    end
    self:RefreshBalanceResult()
end

--endregion

--- 按 TargetId 反查 massId（推荐表存的是 target 而非 mass）
function XReformBalanceControl:_CollectRecommendMassIds(massIds, targetIds, weightType)
    if not targetIds then
        return
    end
    local stageMassIds = self:GetBalanceMassIds(self._StageId, weightType)
    for index = 1, #targetIds do
        local targetId = targetIds[index]
        if targetId and targetId > 0 then
            for stageIndex = 1, #stageMassIds do
                local massId = stageMassIds[stageIndex]
                if self:GetBalanceMass(massId).TargetId == targetId then
                    massIds[#massIds + 1] = massId
                    break
                end
            end
        end
    end
end

--endregion

--region 私有

---@return number|nil XReformBalanceControl.Side
function XReformBalanceControl:_GetSideByMassId(massId)
    local massConfig = self:GetBalanceMass(massId)
    if not massConfig then
        return nil
    end
    return self:GetWeightSide(massConfig.WeightType)
end

--- 按 massId 定位该侧非固定物理槽序号
---@param side number
---@param massId number
---@return number|nil
function XReformBalanceControl:_FindWeightSlotIndex(side, massId)
    local slots = self._Slots[side]
    if not slots then
        return nil
    end
    for index = 1, #slots do
        if not slots[index].IsFixed and slots[index].WeightId == massId then
            return index
        end
    end
    return nil
end

--- 取该侧指定砝码类型对应的 TargetId 集合（角色id / 词缀id）
---@return table<number, boolean>
function XReformBalanceControl:_GetSelectedTargetIdSet(side, weightType)
    local massIds = self:GetSelectedMassIds(side)
    local targetIdSet = {}
    for index = 1, #massIds do
        local massConfig = self:GetBalanceMass(massIds[index])
        if massConfig.WeightType == weightType then
            targetIdSet[massConfig.TargetId] = true
        end
    end
    return targetIdSet
end

--- 已选角色砝码对应的角色配置
---@return XTableReformBalanceCharacter[]
function XReformBalanceControl:_GetSelectedCharacterConfigs()
    local massIds = self:GetSelectedMassIds(self.Side.Wish)
    local characterConfigs = {}
    for index = 1, #massIds do
        local massConfig = self:GetBalanceMass(massIds[index])
        if massConfig.WeightType == WeightType.Character then
            characterConfigs[#characterConfigs + 1] = self:GetBalanceCharacter(massConfig.TargetId)
        end
    end
    return characterConfigs
end

--- 该角色砝码对应的实体：自机与试玩机器人取战力高者
---@param characterConfig XTableReformBalanceCharacter
---@return number|nil
function XReformBalanceControl:GetStrongerEntityId(characterConfig)
    local characterId = characterConfig.CharacterId
    local robotId = characterConfig.RobotId
    local hasRobot = XTool.IsNumberValid(robotId)
    if not XMVCA.XCharacter:IsOwnCharacter(characterId) then
        return hasRobot and robotId or nil
    end
    if not hasRobot then
        return characterId
    end
    if XMVCA.XCharacter:GetCharacterHaveRobotAbilityById(characterId)
            >= XMVCA.XCharacter:GetCharacterHaveRobotAbilityById(robotId) then
        return characterId
    end
    return robotId
end

--- 该角色砝码展示的战力
---@param characterConfig XTableReformBalanceCharacter
---@return number
function XReformBalanceControl:GetCharacterShowAbility(characterConfig)
    local entityId = self:GetStrongerEntityId(characterConfig)
    if not entityId then
        return 0
    end
    return XMVCA.XCharacter:GetCharacterHaveRobotAbilityById(entityId)
end

--- 该角色砝码展示的头像
---@param characterConfig XTableReformBalanceCharacter
---@return string
function XReformBalanceControl:GetCharacterShowHeadIcon(characterConfig)
    if XMVCA.XCharacter:IsOwnCharacter(characterConfig.CharacterId) then
        return XMVCA.XCharacter:GetCharSmallHeadIcon(characterConfig.CharacterId)
    end
    return XRobotManager.GetRobotSmallHeadIcon(characterConfig.RobotId)
end

--endregion

return XReformBalanceControl
