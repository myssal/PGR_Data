--- Control部分类，此处用于角色技能的生效判定与拖动换位的实时预览
--- 当前态条件系数由服务端下发，本地按实际布局判定生效；只对假设态重算条件系数，算法对齐服务端SkyTowerController.Skill.cs
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

--region 工位布局视图
--- 空工位占位数据，不被写入故可共用一份；枚举在活动开启时才初始化，不能在文件加载期求值
---@return XSkyTowerWorkPosInfoProtocol
function XSkyTowerControl:_GetEmptyWorkPos()
    if not self._EmptyWorkPos then
        self._EmptyWorkPos = { WorkType = XMVCA.XSkyTower.WorkType.None, CharacterId = 0, ProductId = 0 }
    end
    return self._EmptyWorkPos
end

--- 全部已解锁工位的坐标列表
---@return { FloorId:number, Index:number }[]
function XSkyTowerControl:_GetAllWorkPosLocations()
    if self._AllWorkPosLocations then
        return self._AllWorkPosLocations
    end
    local list = {}
    local infos = self._Model:GetAllWorkPosInfos()
    if XTool.IsTableEmpty(infos) then
        return list
    end
    for key in pairs(infos) do
        local floorId, index = self._Model:ParseWorkPosKey(key)
        table.insert(list, { FloorId = floorId, Index = index })
    end
    self._AllWorkPosLocations = list
    return list
end

--- 工位数据读取入口，override非空时优先读假设值，用于算"放下后"的预览状态
---@param override table<number, XSkyTowerWorkPosInfoProtocol> 键为工位复合键，值为假设的工位数据
---@return XSkyTowerWorkPosInfoProtocol
function XSkyTowerControl:_GetWorkPosView(override, floorId, index)
    if override then
        local hit = override[self._Model:MakeWorkPosKey(floorId, index)]
        if hit then
            return hit
        end
    end
    return self:GetWorkPos(floorId, index)
end

--- 两个工位对换后的布局override（角色连同工作内容整槽互换）
---@return table<number, XSkyTowerWorkPosInfoProtocol>
function XSkyTowerControl:_MakeSwapOverride(fromFloorId, fromIndex, toFloorId, toIndex)
    local empty = self:_GetEmptyWorkPos()
    return {
        [self._Model:MakeWorkPosKey(fromFloorId, fromIndex)] = self:GetWorkPos(toFloorId, toIndex) or empty,
        [self._Model:MakeWorkPosKey(toFloorId, toIndex)] = self:GetWorkPos(fromFloorId, fromIndex) or empty,
    }
end

--- 按逻辑横坐标反查楼层内的工位下标
---@return number 该楼层没有这个横坐标的工位时返回nil
function XSkyTowerControl:_GetWorkPosIndexByVector(floorId, vectorX)
    if not XTool.IsNumberValid(vectorX) then
        return nil
    end
    if floorId < 1 or floorId > self:GetMaxFloorId() then
        return nil
    end
    for index = 1, self:GetWorkPosCount(floorId) do
        if self:GetFloorWorkPosVector(floorId, index) == vectorX then
            return index
        end
    end
    return nil
end

--- 相对坐标偏移落到的工位
---@param offsetX number 工位横坐标差
---@param offsetY number 楼层差
---@return number, number floorId, index
function XSkyTowerControl:_GetWorkPosByOffset(floorId, index, offsetX, offsetY)
    local selfVectorX = self:GetFloorWorkPosVector(floorId, index)
    if not XTool.IsNumberValid(selfVectorX) then
        XLog.Error(string.format("楼层表Id=%s的WorkPosVector缺第%s个工位坐标", tostring(floorId), tostring(index)))
        return nil, nil
    end
    local targetFloorId = floorId + offsetY
    -- 技能生效范围不跨楼层区间
    if self:GetFloorGroupIdByFloorId(targetFloorId) ~= self:GetFloorGroupIdByFloorId(floorId) then
        return nil, nil
    end
    local targetIndex = self:_GetWorkPosIndexByVector(targetFloorId, selfVectorX + offsetX)
    if not targetIndex then
        return nil, nil
    end
    return targetFloorId, targetIndex
end

--- 技能生效范围覆盖到的工位坐标列表
---@param skillId number
---@param floorId number 技能持有者所在楼层
---@param index number 技能持有者所在工位下标
---@return { FloorId:number, Index:number }[]
function XSkyTowerControl:GetSkillTargetWorkPosList(skillId, floorId, index)
    local list, marked = {}, {}
    local offsetList = self:GetCharacterSkillShareOffsetList(skillId)
    -- ShareType未配时只对自身生效；配了内容则须显式含"0_0"才覆盖自身
    if XTool.IsTableEmpty(offsetList) then
        self:_AppendWorkPosLocation(list, marked, floorId, index)
        return list
    end
    -- 跨区间与无工位的偏移已在_GetWorkPosByOffset里拒绝
    for _, offset in ipairs(offsetList) do
        self:_AppendWorkPosLocation(list, marked, self:_GetWorkPosByOffset(floorId, index, offset.OffsetX, offset.OffsetY))
    end
    return list
