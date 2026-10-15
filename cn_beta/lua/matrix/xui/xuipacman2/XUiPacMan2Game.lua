local XUiPacMan2GameUiController = require("XUi/XUiPacMan2/XUiPacMan2GameUiController")
local XUiPacMan2InputManager = require("XUi/XUiPacMan2/XUiPacMan2InputManager")
local XUiToggle = require("XUi/XUiCommon/XUiToggle")
local XUiPacMan2EventRuntime = require("XUi/XUiPacMan2/XUiPacMan2EventRuntime")
local XUiPacMan2VisualController = require("XUi/XUiPacMan2/XUiPacMan2VisualController")
local EventDefine = require("XUi/XUiPacMan2/XUiPacMan2EventDefine")
local XPacMan2Statistics = require("XUi/XUiPacMan2/XPacMan2Statistics")
local LeaveType = XPacMan2Statistics.LeaveType

local PacMan2SignalType = CS.XPacMan2.XPacMan2SignalType
local GamePauseReason = CS.XPacMan2.XPacMan2GamePauseReason
local CsEntityEnum = CS.XPacMan2.XPacMan2EntityEnum
local CountdownSource = EventDefine.CountdownSource

-- 当前美术血格支持的玩家生命上限；初始生命仍读取关卡配置。
local PlayerMaxLives = 6

-- 两种击杀特效分别计时，不因当前时长相同而共用一个常量。
local PixelationEffectDurationSeconds = 5
local FlashKillEffectDurationSeconds = 5

-- 倒计时使用四个固定图片槽位，与_CountDownText的排列对应。
local CountdownImageCount = 4

-- 配置数值换算比例。
local PercentScale = 100
local TenThousandRatioScale = 10000

-- 毫秒转换为秒，不与速度配置的定点缩放混用语义。
local MillisecondsPerSecond = 1000

-- 离开关卡时用于禁用道具音效，保持原来的CueId取值。
local DisabledItemSoundCueId = 0

-- XUiToggle回调值：0为On，1为Off。
-- 当前界面约定On使用摇杆，Off使用滑动。
local InputToggleValue = {
    Joystick = 0,
    Touch = 1,
}

local SettleType = {
    Abort = 0,
    Normal = 1,
}

-- 游戏实体类型枚举
local EntityEnum = {
    Orb = 1,           -- 豆子
    Key = 2,           -- 钥匙
    GoldOrb = 3,       -- 金豆
    TurnIntoFood = 4,  -- 将怪物变为食物的道具
    TurnIntoShoe = 5,  -- 将怪物变为跑鞋的道具
    Ghost = 6,         -- 普通怪物
    RangeGhost = 7,    -- 范围警戒怪物
    SlowGhost = 8,     -- 减速怪物
    Shoe = 9,          -- 跑鞋道具
    PlayerClone = 10,  -- 玩家分身
    Food = 11,         -- 食物
    ShowKey = 12,      -- 显示钥匙（仅用于UI展示）
    Snake = 13,        -- 贪吃蛇怪物
    EatGhost = 14,     -- 贪吃怪物
    SlowDownGhost = 15,-- 减速效果道具
    SpeedUpPlayer = 16 -- 加速效果道具
}

local BackgroundType = {
    Default = 1,
    PlayerKillGhost = 2,
    GhostKillPlayer = 3,
}

local DialogType = EventDefine.DialogType

---@class UiPacMan2Game : XLuaUi
---@field _Control XPacMan2Control
local XUiPacMan2Game = XLuaUiManager.Register(XLuaUi, "UiPacMan2Game")

function XUiPacMan2Game:OnAwake()
    -- 初始化基本状态
    self._StageId = false
    self._StagePrefab = false
    ---@type XPacMan2.XPacMan2GameManager
    self._GameManager = false
    ---@type XPacMan2.XPacMan2Movement
    self._PlayerMovement = false
    self._IsGameOver = false
    -- 保存本次开局的运行实例Id，不是策划配置Id。
    self._OpeningEventGroupRuntimeId = nil

    -- 正常完成和主动跳过共用结束入口，只能进入一次倒计时。
    self._IsOpeningFlowFinished = false

    -- 尚未执行的结算预约。只用于防止重复预约及生命周期清理。
    -- 预约不代表已经结算，真正执行时才设置_IsGameOver。
    self._SettlementTimerId = nil
    
    -- 注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OpenPauseUi)

    self._VisualController = XUiPacMan2VisualController.New(self)
    self._InputManager = XUiPacMan2InputManager.New(self)
    self._EventRuntime = XUiPacMan2EventRuntime.New(self, self._InputManager, self._Control, self._VisualController)

    -- 关卡星级阈值，供进度计算等逻辑使用。
    ---@type number[]|false
    self._ConfigStarList = false
    
    -- 初始化倒计时相关
    self._CountDown = 0
    --self._CountDownTimer = false
    self._CountDownText = {
        self.RawImgShuzi03,
        self.RawImgShuzi02,
        self.RawImgShuzi01,
        self.RawImgShuzi04,
    }
    self._IsCountDown = false

    self._GameUiController = XUiPacMan2GameUiController.New(self)
    
    -- 旧提示节点保留，但不再显示
    self.TxtTips.text = ""
    self.TxtTips.gameObject:SetActiveEx(false)

    -- 兼容AppendDialog接口，用于避免连续追加相同类型、相同文本的对话。
    self._LastDialogKey = false
    
    -- 初始化操作方式相关
    self._IsTouch = self._Control:GetToggleTouch()
    -- 初始化 XUiToggle 组件
    ---@type XUiToggle
    self._ToggleSwitch = XUiToggle.New(self.BtnSwitch, self)
    self._ToggleSwitch:SetOnValueChanged(function(value)
        -- On = 摇杆，Off = 滑动
        self._IsTouch = value == InputToggleValue.Touch
        self._Control:SetToggleTouch(self._IsTouch)
        self:UpdateInput()
    end)
    -- _IsTouch=false时，开关应显示On，也就是摇杆
    self._ToggleSwitch:SetToggleState(not self._IsTouch)
    self:InitInput()

    self._BackgroundType = BackgroundType.Default
    self._Backgounrd = {}
    
    -- 初始化像素化特效节点列表（用于选择最近的节点）
    self._PixelationNodes = {}
    if self.FxPixelation01 then
        table.insert(self._PixelationNodes, self.FxPixelation01)
    end
    if self.FxPixelation02 then
        table.insert(self._PixelationNodes, self.FxPixelation02)
    end
    if self.FxPixelation03 then
        table.insert(self._PixelationNodes, self.FxPixelation03)
    end
    
    -- 初始化像素化特效定时器列表
    self._PixelationTimers = {}
    
    -- 初始化 FlashKill 特效定时器列表
    self._FlashKillTimers = {}
    
    -- 初始化 FlashKill 特效节点
    if self.FlashKill then
        self.FlashKill.gameObject:SetActiveEx(false)
    end

    -- 开局流程需要同时等待C#场景加载完成和服务端开始请求成功。
    self._IsOpeningStageLoaded = false
    self._IsStageStartRequestCompleted = false
    self._IsOpeningFlowStarted = false
    self._OpeningControlLockToken = nil

    ---@type XPacMan2Statistics
    self._Statistics = nil

    -- 服务器是否真正接受了本次开局。
    -- 与调试模式下允许继续播放开局流程的标记分开。
    self._HasServerStageStarted = false

    -- 本次运行是否已经提交过结算，不表示服务器返回成功。
    self._HasSubmittedSettle = false
end

