local XUiPacMan2GridLife = require("XUi/XUiPacMan2/XUiPacMan2GridLife")
local XUiPacMan2StarTarget = require("XUi/XUiPacMan2/XUiPacMan2StarTarget")
local XUiPacMan2MoveTo = require("XUi/XUiPacMan2/XUiPacMan2MoveTo")

-- 进度条上玩家和敌人头像的移动速度，单位为Transform.position坐标单位/秒。
-- 不影响场景中角色的移动速度。
local ProgressIconMoveSpeed = 100

-- 普通UI需要的状态字段，不依赖ConditionField。
local UiField = {
    PlayerHp = "PlayerHp",
    PlayerOrbCount = "PlayerOrbCount",
    EnemyOrbCount = "EnemyOrbCount",
    OrbTotal = "OrbTotal",
    OrbsAttackThreshold = "OrbsAttackThreshold",
    -- 玩家豆数达到此门槛后，隐藏进度条上的撤离点标记。
    OrbsToShowKey = "OrbsToShowKey",
    -- 玩家累计击杀数，用于判断是否需要播放击杀表现。
    KillCount = "KillCount",
    -- 玩家是否处于可击杀幽灵的反杀状态，包括道具反杀和一血反杀。
    IsPlayerKillGhostPhase = "IsPlayerKillGhostPhase",

    -- 幽灵全局行为状态，保存C#的XPacMan2GhostState枚举值。
    GhostState = "GhostState",
}
local SignalType = CS.XPacMan2.XPacMan2SignalType

---@class XUiPacMan2GameUiController
---普通游戏UI控制器。
---
---职责：
---1. 保存普通UI需要显示的最终状态；
---2. 初始化、界面重新显示时主动同步状态；
---3. 完整事务处理结束后统一刷新UI。
---
---不注册全局事件，不参与条件匹配，不控制游戏流程。
local XUiPacMan2GameUiController = XClass(nil, "XUiPacMan2GameUiController")

---@param rootUi XUiPacMan2Game
function XUiPacMan2GameUiController:Ctor(rootUi)
    self._RootUi = rootUi
    self._GameManager = nil

    -- 普通UI已同步的状态。
    -- 处理事务时先收集pendingValues，收集完成后再统一更新这里。
    -- KillCount保留原Game中_LastKillAmount = 0的比较基线，
    -- 避免首次同步0时，将nil到0误判为需要播放击杀表现。
    self._Values = {
        [UiField.KillCount] = 0,
    }

    -- 消息处理函数只向pendingValues写入新值，不修改_Values，不操作控件。
    self._SignalHandlers = {
        [SignalType.HpChanged] = self._OnHpChanged,
        [SignalType.OrbChanged] = self._OnOrbChanged,
        [SignalType.EnemyOrbChanged] = self._OnEnemyOrbChanged,
        [SignalType.KillChanged] = self._OnKillChanged,
        [SignalType.PlayerKillGhostPhaseChanged] = self._OnPlayerKillGhostPhaseChanged,
        [SignalType.GhostStateChanged] = self._OnGhostStateChanged,
    }
    
    ---@type XUiPacMan2GridLife[]
    self._HpGrids = {}
    rootUi.GridLife.gameObject:SetActiveEx(false)
    -- 血量显示是否已经完成过首次同步。
    -- 这是表现层状态，不保存游戏血量，也不参与字段变化判断。
    self._HasRefreshedHp = false

    -- 进度条上的撤离点标记是否已经隐藏。
    -- 对应原Game中的_IsShowKey，只记录表现，不代表场景撤离点状态。
    -- 一旦隐藏，后续豆数减少也不重新显示。
    self._IsExitMarkerHidden = false

    -- 星级控件仍然以Game作为父节点，只把管理位置迁移到这里。
    ---@type XUiPacMan2StarTarget[]
    self._StarList = {
        XUiPacMan2StarTarget.New(rootUi.GridStar01, rootUi),
        XUiPacMan2StarTarget.New(rootUi.GridStar02, rootUi),
        XUiPacMan2StarTarget.New(rootUi.GridStar03, rootUi),
    }

    -- 星级控件使用的显示参数，由SetStarConfig按关卡创建。
    -- 后续刷新只更新IsOn，避免每次豆数变化都重新创建参数表。
    self._StarDatas = nil

    -- 保留原来的初始位置及移动速度。
    rootUi.PanelPlayer.transform.position = rootUi.StartProgress.position
    rootUi.PanelEnemy.transform.position = rootUi.EndProgress.position

    ---@type XUiPacMan2MoveTo
    self._MoverPlayer = XUiPacMan2MoveTo.New(rootUi.PanelPlayer, ProgressIconMoveSpeed)

    ---@type XUiPacMan2MoveTo
    self._MoverEnemy = XUiPacMan2MoveTo.New(rootUi.PanelEnemy, ProgressIconMoveSpeed)

    self:ResetBuffProgress()
