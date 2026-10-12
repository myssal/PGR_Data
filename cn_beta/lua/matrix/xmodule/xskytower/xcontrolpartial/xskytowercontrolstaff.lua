---Control部分类，此处用于员工（角色）的等级、技能与图标
---员工不单独存工作状态，由所在工位的服务端状态映射（无工位=空闲）
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

function XSkyTowerControl:InitStaff()
end

function XSkyTowerControl:ReleaseStaff()
end

--region 员工状态

--- 查找员工所在工位
---@param characterId number
---@return number, number floorId, index（不在任何工位返回nil）
function XSkyTowerControl:FindWorkPos(characterId)
    if not XTool.IsNumberValid(characterId) then
        return nil, nil
    end
    local infos = self._Model:GetAllWorkPosInfos()
    if XTool.IsTableEmpty(infos) then
        return nil, nil
    end
    for key, workPos in pairs(infos) do
        if workPos.CharacterId == characterId then
            return self._Model:ParseWorkPosKey(key)
        end
    end
    return nil, nil
end

--- 查找员工占用的其它工位（通用角色可同时占多个工位）
---@param floorId number 本次要安排到的工位所在楼层
---@param index number 本次要安排到的工位下标
---@return number, number floorId, index（无其它占用返回nil）
function XSkyTowerControl:FindOtherWorkPos(characterId, floorId, index)
    if self:GetCharacterIsUniversal(characterId) then
        return nil, nil
    end
    local otherFloorId, otherIndex = self:FindWorkPos(characterId)
    if not otherFloorId or (otherFloorId == floorId and otherIndex == index) then
        return nil, nil
    end
    return otherFloorId, otherIndex
end

--- 员工是否空闲（未安排到任何工位）
function XSkyTowerControl:IsStaffFree(characterId)
    local floorId = self:FindWorkPos(characterId)
    return floorId == nil
end

--- 员工当前等级
function XSkyTowerControl:GetCurCharacterLevel(characterId)
    return self._Model:GetCharacterLv(characterId)
end

--- 员工升到指定等级的条件是否满足
---@param characterId number
---@param level number 目标等级
---@return boolean, string 是否满足、未满足时的描述
function XSkyTowerControl:CheckCharacterUpLevelCondition(characterId, level)
    local conditionId = self:GetCharacterLvConditionId(characterId, level)
    return XConditionManager.CheckConditionAndDefaultPass(conditionId)
end

--- 当前升级券与升级条件下，员工最多能升到的等级
---@param characterId number
---@return number, number, string 目标等级（无法升级时等于当前等级）、总消耗、卡住的原因描述
function XSkyTowerControl:GetCharacterUpLevelLimit(characterId)
    local curLevel = self:GetCurCharacterLevel(characterId)
    local maxLevel = self:GetCharacterLvMaxLevel(characterId)
    local ownCount = self._Model:GetCharacterLvUpItemCount()
    local targetLevel, totalCost, blockDesc = curLevel, 0, ""
    for level = curLevel + 1, maxLevel do
        local isPass, desc = self:CheckCharacterUpLevelCondition(characterId, level)
        if not isPass then
            blockDesc = desc
            break
        end
        -- 消耗按目标等级逐级累加，不足时停在上一级
        local cost = totalCost + self:GetCharacterLvNeedItemCount(characterId, level)
        if cost > ownCount then
            break
        end
        totalCost, targetLevel = cost, level
    end
    return targetLevel, totalCost, blockDesc
end
--endregion

--region 技能与加成

--- 员工当前等级持有的技能Id列表
---@return number[]
function XSkyTowerControl:GetCurCharacterSkillIds(characterId)
    return self:GetCharacterLvSkillIds(characterId, self:GetCurCharacterLevel(characterId))
end