---@param stageId number
---@param isRestart boolean|nil 仅暂停菜单内重开传true；结算再来一局属于新的一局。
function XUiPacMan2Game:OnStart(stageId, isRestart)
    self._StageId = stageId

    -- 只记录本次进入方式，不保存关卡播放历史。
    -- 普通进入不传参数，默认播放开局事件。
    self._IsRestart = isRestart == true
    self._Control:RecordGameEntry(self._IsRestart)
    self:StartGame()
end

function XUiPacMan2Game:OnGetEvents()
    return {
        CS.XEventId.EVENT_PACMAN2_GAME_SIGNAL,
    }
end

function XUiPacMan2Game:OnDestroy()
    self._IsOpeningFlowFinished = true
    self._OpeningEventGroupRuntimeId = nil
    -- 在释放关卡实例和各管理器前，取消尚未执行的结算预约。
    self:_CancelSettlementSchedule()
    -- 界面可能在开局流程完成前被关闭，主动释放开局操作锁。
    self:_ReleaseOpeningControlLock()
    -- 禁用道具音效（需要在 _StagePrefab 被置为 nil 之前调用）
    self:_DisableItemSounds()

    self._Statistics = nil

    if self._EventRuntime then
        self._EventRuntime:Dispose()
        self._EventRuntime = nil
    end

    if self._VisualController then
        self._VisualController:Dispose()
        self._VisualController = nil
    end

    if self._InputManager then
        self._InputManager:Dispose()
        self._InputManager = nil
    end

    if self._GameUiController then
        self._GameUiController:Dispose()
        self._GameUiController = nil
    end
    
    -- 因为会缓存 prefab，所以这里要手动销毁
    -- 避免下次打开游戏, 使用了缓存的prefab
    local prefabComponent = self.UiSceneInfo.Transform:GetComponent("XUiLoadPrefab")
    if prefabComponent then
        CS.UnityEngine.Object.DestroyImmediate(prefabComponent)
    end
    self._StagePrefab = nil
    self._GameManager = nil
    self._PlayerMovement = nil
    
    -- XUiToggle 继承自 XUiNode，会自动随父节点销毁，无需手动调用
    
    self._Control:SetPlaying(false)
    
    -- 清理背景相关资源
    self._Backgounrd = {}
    self._BackgroundType = nil
    
    -- 清理像素化特效定时器
    self:_ClearPixelationTimers()
    
    -- 清理 FlashKill 特效定时器
    self:_ClearFlashKillTimers()
    
end

function XUiPacMan2Game:OnEnable()
    -- UI禁用期间不会接收C#事件。
    -- 重新显示时单次同步结束状态，补接漏收或之前被取消的结算请求。
    self:_TryScheduleSettlement()

    -- 已经结束或正在等待结算时，不再补刷普通游戏表现。
    if not self._IsGameOver and not self._SettlementTimerId then
        self._GameUiController:Refresh()
    end

    -- PC显示新版键盘操作提示。
    -- 旧PanelControl及四方向点击按钮已移除，不再控制它们的显示。
    local isPc = XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc
    self.Keyboard.gameObject:SetActiveEx(isPc)

    if self._InputManager then
        self._InputManager:Enable()
    end

    -- 放在输入启用之后，受击倒计时启动时会再次正确停用输入。
    self:_TryStartDamageRecoveryCountdown()
end

function XUiPacMan2Game:OnDisable()
    -- 界面禁用后不再执行结算预约；重新显示时根据C#状态补接。
    self:_CancelSettlementSchedule()
    --if self._CountDownTimer then
    --    XScheduleManager.UnSchedule(self._CountDownTimer)
    --    self._CountDownTimer = false
    --end

    if self._InputManager then
        self._InputManager:Disable()
    end
end

local GameState = {
    None = 0,
    Playing = 1,
    Paused = 2,
    GameOver = 3,
    GameClear = 4,
}

---播放一次原有击杀反馈。
---由GameUiController确认最终击杀数变化后调用。
function XUiPacMan2Game:PlayKillFeedback()
    -- 先像素化特效，再FlashKill。
    self:ShowPixelationEffect()
    self:ShowFlashKillEffect()
end

function XUiPacMan2Game:StartGame()
    self:_ReleaseOpeningControlLock()
    self._IsOpeningStageLoaded = false
    self._IsStageStartRequestCompleted = false
    self._IsOpeningFlowStarted = false
    self._OpeningEventGroupRuntimeId = nil
    self._IsOpeningFlowFinished = false
    
    self._HasServerStageStarted = false
    self._HasSubmittedSettle = false
    
    local stageConfig = self._Control:GetStageConfig(self._StageId)
    local prefab = stageConfig.Prefab
    if not prefab or prefab == "" then
        XLog.Error("[UiPacMan2Game] StartGame prefab is nil")
        return
    end
    -- 必须在加载Prefab之前初始化事件系统。
    -- 避免C#的Start发送StageLoaded时，Context还没开始本关。
    self._EventRuntime:BeginStage(self._StageId)
    
    self._StagePrefab = self.UiSceneInfo.Transform:LoadPrefab(prefab, true, true)
    self._GameManager = self._StagePrefab:FindGameObject("PacManGameManager"):GetComponent("XPacMan2GameManager")
    self._PlayerMovement = self._GameManager.Player:GetComponent("XPacMan2Movement")
    self._InputManager:BindMovement(self._PlayerMovement)
    self:ImportConfig()

    -- 每次关卡运行创建独立统计对象，不继承上一局的数据。
    self._Statistics = XPacMan2Statistics.New(self._GameManager:GetGhostState())

    -- let's start the game
    self._GameManager:Pause()

    -- 开局流程同时禁止输入和移动。
    -- 该锁会一直保持到开局事件播放完毕并进入倒计时。
    if self._InputManager then
        self._OpeningControlLockToken = self._InputManager:AcquireControlLock("PacMan2Opening")
    end
    
    -- GameManager和玩家数据完成配置后，主动读取一次条件状态快照。
    -- 快照只建立变化基线，不会触发规则。
    self._EventRuntime:InitializeContext(self._GameManager)
    self._GameUiController:BindGameManager(self._GameManager)
    self._GameUiController:Refresh()
    local gameManager = self._GameManager
    local function isCurrentGame()
        return self._GameManager == gameManager
    end
    XMVCA.XPacMan2:PacMan2StageStartRequest(self._StageId, function(isSuccess)
        if isSuccess then
            self._HasServerStageStarted = true
            self._IsStageStartRequestCompleted = true
            self:_TryStartOpeningFlow()
            return
        end
        XLog.Warning("[XUiPacMan2Game] PacMan2StageStartRequest失败")
        if XMain.IsZLBDebug then
            self._IsStageStartRequestCompleted = true
            self:_TryStartOpeningFlow()
            return
        end
        
        self:_ReleaseOpeningControlLock()
        self:Close()
    end,isCurrentGame)

    self:InitBackground()
    self._GameUiController:InitStarPosition()
    self:InitPanelExit()
end

function XUiPacMan2Game:OpenSettlement()
    -- 结算时恢复鼠标显示并禁用输入检测
    if self._InputManager then
        self._InputManager:RestoreCursor()
        self._InputManager:Disable()
    end

    local gameState = self._GameManager:GetGameState()
    if gameState == GameState.GameClear then
        self:_SubmitSettle(SettleType.Normal)
    elseif gameState == GameState.GameOver then
        self:_SubmitSettle(SettleType.Abort)
    end

    ---@class XPacMan2SettlementData
    local data = {
        StageId = self._StageId,
        Score = self._GameManager:GetOrbs(),
        IsWin = self._GameManager:GetGameState() == GameState.GameClear,
        Orbs = self._GameManager.Orbs,
        OrbScore = self._GameManager.OrbScore,
        Kills = self._GameManager.Kills,
        KillScore = self._GameManager.KillScore,
        Hp = self._GameManager:GetPlayerHp(),
        --HpScore = 0,
        --ShoeCount = self._GameManager.ShoeCount,
        --ShoeScore = self._GameManager.ShoeScore,
        OrbsPayback = self._GameManager.OrbsPayback,
    }
    XLuaUiManager.Open("UiPacMan2PopupSettlement", data, function()
        -- 使用打开结算页面时的本局结果快照。
        if data.IsWin then
            self:ReportRoundLeave(LeaveType.RestartAfterClear, data.Score)
        else
            self:ReportRoundLeave(LeaveType.Restart)
        end
    end)
