---条件系统内部字段协议。
---
---字段分为两类：
---1. 状态字段：保存在ConditionContext中，供Trigger和Condition读取；
---2. 触发字段：只表示某件事情刚刚发生，不保存到ConditionContext。
---
---只有策划条件或者Trigger需要使用的数据才应加入这里。
local XUiPacMan2ConditionField = {
    -- 状态字段。
    PlayerHp = "PlayerHp",
    -- 本关发生有效扣血的次数。
    DamageTakenCount = "DamageTakenCount",
    -- 本关累计实际损失的生命值。
    DamageTakenAmount = "DamageTakenAmount",

    -- 玩家当前持有的豆子数量。
    -- 包括直接拾取以及击杀怪物后夺回的豆子。
    PlayerOrbCount = "PlayerOrbCount",
    -- 玩家当前持有豆子占本关总豆子数量的百分比，范围为0到100。
    PlayerOrbProgress = "PlayerOrbProgress",
    KillCount = "KillCount",
    -- 玩家当前是否处于可以击杀怪物的反杀阶段。
    -- 这是持续状态，可与击杀、扣血、道具拾取等其他条件组合。
    PlayerKillGhostPhaseActive = "PlayerKillGhostPhaseActive",
    
    
    -- 本关成功拾取回血道具的累计次数。
    HealItemPickupCount = "HealItemPickupCount",
    -- 本关成功拾取加速道具的累计次数。
    SpeedItemPickupCount = "SpeedItemPickupCount",
    -- 本关成功拾取反杀道具的累计次数。
    KillItemPickupCount = "KillItemPickupCount",


    -- 本关成功使用传送门的累计次数。
    PortalEnterCount = "PortalEnterCount",
    
    
    
    -- 瞬时触发字段。
    
    -- 玩家刚刚进入反杀阶段。
    PlayerKillGhostPhaseEntered = "PlayerKillGhostPhaseEntered",
    -- 玩家刚刚退出反杀阶段。
    PlayerKillGhostPhaseExited = "PlayerKillGhostPhaseExited",
    -- 撤离点刚刚开启。
    ExitEnabled = "ExitEnabled",
    -- 反杀道具刚刚整体开放，可以被玩家拾取。
    -- 不表示玩家已经拾取道具或进入反杀阶段。
    KillItemActivated = "KillItemActivated",
}

return XUiPacMan2ConditionField��时正常完成。
    -- 包括正常播放或跳过开局剧情后的倒计时，以及结算界面再来一局。
    -- 不包括暂停菜单内重新挑战。
    OpeningCountdownCompleted = "OpeningCountdownCompleted",

    -- 受伤恢复的321倒计时正常完成。
    DamageRecoveryCountdownCompleted = "DamageRecoveryCountdownCompleted",

    -- 暂停菜单内重新挑战，新关卡的321倒计时正常完成。
    RestartCountdownCompleted = "RestartCountdownCompleted",
}

return XUiPacMan2ConditionField