--- 单个技能对指定产品的三类加成
---@param skillId number
---@param multiplier number 条件系数倍率，无条件技能为1
---@param productId number 产品Id
---@return number, number, number 生产周期缩短秒数、产出数量提升万分比、售卖单价金币增量
function XSkyTowerControl:_GetSkillProductAddition(skillId, multiplier, productId)
    local reduceTime, upProduceRatio, upPriceCount = 0, 0, 0
    -- ProductId与SkillAddition按下标并行配对，同一产品配多项时按类型分别累加
    for _, item in ipairs(self:GetCharacterSkillAdditionList(skillId)) do
        if item.Id == productId then
            local addition = math.floor((item.Addition or 0) * multiplier)
            -- 服务端对非正加成直接跳过，配成负数也不会变成减益
            if addition > 0 then
                if item.AdditionType == XMVCA.XSkyTower.SkillAdditionType.ReduceTime then
                    reduceTime = reduceTime + addition
                elseif item.AdditionType == XMVCA.XSkyTower.SkillAdditionType.UpProduce then
                    upProduceRatio = upProduceRatio + addition
                elseif item.AdditionType == XMVCA.XSkyTower.SkillAdditionType.UpProductPrice then
                    upPriceCount = upPriceCount + addition
                end
            end
        end
    end
    return reduceTime, upProduceRatio, upPriceCount
end

--- 技能的图标类型
function XSkyTowerControl:GetSkillIconType(characterId, skillId)
    if self:GetCharacterIsUniversal(characterId) then
        return XMVCA.XSkyTower.SkillIconType.Universal
    end
    if self:IsCharacterSkillWish(skillId) then
        return XMVCA.XSkyTower.SkillIconType.Wish
    end
    if self:IsCharacterSkillAura(skillId) then
        return XMVCA.XSkyTower.SkillIconType.Aura
    end
    return XMVCA.XSkyTower.SkillIconType.Normal
end

--- 单个角色在给定假设布局下的技能展示明细
---@param workType number 目标工位当前选中的工作类型，与override同源
---@param override table 假设布局，由MakeStaffPreviewOverride造
---@param ratios table<number, number> 该假设布局下这个角色的技能条件系数，与override必须同源
---@return XSkyTowerStaffSkillDesc[]
function XSkyTowerControl:_GetStaffSkillDescList(characterId, floorId, index, workType, override, ratios)
    local list = {}
    -- 通用员工的特性说明不要求配置SectionType，也不代表目标工位有产能加成
    if self:GetCharacterIsUniversal(characterId) then
        for _, skillId in ipairs(self:GetCurCharacterSkillIds(characterId)) do
            if XTool.IsNumberValid(skillId) then
                list[#list + 1] = {
                    SkillId = skillId,
                    IconType = XMVCA.XSkyTower.SkillIconType.Universal,
                    IsEffective = false,
                }
            end
        end
        return list
    end
    local skillId, isEffective = self:_PickWorkPosDisplaySkill(characterId, workType, floorId, index, override, ratios)
    if XTool.IsNumberValid(skillId) then
        list[#list + 1] = {
            SkillId = skillId,
            IconType = self:GetSkillIconType(characterId, skillId),
            IsEffective = isEffective,
        }
    end
    return list
end

--- 员工坐到指定工位的假设布局，候选角色连同当前选中的工作内容一起摆进去
---@return table<number, XSkyTowerWorkPosInfoProtocol>
function XSkyTowerControl:MakeStaffPreviewOverride(characterId, floorId, index, workType, productId)
    local override = {
        [self._Model:MakeWorkPosKey(floorId, index)] = { WorkType = workType, ProductId = productId, CharacterId = characterId },
    }
    local otherFloorId, otherIndex = self:FindOtherWorkPos(characterId, floorId, index)
    if otherFloorId then
        override[self._Model:MakeWorkPosKey(otherFloorId, otherIndex)] = self:_GetEmptyWorkPos()
    end
    return override
end

