-- 4.9 天平配平算法纯逻辑层（A 层）
-- 解耦 C# accessor/UI/运行时：入参为结构化数据（mass 值/砝码行），不读 GetBalanceMass/ReformBalanceConfig
-- 供 XReformBalanceModel 包装（加状态 + accessor 读）+ UI 单向消费
-- 封存时随 Balance 夹一并删除
-- 源：需求案 §三天平规则 + 常量揭示（ReformBalanceConfig：普通配平差异10%/完美配平+10%）
-- 继承 XClass（工程整体风格，非 plain module 静态写法）；根类无 MVCA 依赖，New() 独立可用
local XReformBalanceLogic = XClass(nil, "XReformBalanceLogic")

-- 配平三档结果（callers 用 BalanceResult.Xxx 而非字面量，避免魔法数字）
-- 封存模块内部枚举：file-local + 类字段暴露（不入 XMVCA.EnumConst，封存时不污染全局）
local BalanceResult = {
    Unbalanced = 0,  -- 未配平（差异>阈值）
    Normal = 1,      -- 普通配平（0<差异≤阈值）
    Perfect = 2,     -- 完美配平（差异=0）
}
XReformBalanceLogic.BalanceResult = BalanceResult

-- 质量难度档结果（代价总质量 vs DifficultyMassThresholds 阶梯判定）
-- A 解读：thresholds[1]→普通档(buff1), [2]→困难档(buff2), [3]→噩梦档(buff3)；基础态(无满足)→普通档
-- buff 选取属战斗端/表现层（算法外），本 enum 仅判档位
local DifficultyResult = {
    Normal = 0,    -- 普通档（含基础态 costTotal<thresholds[1] 与 thresholds[1]≤costTotal<thresholds[2]）
    Hard = 1,      -- 困难档（thresholds[2]≤costTotal<thresholds[3]）
    Nightmare = 2, -- 噩梦档（costTotal≥thresholds[3]）
}
XReformBalanceLogic.DifficultyResult = DifficultyResult

-- 天平倾斜档（驱动 Tab 动效停在哪一刻；负值我方沉，正值敌方沉）
local TiltResult = {
    WishSevere = -2, -- 我方质量大幅超出
    WishSlight = -1, -- 我方质量小幅超出
    Balanced = 0,    -- 差异在普通配平阈值内
    CostSlight = 1,  -- 敌方质量小幅超出
    CostSevere = 2,  -- 敌方质量大幅超出
}
XReformBalanceLogic.TiltResult = TiltResult

-- 羁绊触发方式（对齐服务端 ReformBalanceBondTriggerMode enum，两端口径一致）
-- All=1：RequiredCharacterIds 与 RequiredAffixIds 两组条件需全部满足（空组视为满足 / vacuous true）
-- Any=2：任意一个所需角色或所需词缀满足即触发（single-OR，空组贡献 false）
local BondTriggerMode = {
    All = 1,
    Any = 2,
}
XReformBalanceLogic.BondTriggerMode = BondTriggerMode

-- 砝码总质量求和（massValues 已按 WeightSide 分好侧的砝码质量数组）
---@param massValues number[]|nil
---@return number
function XReformBalanceLogic:SumMass(massValues)
    local sum = 0
    if massValues then
        for index = 1, #massValues do
            sum = sum + (massValues[index] or 0)
        end
    end
    return sum
end

-- 质量差异 = |wishTotal - costTotal| / wishTotal（0~1）
-- wishTotal<=0 时无愿望砝码或分母非法，返回 0（配平无意义，交 JudgeBalance 判未配平）
---@param wishTotal number
---@param costTotal number
---@return number
function XReformBalanceLogic:CalcMassDiff(wishTotal, costTotal)
    local wishTotal = wishTotal or 0
    local costTotal = costTotal or 0
    if wishTotal <= 0 then
        return 0
    end
    return math.abs(wishTotal - costTotal) / wishTotal
end