end

---绑定关卡实例，不修改C#状态。
---已有显示状态保留，随后由Refresh同步新实例的数据。
---@param gameManager XPacMan2.XPacMan2GameManager
function XUiPacMan2GameUiController:BindGameManager(gameManager)
    self._GameManager = gameManager
end

---初始化或界面重新显示时，主动获取已迁移UI的状态。
---这里只收集数据，变化判断、状态提交和UI刷新统一交给_ApplyPendingValues。
function XUiPacMan2GameUiController:Refresh()
    if not self._GameManager then
        return
    end

    local pendingValues = {
        [UiField.PlayerHp] = self._GameManager:GetPlayerHp(),
        [UiField.PlayerOrbCount] = self._GameManager:GetOrbs(),
        [UiField.EnemyOrbCount] = self._GameManager.EnemyOrbs,
        [UiField.OrbTotal] = self._GameManager.OrbsTotal,
        [UiField.OrbsAttackThreshold] = self._GameManager.OrbsAttackThreshold,
        [UiField.OrbsToShowKey] = self._GameManager.OrbsToShowKey,
        [UiField.KillCount] = self._GameManager.Kills,
        [UiField.IsPlayerKillGhostPhase] = self._GameManager.IsPlayerKillGhostPhase,
        [UiField.GhostState] = self._GameManager:GetGhostState(),
    }

    -- 主动同步需要完整刷新控件，即使状态没有变化。
    self:_ApplyPendingValues(pendingValues, true)
end

---先收集完整事务的最终值，再统一提交并刷新普通UI。
---同一字段多次变化时，只保留最后一次收到的新值。
---不记录中间过程，不参与条件匹配。
---@param transaction XPacMan2.XPacMan2GameSignalTransaction
function XUiPacMan2GameUiController:OnGameSignalTransaction(transaction)
    if not self._GameManager then
        return
    end

    local signals = transaction.Signals
    local pendingValues

    --只收集新值，不修改当前状态，不刷新UI。
    for index = 0, signals.Length - 1 do
        local signal = signals[index]
        local handler = signal and self._SignalHandlers[signal.SignalType]

        if handler then
            -- 只在收到UI关心的消息时创建，整个事务共用这一张表。
            pendingValues = pendingValues or {}
            handler(self, signal.Args, pendingValues)
        end
    end

    if not pendingValues then
        return
    end

    -- 普通事务只刷新最终值发生变化的UI。
    self:_ApplyPendingValues(pendingValues, false)
end

---统一处理主动同步和业务事务收集到的最终值。
---直接修改传入的pendingValues：去掉未变字段，保留发生变化的字段及最终值。
---不创建额外的变化表，不保存中间过程。
---@param pendingValues table 本次收集的最终值，调用方提交后不再使用。
---@param forceRefresh boolean 是否完整刷新控件，不代表字段发生了变化。
function XUiPacMan2GameUiController:_ApplyPendingValues(pendingValues, forceRefresh)
    -- 先比较并提交全部状态，期间不刷新任何控件。
    -- 删除已有键是允许的，这里不向pendingValues添加新键。
    for field, value in pairs(pendingValues) do
        if self._Values[field] == value then
            pendingValues[field] = nil
        else
            self._Values[field] = value
        end
    end

    -- 普通事务没有实际变化时，不刷新。
    -- 主动同步即使没有变化，也需要刷新控件。
    if not forceRefresh and next(pendingValues) == nil then
        return
    end

    -- 所有状态已提交，控件读取到的都是本次最终值。
    self:_RefreshUi(pendingValues, forceRefresh)