--- 工位吃到的他人光环加成明细，不含工位自己角色的技能
---@param override table 布局override，为空时读取实际工位
---@param previewRatios table<number, table<number, number>> 与override同源的技能条件系数
---@return XSkyTowerStaffAddition[]
function XSkyTowerControl:GetWorkPosAdditionDescList(floorId, index, override, previewRatios)
    local list = {}
    local workPosInfo = self:_GetWorkPosView(override, floorId, index)
    -- 无人工位与GetAdditions同样不结算，光环虽覆盖得到但没人干活
    if not workPosInfo or not (XTool.IsNumberValid(workPosInfo.CharacterId) and XTool.IsNumberValid(workPosInfo.ProductId)) then
        return list
    end
    local workType = workPosInfo.WorkType
    local productId = workPosInfo.ProductId
    local characterId = workPosInfo.CharacterId
    local sharedSkills = self:_GetSkillShareIndex(override, previewRatios)[self._Model:MakeWorkPosKey(floorId, index)]
    for _, shared in ipairs(sharedSkills or table.empty) do
        -- 用发出方技能的SectionType比对目标工位的工作类型
        if shared.FromCharacterId ~= characterId and self:GetCharacterSkillSectionType(shared.SkillId) == workType then
            self:_AppendSkillAdditionDescItems(list, shared, workType, productId)
        end
    end
    return list
end

--- 把单个技能对该产品的加成拆成明细条追加到列表
---@param list XSkyTowerStaffAddition[] 输出列表
---@param shared XSkyTowerSharedSkill 覆盖过来的技能，Ratio为0表示条件未满足
function XSkyTowerControl:_AppendSkillAdditionDescItems(list, shared, workType, productId)
    local multiplier = shared.Ratio / XMVCA.XSkyTower.TenThousandRate
    if multiplier <= 0 then
        return
    end
    local name = self:GetCharacterName(shared.FromCharacterId)
    local iconType = self:GetSkillIconType(shared.FromCharacterId, shared.SkillId)
    for _, item in ipairs(self:GetCharacterSkillAdditionList(shared.SkillId)) do
        if item.Id == productId then
            local addition = math.floor((item.Addition or 0) * multiplier)
            -- 非正加成服务端不结算，展示出来会与实际产量对不上
            if addition > 0 then
                list[#list + 1] = {
                    Name = name,
                    Addition = addition,
                    AdditionType = item.AdditionType,
                    AdditionText = self:GetSkillAdditionDescText(addition, workType, item.AdditionType),
                    IconType = iconType,
                }
            end
        end
    end
end
--endregion

--region 标签
--- 角色是否拥有该技能标签
---@param skillType number 传0表示不筛选，直接通过
function XSkyTowerControl:IsCharacterHasSkillTag(characterId, skillType)
    if not XTool.IsNumberValid(skillType) then
        return true
    end
    local skillTabType = XMVCA.XSkyTower.SkillTabType
    local isWorkSkillTag = skillType == skillTabType.Collect or skillType == skillTabType.Make or skillType == skillTabType.Sale
    for _, value in ipairs(self:GetCharacterSkillTypes(characterId)) do
        -- 全能标签只在工作类型筛选中包含订购、修造、酬宾，不展开外显标签。
        if value == skillType or (value == skillTabType.AllRound and isWorkSkillTag) then
            return true
        end
    end
    return false
end

--- 角色是否属于该分区
function XSkyTowerControl:IsCharacterInFloorGroup(characterId, floorGroupId)
    local floorGroup = self:GetCharacterFloorGroup(characterId)
    return floorGroup == XMVCA.XSkyTower.CharacterFloorGroupAll or floorGroup == floorGroupId
end
--endregion

