--- 玩法内部使用的枚举类，单独封装方便管理
local Theatre5EnumConst = {
    --- 游戏模式
    GameModel = {
        PVP = 1,
        PVE = 2,
    },
    
    --- 大段位状态
    RankMajorState = {
        Beyond = 1, -- 玩家当前段位超过目标大段位
        Belong = 2, -- 玩家当前段位处于目标大段位
        Below = 3, -- 玩家当前段位低于目标大段位
    },
    
    --- 物品类型
    ItemType = {
        Skill = 1, -- 技能
        Equip = 2, -- 装备
        ItemBox = 3, --道具箱
        Gold = 4, --金币
        Clue = 5, --线索
        Common = 6, --通用的道具， Item.tab
    },
    
    --- 物品容器类型
    ItemContainerType = {
        Goods = 1, -- 商品
        BagBlock = 2, -- 背包格子
        SkillBlock = 3, -- 技能格子
        EquipBlock = 4, -- 装备格子
        SkillSelection = 5, -- 新技能选择
        NormalDetails = 6, --常规详情展示(不要按钮)
        TempBagBlock = 7, --临时背包格子
    },
    
    --- 商店操作类型
    ShopOperationType = {
        BuyGem = 1,
        SellGem = 2,
        SelectSkill = 3,
        DiscardSkill = 4,
    },
    
    --- Theatre5ShopRefreshCost配置表Id的前缀
    RefreshCntCostIdPreix = 1000,
    PveSceneChatPreix = 1000,
    PveEventLevelPreix = 1000,
    PveEventOptionPreix = 10, -- *10
    PveChapterLevelPreix = 1000,
    ShopNpcChatPreix = 1000,
    DeduceQuestionPreix = 1000,
    
    --- 结算状态
    DlcFightSettleState = {
        None = 0, -- 正常结算
        ForceExit = 1, -- 未完成对局主动退出
        AdvanceExit = 2, -- 完成对局提前结算
        PlayerOffline = 3, -- 玩家掉线
    },
    
    --- 商店状态
    ShopState = {
        Normal = 1, -- 常规商店
        SkillChoice = 2, -- 技能三选一
    },

    --故事线类型
    PVEStoryLineType = {
        Normal = 1, --普通故事线
        Guide = 2, --教学故事线
        Together = 3, --共同故事线
    },

    --章节类型
    PVEChapterType = {
        Deduce = 1, --推演
        Chat = 2, --场景对话
        AVG = 3,
        NormalBattle = 4, --一次性战斗
        DeduceBattle = 5, --推演战斗
        StoryLineEnd = 6, --故事线结束
    },

    --章节进度
    PVEChapterProcess = {
        Head = 1, --头
        Process = 2,
        End = 3, --尾
    },

    --节点状态
    PVENodeState = {
        Idle = 1,
        Running = 2,
        Completed = 3
    },

    --事件类型
    PVEEventType = {
        Chat = 1, --对话
        Option = 2, --选项
    },

    --事件选项
    PVEOptionType = {
        CostItem = 1, --需要花费道具
        HasItem = 2, --需要有指定的道具
        NormalChat = 3, --普通对话
    },

    --线索类型
    PVEClueType = {
        Core = 1, --核心线索
        Normal = 2, --普通线索
    },

    --线索状态
    PVEClueState = {
        NoShow = 1, --未展示
        Lock = 2, --未解锁
        Unlock = 3, --已解锁
        Deduce = 4, --可推演
        Completed = 5, --已完成
    },

    --普通线索显示类型
    PVEClueShowType = {
        Core = 1, --核心线索样式
        Normal = 2, --普通线索样式
    },

    --故事线节点类型
    PVENodeType = {
        Deduce = 1, --推演
        Chat = 2, --场景对话
        AVG = 3,
        Event = 4, --事件
        BattleChapterMain = 5, --战斗章节
        Shop = 6, --商店节点
        Battle = 7, --战斗
        StoryLineEnd = 8, --故事线结束
        BattleChapterStart = 9, --战斗章节关开始
        BattleChapterEnd = 10, --战斗章节关结束
        SkillSelect = 11, --技能选择
        ItemBoxSelect = 12, --宝箱选择
        BattleChapterInit = 13, --战斗章节初始化
    },
    
    --- 玩家游戏状态
    PlayStatus = {
        PveEveHandle = 1, --事件处理中
        NotStart = 2,  -- 未开始游戏
        ChoiceSkill = 3,  -- 技能三选一
        Shopping = 4,  -- 商店购物中
        Matching = 5,  -- 匹配中
        Battling = 6,  -- 正在战斗
        BattleFinish = 7,  -- 战斗结束（结算界面）
    },

    --章节关卡状态
    PVEChapterLevelState = {
        Lock = 1, --未开始
        Running = 2, --进行中
        Completed = 3, --完成
    },

    --宝珠品质颜色
    GemQualityColor = {
        Blue = 1,
        Purple = 2,
        Orange = 3,
    },
    
    -- 宝珠类型
    GemType = {
        Passive = 0, -- 被动型
        Active = 1, -- 主动型
    },

    --道具宝箱打开的方式
    ItemBoxOpenType = {
        SelectOne = 1, --多选一
        All = 2, --全部获得
    },
    
    -- 角色属性显示方式
    AttribShowType = {
        Normal = 1, -- 自然数，直接显示数值
        Percentage = 2, -- 百分比，需要除以100后显示，带%符号
    },

    -- 对话触发类型
    ChatTriggerType = {
        UIPanel = 1,  --点击界面
        ClickBtn = 2, --按钮点击
    },

    --商店npc触发对话的方式
    ShopNpcTriggerChatType = {
        Click = 1, --点击
        Buy = 2, --购买
        Sell = 3, --出售
    },

    --pve战斗结束状态
    PVEBattleEndState = {
        BattleLevelCompleted = 1, --战斗关卡完成
        BattleChapterCompleted = 2, --战斗章节完成
        BattleAgain = 3, --再来一次
    },
    
    -- 角色涂装配置索引
    CharacterFashionIndexType = {
        Default = 1, -- 默认涂装
        Special = 2, -- 特殊涂装
    },

    --任务商店的类型
    TaskShopType = {
        Shop = 1, --商店
        Task = 2, --任务
    },
    
    -- 需要乘基数的属性枚举
    EnlargedAttribs = {
        [XDlcNpcAttribType.Speed] = true,
        [XDlcNpcAttribType.JumpSpeed] = true,
        [XDlcNpcAttribType.RunSpeed] = true,
        [XDlcNpcAttribType.RunSpeedCOE] = true,
        [XDlcNpcAttribType.JumpSpeedCOE] = true,
        [XDlcNpcAttribType.IdleJumpSpeedCOE] = true,
        [XDlcNpcAttribType.WalkJumpSpeedCOE] = true,
        [XDlcNpcAttribType.SprintJumpSpeedCOE] = true,
        [XDlcNpcAttribType.RunStartJumpSpeedCOE] = true,
        [XDlcNpcAttribType.SprintStartJumpSpeedCOE] = true,
        [XDlcNpcAttribType.RotationSpeed] = true,
        [XDlcNpcAttribType.WalkSpeed] = true,
        [XDlcNpcAttribType.WalkSpeedCOE] = true,
        [XDlcNpcAttribType.SprintSpeed] = true,
        [XDlcNpcAttribType.SprintSpeedCOE] = true,
    },
    
    -- 角色动画状态
    CharacterAnimaState = {
        Start = 1, -- 动画开始状态，相当于AnyState
        Choose = 2, -- 角色选择界面选中状态
        FullView = 3, -- 角色选择界面全景状态
        Detail = 4, -- 商店等局内详情状态
    },

    -- 角色动画类型
    CharacterAnimaType = {
        FullViewSwitch = 1, -- 切换全景时的待机动画
        FullView = 2, -- 全景时的待机动画
        ChooseSwitch = 3, -- 切换选中的待机动画
        Choose = 4, -- 选中时的待机动画
        Detail = 5, -- 局内详情页待机动画
    },
    
    -- 引导战斗暂停指令
    FightPauseOrResumeType = {
        Resume = 0,
        Pause = 1,
    }
}


return Theatre5EnumConst