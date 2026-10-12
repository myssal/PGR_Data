local ConditionDefine = require("XUi/XUiPacMan2/XUiPacMan2ConditionDefine")
local ConditionField = require("XUi/XUiPacMan2/XUiPacMan2ConditionField")

local ChangeType = ConditionDefine.ChangeType
local SignalType = CS.XPacMan2.XPacMan2SignalType
local EntityType = CS.XPacMan2.XPacMan2EntityEnum
local EventDefine = require("XUi/XUiPacMan2/XUiPacMan2EventDefine")
local CountdownSource = EventDefine.CountdownSource
-- 将Lua内部的倒计时来源枚举转换为策划使用的条件字段。
-- 每次倒计时完成只产生其中一个字段。
local CountdownFieldBySource = {
    [CountdownSource.Opening] = ConditionField.OpeningCountdownCompleted,
    [CountdownSource.DamageRecovery] = ConditionField.DamageRecoveryCountdownCompleted,
    [CountdownSource.Restart] = ConditionField.RestartCountdownCompleted,
}

---@class XUiPacMan2ConditionContextUpdater
---将C#业务信号及Lua主流程通知转换成条件系统能够识别的变化信息。
---
---职责：
---1. 初始化时主动从GameManager读取一次状态快照；
---2. 理解每种SignalType携带的参数；
---3. 将状态信号携带的新值写入Context；
---4. 为瞬时事件直接生成Triggered；
---5. 将单条C#信号或Lua流程通知产生的变化信息返回给EventRuntime；
---6. EventRuntime在本次相关数据处理完毕后，将完整变化交给Matcher。
---
---协议：
---1. 值变化信号携带oldValue和newValue；
---2. Context保存最新状态，并检查Lua快照是否与C#同步；
---3. Matcher使用信号携带的OldValue和NewValue判断变化类条件；
---4. Triggered信号不写入Context；
---5. Value表示Triggered事件用于条件匹配的主要值；
local XUiPacMan2ConditionContextUpdater = XClass(nil, "XUiPacMan2ConditionContextUpdater")

---计算玩家当前豆子收集进度。
---返回0到100之间的百分比数值，策划表直接填写30、60、80。
---@param orbCount number
---@param orbTotal number
---@return number
local function CalculateOrbProgress(orbCount, orbTotal)
    if orbTotal == nil or orbTotal <= 0 then
        return 0
    end

    local progress = orbCount / orbTotal * 100
    return math.min(math.max(progress, 0), 100)
end

---将单个字段变化加入本次信号的变化集合。
---@param fieldChanges table
---@param field string
---@param fieldChange table|nil
local function AddFieldChange(fieldChanges, field, fieldChange)
    if fieldChange then
        fieldChanges[field] = fieldChange
    end
end

---@param conditionContext XUiPacMan2ConditionContext
function XUiPacMan2ConditionContextUpdater:Ctor(conditionContext)
    if not conditionContext then
        XLog.Error("[PacMan2ConditionContextUpdater] conditionContext为空")
        return
    end

    self._ConditionContext = conditionContext
    -- 本Updater实例复用的单次通知变化集合。
    -- 每次Apply开始时清空，调用方必须在下一次Apply前完成读取或合并。
    -- 只复用外层集合，不复用其中的字段变化记录。
    self._FieldChanges = {}

    -- 每种C#信号在这里对应一个转换函数。
    self._SignalHandlers = {
        [SignalType.HpChanged] = self._OnHpChanged,
        [SignalType.ItemChanged] = self._OnItemChanged,
        [SignalType.PlayerKillGhostPhaseChanged] = self._OnPlayerKillGhostPhaseChanged,
        [SignalType.ExitEnabled] = self._OnExitEnabled,
        [SignalType.KillChanged] = self._OnKillChanged,
        [SignalType.OrbChanged] = self._OnOrbChanged,
        [SignalType.PortalEntered] = self._OnPortalEntered,
        [SignalType.KillItemActivated] = self._OnKillItemActivated,
    }
    -- C#只通知“成功拾取了哪种道具”。
    -- Updater负责将这次拾取转换为条件系统内部的累计次数变化。
    self._ItemPickupCountFields = {
        [EntityType.GoldOrb] = ConditionField.HealItemPickupCount,
        [EntityType.SpeedUpPlayer] = ConditionField.SpeedItemPickupCount,
        [EntityType.TurnIntoFood] = ConditionField.KillItemPickupCount,
    }