end

---@class XUiPacMan2StarTargetData
---@field Star number 星级序号。
---@field Score number 达到该星级需要的玩家豆数。
---@field IsOn boolean 当前是否达到该星级。

---设置本关星级要求，只准备显示参数，不刷新控件。
---关卡配置完成后，由Refresh统一同步初始状态。
---@param starScores number[]
function XUiPacMan2GameUiController:SetStarConfig(starScores)
    self._StarDatas = {}

    for i = 1, #starScores do
        self._StarDatas[i] = {
            Star = i,
            Score = starScores[i],
            IsOn = false,
        }
    end
end

---使用_Values中的最终状态刷新UI。
---forceRefresh只决定是否完整刷新，不代表字段发生变化。
---@param pendingValues table 本次真正变化的字段及最终值。
---@param forceRefresh boolean 是否完整刷新已迁移UI。
function XUiPacMan2GameUiController:_RefreshUi(pendingValues, forceRefresh)
    local playerOrbChanged = pendingValues[UiField.PlayerOrbCount] ~= nil
    local enemyOrbChanged = pendingValues[UiField.EnemyOrbCount] ~= nil
    local orbCountChanged = playerOrbChanged or enemyOrbChanged

    if forceRefresh or pendingValues[UiField.PlayerHp] ~= nil then
        self:_RefreshHp()
    end

    if forceRefresh or playerOrbChanged then
        self:_RefreshStars()
    end

    -- 双方数量都已提交，整个事务只刷新一次共享进度。
    if forceRefresh or orbCountChanged or pendingValues[UiField.OrbTotal] ~= nil then
        self:_RefreshProgressBar()
    end

    if forceRefresh or orbCountChanged or pendingValues[UiField.OrbsAttackThreshold] ~= nil then
        self:_RefreshBuffProgress()
    end

    -- _ApplyPendingValues已经提交全部状态，并移除了未变化字段。
    -- 击杀数真正变化时播放一次表现，同一事务不按击杀次数重复播放。
    -- 不使用forceRefresh作为触发条件，避免界面重新显示时重复播放。
    if pendingValues[UiField.KillCount] ~= nil then
        self._RootUi:PlayKillFeedback()
    end
    
    -- 只使用本次事务提交后的最终玩家豆数。
    -- 敌人豆数变化不影响撤离点标记的显示。
    if forceRefresh or playerOrbChanged or pendingValues[UiField.OrbsToShowKey] ~= nil then
        self:_RefreshExitMarker()
    end

    -- 两个状态都已提交，统一根据本次最终值刷新背景。
    -- 必须使用~= nil判断字段是否变化，退出反杀时的false也需要处理。
    if forceRefresh or pendingValues[UiField.IsPlayerKillGhostPhase] ~= nil or pendingValues[UiField.GhostState] ~= nil then
        self:_RefreshBackground()
    end
end

---根据事务提交后的最终玩家豆数刷新星级。
function XUiPacMan2GameUiController:_RefreshStars()
    local playerOrbCount = self._Values[UiField.PlayerOrbCount]
    local starDatas = self._StarDatas
    if playerOrbCount == nil or starDatas == nil then
        return
    end

    for i = 1, #starDatas do
        local starData = starDatas[i]
        starData.IsOn = playerOrbCount >= starData.Score
    end

    local rootUi = self._RootUi
    XTool.UpdateDynamicItem(self._StarList, starDatas, rootUi.GridStar01, XUiPacMan2StarTarget, rootUi)
end