end

--- 工位坐标去重后追加到列表，坐标非法时不追加
---@param list { FloorId:number, Index:number }[] 输出列表
---@param marked table<number, boolean> 已追加过的工位复合键
function XSkyTowerControl:_AppendWorkPosLocation(list, marked, floorId, index)
    if not XTool.IsNumberValid(floorId) or not XTool.IsNumberValid(index) then
        return
    end
    local key = self._Model:MakeWorkPosKey(floorId, index)
    if marked[key] then
        return
    end
    marked[key] = true
    table.insert(list, { FloorId = floorId, Index = index })
end
--endregion

--region 技能光环反查索引
function XSkyTowerControl:ReleaseSkill()
    self:ClearSkillShareIndex()
end

--- 清掉工位相关缓存，工位布局或技能激活态一变就要重建
function XSkyTowerControl:ClearSkillShareIndex()
    self._AllWorkPosLocations = nil
    self._SkillShareIndex = nil
    -- 预览索引按布局算出，布局变了旧值不能再复用
    self._PreviewShareIndexKey = nil
    self._PreviewShareIndex = nil
end

--- 工位到"影响它的技能"的反查索引，只有当前态走缓存
---@param override table 布局override，为空表示当前实际布局
---@param previewRatios table<number, table<number, number>> 假设布局下的条件系数，override为空时不传
---@return table<number, XSkyTowerSharedSkill[]> 工位复合键 -> 覆盖到它的技能
function XSkyTowerControl:_GetSkillShareIndex(override, previewRatios)
    if override then
        -- 一次预览要对全部工位逐个取索引，按override表实例记一份，换一次拖动自然失效
        if self._PreviewShareIndexKey ~= override then
            self._PreviewShareIndexKey = override
            self._PreviewShareIndex = self:_BuildSkillShareIndex(override, previewRatios)
        end
        return self._PreviewShareIndex
    end
    if not self._SkillShareIndex then
        self._SkillShareIndex = self:_BuildSkillShareIndex()
    end
    return self._SkillShareIndex
end

--- 遍历工位构建光环反查索引
--- 以工位而非角色为发射源：通用角色可同时占多个工位，会从各自位置分别发射
---@return table<number, XSkyTowerSharedSkill[]>
function XSkyTowerControl:_BuildSkillShareIndex(override, previewRatios)
    local index = {}
    for _, location in ipairs(self:_GetAllWorkPosLocations()) do
        local workPosInfo = self:_GetWorkPosView(override, location.FloorId, location.Index)
        local characterId = workPosInfo and workPosInfo.CharacterId or 0
        if XTool.IsNumberValid(characterId) then
            -- 假设态的系数来自本地重算，当前态直接读服务端下发结果
            local ratios = previewRatios and (previewRatios[characterId] or table.empty) or self._Model:GetCharacterActiveSkillRatios(characterId)
            for skillId, ratio in pairs(ratios) do
                -- 条件未满足的技能系数为0，不产生任何加成，也就不必建索引
                if XTool.IsNumberValid(ratio) then
                    for _, target in ipairs(self:GetSkillTargetWorkPosList(skillId, location.FloorId, location.Index)) do
                        local key = self._Model:MakeWorkPosKey(target.FloorId, target.Index)
                        index[key] = index[key] or {}
                        -- 不按角色去重：多个角色的光环覆盖同一工位时，各自的加成全部叠加
                        table.insert(index[key], { SkillId = skillId, Ratio = ratio, FromCharacterId = characterId })
                    end
                end
            end
        end
    end
    return index
end

