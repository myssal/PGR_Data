---向导AI的key值索引(待优化)
NGuideAINoteKey = {
    AIMode = 1000,                  -- int AI 模式
    GuideCaptionId = 10011,         -- int 向导提示字幕
    GuideTargetPos = 10012,         -- float3 向导目标位置
    GuideOutOfRouteDistance = 10013,-- float 向导时玩家偏移路径的距离范围
    FollowIdleLimit = 10021,     -- float 跟随玩家时待机距离范围
    FollowRunLimit = 10022,      -- float 跟随玩家时待机距离范围, 该值要大于FollowIdleDistance
}

---跳跳乐参数索引值
EJumperLevelVarKey = {
    Score = "Score",                            -- int 分数
    DeathCount = "DeathCount",                  -- int 掉入死区次数
    GoldCount = "GoldCount",                    -- int 吃金币数
    StarCount = "StarCount",                    -- int 获得星星数
    IsTriggerJudge = "IsTriggerJudge",          -- bool 是否触发保底
    IsTriggerHideRoad = "IsTriggerHideRoad",    -- bool 是否触发隐藏路线
}