end

function XUiPacMan2Game:ImportConfig()
    -- 初始化游戏管理器配置
    self._GameManager.ShouldPauseOnHpDecrease = true

    ---@type UnityEngine.GameObject
    local stagePrefab = self._StagePrefab
    local gameConfig = self._Control:GetGameConfig()

    ---@type XTablePacMan2Stage
    local stageConfig = self._Control:GetStageConfig(self._StageId)
    self._GameManager.OrbsToShowKey = stageConfig.RedOrb
    self._GameManager:InitializeOrbState(0, 0)
    self._GameManager:SetOrbsAttackThreshold(stageConfig.OrbsAttackThreshold)
    self._GameManager.ReviveProtectionTimeDuration = self:Divide1000(stageConfig.ReviveProtectionTime)

    -- 每局重置反杀进度表现。
    -- 数据显示统一由ImportConfig完成后的GameUiController:Refresh同步。
    self._GameUiController:ResetBuffProgress()

    -- 初始化玩家生命值组件
    ---@type XPacMan2.XPacMan2Hp
    local hpComponent = self._GameManager.Player.transform:GetComponent(typeof(CS.XPacMan2.XPacMan2Hp))
    hpComponent.Lives = stageConfig.InitialHp
    -- 使用当前美术血格支持的生命上限，初始生命仍由关卡表决定。
    hpComponent.MaxLives = PlayerMaxLives

    -- 配置玩家角色移动参数
    local characterSpeed = gameConfig.CharacterSpeed.Value
    local players = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Player), true)
    local characterTurningSpend = gameConfig.CharacterTurningSpend.Value
    for i = 0, players.Length - 1 do
        local player = players[i]
        ---@type UnityEngine.Transform
        local playerTransform = player.transform
        ---@type XPacMan2.XPacMan2Movement
        local movement = playerTransform:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:Divide1000(characterSpeed)
        movement.RotateDuration = self:Divide1000(characterTurningSpend)
    end

    -- 配置金豆（金魂石）参数
    local goldOrbConfig = self._Control:GetEntityConfig(EntityEnum.GoldOrb)
    local goldOrbs = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2GoldOrb), true)
    for i = 0, goldOrbs.Length - 1 do
        local goldOrb = goldOrbs[i]
        goldOrb.Hp = goldOrbConfig.Params[1]
    end

    -- 配置将怪物变为食物的道具参数
    local turnIntoFoodConfig = self._Control:GetEntityConfig(EntityEnum.TurnIntoFood)
    local turnIntoFoods = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2TurnGhostIntoFood), true)
    for i = 0, turnIntoFoods.Length - 1 do
        ---@type XPacMan2.XPacMan2TurnGhostIntoFood
        local turnIntoFood = turnIntoFoods[i]
        turnIntoFood.Duration = turnIntoFoodConfig.Params[1]
        turnIntoFood.CoolDown = turnIntoFoodConfig.Params[2]
    end

    -- 配置食物参数
    local foodConfig = self._Control:GetEntityConfig(EntityEnum.Food)
    if foodConfig then
        local foods = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Food), true)
        for i = 0, foods.Length - 1 do
            local food = foods[i]
            local movement = food:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
            movement.Speed = self:Divide1000(foodConfig.Speed)
        end
    end

    -- 配置将怪物变为跑鞋的道具参数
    local turnIntoShoeConfig = self._Control:GetEntityConfig(EntityEnum.TurnIntoShoe)
    local turnIntoShoes = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2TurnGhostIntoShoe), true)
    local shoeConfig = self._Control:GetEntityConfig(EntityEnum.Shoe)
    for i = 0, turnIntoShoes.Length - 1 do
        ---@type XPacMan2.XPacMan2TurnGhostIntoShoe
        local turnIntoShoe = turnIntoShoes[i]
        turnIntoShoe.Duration = turnIntoShoeConfig.Params[1]
        turnIntoShoe.SpeedOverlay = self:Divide1000(shoeConfig.Params[2])
        turnIntoShoe.SpeedIncrease = self:Divide1000(shoeConfig.Params[3])
        if shoeConfig.Params[4] and shoeConfig.Params[4] > 0 then
            turnIntoShoe.MaxLayer = shoeConfig.Params[4]
        end
    end

    -- 配置普通怪物参数
    local ghostConfig = self._Control:GetEntityConfig(EntityEnum.Ghost)
    local ghostPatrols = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2BehaviorGhostPatrol), true)
    for i = 0, ghostPatrols.Length - 1 do
        local ghost = ghostPatrols[i]
        local ghostEntity = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2Ghost))
        ghostEntity:SetEntityType(CsEntityEnum.Ghost)
        
        local speed = ghostConfig.Speed
        local movement = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:Divide1000(speed)
        movement.RotateDuration = ghostConfig.TurningDuration

        ---@type XPacMan2.XPacMan2BehaviorGhostRange
        local range = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange))
        if range then
            range.Range = Vector2(ghostConfig.AlertX, ghostConfig.AlertY)
            range:UpdateRangeVisible()
            self:UpdateRange(range, ghostConfig.AlertVisibility)
        end
    end

    -- 配置警戒范围怪物参数
    local ghostRangeConfig = self._Control:GetEntityConfig(EntityEnum.RangeGhost)
    local ghostRanges = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange), true)
    for i = 0, ghostRanges.Length - 1 do
        local ghost = ghostRanges[i]
        if ghost:GetType().Name == "XPacMan2BehaviorGhostRange" then
            local ghostEntity = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2Ghost))
            ghostEntity:SetEntityType(CsEntityEnum.RangeGhost)
            
            local speed = ghostRangeConfig.Speed
            local movement = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
            movement.Speed = self:Divide1000(speed)
            movement.RotateDuration = ghostRangeConfig.TurningDuration

            ---@type XPacMan2.XPacMan2BehaviorGhostRange
            local range = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange))
            if range then
                range.Range = Vector2(ghostRangeConfig.AlertX, ghostRangeConfig.AlertY)
                range:UpdateRangeVisible()
            end
            self:UpdateRange(range, ghostRangeConfig.AlertVisibility)
        end
    end

    -- 配置减速怪物（淤泥怪）参数
    local ghostSlowConfig = self._Control:GetEntityConfig(EntityEnum.SlowGhost)
    local ghostSlowDowns = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SlowDown), true)
    for i = 0, ghostSlowDowns.Length - 1 do
        ---@type XPacMan2.XPacMan2SlowDown
        local ghost = ghostSlowDowns[i]
        
        local ghostEntity = ghost.transform.parent:GetComponent(typeof(CS.XPacMan2.XPacMan2Ghost))
        ghostEntity:SetEntityType(CsEntityEnum.SlowGhost)
        
        local speed = ghostSlowConfig.Speed
        local movement = ghost.transform.parent:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:Divide1000(speed)
        movement.RotateDuration = ghostSlowConfig.TurningDuration

        ---@type XPacMan2.XPacMan2BehaviorGhostRange
        local range = ghost.transform.parent:GetComponent(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange))
        if range then
            range.Range = Vector2(ghostSlowConfig.Params[2], ghostSlowConfig.Params[3])
            self:UpdateRange(range, true)
            range:UpdateRangeVisible()
        end

        ghost.SpeedMultipiler = ghostSlowConfig.Params[1] / PercentScale
        --ghost.Range = Vector2(ghostSlowConfig.Params[2], ghostSlowConfig.Params[3])

        ---@type XPacMan2.XPacMan2SlowDown
        local slowDown = ghostSlowDowns[i]
        slowDown.Range = Vector2(ghostSlowConfig.Params[2], ghostSlowConfig.Params[3])
        slowDown:UpdateRange()
    end

    -- 配置跑鞋道具参数
    local shoeConfig = self._Control:GetEntityConfig(EntityEnum.Shoe)
    local shoes = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Shoe), true)
    for i = 0, shoes.Length - 1 do
        local shoe = shoes[i]
        local shoeTransform = shoe.transform
        local movement = shoeTransform:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:Divide1000(shoeConfig.Speed)
    end

    -- 配置玩家分身参数
    local playerCloneConfig = self._Control:GetEntityConfig(EntityEnum.PlayerClone)
    local playerClones = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2PlayerClone), true)
    for i = 0, playerClones.Length - 1 do
        local playerClone = playerClones[i]
        local playerCloneTransform = playerClone.transform
        local movement = playerCloneTransform:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:Divide1000(playerCloneConfig.Speed)

        playerClone.Duration = playerCloneConfig.Params[1]
        playerClone.GhostStopDuration = playerCloneConfig.Params[2]
    end

    -- 设置关卡星级要求。
    -- Game保留进度计算所需的配置，UI控制器准备星级显示参数。
    self._ConfigStarList = stageConfig.Star
    self._GameUiController:SetStarConfig(stageConfig.Star)

    -- 配置无敌效果持续时间
    local invincibleValue = gameConfig.Invincible.Value
    if invincibleValue then
        local invincibles = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Invincible), true)
        for i = 0, invincibles.Length - 1 do
            local invincible = invincibles[i]
            invincible.Duration = invincibleValue / 1000
        end
    else
        XLog.Error("[XUiPacMan2Game] 找不到无敌时间长度的配置")
    end

    -- 配置贪吃蛇怪物参数
    local snakeConfig = self._Control:GetEntityConfig(EntityEnum.Snake)
    if snakeConfig then
        local snakes = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SnakeHead), true)
        for i = 0, snakes.Length - 1 do
            local snake = snakes[i]
            
            local ghostEntity = snake:GetComponent(typeof(CS.XPacMan2.XPacMan2Ghost))
            ghostEntity:SetEntityType(CsEntityEnum.Snake)
            
            snake.MaxLength = snakeConfig.Params[1]

            local movement = snake:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
            movement.Speed = self:Divide1000(snakeConfig.Speed)
        end
    end

    -- 配置贪吃怪物参数
    local ghostEatOrbConfig = self._Control:GetEntityConfig(EntityEnum.EatGhost)
    if ghostEatOrbConfig then
        local ghostEatOrbs = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2BehaviorGhostEatOrb), true)
        for i = 0, ghostEatOrbs.Length - 1 do
            local ghostEatOrb = ghostEatOrbs[i]
            
            local ghostEntity = ghostEatOrb:GetComponent(typeof(CS.XPacMan2.XPacMan2Ghost))
            ghostEntity:SetEntityType(CsEntityEnum.EatGhost)
            
            ghostEatOrb.SpeedHungry = self:Divide1000(ghostEatOrbConfig.Speed)
            ghostEatOrb.SpeedFull = self:Divide1000(ghostEatOrbConfig.Params[1])
            ghostEatOrb.Full = ghostEatOrbConfig.Params[2]
            ghostEatOrb:UpdateStatus()
        end
    end

    -- 配置全局减速道具参数
    local ghostSlowDownGhostsConfig = self._Control:GetEntityConfig(EntityEnum.SlowDownGhost)
    if ghostSlowDownGhostsConfig then
        local ghostSlowDownGhosts = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SlowDownGhosts), true)
        for i = 0, ghostSlowDownGhosts.Length - 1 do
            local ghostSlowDownGhost = ghostSlowDownGhosts[i]
            ghostSlowDownGhost.SpeedMultiplier = ghostSlowDownGhostsConfig.Params[1] / TenThousandRatioScale
            ghostSlowDownGhost.Duration = ghostSlowDownGhostsConfig.Params[2]
        end
    end

    -- 配置玩家加速道具参数
    local speedUpPlayerConfig = self._Control:GetEntityConfig(EntityEnum.SpeedUpPlayer)
    if speedUpPlayerConfig then
        local speedUpPlayers = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SpeedUpPlayer), true)
        for i = 0, speedUpPlayers.Length - 1 do
            local speedUpPlayer = speedUpPlayers[i]
            speedUpPlayer.SpeedMultiplier = (speedUpPlayerConfig.Params[1] / TenThousandRatioScale + 1)
            speedUpPlayer.Duration = speedUpPlayerConfig.Params[2]
        end
    end