--- 工位实际吃到的技能加成，含他人光环覆盖过来的技能
---@param override table 布局override，为空表示按当前实际布局算
---@param previewRatios table<number, table<number, number>> 假设布局下的条件系数，override为空时不传
---@return number, number, number 生产周期缩短秒数、产出数量提升万分比、售卖单价金币增量
function XSkyTowerControl:GetWorkPosSkillAdditions(floorId, index, override, previewRatios)
    local workPosInfo = self:_GetWorkPosView(override, floorId, index)
    if not workPosInfo or not XTool.IsNumberValid(workPosInfo.ProductId) then
        return 0, 0, 0
    end
    local sharedSkills = self:_GetSkillShareIndex(override, previewRatios)[self._Model:MakeWorkPosKey(floorId, index)]
    if XTool.IsTableEmpty(sharedSkills) then
        return 0, 0, 0
    end
    local reduceTime, upProduceRatio, upPriceCount = 0, 0, 0
    for _, shared in ipairs(sharedSkills) do
        -- 用发出方技能的SectionType比对目标工位的工作类型
        if self:GetCharacterSkillSectionType(shared.SkillId) == workPosInfo.WorkType then
            local multiplier = shared.Ratio / XMVCA.XSkyTower.TenThousandRate
            local reduce, produce, price = self:_GetSkillProductAddition(shared.SkillId, multiplier, workPosInfo.ProductId)
            reduceTime, upProduceRatio, upPriceCount = reduceTime + reduce, upProduceRatio + produce, upPriceCount + price
        end
    end
    return reduceTime, upProduceRatio, upPriceCount
end
--endregion

--region 技能激活状态
--- 员工在指定工位上要展示的那一条技能，展示位只有一个，多技能角色得挑出最能代表这个工位的那条
--- 优先级：已生效 > 工作类型对得上 > 第一条
---@return number, boolean 技能Id、该技能是否生效
function XSkyTowerControl:_PickWorkPosDisplaySkill(characterId, workType, floorId, index, override, activeSkillRatios)
    local matchId, firstId = 0, 0
    for _, skillId in ipairs(self:GetCurCharacterSkillIds(characterId)) do
        local sectionType = self:GetCharacterSkillSectionType(skillId)
        -- 没配SectionType的是角色特性说明非产能技能，无生效概念
        if XTool.IsNumberValid(sectionType) then
            if self:_IsSkillEffectiveByRatios(skillId, floorId, index, override, activeSkillRatios) then
                return skillId, true
            end
            if matchId == 0 and sectionType == workType then
                matchId = skillId
            end
            if firstId == 0 then
                firstId = skillId
            end
        end
    end
    return XTool.IsNumberValid(matchId) and matchId or firstId, false
end

--- 工位上员工的技能生效状态，供工位详情展示
--- 通用角色可同时占多个工位，同一技能在不同工位上生效结果可以不同，故按工位而不是按角色算
---@param override table 布局override，为空时读取实际工位
---@param previewRatios table<number, table<number, number>> 与override同源的技能条件系数
---@return number|nil characterId 无可展示技能时返回nil
---@return number|nil skillId
---@return number|nil state XMVCA.XSkyTower.SkillEffectState
function XSkyTowerControl:GetStaffSkillEffectList(floorId, index, override, previewRatios)
    local workPos = self:_GetWorkPosView(override, floorId, index)
    local characterId = workPos and workPos.CharacterId or 0
    if not XTool.IsNumberValid(characterId) then
        return
    end
    -- 条件系数取当前布局下的结果，工作类型与产品是否对得上再本地判一次
    local activeSkillRatios = previewRatios and (previewRatios[characterId] or table.empty) or self._Model:GetCharacterActiveSkillRatios(characterId)
    local skillId, isEffective = self:_PickWorkPosDisplaySkill(characterId, workPos.WorkType, floorId, index, override, activeSkillRatios)
    if not XTool.IsNumberValid(skillId) then
        return
    end
    return characterId, skillId, isEffective and XMVCA.XSkyTower.SkillEffectState.Active or XMVCA.XSkyTower.SkillEffectState.NotActive
end
--endregion

--region 技能条件重算（搬迁服务端算法，仅用于假设态预览）
--- 角色到工位坐标的反查表
--- 通用角色可同时占多个工位、无法用单一坐标表达，故不建索引；查不到坐标的角色只有无条件技能能激活
---@param override table 布局override，可空
---@return table<number, table> characterId -> { FloorId, Index }
function XSkyTowerControl:_GetCharacterLocationMap(override)
    local map = {}
    for _, location in ipairs(self:_GetAllWorkPosLocations()) do
        local workPosInfo = self:_GetWorkPosView(override, location.FloorId, location.Index)
        local characterId = workPosInfo and workPosInfo.CharacterId or 0
        if XTool.IsNumberValid(characterId) and not self:GetCharacterIsUniversal(characterId) then
            map[characterId] = location
        end
    end
    return map
end