end

---开始新关卡时清空上一关的临时变化集合和条件状态。
function XUiPacMan2ConditionContextUpdater:BeginStage()
    table.clear(self._FieldChanges)
    self._ConditionContext:Reset()
end

---主动从GameManager读取一次条件系统初始状态。
---
---这是所有状态字段的统一初始化入口。
---以后新增一个能够被条件读取的C#状态字段时，应在这里补充初始值。
---
---初始化只建立状态基线，不产生变化，不触发Matcher。
---@param gameManager XPacMan2.XPacMan2GameManager
---@return boolean
function XUiPacMan2ConditionContextUpdater:InitializeFromGameManager(gameManager)
    if not gameManager then
        XLog.Error("[PacMan2ConditionContextUpdater] InitializeFromGameManager gameManager为空")
        return false
    end

    if not gameManager.Player then
        XLog.Error("[PacMan2ConditionContextUpdater] InitializeFromGameManager Player为空")
        return false
    end
    
    local playerHp = gameManager:GetPlayerHp()
    local playerOrbCount = gameManager:GetOrbs()
    local orbTotal = gameManager.OrbsTotal

    self._ConditionContext:Initialize({
        [ConditionField.PlayerHp] = playerHp,
        [ConditionField.PlayerOrbCount] = playerOrbCount,
        [ConditionField.PlayerOrbProgress] = CalculateOrbProgress(playerOrbCount, orbTotal),
        [ConditionField.KillCount] = gameManager.Kills,


        -- Lua事件系统自身维护的累计状态。
        
        [ConditionField.DamageTakenCount] = 0,
        [ConditionField.DamageTakenAmount] = 0,
        [ConditionField.PlayerKillGhostPhaseActive] = gameManager.IsPlayerKillGhostPhase,
        -- 以下计数是事件条件系统根据C#拾取通知维护的本关累计状态。
        [ConditionField.HealItemPickupCount] = 0,
        [ConditionField.SpeedItemPickupCount] = 0,
        [ConditionField.KillItemPickupCount] = 0,
        [ConditionField.PortalEnterCount] = 0,
    })

    return true
end

---处理业务Transaction中的一条C# Signal。
---Signal.Args是从0开始索引的C# object[]。
---各Signal Handler负责按照自身参数协议读取数组内容。
---返回的fieldChanges为复用的临时集合，只保证在下一次Apply调用前有效。
---调用方必须立即读取或合并，不得保存该外层集合用于延迟执行。
---@param signal XPacMan2.XPacMan2GameSignal
---@return table|nil fieldChanges
---@return table|nil runtimeInfo
function XUiPacMan2ConditionContextUpdater:ApplySignal(signal)
    -- Handler共用同一张临时表，每条Signal处理前清空上一条的字段引用。
    table.clear(self._FieldChanges)

    if not signal then
        XLog.Error("[PacMan2ConditionContextUpdater] signal为空")
        return nil
    end

    local signalType = signal.SignalType
    local handler = self._SignalHandlers[signalType]

    -- 允许事务中存在条件系统暂时不关心的Signal。
    if not handler then
        return nil
    end

    return handler(self, signal.Args)
end

---创建一个瞬时字段变化。
---该变化只服务于本次Matcher检查，不写入Context。
---@param value any|nil
---@return table fieldChange
function XUiPacMan2ConditionContextUpdater:_CreateTriggeredFieldChange(value)
    return {
        Type = ChangeType.Triggered,
        Value = value,
    }
end