end

function XUiPacMan2Game:Divide1000(value)
    return value / 1000
end

--- 禁用道具音效（在离开关卡时调用）
function XUiPacMan2Game:_DisableItemSounds()
    if not self._StagePrefab then
        return
    end
    
    -- 查找所有 XPacMan2SlowDownGhosts 组件
    local ghostSlowDownGhosts = self._StagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SlowDownGhosts), true)
    for i = 0, ghostSlowDownGhosts.Length - 1 do
        local component = ghostSlowDownGhosts[i]
        local soundComp = component:GetComponent("XUguiPlaySoundWithSource")
        if soundComp then
            soundComp.CueId = DisabledItemSoundCueId
        end
    end
    
    -- 查找所有 XPacMan2SpeedUpPlayer 组件
    local speedUpPlayers = self._StagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SpeedUpPlayer), true)
    for i = 0, speedUpPlayers.Length - 1 do
        local component = speedUpPlayers[i]
        local soundComp = component:GetComponent("XUguiPlaySoundWithSource")
        if soundComp then
            soundComp.CueId = DisabledItemSoundCueId
        end
    end
end

function XUiPacMan2Game:UpdateRange(range, value)
    -- 这一期没有范围怪
    --if value then
    --    if range.RangeTransform then
    --        range.RangeTransform.gameObject:SetActiveEx(true)
    --    end
    --    range.IsRangeVisible = true
    --else
    --    if range.RangeTransform then
    --        range.RangeTransform.gameObject:SetActiveEx(false)
    --    end
    --    range.IsRangeVisible = false
    --end
end

function XUiPacMan2Game:OnControlStateChanged(inputEnabled, movementEnabled)
    -- 摇杆隐藏或置灰等UE表现以后在这里处理
end

---尝试开始受击恢复倒计时。
---由事务通知触发；界面重新显示时也会调用一次，补接未消费的恢复请求。
---不重新执行C#的Pause、StopBuff或ResetState。
function XUiPacMan2Game:_TryStartDamageRecoveryCountdown()
    local gameManager = self._GameManager
    if not gameManager or self._IsGameOver or self._IsCountDown then
        return
    end

    -- 标记由C#进入受击恢复流程时设置。
    -- 没有待处理的受击恢复请求，就不启动倒计时。
    if not gameManager.IsPauseOnHpDecrease then
        return
    end

    -- 游戏已经结束时，不再开始受击恢复。
    -- 此处不打开结算界面，结算由GameEnded通知或OnEnable同步后延后执行。
    local gameState = gameManager:GetGameState()
    if gameState == GameState.GameClear or gameState == GameState.GameOver then
        return
    end

    -- 正常事务路径中，Runtime已经提前申请了这个暂停来源。
    -- 同一来源重复申请不会叠加；这里也覆盖界面重新显示时的补接路径。
    if self._EventRuntime then
        self._EventRuntime:OnGamePauseRequested(GamePauseReason.DamageRecovery)
    end

    -- 暂不清除IsPauseOnHpDecrease，保留受击恢复期间的防重复扣血保护。
    self:StartCountDown(GamePauseReason.DamageRecovery)