-- 配平档判定
-- normalThreshold: 普通配平差异阈值（0~1，如 0.1）
-- 差异=0→完美，0<差异≤阈值→普通，差异>阈值→未配平；wishTotal<=0→未配平（除零兜底）
---@param wishTotal number
---@param costTotal number
---@param normalThreshold number 0~1
---@return number  XReformBalanceLogic.BalanceResult
function XReformBalanceLogic:JudgeBalance(wishTotal, costTotal, normalThreshold)
    local wishTotal = wishTotal or 0
    if wishTotal <= 0 then
        return BalanceResult.Unbalanced
    end
    local diff = self:CalcMassDiff(wishTotal, costTotal)
    if diff == 0 then
        return BalanceResult.Perfect
    end
    if diff <= (normalThreshold or 0) then
        return BalanceResult.Normal
    end
    return BalanceResult.Unbalanced
end

-- 天平倾斜档判定（差异在普通阈值内视为平衡，超出严重阈值为大幅倾斜）
-- normalThreshold / severeThreshold: 0~1
---@param wishTotal number
---@param costTotal number
---@param normalThreshold number
---@param severeThreshold number
---@return number XReformBalanceLogic.TiltResult
function XReformBalanceLogic:JudgeTilt(wishTotal, costTotal, normalThreshold, severeThreshold)
    local wishTotal = wishTotal or 0
    local costTotal = costTotal or 0
    -- 单侧为空按大幅倾斜处理：CalcMassDiff 对 wishTotal<=0 返回 0，会被误判成平衡
    if wishTotal <= 0 or costTotal <= 0 then
        if wishTotal == costTotal then
            return TiltResult.Balanced
        end
        return wishTotal > costTotal and TiltResult.WishSevere or TiltResult.CostSevere
    end
    local diff = self:CalcMassDiff(wishTotal, costTotal)
    if diff <= (normalThreshold or 0) then
        return TiltResult.Balanced
    end
    local isSevere = diff > (severeThreshold or 0)
    if wishTotal > costTotal then
        return isSevere and TiltResult.WishSevere or TiltResult.WishSlight
    end
    return isSevere and TiltResult.CostSevere or TiltResult.CostSlight
end

-- 完美配平通关后愿望总质量提升（结算侧 utility，非配平判定算法本体）-- 仅困难模式完美配平通关触发；普通模式完美配平走 buff（战斗端，算法外）
-- 完美+10%累积/跨关卡/上限属结算存档（算法外），本函数仅算单次 boost
-- perfectBoostPct: 提升百分比（0~1，如 0.1=+10%）；boosted = wishTotal * (1 + perfectBoostPct)
---@param wishTotal number
---@param perfectBoostPct number
---@return number
function XReformBalanceLogic:ApplyPerfectBoost(wishTotal, perfectBoostPct)
    local wishTotal = wishTotal or 0
    local perfectBoostPct = perfectBoostPct or 0
    return wishTotal * (1 + perfectBoostPct)
end

-- 质量难度档判定（配平判定算法·代价质量侧）
-- thresholds: Stage.DifficultyMassThresholds（int[3] 升序，A 解读 [1]→普通档/[2]→困难档/[3]→噩梦档）
-- 取最高满足档（costTotal≥thresholds[index] 即满足档 index，取最大 index）；基础态（无满足）→普通档
-- buff 选取（buff1/2/3）属战斗端（算法外），本函数仅判档位
---@param costTotal number
---@param thresholds number[]|nil
---@return number  XReformBalanceLogic.DifficultyResult
function XReformBalanceLogic:JudgeDifficulty(costTotal, thresholds)
    local costTotal = costTotal or 0
    if not thresholds or #thresholds == 0 then
        return DifficultyResult.Normal
    end
    -- 倒序取最高满足档：[3]→Nightmare, [2]→Hard, [1]→Normal(普通档)
    for index = #thresholds, 1, -1 do
        local threshold = thresholds[index]
        if threshold and costTotal >= threshold then
            if index >= 3 then
                return DifficultyResult.Nightmare
            elseif index == 2 then
                return DifficultyResult.Hard
            else
                return DifficultyResult.Normal
            end
        end
    end
    return DifficultyResult.Normal  -- 基础态普通档