--region 排序
--- 候选角色在目标布局下对自身工位的加成，以及是否持有光环技能
---@param override table 该候选安排到目标工位后的布局
---@param previewRatios table<number, table<number, number>> 与override同源的完整条件系数
---@return number, number, number, boolean 周期缩短秒数、增产万分比、单价增量、是否持有光环
function XSkyTowerControl:_GetStaffPreviewWorkAdditions(characterId, floorId, index, override, previewRatios)
    local workPos = self:_GetWorkPosView(override, floorId, index)
    local ratios = previewRatios[characterId] or table.empty
    local reduceTime, upProduceRatio, upPriceCount = 0, 0, 0
    local hasAura = false
    for _, skillId in ipairs(self:GetCurCharacterSkillIds(characterId)) do
        -- 有光环沿用技能标签定义，不要求当前条件已满足或对本工位生效
        hasAura = hasAura or self:IsCharacterSkillAura(skillId)
        local ratio = ratios[skillId]
        if XTool.IsNumberValid(ratio) and self:GetCharacterSkillSectionType(skillId) == workPos.WorkType then
            for _, target in ipairs(self:GetSkillTargetWorkPosList(skillId, floorId, index)) do
                if target.FloorId == floorId and target.Index == index then
                    local multiplier = ratio / XMVCA.XSkyTower.TenThousandRate
                    local reduce, produce, price = self:_GetSkillProductAddition(skillId, multiplier, workPos.ProductId)
                    reduceTime, upProduceRatio, upPriceCount = reduceTime + reduce, upProduceRatio + produce, upPriceCount + price
                    break
                end
            end
        end
    end
    return reduceTime, upProduceRatio, upPriceCount, hasAura
end

--- 根据目标工位预览加成计算候选自身效率，不读取当前激活态
---@param workType number 区域类型
---@param productId number 产品Id，未选产品时无从比较，恒返回0
---@param reduceTime number 周期缩短秒数
---@param upProduceRatio number 增产万分比
---@param upPriceCount number 单价金币增量
---@return number 非售卖区为件/秒，售卖区为金币/秒
function XSkyTowerControl:GetStaffWorkEfficiency(workType, productId, reduceTime, upProduceRatio, upPriceCount)
    if not XTool.IsNumberValid(productId) then
        return 0
    end
    local baseSpeed = self:IsSaleArea(workType) and self:GetProductSellSpeed(workType, productId) or self:GetProductSpeed(workType, productId)
    if baseSpeed <= 0 then
        return 0
    end
    local singleTime = math.max(baseSpeed - reduceTime, XMVCA.XSkyTower.MinCycleDuration)
    if self:IsSaleArea(workType) then
        -- 基础售价仅叠加售卖单价金币增量
        local price = self:GetFoodBaseSellPrice(productId) + upPriceCount
        return price / singleTime
    end
    local outputCount = math.max((XMVCA.XSkyTower.TenThousandRate + upProduceRatio) / XMVCA.XSkyTower.TenThousandRate, XMVCA.XSkyTower.MinOutputCount)
    return outputCount / singleTime
end

--- 从预览加成中取对当前工种有效的最小枚举，售卖增产与生产提价不计入
---@return number 取值见XMVCA.XSkyTower.SkillAdditionType，无加成返回None
function XSkyTowerControl:GetStaffAdditionType(workType, productId, reduceTime, upProduceRatio, upPriceCount)
    if not XTool.IsNumberValid(productId) then
        return XMVCA.XSkyTower.SkillAdditionType.None
    end
    if reduceTime > 0 then
        return XMVCA.XSkyTower.SkillAdditionType.ReduceTime
    end
    if self:IsSaleArea(workType) then
        return upPriceCount > 0 and XMVCA.XSkyTower.SkillAdditionType.UpProductPrice or XMVCA.XSkyTower.SkillAdditionType.None
    end
    return upProduceRatio > 0 and XMVCA.XSkyTower.SkillAdditionType.UpProduce or XMVCA.XSkyTower.SkillAdditionType.None
end

--- 分组先保留通用身份与安排前忙闲，再区分未工作角色的目标工位加成及光环标签
---@param busySet table<number, boolean> 安排前已在工位上的角色集合
---@param hasAddition boolean 目标工位是否有自身技能加成
---@param hasAura boolean 当前等级是否持有光环技能
---@return number 越小排越前
function XSkyTowerControl:GetStaffSortGroup(characterId, busySet, hasAddition, hasAura)
    -- 通用角色无论闲忙都单独成组；其他角色的忙闲不能按预览布局判断
    if self:GetCharacterIsUniversal(characterId) then
        return XMVCA.XSkyTower.StaffSortGroup.Universal
    end
    if busySet[characterId] then
        return XMVCA.XSkyTower.StaffSortGroup.Working
    end
    if hasAddition then
        return XMVCA.XSkyTower.StaffSortGroup.FreeWithAddition
    end
    return hasAura and XMVCA.XSkyTower.StaffSortGroup.FreeWithAura or XMVCA.XSkyTower.StaffSortGroup.FreeWithoutAddition