end

---游戏已经结束时，预约一次延后结算。
---由GameEnded通知或OnEnable的单次状态同步调用
---只预约，不在当前事务、事件执行或UI启用调用栈中打开结算界面。
function XUiPacMan2Game:_TryScheduleSettlement()
    local gameManager = self._GameManager
    if not gameManager or self._IsGameOver or self._SettlementTimerId then
        return
    end

    local gameState = gameManager:GetGameState()
    if gameState ~= GameState.GameClear and gameState ~= GameState.GameOver then
        return
    end

    -- 即使事件系统处于暂停状态，结算也必须能够执行。
    self._SettlementTimerId = XScheduleManager.ScheduleNextFrame(function()
        self._SettlementTimerId = nil

        -- 只处理预约时的关卡实例，已经结算或实例变化时不再执行。
        if self._IsGameOver or self._GameManager ~= gameManager then
            return
        end

        -- 通知只负责唤醒流程。
        -- 延后执行时重新确认最终状态，不固定使用第一条结束消息的结果。
        local finalState = gameManager:GetGameState()
        if finalState ~= GameState.GameClear and finalState ~= GameState.GameOver then
            return
        end

        -- 在调用结算前标记，避免重复弹窗和重复发送服务器请求。
        self._IsGameOver = true
        self:OpenSettlement()
    end)
end

---取消尚未执行的结算预约，可以重复调用。
---不设置_IsGameOver，界面重新显示时仍可根据C#状态重新预约。
function XUiPacMan2Game:_CancelSettlementSchedule()
    if not self._SettlementTimerId then
        return
    end

    XScheduleManager.UnSchedule(self._SettlementTimerId)
    self._SettlementTimerId = nil
end

---播放321倒计时，并在正常完成后恢复原有游戏流程。
---根据本次来源，额外通知事件系统对应的倒计时完成条件。
---@param pauseReason XPacMan2.XPacMan2GamePauseReason|nil
function XUiPacMan2Game:StartCountDown(pauseReason)
    -- 开始时确定本次倒计时来源，完成回调直接使用该结果。
    -- 受伤恢复优先按本次pauseReason判断；
    -- _IsRestart只用于区分关卡开始时的普通开局和局内重开。
    local countdownSource

    if pauseReason == GamePauseReason.DamageRecovery then
        countdownSource = CountdownSource.DamageRecovery
    elseif pauseReason == nil then
        countdownSource = self._IsRestart and CountdownSource.Restart or CountdownSource.Opening
    end

    -- 关闭暂停菜单继续游戏时，不产生这三个倒计时完成条件。

    if self._InputManager then
        self._InputManager:Disable()
    end

    self._IsCountDown = true
    self.PanelCountdown.gameObject:SetActiveEx(true)

    self:PlayAnimation("Countdown", function()
        self._IsCountDown = false
        self.PanelCountdown.gameObject:SetActiveEx(false)

        -- 只有受击恢复倒计时负责清除该标记。
        -- 保留到此处，避免事务同步通知后，后续碰撞再次进入扣血流程。
        if pauseReason == GamePauseReason.DamageRecovery then
            self._GameManager.IsPauseOnHpDecrease = false
        end

        self._GameManager:Resume()

        if self._InputManager then
            self._InputManager:Enable()
        end

        if pauseReason and self._EventRuntime then
            self._EventRuntime:ReleasePause(pauseReason)
        end

        -- 原有倒计时结束及恢复流程完成后，再报告本次瞬时条件。
        if countdownSource and self._EventRuntime then
            self._EventRuntime:OnCountdownCompleted(countdownSource)
        end
    end)
end

function XUiPacMan2Game:SetCountDownText(value)
    for i = 1, CountdownImageCount  do
        local ui = self._CountDownText[i]
        if ui then
            if value then
                ui.gameObject:SetActiveEx(value == i)
            end
        end
    end
end

function XUiPacMan2Game:OpenPauseUi()
    if self._IsCountDown then
        return
    end
    -- 只有playing可以打开暂停界面
    -- 修复:复活触发倒计时的时候，点快点能打开暂停界面
    if self._GameManager:GetGameState() == GameState.Playing then
        self._GameManager:Pause()
        if self._Statistics then
            self._Statistics:BeginManualPause()
        end
        if self._EventRuntime then
            self._EventRuntime:OnGamePauseRequested(GamePauseReason.PauseMenu)
        end
        -- 暂停游戏时恢复鼠标显示并禁用输入功能
        if self._InputManager then
            self._InputManager:RestoreCursor()
            self._InputManager:Disable()
        end
        XLuaUiManager.Open("UiPacMan2PopupStageStop", self._StageId,
            function()
                -- ESC菜单停留结束，后面的恢复倒计时计入对局时长。
                if self._Statistics then
                    self._Statistics:EndManualPause()
                end

                self:StartCountDown(GamePauseReason.PauseMenu)
            end,
            function()
                self:SubmitAbortSettlement()
            end,
            function(isRestart)
                local leaveType = isRestart and LeaveType.Restart or LeaveType.Abort
                self:ReportRoundLeave(leaveType)
            end)
    else
        XLog.Warning("[XUiPacMan2Game] 游戏不在进行中，禁止打开暂停界面")
    end
end

function XUiPacMan2Game:InitInput()
    local mode = XDataCenter.UiPcManager.GetUiPcMode()
    local uiPcMode = XDataCenter.UiPcManager.XUiPcMode

    if mode == uiPcMode.CloudGame or mode == uiPcMode.Default then
        -- 保留移动端／云游戏原有的滑动与摇杆切换。
        self.BtnSwitch.gameObject:SetActiveEx(true)
        self.Keyboard.gameObject:SetActiveEx(false)
        self:UpdateInput()
        return
    end

    if mode == uiPcMode.Pc then
        -- PC显示键盘提示，隐藏屏幕滑动区域和移动端摇杆。
        -- 实际按键读取由KeyboardInput负责，与提示节点相互独立。
        self.BtnSwitch.gameObject:SetActiveEx(false)
        self.Keyboard.gameObject:SetActiveEx(true)
        self.InputHandler.gameObject:SetActiveEx(false)
        self.PanelJoystick.gameObject:SetActiveEx(false)
        return
    end
end

function XUiPacMan2Game:UpdateInput()
    if self._IsTouch then
        -- 滑动模式：开启滑动输入区域，隐藏摇杆。
        self.InputHandler.gameObject:SetActiveEx(true)
        self.PanelJoystick.gameObject:SetActiveEx(false)
    else
        -- 摇杆模式：关闭滑动输入区域，显示摇杆。
        self.InputHandler.gameObject:SetActiveEx(false)
        self.PanelJoystick.gameObject:SetActiveEx(true)
    end
end