end

-- 最低质量门槛判定（进关条件·愿望质量侧）
-- wishTotal: 当前愿望砝码总质量；minQuality: Stage.MinQuality（关卡目标愿望质量下限）
-- 达标（wishTotal >= minQuality）→ true（允许进关）；未达 → false（UI 飘字"请继续添加砝码…"拦截）
-- 实时纯函数：caller 传当前值即时返，不存字段；与现网 IsEnableBtnEnter 并列（UI 自合两条件，不并入/不侵入）
---@param wishTotal number
---@param minQuality number
---@return boolean
function XReformBalanceLogic:IsMinQualityMet(wishTotal, minQuality)
    local wishTotal = wishTotal or 0
    local minQuality = minQuality or 0
    return wishTotal >= minQuality
end

-- 莱亚成长质量取值
-- massRow: 砝码行 { DefaultMass, UnlockStageIds[], MassValues[] }（UnlockStageIds[index]/Values[index] 按下标对应）
-- satisfiedConditions: table<number, boolean> 已通关关卡id 集合（UnlockStageIds 配置为通关关卡id）
-- 取已满足条件中最高下标对应的 MassValues[index]（莱亚随通关越来越重，单调升序），否则 DefaultMass
-- 字段名对齐 XTable.lua（XTableReformBalanceMass），非 .stab 源名 MassChangeConditions
---@param massRow table
---@param satisfiedConditions table<number, boolean>|nil
---@return number
function XReformBalanceLogic:ResolveMass(massRow, satisfiedConditions)
    if not massRow then
        return 0
    end
    local conditions = massRow.UnlockStageIds
    local values = massRow.MassValues
    if conditions and values and satisfiedConditions then
        local hitIndex = 0
        for index = 1, #conditions do
            local condId = conditions[index]
            if condId and satisfiedConditions[condId] then
                hitIndex = index
            end
        end
        if hitIndex > 0 and values[hitIndex] ~= nil then
            return values[hitIndex]
        end
    end
    return massRow.DefaultMass or 0
end