---使用已同步的最终状态刷新背景。
---背景类型及节点仍由Game管理，这里不重复保存表现状态。
function XUiPacMan2GameUiController:_RefreshBackground()
    local isPlayerKillGhostPhase = self._Values[UiField.IsPlayerKillGhostPhase]
    local ghostState = self._Values[UiField.GhostState]
    if isPlayerKillGhostPhase == nil or ghostState == nil then
        return
    end

    self._RootUi:RefreshBackgroundByState(isPlayerKillGhostPhase, ghostState)
end

---初始化星级节点位置。
---保留原来的位置计算方式，由Game在原来的流程位置调用。
function XUiPacMan2GameUiController:InitStarPosition()
    local rootUi = self._RootUi
    local startPosition = rootUi.StartPosition.position
    local endPosition = rootUi.EndPosition.position

    for i = 1, #self._StarList do
        local star = self._StarList[i]
        star.Transform.position = Vector3.Lerp(startPosition, endPosition, i / (#self._StarList + 1))
    end
end

---重置反杀道具进度的表现状态。
---只在控制器初始化及新关卡初始化时调用，普通Refresh不调用。
---不修改C#状态，不控制反杀道具是否真正开放。
function XUiPacMan2GameUiController:ResetBuffProgress()
    local rootUi = self._RootUi

    self._IsBuffActivated = false

    rootUi.PanelBuff.gameObject:SetActiveEx(true)
    rootUi.PanelBar.gameObject:SetActiveEx(true)
    rootUi.ImgBarActive.gameObject:SetActiveEx(false)
    rootUi.TxtGroup.gameObject:SetActiveEx(true)

    -- 上一关激活后会隐藏这两条进度，新关卡要恢复。
    rootUi.ImgBar1.gameObject:SetActiveEx(true)
    rootUi.ImgBar2.gameObject:SetActiveEx(true)

    rootUi.ImgBar1.fillAmount = 0
    rootUi.ImgBar2.fillAmount = 0
    rootUi.TxtGem1.text = "0"
    rootUi.TxtGemTotal1.text = "0"
end

---根据最终双方豆数刷新进度条及头像移动目标。
---保留原来的分段进度公式和移动效果，不再查询C#。
function XUiPacMan2GameUiController:_RefreshProgressBar()
    local totalScore = self._Values[UiField.OrbTotal]
    local playerScore = self._Values[UiField.PlayerOrbCount]
    local enemyScore = self._Values[UiField.EnemyOrbCount]
    if totalScore == nil or playerScore == nil or enemyScore == nil then
        return
    end

    local rootUi = self._RootUi
    local startProgressPosition = rootUi.StartProgress.position
    local endProgressPosition = rootUi.EndProgress.position

    -- 暂时复用Game中的原计算函数；该函数不查询C#。
    local playerProgress = rootUi:CalculateProgress(playerScore, totalScore)
    rootUi.ImgPlayerBar.fillAmount = playerProgress
    local playerPosition = Vector3.Lerp(startProgressPosition, endProgressPosition, playerProgress)
    self._MoverPlayer:SetTargetPosition(playerPosition)

    -- 敌人的进度和玩家是倒着算的，保留原公式。
    local enemyProgress = 1 - rootUi:CalculateProgress(totalScore - enemyScore, totalScore)
    rootUi.ImgEnemyBar.fillAmount = enemyProgress
    local enemyPosition = Vector3.Lerp(endProgressPosition, startProgressPosition, enemyProgress)
    self._MoverEnemy:SetTargetPosition(enemyPosition)
end

---根据最终双方豆数刷新反杀道具进度。
---保留原表现：达到目标后，本关保持激活显示。
---这里只控制UI，不代替C#的道具开放逻辑。
function XUiPacMan2GameUiController:_RefreshBuffProgress()
    local playerCount = self._Values[UiField.PlayerOrbCount]
    local enemyCount = self._Values[UiField.EnemyOrbCount]
    local targetCount = self._Values[UiField.OrbsAttackThreshold]
    if playerCount == nil or enemyCount == nil or targetCount == nil then
        return
    end

    local rootUi = self._RootUi

    if targetCount <= 0 then
        rootUi.PanelBuff.gameObject:SetActiveEx(false)
        return
    end

    local currentCount = playerCount + enemyCount
    rootUi.PanelBuff.gameObject:SetActiveEx(true)

    -- 总量直接从本次提交后的双方数量计算，不再保存一份重复状态。
    rootUi.TxtGem1.text = tostring(currentCount)
    rootUi.TxtGemTotal1.text = tostring(targetCount)

    if not self._IsBuffActivated then
        -- 底层绿色条表示双方总量，上层红色条覆盖敌人持有的部分。
        rootUi.ImgBar1.fillAmount = math.min(currentCount / targetCount, 1)
        rootUi.ImgBar2.fillAmount = math.min(enemyCount / targetCount, 1)

        if currentCount >= targetCount then
            self._IsBuffActivated = true

            rootUi.PanelBar.gameObject:SetActiveEx(true)
            rootUi.ImgBar1.gameObject:SetActiveEx(false)
            rootUi.ImgBar2.gameObject:SetActiveEx(false)
            rootUi.TxtGroup.gameObject:SetActiveEx(false)
            rootUi.ImgBarActive.gameObject:SetActiveEx(true)
        end
    end
end

---根据最终玩家豆数刷新进度条上的撤离点标记。
---保留原UpdateKeyVisibility的判断：达到门槛后隐藏，之后不重新显示。
---这里只控制PanelExit，不负责开启场景中的撤离点。
function XUiPacMan2GameUiController:_RefreshExitMarker()
    if self._IsExitMarkerHidden then
        return
    end

    local playerOrbCount = self._Values[UiField.PlayerOrbCount]
    local orbsToShowKey = self._Values[UiField.OrbsToShowKey]
    if playerOrbCount == nil or orbsToShowKey == nil then
        return
    end

    if playerOrbCount >= orbsToShowKey then
        self._IsExitMarkerHidden = true
        self._RootUi.PanelExit.gameObject:SetActiveEx(false)
    end
end

---读取最终血量刷新血格。
---首次有效同步不播放动画，后续刷新允许播放变化动画。
---血格自身会跳过未变化的显示状态，因此完整刷新不会重复播放动画。
function XUiPacMan2GameUiController:_RefreshHp()
    local hp = self._Values[UiField.PlayerHp]
    if hp == nil then
        return
    end

    self:_UpdateHp(hp, self._HasRefreshedHp)

    -- 完成有效同步后才标记，缺少血量数据的调用不算首次显示。
    self._HasRefreshedHp = true
end

---原Game中的血格显示逻辑，仅迁移位置，不改变动画行为。
function XUiPacMan2GameUiController:_UpdateHp(hp, animation)
    local rootUi = self._RootUi

    for i = 1, hp do
        local gridLife = self._HpGrids[i]
        if not gridLife then
            local ui = XUiHelper.Instantiate(rootUi.GridLife, rootUi.GridLife.transform.parent)
            ui.gameObject:SetActiveEx(true)

            -- 血格仍以原来的Game界面作为父节点。
            -- 不把普通Lua控制器当成XUiNode父节点。
            gridLife = XUiPacMan2GridLife.New(ui, rootUi)
            table.insert(self._HpGrids, gridLife)
        end
        gridLife:Update(true, animation)
    end

    for i = hp + 1, #self._HpGrids do
        local gridLife = self._HpGrids[i]
        if gridLife then
            gridLife:Update(false, animation)
        end
    end
end

---HpChanged参数：[0]旧血量，[1]新血量。
---普通UI只收集新值，不使用消息中的旧值，也不播放动画。
---同一事务中多次收到血量变化时，后值直接覆盖前值。
---@param args System.Array
---@param pendingValues table 本事务收集的最终值，所有消息处理函数共用。
function XUiPacMan2GameUiController:_OnHpChanged(args, pendingValues)
    local newHp = args[1]
    if newHp == nil then
        XLog.Error("[PacMan2GameUiController] HpChanged缺少newHp")
        return
    end

    pendingValues[UiField.PlayerHp] = newHp
end

---OrbChanged参数：[0]旧玩家豆数，[1]新玩家豆数，[2]关卡豆子总数。
---新玩家豆数包含直接吃豆和击杀敌人后夺回的豆子。
---这里只收集数据，不刷新UI。
---@param args System.Array
---@param pendingValues table 本事务收集的最终值。
function XUiPacMan2GameUiController:_OnOrbChanged(args, pendingValues)
    local newOrbs = args[1]
    local orbTotal = args[2]
    if newOrbs == nil or orbTotal == nil then
        XLog.Error("[PacMan2GameUiController] OrbChanged参数不完整")
        return
    end

    pendingValues[UiField.PlayerOrbCount] = newOrbs
    pendingValues[UiField.OrbTotal] = orbTotal
end

---EnemyOrbChanged参数：[0]旧敌人豆数，[1]新敌人豆数。
---表示敌人当前持有的总量，不是累计吃豆次数。
---@param args System.Array
---@param pendingValues table 本事务收集的最终值。
function XUiPacMan2GameUiController:_OnEnemyOrbChanged(args, pendingValues)
    local newEnemyOrbs = args[1]
    if newEnemyOrbs == nil then
        XLog.Error("[PacMan2GameUiController] EnemyOrbChanged缺少newEnemyOrbs")
        return
    end

    pendingValues[UiField.EnemyOrbCount] = newEnemyOrbs
end

---KillChanged参数：
---[0] 旧累计击杀数。
---[1] 新累计击杀数。
---[2] 被击杀怪物的原始类型，本处理器不使用。
---这里只收集最终新值，不播放表现，也不再次查询C#。
---同一事务中多次收到击杀变化时，后值覆盖前值。
---@param args System.Array
---@param pendingValues table 本事务收集的最终值。
function XUiPacMan2GameUiController:_OnKillChanged(args, pendingValues)
    local newKills = args[1]
    if newKills == nil then
        XLog.Error("[PacMan2GameUiController] KillChanged缺少newKills")
        return
    end

    pendingValues[UiField.KillCount] = newKills
end

---PlayerKillGhostPhaseChanged参数：[0]旧状态，[1]新状态。
---这里只保存最终布尔值，不在逐条处理消息时切换背景。
---@param args System.Array
---@param pendingValues table 本事务收集的最终值。
function XUiPacMan2GameUiController:_OnPlayerKillGhostPhaseChanged(args, pendingValues)
    local newValue = args[1]
    if newValue == nil then
        XLog.Error("[PacMan2GameUiController] PlayerKillGhostPhaseChanged缺少newValue")
        return
    end

    -- false表示退出反杀，是有效数据，不能当成缺参忽略。
    pendingValues[UiField.IsPlayerKillGhostPhase] = newValue
end

---GhostStateChanged参数：[0]旧幽灵状态，[1]新幽灵状态。
---直接保存C#枚举值，不通过豆数推算幽灵状态。
---@param args System.Array
---@param pendingValues table 本事务收集的最终值。
function XUiPacMan2GameUiController:_OnGhostStateChanged(args, pendingValues)
    local newState = args[1]
    if newState == nil then
        XLog.Error("[PacMan2GameUiController] GhostStateChanged缺少newState")
        return
    end

    pendingValues[UiField.GhostState] = newState
end

function XUiPacMan2GameUiController:Dispose()
    if self._MoverPlayer then
        self._MoverPlayer:Destroy()
        self._MoverPlayer = nil
    end

    if self._MoverEnemy then
        self._MoverEnemy:Destroy()
        self._MoverEnemy = nil
    end
    
    self._Values = nil
    self._SignalHandlers = nil

    -- 血格属于原Game界面的节点生命周期，这里只释放引用。
    self._HpGrids = nil
    self._GameManager = nil
    self._RootUi = nil

    -- 星级控件同样属于Game节点生命周期，这里只释放引用。
    self._StarList = nil
    self._StarDatas = nil
end

return XUiPacMan2GameUiController