---HpChanged参数协议：oldHp, newHp。
---PlayerHp保存玩家当前生命值。
---DamageTakenCount表示本关发生有效扣血的次数。
---DamageTakenAmount表示本关累计实际损失的生命值。
---
---一次HpChanged无论损失几点生命，DamageTakenCount都只增加1。
---DamageTakenAmount按照oldHp与newHp的实际差值增加。
---回血只更新PlayerHp，不会减少两个累计字段。
---Args参数协议：
---[0] oldHp：变化前血量；
---[1] newHp：变化后血量。
---@param args System.Array
---@return table|nil fieldChanges
---@return table runtimeInfo
function XUiPacMan2ConditionContextUpdater:_OnHpChanged(args)
    local oldHp = args[0]
    local newHp = args[1]
    if oldHp == nil or newHp == nil then
        XLog.Error("[PacMan2ConditionContextUpdater] HpChanged参数不完整, oldHp=" .. tostring(oldHp) .. ", newHp=" .. tostring(newHp))
        return nil
    end

    local fieldChanges = self._FieldChanges
    local hpChange = self._ConditionContext:Update(ConditionField.PlayerHp, oldHp, newHp)
    AddFieldChange(fieldChanges, ConditionField.PlayerHp, hpChange)

    if newHp < oldHp then
        local oldDamageTakenCount = self._ConditionContext:Get(ConditionField.DamageTakenCount) or 0
        local newDamageTakenCount = oldDamageTakenCount + 1
        local countChange = self._ConditionContext:Update(ConditionField.DamageTakenCount, oldDamageTakenCount, newDamageTakenCount)
        AddFieldChange(fieldChanges, ConditionField.DamageTakenCount, countChange)

        local oldDamageTakenAmount = self._ConditionContext:Get(ConditionField.DamageTakenAmount) or 0
        local newDamageTakenAmount = oldDamageTakenAmount + oldHp - newHp
        local amountChange = self._ConditionContext:Update(ConditionField.DamageTakenAmount, oldDamageTakenAmount, newDamageTakenAmount)
        AddFieldChange(fieldChanges, ConditionField.DamageTakenAmount, amountChange)
    end

    if next(fieldChanges) == nil then
        return nil
    end

    local runtimeInfo = {
        OldHp = oldHp,
        NewHp = newHp,
    }

    return fieldChanges, runtimeInfo
end

---KillChanged参数协议：oldKills, newKills, ghostType。
---KillCount保存玩家本关累计成功击杀的怪物数量。
---
---C#中的Kills是权威状态，因此由C#发送明确的新旧值。
---策划可以使用Increased判断“每次击杀”，
---也可以使用Equal或GreaterEqual判断累计击杀数量。
---Args参数协议：
---[0] 旧累计击杀数。
---[1] 新累计击杀数。
---[2] 被击杀怪物的原始类型，本处理器不使用。
---@param args System.Array
---@return table|nil fieldChanges
---@return table|nil runtimeInfo
function XUiPacMan2ConditionContextUpdater:_OnKillChanged(args)
    local oldKills = args[0]
    local newKills = args[1]
    if oldKills == nil or newKills == nil then
        XLog.Error("[PacMan2ConditionContextUpdater] KillChanged参数不完整, oldKills=" .. tostring(oldKills) .. ", newKills=" .. tostring(newKills))
        return nil
    end

    local fieldChanges = self._FieldChanges
    local killChange = self._ConditionContext:Update(ConditionField.KillCount, oldKills, newKills)
    AddFieldChange(fieldChanges, ConditionField.KillCount, killChange)

    if next(fieldChanges) == nil then
        return nil
    end

    local runtimeInfo = {
        OldKills = oldKills,
        NewKills = newKills,
    }

    return fieldChanges, runtimeInfo
end