--- SkillConditionType.NearbyCharacter：指定角色位于自身的指定相对坐标时激活
--- ConditionParams[1]为需要的角色Id，[2]起每一项都是形如"x_y"的整串坐标，命中任一项即激活
---@param location { FloorId:number, Index:number } 技能持有者所在工位
---@return number 未激活时返回nil
function XSkyTowerControl:_GetNearbyCharacterRatio(skillId, location, override)
    local needCharacterId = self:GetCharacterSkillConditionParam(skillId, 1)
    if needCharacterId == XMVCA.XSkyTower.UnlimitedConditionParam then
        return nil
    end
    for _, offset in ipairs(self:GetCharacterSkillConditionOffsetList(skillId)) do
        local targetFloorId, targetIndex = self:_GetWorkPosByOffset(location.FloorId, location.Index, offset.OffsetX, offset.OffsetY)
        if targetIndex then
            local workPosInfo = self:_GetWorkPosView(override, targetFloorId, targetIndex)
            if workPosInfo and workPosInfo.CharacterId == needCharacterId then
                return XMVCA.XSkyTower.TenThousandRate
            end
        end
    end
    return nil
end

--- SkillConditionType.WorkPosition：位于指定楼层与指定工作区域时激活，配0的维度不做限制
---@param location { FloorId:number, Index:number } 技能持有者所在工位
---@return number 未激活时返回nil
function XSkyTowerControl:_GetWorkPositionRatio(skillId, location)
    local needFloorId = self:GetCharacterSkillConditionParam(skillId, 1)
    if needFloorId ~= XMVCA.XSkyTower.UnlimitedConditionParam and needFloorId ~= location.FloorId then
        return nil
    end
    local needWorkPosX = self:GetCharacterSkillConditionParam(skillId, 2)
    if needWorkPosX ~= XMVCA.XSkyTower.UnlimitedConditionParam and needWorkPosX ~= self:GetFloorWorkPosVector(location.FloorId, location.Index) then
        return nil
    end
    return XMVCA.XSkyTower.TenThousandRate
end

--- SkillConditionType.FloorHeight：所处楼层越高系数越大，未达基准楼层不激活
--- 系数 = Params[2] + Params[3] * (当前楼层 - 基准楼层)，两个数值都按万分比配
---@param location { FloorId:number, Index:number } 技能持有者所在工位
---@return number 未激活时返回nil
function XSkyTowerControl:_GetFloorHeightRatio(skillId, location)
    local baseFloorId = self:GetCharacterSkillConditionParam(skillId, 1)
    if location.FloorId < baseFloorId then
        return nil
    end
    local baseRatio = self:GetCharacterSkillConditionParam(skillId, 2)
    local floorRatio = self:GetCharacterSkillConditionParam(skillId, 3)
    return baseRatio + floorRatio * (location.FloorId - baseFloorId)
end

--- 工位是否落在技能的统计范围内，范围类型没配或配了未知值时一个都不统计
---@param selfFloorId number 技能持有者所在楼层
---@param selfGroupId number 技能持有者所在楼层区间
---@param areaType number XMVCA.XSkyTower.SkillAreaType
---@return boolean
function XSkyTowerControl:_IsWorkPosInSkillArea(floorId, selfFloorId, selfGroupId, areaType)
    if areaType == XMVCA.XSkyTower.SkillAreaType.FloorGroup then
        return self:GetFloorGroupIdByFloorId(floorId) == selfGroupId
    end
    if areaType == XMVCA.XSkyTower.SkillAreaType.Floor then
        return floorId == selfFloorId
    end
    if areaType == XMVCA.XSkyTower.SkillAreaType.AllFloor then
        return true
    end
    return false
end

--- 统计范围内的候选角色数，满足条件的自身也计入
---@param location { FloorId:number, Index:number }
---@param activeLocations table[] 已按角色去重的候选位置
---@return number
function XSkyTowerControl:_CountCharactersWithActiveSkills(skillId, location, activeLocations)
    local areaType = self:GetCharacterSkillConditionParam(skillId, 1)
    if areaType == XMVCA.XSkyTower.SkillAreaType.AllFloor then
        return #activeLocations
    end
    local selfGroupId = self:GetFloorGroupIdByFloorId(location.FloorId)
    local count = 0
    for _, other in ipairs(activeLocations) do
        if self:_IsWorkPosInSkillArea(other.FloorId, location.FloorId, selfGroupId, areaType) then
            count = count + 1
        end
    end
    return count
end

--- SkillConditionType.OtherActiveCharacter：上岗时按候选角色数计算系数
--- 系数 = Params[2] + Params[3] * 角色数，统计为0时退化成基准值Params[2]
---@param location { FloorId:number, Index:number } 取不到坐标时不激活
---@param activeLocations table[]
---@return number 未激活时返回nil
function XSkyTowerControl:_GetOtherActiveCharacterRatio(skillId, location, activeLocations)
    if not location then
        return nil
    end
    local matchCount = self:_CountCharactersWithActiveSkills(skillId, location, activeLocations)
    local baseRatio = self:GetCharacterSkillConditionParam(skillId, 2)
    local perCharacterRatio = self:GetCharacterSkillConditionParam(skillId, 3)
    return baseRatio + perCharacterRatio * matchCount