end

--- 工作界面可安排的角色列表（已获得且属于该楼层分区）
---@param floorId number 工位所在楼层
---@param index number 目标工位下标
---@param workType number 区域类型
---@param productId number 已选产品Id，未选时效率与效果类型两级退化为无差别
---@return number[], table<number, XSkyTowerStaffSkillDesc[]> 排序后的角色Id列表、同源预览技能明细
function XSkyTowerControl:GetWorkStaffIdsWithSort(floorId, index, workType, productId)
    local groupId = self:GetFloorGroupIdByFloorId(floorId)
    local list, skillDescMap = {}, {}
    local characterInfos = self._Model:GetCharacterInfos()
    if XTool.IsTableEmpty(characterInfos) then
        return list, skillDescMap
    end
    -- 每个候选只构建一次完整预览，排序与技能展示共用，不跨刷新缓存
    local noneType = XMVCA.XSkyTower.SkillAdditionType.None
    local busySet = self:GetWorkingCharacterIdSet()
    local keys = {}
    for characterId in pairs(characterInfos) do
        if self:IsCharacterInFloorGroup(characterId, groupId) then
            list[#list + 1] = characterId
            local override = self:MakeStaffPreviewOverride(characterId, floorId, index, workType, productId)
            local previewRatios = self:BuildPreviewSkillRatios(override)
            local reduceTime, upProduceRatio, upPriceCount, hasAura = self:_GetStaffPreviewWorkAdditions(characterId, floorId, index, override, previewRatios)
            local additionType = self:GetStaffAdditionType(workType, productId, reduceTime, upProduceRatio, upPriceCount)
            skillDescMap[characterId] = self:_GetStaffSkillDescList(characterId, floorId, index, workType, override, previewRatios[characterId] or table.empty)
            keys[characterId] = {
                Group = self:GetStaffSortGroup(characterId, busySet, additionType ~= noneType, hasAura),
                AdditionType = additionType == noneType and math.huge or additionType,
                Efficiency = self:GetStaffWorkEfficiency(workType, productId, reduceTime, upProduceRatio, upPriceCount),
                Level = self:GetCurCharacterLevel(characterId),
            }
        end
    end
    -- 未工作(有加成 > 无加成有光环) > 通用员工 > 未工作(无加成无光环) > 工作中
    table.sort(list, function(a, b)
        local keyA, keyB = keys[a], keys[b]
        if keyA.Group ~= keyB.Group then
            return keyA.Group < keyB.Group
        end
        if keyA.Efficiency ~= keyB.Efficiency then
            return keyA.Efficiency > keyB.Efficiency
        end
        if keyA.AdditionType ~= keyB.AdditionType then
            return keyA.AdditionType < keyB.AdditionType
        end
        if keyA.Level ~= keyB.Level then
            return keyA.Level > keyB.Level
        end
        return a < b
    end)
    return list, skillDescMap
end
--endregion

return XSkyTowerControl

---@class XSkyTowerStaffAddition
---@field Name string 放出这条光环的角色名
---@field Addition number 已乘过条件系数的加成值
---@field AdditionType number 取XMVCA.XSkyTower.SkillAdditionType
---@field AdditionText string 带符号与单位的展示文案
---@field IconType number 取XMVCA.XSkyTower.SkillIconType

---@class XSkyTowerStaffSkillDesc
---@field SkillId number
---@field IconType number 取XMVCA.XSkyTower.SkillIconType
---@field IsEffective boolean 该角色坐上这个工位后这条产能技能是否生效，通用特性说明恒为false