---ItemChanged表示玩家成功拾取了一次道具。
---参数协议：itemType。
---
---C#只报告本次拾取的道具类型，不负责维护条件系统的累计次数。
---Updater根据道具类型找到对应计数字段，并生成一次ValueChanged。
---
---例如第一次拾取回血道具：
---HealItemPickupCount从0变化为1。
---
---这样策划既可以使用Increased判断“每次拾取”，
---也可以使用Equal判断“第几次拾取”。
---Args参数协议：
---[0] itemType：本次拾取的道具类型。
---@param args System.Array
---@return table|nil fieldChanges
---@return table|nil runtimeInfo
function XUiPacMan2ConditionContextUpdater:_OnItemChanged(args)
    local itemType = args[0]
    if itemType == nil then
        XLog.Error("[PacMan2ConditionContextUpdater] ItemChanged缺少itemType")
        return nil
    end

    local countField = self._ItemPickupCountFields[itemType]

    -- 部分道具仅有统计需求，暂时没有策划条件。
    -- 条件系统忽略不关注的类型，不影响独立统计对象接收同一条信号。
    if not countField then
        return nil
    end

    local oldCount = self._ConditionContext:Get(countField) or 0
    local newCount = oldCount + 1
    local fieldChanges = self._FieldChanges
    local countChange = self._ConditionContext:Update(countField, oldCount, newCount)
    AddFieldChange(fieldChanges, countField, countChange)

    if next(fieldChanges) == nil then
        return nil
    end

    local runtimeInfo = {
        ItemType = itemType,
        PickupCount = newCount,
    }

    return fieldChanges, runtimeInfo
end

---更新玩家反杀阶段的持续状态，并产生进入或退出的瞬时Trigger。
---参数协议：oldValue, newValue。
---
---PlayerKillGhostPhaseActive保存在Context中，
---用于表达“当前正处于反杀阶段”并与其他条件组合。
---
---PlayerKillGhostPhaseEntered和PlayerKillGhostPhaseExited是瞬时字段，
---用于表达“刚刚进入”或者“刚刚退出”。
---Args参数协议：
---[0] oldValue：变化前是否处于反杀阶段；
---[1] newValue：变化后是否处于反杀阶段。
---@param args System.Array
---@return table|nil fieldChanges
---@return table|nil runtimeInfo
function XUiPacMan2ConditionContextUpdater:_OnPlayerKillGhostPhaseChanged(args)
    local oldValue = args[0]
    local newValue = args[1]
    if oldValue == nil or newValue == nil then
        XLog.Error("[PacMan2ConditionContextUpdater] PlayerKillGhostPhaseChanged参数不完整, oldValue=" .. tostring(oldValue) .. ", newValue=" .. tostring(newValue))
        return nil
    end

    if oldValue == newValue then
        XLog.Warning("[PacMan2ConditionContextUpdater] PlayerKillGhostPhaseChanged状态没有发生变化, value=" .. tostring(newValue))
        return nil
    end

    local fieldChanges = self._FieldChanges
    local activeChange = self._ConditionContext:Update(ConditionField.PlayerKillGhostPhaseActive, oldValue, newValue)
    AddFieldChange(fieldChanges, ConditionField.PlayerKillGhostPhaseActive, activeChange)

    local triggeredField

    if newValue then
        triggeredField = ConditionField.PlayerKillGhostPhaseEntered
    else
        triggeredField = ConditionField.PlayerKillGhostPhaseExited
    end

    local triggeredChange = self:_CreateTriggeredFieldChange()
    AddFieldChange(fieldChanges, triggeredField, triggeredChange)

    local runtimeInfo = {
        OldValue = oldValue,
        NewValue = newValue,
    }

    return fieldChanges, runtimeInfo
end