end

--- 不依赖其他角色的技能条件系数
---@param conditionType number XMVCA.XSkyTower.SkillConditionType
---@param location { FloorId:number, Index:number } 未上工位或通用角色传nil
---@return number 未激活时返回nil
function XSkyTowerControl:_GetIndependentSkillRatio(skillId, conditionType, location, override)
    if conditionType == XMVCA.XSkyTower.SkillConditionType.None then
        return XMVCA.XSkyTower.TenThousandRate
    end
    -- 余下三类都要用自身坐标作判定基准，取不到坐标一律不激活
    if not location then
        return nil
    end
    if conditionType == XMVCA.XSkyTower.SkillConditionType.NearbyCharacter then
        return self:_GetNearbyCharacterRatio(skillId, location, override)
    end
    if conditionType == XMVCA.XSkyTower.SkillConditionType.WorkPosition then
        return self:_GetWorkPositionRatio(skillId, location)
    end
    if conditionType == XMVCA.XSkyTower.SkillConditionType.FloorHeight then
        return self:_GetFloorHeightRatio(skillId, location)
    end
    XLog.Error(string.format("角色技能表Id=%s的ConditionType未支持：%s", tostring(skillId), tostring(conditionType)))
    return nil
end

--- 按假设布局重算全部角色的技能条件系数
--- 候选在阶段一固定，条件4不互相计入
---@param override table 布局override，为空时按当前实际布局算
---@return table<number, table<number, number>> characterId -> skillId -> 万分比条件系数
function XSkyTowerControl:BuildPreviewSkillRatios(override)
    local characterInfos = self._Model:GetCharacterInfos()
    if XTool.IsTableEmpty(characterInfos) then
        return table.empty
    end
    local locations = self:_GetCharacterLocationMap(override)

    --阶段一：独立技能与候选角色
    local result = {}
    local dependentSkillsByCharacter = {}
    local activeLocations = {}
    for characterId in pairs(characterInfos) do
        local location = locations[characterId]
        local ratios, dependentSkillIds, hasActiveConditionSkill = self:_CollectIndependentSkillRatios(characterId, location, override)
        result[characterId] = ratios
        if location and hasActiveConditionSkill then
            activeLocations[#activeLocations + 1] = location
        end
        if not XTool.IsTableEmpty(dependentSkillIds) then
            dependentSkillsByCharacter[characterId] = dependentSkillIds
        end
    end
    if XTool.IsTableEmpty(dependentSkillsByCharacter) then
        return result
    end

    --阶段二：补算依赖技能
    for characterId, dependentSkillIds in pairs(dependentSkillsByCharacter) do
        self:_CollectDependentSkillRatios(dependentSkillIds, locations[characterId], activeLocations, result[characterId])
    end
    return result
end

--- 收集独立技能系数和待计算的依赖技能
---@param location { FloorId:number, Index:number } 未上工位或通用角色传nil
---@return table<number, number> skillId -> 万分比条件系数，未激活的技能不入表
---@return number[] dependentSkillIds
---@return boolean hasActiveConditionSkill 是否有已激活的非None独立技能（含零、负系数）
function XSkyTowerControl:_CollectIndependentSkillRatios(characterId, location, override)
    local ratios = {}
    local dependentSkillIds = {}
    local hasActiveConditionSkill = false
    for _, skillId in ipairs(self:GetCurCharacterSkillIds(characterId)) do
        if XTool.IsNumberValid(skillId) and ratios[skillId] == nil then
            local conditionType = self:GetCharacterSkillConditionType(skillId)
            if conditionType == XMVCA.XSkyTower.SkillConditionType.OtherActiveCharacter then
                dependentSkillIds[#dependentSkillIds + 1] = skillId
            else
                local ratio = self:_GetIndependentSkillRatio(skillId, conditionType, location, override)
                ratios[skillId] = ratio
                if ratio ~= nil and conditionType ~= XMVCA.XSkyTower.SkillConditionType.None then
                    hasActiveConditionSkill = true
                end
            end
        end
    end
    return ratios, dependentSkillIds, hasActiveConditionSkill
end

--- 将依赖技能系数补入ratios
---@param dependentSkillIds number[] OtherActiveCharacter类技能Id
---@param location { FloorId:number, Index:number } 未上工位或通用角色传nil
---@param activeLocations table[]
---@param ratios table<number, number>
function XSkyTowerControl:_CollectDependentSkillRatios(dependentSkillIds, location, activeLocations, ratios)
    if not location then
        return
    end
    for _, skillId in ipairs(dependentSkillIds) do
        if ratios[skillId] == nil then
            ratios[skillId] = self:_GetOtherActiveCharacterRatio(skillId, location, activeLocations)
        end
    end
end
--endregion

--region 技能生效判定（当前态与假设态）
--- 工位上的工作是否落在技能的加成范围内（工作区域与具体产品都要对得上）
--- ProductId与SkillAddition按下标并行配对
---@param override table 布局override，可空
---@return boolean
function XSkyTowerControl:_IsWorkPosMatchSkill(skillId, floorId, index, override)
    local workPosInfo = self:_GetWorkPosView(override, floorId, index)
    if not workPosInfo then
        return false
    end
    if workPosInfo.WorkType ~= self:GetCharacterSkillSectionType(skillId) then
        return false
    end
    local productIds = self:GetCharacterSkillProductIds(skillId)
    -- 未配产品的技能不限定具体物品，工作类型对得上就算命中
    if XTool.IsTableEmpty(productIds) then
        return true
    end
    for _, id in ipairs(productIds) do
        if id == workPosInfo.ProductId then
            return true
        end
    end
    return false
end

--- 技能在指定布局下是否生效：条件系数为正，且生效范围内至少有一个工位的工作对得上
---@param ratios table<number, number> 当前态取服务端结果，假设态取BuildPreviewSkillRatios结果里该角色那一份
---@return boolean
function XSkyTowerControl:_IsSkillEffectiveByRatios(skillId, floorId, index, override, ratios)
    if not ratios or not XTool.IsNumberValid(ratios[skillId]) then
        return false
    end
    for _, pos in ipairs(self:GetSkillTargetWorkPosList(skillId, floorId, index)) do
        if self:_IsWorkPosMatchSkill(skillId, pos.FloorId, pos.Index, override) then
            return true
        end
    end
    return false
end

--endregion

--region 拖动换位
--- 目标工位能否接收从源工位拖来的内容
---@return number XMVCA.XSkyTower.DropCheckResult
function XSkyTowerControl:CheckWorkPosDrop(fromFloorId, fromIndex, toFloorId, toIndex)
    if fromFloorId == toFloorId and fromIndex == toIndex then
        return XMVCA.XSkyTower.DropCheckResult.Ok
    end
    local fromWorkType = self:GetWorkType(fromFloorId, fromIndex)
    local toWorkType = self:GetWorkType(toFloorId, toIndex)
    local fromAppoint = self:GetFloorAppointWorkByIndex(fromFloorId, fromIndex)
    local toAppoint = self:GetFloorAppointWorkByIndex(toFloorId, toIndex)

    if XTool.IsNumberValid(toAppoint) and XTool.IsNumberValid(fromWorkType) and toAppoint ~= fromWorkType then
        return XMVCA.XSkyTower.DropCheckResult.WorkTypeMismatch
    end
    -- 源工位有工作限制时，对方的工作换过来会落到限制工位上引起冲突
    if XTool.IsNumberValid(fromAppoint) and XTool.IsNumberValid(toWorkType) and fromAppoint ~= toWorkType then
        return XMVCA.XSkyTower.DropCheckResult.SourceLimited
    end
    -- 角色随槽位去往对方楼层，双方都得能在对方所属分区工作
    if not self:_IsSwapCharacterFloorGroupValid(fromFloorId, fromIndex, toFloorId) or not self:_IsSwapCharacterFloorGroupValid(toFloorId, toIndex, fromFloorId) then
        return XMVCA.XSkyTower.DropCheckResult.FloorGroupMismatch
    end
    -- 产品按分区限定，跨分区换位会让产品找不到仓库槽位，工位永久卡在等待入库且界面无提示
    if not self:_IsSwapWorkPosProductValid(fromFloorId, fromIndex, toFloorId) or not self:_IsSwapWorkPosProductValid(toFloorId, toIndex, fromFloorId) then
        return XMVCA.XSkyTower.DropCheckResult.ProductGroupMismatch
    end
    return XMVCA.XSkyTower.DropCheckResult.Ok
end

--- 工位上的角色能否在目标楼层所属分区工作，空工位无需校验
---@param floorId number 角色当前所在楼层
---@param index number 角色当前所在工位下标
---@param targetFloorId number 换位后去往的楼层
---@return boolean
function XSkyTowerControl:_IsSwapCharacterFloorGroupValid(floorId, index, targetFloorId)
    local characterId = self:GetCharacterId(floorId, index)
    if not XTool.IsNumberValid(characterId) then
        return true
    end
    return self:IsCharacterInFloorGroup(characterId, self:GetFloorGroupIdByFloorId(targetFloorId))
end

--- 工位上的产品能否放进目标楼层所属分区的仓库，无产品的工位无需校验
---@param floorId number 产品当前所在楼层
---@param index number 产品当前所在工位下标
---@param targetFloorId number 换位后去往的楼层
---@return boolean
function XSkyTowerControl:_IsSwapWorkPosProductValid(floorId, index, targetFloorId)
    local workType = self:GetWorkType(floorId, index)
    local productId = self:GetProductId(floorId, index)
    if workType == XMVCA.XSkyTower.WorkType.None or not XTool.IsNumberValid(productId) then
        return true
    end
    return self:IsProductInFloorGroup(self:GetFloorGroupIdByFloorId(targetFloorId), self:GetProductTypeByWorkType(workType), productId)
end

---@return boolean
function XSkyTowerControl:CanDropWorkPos(fromFloorId, fromIndex, toFloorId, toIndex)
    return self:CheckWorkPosDrop(fromFloorId, fromIndex, toFloorId, toIndex) == XMVCA.XSkyTower.DropCheckResult.Ok
end

--- 当前状态与假设状态比对出的技能生效态
---@return number XMVCA.XSkyTower.SkillEffectState
function XSkyTowerControl:_MakeSkillEffectState(isCurEffective, isNextEffective)
    if isCurEffective == isNextEffective then
        return isCurEffective and XMVCA.XSkyTower.SkillEffectState.Active or XMVCA.XSkyTower.SkillEffectState.NotActive
    end
    return isNextEffective and XMVCA.XSkyTower.SkillEffectState.WillActive or XMVCA.XSkyTower.SkillEffectState.WillDeactivate
end

--- 员工换位前后的技能生效状态，按工位展示规则选一条，仍只提示愿望型与光环型
---@param currentFloorId number 换位前所在楼层
---@param currentIndex number 换位前所在工位
---@param override table 换位后的布局override，为空表示只看当前状态
---@param previewRatios table<number, table<number, number>> 换位后的条件系数，override为空时可不传
---@return XSkyTowerSkillEffectItem[]
function XSkyTowerControl:_GetStaffSkillEffectList(characterId, currentFloorId, currentIndex, nextFloorId, nextIndex, override, previewRatios)
    local list = {}
    if not XTool.IsNumberValid(characterId) then
        return list
    end
    local currentRatios = self._Model:GetCharacterActiveSkillRatios(characterId)
    local displayFloorId, displayIndex = currentFloorId, currentIndex
    local displayRatios = currentRatios
    if override then
        displayFloorId, displayIndex = nextFloorId, nextIndex
        displayRatios = previewRatios and previewRatios[characterId] or table.empty
    end
    -- 有合法落点时按换位后布局选技能；角色与工作内容整槽交换，不能读目标交换前的工作类型
    local workPos = self:_GetWorkPosView(override, displayFloorId, displayIndex)
    local skillId, isNextEffective = self:_PickWorkPosDisplaySkill(characterId, workPos.WorkType, displayFloorId, displayIndex, override, displayRatios)
    if not XTool.IsNumberValid(skillId) or not (self:IsCharacterSkillWish(skillId) or self:IsCharacterSkillAura(skillId)) then
        return list
    end
    -- 比较同一条技能的前后状态；无预览时两者相同，当前态始终读取服务端条件系数
    local isCurEffective = isNextEffective
    if override then
        isCurEffective = self:_IsSkillEffectiveByRatios(skillId, currentFloorId, currentIndex, nil, currentRatios)
    end
    table.insert(list, {
        CharacterId = characterId,
        SkillId = skillId,
        State = self:_MakeSkillEffectState(isCurEffective, isNextEffective),
    })
    return list
end

--- 拖动预览的假设布局与其条件系数，两种预览共用
--- 落点无效或没有落点时返回nil，调用方据此退化为只看当前状态
---@return table, table<number, table<number, number>> 布局override、假设布局下的条件系数
function XSkyTowerControl:_MakeDragPreviewContext(fromFloorId, fromIndex, toFloorId, toIndex)
    if not XTool.IsNumberValid(toFloorId) or not XTool.IsNumberValid(toIndex) then
        return nil, nil
    end
    if toFloorId == fromFloorId and toIndex == fromIndex then
        return nil, nil
    end
    -- 不可放入的工位不做预览，避免展示不会发生的结果
    if not self:CanDropWorkPos(fromFloorId, fromIndex, toFloorId, toIndex) then
        return nil, nil
    end
    local override = self:_MakeSwapOverride(fromFloorId, fromIndex, toFloorId, toIndex)
    -- 换位双方共用一份重算结果，条件系数本就是全角色一起算的
    return override, self:BuildPreviewSkillRatios(override)
end

--- 拖动预览：只展示源工位所在分区内，受换位影响的员工技能生效状态
--- 目标工位有员工时对方也会被换位，故双方各自成条
---@return XSkyTowerSkillEffectItem[]
function XSkyTowerControl:GetDragSkillEffectPreview(fromFloorId, fromIndex, toFloorId, toIndex)
    local fromCharacterId = self:GetCharacterId(fromFloorId, fromIndex)
    local floorGroupId = self:GetFloorGroupIdByFloorId(fromFloorId)
    -- 拖动不能跨分区，跨区目标按无效落点处理，不构造不会发生的换位预览
    if XTool.IsNumberValid(toFloorId) and self:GetFloorGroupIdByFloorId(toFloorId) ~= floorGroupId then
        return self:_GetStaffSkillEffectList(fromCharacterId, fromFloorId, fromIndex, nil, nil, nil, nil)
    end
    local override, previewRatios = self:_MakeDragPreviewContext(fromFloorId, fromIndex, toFloorId, toIndex)
    local hasTarget = override ~= nil
    local list = self:_GetStaffSkillEffectList(fromCharacterId, fromFloorId, fromIndex, toFloorId, toIndex, override, previewRatios)
    if not hasTarget then
        return list
    end
    local toCharacterId = self:GetCharacterId(toFloorId, toIndex)
    if XTool.IsNumberValid(toCharacterId) and toCharacterId ~= fromCharacterId then
        local otherList = self:_GetStaffSkillEffectList(toCharacterId, toFloorId, toIndex, fromFloorId, fromIndex, override, previewRatios)
        for _, item in ipairs(otherList) do
            table.insert(list, item)
        end
    end
    self:_AppendAffectedStaffSkillEffect(list, override, previewRatios, fromCharacterId, toCharacterId, floorGroupId)
    return list
end

--- 换位波及到的第三方员工技能状态：光环与邻位条件会让没被拖动的角色也跟着变
--- 只收拖动分区内状态真的变了的，不展示其它分区的角色
---@param list XSkyTowerSkillEffectItem[] 输出列表
---@param override table 换位后的布局override
---@param previewRatios table<number, table<number, number>> 换位后的条件系数
---@param floorGroupId number 拖动源工位所在分区
function XSkyTowerControl:_AppendAffectedStaffSkillEffect(list, override, previewRatios, fromCharacterId, toCharacterId, floorGroupId)
    local marked = { [fromCharacterId] = true, [toCharacterId] = true }
    for _, location in ipairs(self:_GetAllWorkPosLocations()) do
        if self:GetFloorGroupIdByFloorId(location.FloorId) == floorGroupId then
            local characterId = self:GetCharacterId(location.FloorId, location.Index)
            if XTool.IsNumberValid(characterId) and not marked[characterId] then
                -- 先过滤分区再去重，通用角色只按本分区内遇到的第一个位置算一次
                marked[characterId] = true
                for _, item in ipairs(self:_GetStaffSkillEffectList(characterId, location.FloorId, location.Index, location.FloorId, location.Index, override, previewRatios)) do
                    if item.State == XMVCA.XSkyTower.SkillEffectState.WillActive or item.State == XMVCA.XSkyTower.SkillEffectState.WillDeactivate then
                        table.insert(list, item)
                    end
                end
            end
        end
    end
end

--- 技能生效状态的富文本（技能描述 + 带色状态文案）
---@param skillId number|nil
---@param state number XMVCA.XSkyTower.SkillEffectState
---@return string
function XSkyTowerControl:GetSkillEffectStateDesc(skillId, state)
    if not XTool.IsNumberValid(skillId) then
        return ""
    end
    local isActive = state == XMVCA.XSkyTower.SkillEffectState.Active or state == XMVCA.XSkyTower.SkillEffectState.WillActive
    local stateText = self:GetClientConfigValue("SkillEffectStateText", state)
    local desc = self:GetCharacterSkillDesc(skillId)
    -- 状态文案未配表时只展示技能描述，不拼空的color标签
    if string.IsNilOrEmpty(stateText) then
        return desc or ""
    end
    return self:GetClientConfigText("SkillEffectStateDesc", isActive and 1 or 2, desc, stateText)
end
--endregion

return XSkyTowerControl

---@class XSkyTowerSharedSkill
---@field SkillId number
---@field Ratio number 条件系数万分比
---@field FromCharacterId number 发出这个技能的角色

---@class XSkyTowerSkillEffectItem
---@field CharacterId number
---@field SkillId number
---@field State number 生效状态，取XMVCA.XSkyTower.SkillEffectState
