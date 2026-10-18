
---Regression4 常量（配置读取在 XRegression4AgencyConfig）
XRegression4EnumConst = {}

--- 页签类型
---@field Main 主界面
---@field Sign 签到
---@field Passport 战令
---@field Task 任务
---@field Shop 商店
---@field Activity 活动
---@field Questionnaire 问卷
---@field GiftShop 礼品商店
---@field Boost 回归助力
XRegression4EnumConst.ActivityType = {
    Main = 1,
    Sign = 2,
    Passport = 3,
    Task = 4,
    Shop = 5,
    Activity = 6,
    Questionnaire = 7,
    GiftShop = 8,
    Boost = 9,
}

--- 双倍奖励类型，对应服务端 XRegression4DoubleType
---@field RepeatChallengeMultiReward 复刷关(预热关)多倍奖励
XRegression4EnumConst.DoubleType = {
    RepeatChallengeMultiReward = 1,
}

--- 任务类型
XRegression4EnumConst.TaskType = {
    Daily       = 1,
    Weekly      = 2,
    Permanent   = 3,
    TimeLimit   = 4,
}

--- 活动状态
---@field NotInRegression 不在活动开放期内
---@field InRegression 活动开放期内
---@field RegressionEnded 活动已结束
XRegression4EnumConst.ActivityState = {
    NotInRegression = 1,
    InRegression    = 2,
    RegressionEnded = 3,
}

--- 玩法货币Id
XRegression4EnumConst.Regression4CoinId = 107

return XRegression4EnumConst