function XUiPacMan2Game:CalculateProgress(score, totalScore)
    local progress = 0
    local lastStarScore = 0
    for i = 1, #self._ConfigStarList do
        local starScore = self._ConfigStarList[i]
        if score >= starScore then
            progress = progress + 1 / (#self._ConfigStarList + 1)
        else
            progress = progress + (score - lastStarScore) / (starScore - lastStarScore) / (#self._ConfigStarList + 1)
            break
        end
        lastStarScore = starScore
    end
    lastStarScore = self._ConfigStarList[#self._ConfigStarList]
    if score > lastStarScore then
        progress = progress + (score - lastStarScore) / (totalScore - lastStarScore) / (#self._ConfigStarList + 1)
    end
    return progress
end

function XUiPacMan2Game:InitPanelExit()
    -- 设置进度条上，面包车的位置
    local position = self.PanelExit.transform.position
    local startPosition = self.StartPosition.position
    local endPosition = self.EndPosition.position
    local orbsToShowKey = self._GameManager.OrbsToShowKey
    local orbsTotal = self._GameManager.OrbsTotal
    local progress = self:CalculateProgress(orbsToShowKey, orbsTotal)
    position.x = startPosition.x + (endPosition.x - startPosition.x) * progress
    position.y = startPosition.y
    self.PanelExit.transform.position = position
end

function XUiPacMan2Game:UpdateBackground()
    local backgroundType = self._BackgroundType
    
    -- 遍历所有背景类型，显示当前类型，隐藏其他类型
    for bgType, bgGameObject in pairs(self._Backgounrd) do
        if bgGameObject then
            bgGameObject.gameObject:SetActiveEx(bgType == backgroundType)
        end
    end
end

function XUiPacMan2Game:InitBackground()
    local bgTileTextureSlow = self._StagePrefab.transform:Find("CameraLayer/TileMapCamera/UiPacMan2Background/GameObject/BgTileTextureSlow")
    local bgTileTextureQuick = self._StagePrefab.transform:Find("CameraLayer/TileMapCamera/UiPacMan2Background/GameObject/BgTileTextureQuick")
    local bgTileTextureReverse = self._StagePrefab.transform:Find("CameraLayer/TileMapCamera/UiPacMan2Background/GameObject/BgTileTextureReverse")
    
    if bgTileTextureSlow then
        self._Backgounrd[BackgroundType.Default] = bgTileTextureSlow
    end
    if bgTileTextureQuick then
        self._Backgounrd[BackgroundType.PlayerKillGhost] = bgTileTextureReverse
    end
    if bgTileTextureReverse then
        self._Backgounrd[BackgroundType.GhostKillPlayer] = bgTileTextureQuick
    end
    
    self:UpdateBackground()
end

--- 显示像素化特效（当 kills 数量变化时）
function XUiPacMan2Game:ShowPixelationEffect()
    if not self.FxPixelation01 or not self._GameManager or not self._GameManager.Player then
        return
    end
    
    -- 获取玩家世界坐标
    local playerWorldPosition = self._GameManager.Player.transform.position
    
    -- 获取场景相机（TileMapCamera）
    local sceneCameraTransform = self._StagePrefab and self._StagePrefab.transform:Find("CameraLayer/TileMapCamera")
    if not sceneCameraTransform then
        return
    end
    
    local sceneCamera = sceneCameraTransform:GetComponent(typeof(CS.UnityEngine.Camera))
    if not sceneCamera then
        return
    end
    
    -- 将玩家世界坐标转换为视口坐标
    local playerViewportPos = sceneCamera:WorldToViewportPoint(playerWorldPosition)
    
    -- 获取UI相机
    local uiCamera = CS.XUiManager.Instance.UiCamera
    
    -- 获取 _MoverPlayer 的位置（PanelPlayer 的 UI 世界坐标）
    local moverPlayerWorldPos = self.PanelPlayer.transform.position
    local moverPlayerViewportPos = uiCamera:WorldToViewportPoint(moverPlayerWorldPos)
    
    -- 计算玩家到 _MoverPlayer 的距离
    local dxPlayer = playerViewportPos.x - moverPlayerViewportPos.x
    local dyPlayer = playerViewportPos.y - moverPlayerViewportPos.y
    local playerToMoverDistance = math.sqrt(dxPlayer * dxPlayer + dyPlayer * dyPlayer)
    
    -- 计算 _MoverPlayer 到 3 个节点的距离
    local nodeDistances = {}
    if self._PixelationNodes then
        for i, node in ipairs(self._PixelationNodes) do
            if node and not XTool.UObjIsNil(node) then
                local nodeWorldPos = node.transform.position
                local nodeViewportPos = uiCamera:WorldToViewportPoint(nodeWorldPos)
                
                local dx = moverPlayerViewportPos.x - nodeViewportPos.x
                local dy = moverPlayerViewportPos.y - nodeViewportPos.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                nodeDistances[i] = {
                    node = node,
                    distance = distance
                }
            end
        end
    end
    
    -- 选择节点
    local selectedNode = nil
    
    -- 如果没有节点距离数据，使用默认的 FxPixelation01
    if XTool.IsTableEmpty(nodeDistances) then
        selectedNode = self.FxPixelation01
    else
        -- 按距离排序（从小到大）
        table.sort(nodeDistances, function(a, b)
            return a.distance < b.distance
        end)
        
        -- 根据玩家到 _MoverPlayer 的距离选择节点
        if #nodeDistances == 1 then
            selectedNode = nodeDistances[1].node
        elseif #nodeDistances == 2 then
            local d1 = nodeDistances[1].distance
            local d2 = nodeDistances[2].distance
            
            if playerToMoverDistance <= d1 then
                selectedNode = nodeDistances[1].node
            elseif playerToMoverDistance <= d2 then
                -- 在 d1 和 d2 之间，看更接近哪个
                local distToD1 = math.abs(playerToMoverDistance - d1)
                local distToD2 = math.abs(playerToMoverDistance - d2)
                selectedNode = (distToD1 < distToD2) and nodeDistances[1].node or nodeDistances[2].node
            else
                selectedNode = nodeDistances[2].node
            end
        elseif #nodeDistances >= 3 then
            local d1 = nodeDistances[1].distance
            local d2 = nodeDistances[2].distance
            local d3 = nodeDistances[3].distance
            
            if playerToMoverDistance <= d1 then
                selectedNode = nodeDistances[1].node
            elseif playerToMoverDistance <= d2 then
                -- 在 d1 和 d2 之间，看更接近哪个
                local distToD1 = math.abs(playerToMoverDistance - d1)
                local distToD2 = math.abs(playerToMoverDistance - d2)
                selectedNode = (distToD1 < distToD2) and nodeDistances[1].node or nodeDistances[2].node
            elseif playerToMoverDistance <= d3 then
                -- 在 d2 和 d3 之间，看更接近哪个
                local distToD2 = math.abs(playerToMoverDistance - d2)
                local distToD3 = math.abs(playerToMoverDistance - d3)
                selectedNode = (distToD2 < distToD3) and nodeDistances[2].node or nodeDistances[3].node
            else
                selectedNode = nodeDistances[3].node
            end
        end
    end
    
    -- 如果没有找到可用的节点，使用默认的 FxPixelation01
    if not selectedNode then
        selectedNode = self.FxPixelation01
    end
    
    -- 克隆选中的节点
    local clonedFx = XUiHelper.Instantiate(selectedNode.gameObject, selectedNode.transform.parent)
    
    -- 获取节点原始位置的 z 坐标（保持在相同的 UI 层级）
    local originalZ = selectedNode.transform.position.z
    
    -- 计算相机到节点的距离（用于 ViewportToWorldPoint）
    local cameraToNodeDistance = originalZ - uiCamera.transform.position.z
    
    -- 将玩家视口坐标转换为UI世界坐标，使用相机到节点的距离作为 z
    local viewportPosWithDepth = CS.UnityEngine.Vector3(playerViewportPos.x, playerViewportPos.y, cameraToNodeDistance)
    local uiWorldPosition = uiCamera:ViewportToWorldPoint(viewportPosWithDepth)
    
    -- 设置克隆体的位置
    clonedFx.transform.position = uiWorldPosition
    
    -- 激活克隆体
    clonedFx:SetActiveEx(true)
    
    -- 保存定时器ID以便后续销毁
    if not self._PixelationTimers then
        self._PixelationTimers = {}
    end
    
    -- 先声明 timerId，才能在回调函数内使用
    local timerId
    -- 一定时间后移除克隆体
    timerId = XScheduleManager.ScheduleOnce(function()
        if clonedFx and not XTool.UObjIsNil(clonedFx) then
            CS.UnityEngine.Object.Destroy(clonedFx)
        end
        -- 从定时器列表中移除
        if self._PixelationTimers then
            for i, id in ipairs(self._PixelationTimers) do
                if id == timerId then
                    table.remove(self._PixelationTimers, i)
                    break
                end
            end
        end
    end, XScheduleManager.SECOND * PixelationEffectDurationSeconds)
    
    -- 保存定时器ID以便后续销毁
    table.insert(self._PixelationTimers, timerId)
end

--- 清理所有像素化特效定时器
function XUiPacMan2Game:_ClearPixelationTimers()
    if self._PixelationTimers then
        for _, timerId in ipairs(self._PixelationTimers) do
            if timerId then
                XScheduleManager.UnSchedule(timerId)
            end
        end
        self._PixelationTimers = {}
    end
end

--- 显示 FlashKill 特效（当 kills 数量变化时）
function XUiPacMan2Game:ShowFlashKillEffect()
    if not self.FlashKill then
        return
    end
    
    -- 克隆 FlashKill 节点
    local clonedFx = XUiHelper.Instantiate(self.FlashKill.gameObject, self.FlashKill.transform.parent)
    
    -- 激活克隆体
    clonedFx:SetActiveEx(true)
    
    -- 保存定时器ID以便后续销毁
    if not self._FlashKillTimers then
        self._FlashKillTimers = {}
    end
    
    -- 先声明 timerId，才能在回调函数内使用
    local timerId
    -- 在配置的特效持续时间结束后移除克隆体。
    timerId = XScheduleManager.ScheduleOnce(function()
        if clonedFx and not XTool.UObjIsNil(clonedFx) then
            CS.UnityEngine.Object.Destroy(clonedFx)
        end
        -- 从定时器列表中移除
        if self._FlashKillTimers then
            for i, id in ipairs(self._FlashKillTimers) do
                if id == timerId then
                    table.remove(self._FlashKillTimers, i)
                    break
                end
            end
        end
    end, XScheduleManager.SECOND * FlashKillEffectDurationSeconds)
    
    -- 保存定时器ID以便后续销毁
    table.insert(self._FlashKillTimers, timerId)
end

--- 清理所有 FlashKill 特效定时器
function XUiPacMan2Game:_ClearFlashKillTimers()
    if self._FlashKillTimers then
        for _, timerId in ipairs(self._FlashKillTimers) do
            if timerId then
                XScheduleManager.UnSchedule(timerId)
            end
        end
        self._FlashKillTimers = {}
    end
end

function XUiPacMan2Game:OnNotify(eventId, gameManager, message, ...)
    if eventId ~= CS.XEventId.EVENT_PACMAN2_GAME_SIGNAL then
        return
    end

    -- 防止接收到其他玩法实例发出的消息。
    if not self._GameManager or gameManager ~= self._GameManager then
        return
    end

    -- StageLoaded属于开局主流程，仍然使用立即通知，
    -- 不进入普通业务Transaction和条件系统。
    -- 主流程消息直接使用SignalType作为message；
    -- 普通业务消息使用完整Transaction作为message。
    if message == PacMan2SignalType.StageLoaded then
        self._IsOpeningStageLoaded = true
        self:_TryStartOpeningFlow()
        return
    end

    -- 其余消息必须是C#已经收集完成的完整业务Transaction。
    
    -- 先记录业务事实，再执行可能产生表现和流程回调的逻辑。
    -- Statistics只更新统计数据，不触发游戏流程。
    if self._Statistics then
        self._Statistics:OnGameSignalTransaction(message)
    end
    

    -- Runtime先处理暂停请求，保证本事务命中的0秒事件不会提前播放。
    if self._EventRuntime then
        self._EventRuntime:OnGameSignalTransaction(message)
    end

    if not self._IsGameOver then
        -- 普通UI先提交完整事务的最终状态。
        self._GameUiController:OnGameSignalTransaction(message)

        -- 最后处理游戏流程：预约结算或启动受击恢复倒计时。
        self:_HandleGameFlowTransaction(message)
    end
end

---处理完整事务中的游戏流程请求。
---在Runtime处理完事件暂停、普通UI提交完最终显示状态后调用。
---完整扫描后再处理：游戏结束优先于受击恢复，避免依赖消息排列顺序。
---这里只预约结算，不在当前事务调用栈中打开结算界面。
---@param transaction XPacMan2.XPacMan2GameSignalTransaction
function XUiPacMan2Game:_HandleGameFlowTransaction(transaction)
    local signals = transaction.Signals
    local hasGameEnded = false
    local hasDamageRecovery = false

    for index = 0, signals.Length - 1 do
        local signal = signals[index]
        if signal then
            if signal.SignalType == PacMan2SignalType.GameEnded then
                -- 结束通知负责唤醒流程，结算结果以执行时的C#最终状态为准。
                hasGameEnded = true
            elseif signal.SignalType == PacMan2SignalType.GamePauseRequested then
                local reason = signal.Args.Length > 0 and signal.Args[0] or nil
                if reason == GamePauseReason.DamageRecovery then
                    hasDamageRecovery = true
                end
            end
        end
    end

    -- 同一事务同时包含结束和受击恢复时，只处理结束流程。
    if hasGameEnded then
        self:_TryScheduleSettlement()
        return
    end

    if hasDamageRecovery then
        self:_TryStartDamageRecoveryCountdown()
    end
end

---@param dialogType number DialogType
---@param text string
---@param forceAppend? boolean
---@param characterName? string
---@param headIcon? string
function XUiPacMan2Game:AppendDialog(dialogType, text, forceAppend, characterName, headIcon)
    text = text or ""

    if text == "" then
        return
    end
    local dialogKey = tostring(dialogType) .. "|" .. text

    if not forceAppend and self._LastDialogKey == dialogKey then
        return
    end

    self._LastDialogKey = dialogKey

    if self._VisualController then
        self._VisualController:ShowDialogue(dialogType, text, characterName, headIcon)
    end

    if XMain.IsDebug then
        print("Append dialog:" .. text)
    end
end

-- 纯文本接口
function XUiPacMan2Game:AppendText(text, forceAppend)
    self:AppendDialog(DialogType.Text, text, forceAppend)
end

-- 头像、名字、文本接口
function XUiPacMan2Game:AppendCharacterText(text, characterName, headIcon, forceAppend)
    self:AppendDialog(DialogType.Character, text, forceAppend, characterName, headIcon)
end

---根据普通UI已同步的最终状态选择背景，不再查询C#。
---优先级：玩家反杀背景 > 幽灵追击背景 > 普通背景。
---@param isPlayerKillGhostPhase boolean 玩家是否处于反杀状态。
---@param ghostState XPacMan2.XPacMan2GhostState 幽灵全局行为状态。
function XUiPacMan2Game:RefreshBackgroundByState(isPlayerKillGhostPhase, ghostState)
    local backgroundType = BackgroundType.Default
    if isPlayerKillGhostPhase then
        backgroundType = BackgroundType.PlayerKillGhost
    elseif ghostState == CS.XPacMan2.XPacMan2GhostState.Attack then
        backgroundType = BackgroundType.GhostKillPlayer
    end

    -- 相同背景不重复开关节点
    if self._BackgroundType ~= backgroundType then
        self._BackgroundType = backgroundType
        self:UpdateBackground()
    end
end

---释放开局流程持有的操作锁。
function XUiPacMan2Game:_ReleaseOpeningControlLock()
    if not self._OpeningControlLockToken then
        return
    end

    if self._InputManager then
        self._InputManager:ReleaseLock(self._OpeningControlLockToken)
    end

    self._OpeningControlLockToken = nil
end

---尝试启动开局流程。
---StageLoaded和StageStartRequest的完成顺序不固定，
---因此两边完成后都调用本方法，由本方法统一判断。
function XUiPacMan2Game:_TryStartOpeningFlow()
    if self._IsOpeningFlowStarted then
        return
    end

    if not self._IsOpeningStageLoaded then
        return
    end

    if not self._IsStageStartRequestCompleted then
        return
    end

    self._IsOpeningFlowStarted = true

    if self._HasServerStageStarted and self._Statistics then
        self._Statistics:BeginRound()
    end

    XLog.Debug("[XUiPacMan2Game] OpeningFlowStarted, stageId=" .. tostring(self._StageId))

    -- 局内重开仍然等待场景加载和服务器开始请求完成，
    -- 但不提交开局事件组，直接进入原有321倒计时。
    if self._IsRestart then
        XLog.Debug("[XUiPacMan2Game] RestartWithoutOpeningEvent, stageId=" .. tostring(self._StageId))
        self:_FinishOpeningFlow()
        return
    end

    -- 只提供按钮响应，不主动打开Overlay。
    -- 开局事件是否使用Overlay仍由策划配置决定。
    if self._VisualController then
        self._VisualController:SetOverlaySkipCallback(function()
            return self:OnOverlaySkipRequested()
        end)
    end

    local onOpeningCompleted = function()
        XLog.Debug("[XUiPacMan2Game] OpeningEventCompleted, stageId=" .. tostring(self._StageId))
        self:_FinishOpeningFlow()
    end

    if not self._EventRuntime then
        onOpeningCompleted()
        return
    end

    local groupRuntimeId = self._EventRuntime:ExecuteOpeningEvent(self._StageId, onOpeningCompleted)

    -- 零秒事件可能同步完成，不能把已经结束的运行Id重新写回来。
    if not self._IsOpeningFlowFinished then
        self._OpeningEventGroupRuntimeId = groupRuntimeId
    end
end

---正常播放完成、主动跳过和局内重开共用的开局结束入口。
---撤销本流程提供的跳过响应，再进入原有倒计时。
---不负责打开或关闭Overlay，页面是否关闭由具体业务操作决定。
function XUiPacMan2Game:_FinishOpeningFlow()
    if not self._IsOpeningFlowStarted or self._IsOpeningFlowFinished then
        return
    end

    self._IsOpeningFlowFinished = true
    self._OpeningEventGroupRuntimeId = nil

    -- 开局已经结束，撤销“跳过开局”的入口，但不关闭Overlay。
    if self._VisualController then
        self._VisualController:SetOverlaySkipCallback(nil)
    end

    XLog.Debug("[XUiPacMan2Game] OpeningFlowFinished, stageId=" .. tostring(self._StageId))

    -- 保持原有顺序：先启动倒计时停用输入，再释放开局操作锁。
    self:StartCountDown()
    self:_ReleaseOpeningControlLock()
end

---由Overlay的跳过入口调用。
---先取消事件组，再关闭页面，页面关闭后继续倒计时。
---@return boolean 是否受理
function XUiPacMan2Game:OnOverlaySkipRequested()
    local groupRuntimeId = self._OpeningEventGroupRuntimeId

    if self._IsOpeningFlowFinished or not groupRuntimeId then
        return false
    end

    if not self._EventRuntime or not self._VisualController then
        return false
    end

    -- 只取消当前开局实例，不调用正常完成回调，也不重置整个Runtime。
    if not self._EventRuntime:CancelEventGroup(groupRuntimeId) then
        return false
    end

    -- 清除Id后，重复请求不会再次进入。
    self._OpeningEventGroupRuntimeId = nil

    XLog.Debug("[XUiPacMan2Game] OpeningSkipRequested")

    -- 关闭期间仍保留Game的开局操作锁。
    -- 直到页面关闭、开始321后，再由统一结束入口释放。
    self._VisualController:SetOverlayEnabled(false, function()
        self:_FinishOpeningFlow()
    end)

    return true
end

function XUiPacMan2Game:OnPacMan2EventGroupCompleted(groupRuntime)
    XLog.Debug("[XUiPacMan2Game] EventGroup completed, eventGroupId=" .. tostring(groupRuntime.EventGroupId) .. ", runtimeId=" .. tostring(groupRuntime.RuntimeId))
end

---@param settleType number
---@return table
function XUiPacMan2Game:_BuildSettleData(settleType)
    local gameManager = self._GameManager
    local data = {
        StageId = self._StageId,
        Score = gameManager:GetOrbs(),
        SettleType = settleType,
        OperateType = self._IsTouch and 1 or 2,
        ReStartTimes = self._Control:GetRestartTimes(),
        -- 只累计Playing期间的时间，暂停和倒计时不计入。
        Time = math.floor(gameManager.Duration),
        Orbs = gameManager.Orbs,
        Kills = gameManager.Kills,
        Hp = gameManager:GetPlayerHp(),
        IsLastHp = gameManager.IsLastHp,
        Shoe = {
            { Id = EntityEnum.Ghost, Times = gameManager.ShoeNormalGhost },
            { Id = EntityEnum.RangeGhost, Times = gameManager.ShoeRangeGhost },
            { Id = EntityEnum.SlowGhost, Times = gameManager.ShoeSlowGhost },
            { Id = EntityEnum.Shoe, Times = gameManager.ShoeProp },
        },
        TakeBackPoint = gameManager.OrbsPayback,
    }
    self._Statistics:FillSettleData(data)
    return data
end

---提交本次运行的结算数据。
---防重复标记表示已提交请求，不等于服务器已确认成功。
---@param settleType number
---@return boolean
function XUiPacMan2Game:_SubmitSettle(settleType)
    if self._HasSubmittedSettle then
        return false
    end
    -- 调试模式可能没有成功建立服务器对局，此时不能提交结算。
    if not self._HasServerStageStarted  then
        return false
    end

    if not self._GameManager or not self._Statistics then
        return false
    end

    -- 在Game和统计对象销毁前，生成完整的数据快照。
    local data = self:_BuildSettleData(settleType)
    self._HasSubmittedSettle = true
    local accepted = XMVCA.XPacMan2:PacMan2SettleRequest(data)
    if not accepted then
        self._HasSubmittedSettle = false
        return false
    end
    return true
end

function XUiPacMan2Game:SubmitAbortSettlement()
    self:_SubmitSettle(SettleType.Abort)
end

function XUiPacMan2Game:ReportRoundLeave(leaveType,roundScore)
    if not self._Statistics then
        return
    end
    local starCount = nil
    if leaveType == LeaveType.RestartAfterClear then
        starCount = self._Control:CalculateStageStar(self._StageId, roundScore)
    end
    
    local operateType = self._IsTouch and 1 or 2
    local orbCount = self._GameManager:GetOrbs()
    self._Statistics:ReportRoundLeave(leaveType,operateType,starCount, orbCount)
end

return XUiPacMan2Game