-- 羁绊触发判定（4.9 天平·角色羁绊，A 层纯逻辑）
-- bondRow: XTableReformBalanceBond { Id, RequiredCharacterIds[], RequiredAffixIds[], UnlockedAffixIds[], TriggerMode }
-- selectedCharacterIds: table<id, true>|nil 当前已选角色集
-- selectedAffixIds: table<id, true>|nil 当前已选我方词缀集
-- 触发规则（对齐服务端 ReformBalanceBondTriggerMode enum，两端口径一致）：
--   All(1)：RequiredCharacterIds 与 RequiredAffixIds 两组条件需全部满足（空组视为满足 / vacuous true）
--   Any(2)：任意一个所需角色或所需词缀满足即触发（single-OR，空组贡献 false）
-- 双侧均无条件（两张表都空）→ 防空误触 false
-- TriggerMode 缺失/非法（非 1/2）→ 配置错误，保守不触发（不误解锁）
-- 升级候选绑"词缀侧参与触发"：All=词缀组全中、Any=词缀任一中 → 输出 RequiredAffixIds；解锁绑任意触发 → 输出 UnlockedAffixIds
-- 仅判定 + 透出候选；实际升级（描述切换/效果加成）/解锁（入砝码池）属下游战斗端，本函数不应用
---@param bondRow table
---@param selectedCharacterIds table<number, boolean>|nil
---@param selectedAffixIds table<number, boolean>|nil
---@return boolean triggered
---@return number[]|nil upgradedAffixIds  词缀侧参与触发时输出 RequiredAffixIds（所需词缀升级候选）
---@return number[]|nil unlockedAffixIds   命中时输出 UnlockedAffixIds（解锁词缀候选）
function XReformBalanceLogic:JudgeBond(bondRow, selectedCharacterIds, selectedAffixIds)
    if not bondRow then
        return false, nil, nil
    end
    local charIds = bondRow.RequiredCharacterIds
    local affixIds = bondRow.RequiredAffixIds
    local hasCharCond = charIds ~= nil and #charIds > 0
    local hasAffixCond = affixIds ~= nil and #affixIds > 0
    -- 双侧均无条件 → 防空误触
    if not hasCharCond and not hasAffixCond then
        return false, nil, nil
    end

    local mode = bondRow.TriggerMode
    local triggered = false
    local affixTriggered = false
    if mode == BondTriggerMode.All then
        -- All：两组全满足（空组 vacuous true）
        local charAllHit = self:_BondAllInSet(charIds, selectedCharacterIds)
        local affixAllHit = self:_BondAllInSet(affixIds, selectedAffixIds)
        triggered = charAllHit and affixAllHit
        affixTriggered = hasAffixCond and affixAllHit
    elseif mode == BondTriggerMode.Any then
        -- Any：任一所需角色或所需词缀命中
        local charAnyHit = self:_BondAnyInSet(charIds, selectedCharacterIds)
        local affixAnyHit = self:_BondAnyInSet(affixIds, selectedAffixIds)
        triggered = charAnyHit or affixAnyHit
        affixTriggered = hasAffixCond and affixAnyHit
    else
        -- TriggerMode 缺失/非法（配置应设 All/Any），保守不触发
        return false, nil, nil
    end

    if not triggered then
        return false, nil, nil
    end
    local upgradedAffixIds = affixTriggered and bondRow.RequiredAffixIds or nil
    local unlockedAffixIds = bondRow.UnlockedAffixIds
    return true, upgradedAffixIds, unlockedAffixIds
end

-- 批量判定（关卡多 Bond 并存，逐行判定，返回命中 Bond 的效果候选列表）
---@param bondRows table[]|nil
---@param selectedCharacterIds table<number, boolean>|nil
---@param selectedAffixIds table<number, boolean>|nil
---@return table[]  [{ BondId, UpgradedAffixIds, UnlockedAffixIds }]
function XReformBalanceLogic:JudgeBonds(bondRows, selectedCharacterIds, selectedAffixIds)
    local hits = {}
    if not bondRows then
        return hits
    end
    for index = 1, #bondRows do
        local bondRow = bondRows[index]
        local triggered, upgradedAffixIds, unlockedAffixIds = self:JudgeBond(bondRow, selectedCharacterIds, selectedAffixIds)
        if triggered then
            hits[#hits + 1] = {
                BondId = bondRow.Id,
                UpgradedAffixIds = upgradedAffixIds,
                UnlockedAffixIds = unlockedAffixIds,
            }
        end
    end
    return hits
end

-- 羁绊判定 helper（All 模式用）：ids 全在 set 中
-- 空 ids → true（vacuous 满足，All 模式该侧无要求）；非空 ids + nil set → false
---@param ids number[]|nil
---@param set table<number, boolean>|nil
---@return boolean
function XReformBalanceLogic:_BondAllInSet(ids, set)
    if not ids or #ids == 0 then
        return true
    end
    if not set then
        return false
    end
    for index = 1, #ids do
        if not set[ids[index]] then
            return false
        end
    end
    return true
end

-- 羁绊判定 helper（Any 模式用）：ids 任一在 set 中（空 ids → false，无单元素可命中）
---@param ids number[]|nil
---@param set table<number, boolean>|nil
---@return boolean
function XReformBalanceLogic:_BondAnyInSet(ids, set)
    if not ids or #ids == 0 then
        return false
    end
    if not set then
        return false
    end
    for index = 1, #ids do
        if set[ids[index]] then
            return true
        end
    end
    return false
end

return XReformBalanceLogic