---OrbChanged参数协议：oldOrbs, newOrbs, orbsTotal。
---一条消息同时更新玩家豆子数量和豆子收集进度。
---
---PlayerOrbCount用于配置具体数量条件。
---PlayerOrbProgress用于配置30%、60%、80%等比例条件。
---Args参数协议：
---[0] oldOrbs：变化前玩家持有豆子数量；
---[1] newOrbs：变化后玩家持有豆子数量；
---[2] orbsTotal：本关豆子总量。
---@param args System.Array
---@return table|nil fieldChanges
---@return table|nil runtimeInfo
function XUiPacMan2ConditionContextUpdater:_OnOrbChanged(args)
    local oldOrbs = args[0]
    local newOrbs = args[1]
    local orbsTotal = args[2]
    if oldOrbs == nil or newOrbs == nil or orbsTotal == nil then
        XLog.Error("[PacMan2ConditionContextUpdater] OrbChanged参数不完整, oldOrbs=" .. tostring(oldOrbs) .. ", newOrbs=" .. tostring(newOrbs) .. ", orbsTotal=" .. tostring(orbsTotal))
        return nil
    end

    local fieldChanges = self._FieldChanges

    local orbCountChange = self._ConditionContext:Update(ConditionField.PlayerOrbCount, oldOrbs, newOrbs)
    AddFieldChange(fieldChanges, ConditionField.PlayerOrbCount, orbCountChange)

    local oldProgress = CalculateOrbProgress(oldOrbs, orbsTotal)
    local newProgress = CalculateOrbProgress(newOrbs, orbsTotal)
    local progressChange = self._ConditionContext:Update(ConditionField.PlayerOrbProgress, oldProgress, newProgress)
    AddFieldChange(fieldChanges, ConditionField.PlayerOrbProgress, progressChange)

    if next(fieldChanges) == nil then
        return nil
    end

    local runtimeInfo = {
        OldOrbCount = oldOrbs,
        NewOrbCount = newOrbs,
        OrbTotal = orbsTotal,
        OldOrbProgress = oldProgress,
        NewOrbProgress = newProgress,
    }

    return fieldChanges, runtimeInfo
end

---撤离点首次开启。
---该信号属于瞬时事件，不写入ConditionContext。
---@return table fieldChanges
function XUiPacMan2ConditionContextUpdater:_OnExitEnabled(args)
    local fieldChanges = self._FieldChanges
    local triggeredChange = self:_CreateTriggeredFieldChange()
    AddFieldChange(fieldChanges, ConditionField.ExitEnabled, triggeredChange)
    return fieldChanges, nil
end

---PortalEntered表示玩家成功使用了一次传送门。
---C#只报告传送发生，累计次数由Lua事件系统维护。
---@return table fieldChanges
---@return table runtimeInfo
function XUiPacMan2ConditionContextUpdater:_OnPortalEntered(args)
    local oldCount = self._ConditionContext:Get(ConditionField.PortalEnterCount) or 0
    local newCount = oldCount + 1
    local fieldChanges = self._FieldChanges
    local countChange = self._ConditionContext:Update(ConditionField.PortalEnterCount, oldCount, newCount)
    AddFieldChange(fieldChanges, ConditionField.PortalEnterCount, countChange)

    local runtimeInfo = {
        PortalEnterCount = newCount,
    }

    return fieldChanges, runtimeInfo
end

---KillItemActivated表示反杀道具刚刚整体开放，可以被玩家拾取。
---不表示玩家已经拾取道具或进入反杀阶段。
---这是瞬时事件，因此不写入ConditionContext。
---@return table fieldChanges
function XUiPacMan2ConditionContextUpdater:_OnKillItemActivated(args)
    local fieldChanges = self._FieldChanges
    local triggeredChange = self:_CreateTriggeredFieldChange()
    AddFieldChange(fieldChanges, ConditionField.KillItemActivated, triggeredChange)
    return fieldChanges, nil
end

---将Lua主流程报告的倒计时完成转换为瞬时条件。
---不写入Context，变化信息只在本次Matcher检查时有效。
---返回的fieldChanges为复用的临时集合，只保证在下一次Apply调用前有效。
---@param source number EventDefine.CountdownSource中的值
---@return table|nil fieldChanges
---@return table|nil runtimeInfo
function XUiPacMan2ConditionContextUpdater:ApplyCountdownCompleted(source)
    table.clear(self._FieldChanges)

    local field = CountdownFieldBySource[source]

    if not field then
        XLog.Error("[PacMan2ConditionContextUpdater] 未知的倒计时来源, source=" .. tostring(source))
        return nil
    end

    local fieldChanges = self._FieldChanges
    fieldChanges[field] = self:_CreateTriggeredFieldChange()

    local runtimeInfo = {
        CountdownSource = source,
    }

    return fieldChanges, runtimeInfo
end

function XUiPacMan2ConditionContextUpdater:Dispose()
    self._SignalHandlers = nil
    self._ConditionContext = nil
    self._ItemPickupCountFields = nil
    self._FieldChanges = nil
end

return XUiPacMan2ConditionContextUpdater