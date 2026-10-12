---Agency部分类，注册枚举与常量
---@type XSkyTowerAgency
local XSkyTowerAgency = XClassPartial('XSkyTowerAgency')

--初始化通天塔枚举，只有活动开启才会分配内存
function XSkyTowerAgency:InitEnum()
    --region 区域与工位
    -- UI与行为树的表现状态，由ServerWorkState映射，不参与生产结算
    self.WorkState = {
        -- 空闲
        Free = 1,
        -- 工作中
        Working = 2,
        -- 工作暂停
        Pause = 3,
    }
    -- 服务端工位工作类型（对应服务端XSkyTowerWorkType，与SkyTowerWorkPos表Type一致）
    self.WorkType = {
        None = 0,
        -- 备菜
        Ingredient = 1,
        -- 做菜
        Food = 2,
        -- 售卖
        Sale = 3,
    }
    -- 服务端工位工作状态（对应服务端XSkyTowerWorkState）
    self.ServerWorkState = {
        -- 正常
        Normal = 0,
        -- 等待入库（产出满）
        WaitForStorage = 1,
        -- 等待消耗（原料不足）
        WaitForConsume = 2,
        -- 停止
        Stop = 3,
    }
    --endregion

    --region 产品与演出
    -- 服务端产品类型（对应服务端XSkyTowerProductType）
    self.ProductType = {
        -- 材料
        Ingredient = 1,
        -- 物品
        Food = 2,
    }
    -- 演出类型
    self.PerformType = {
        --演出/事件
        Event = 1,
        --订单
        Indent = 2,
        --区间目标事件
        FloorGroup = 3,
    }
    -- 订单状态
    self.PerformState = {
        NotStart = 0,
        OnGoing = 1,
        Finish = 2,
    }
    -- 需要显示解锁弹窗的物品（有序）
    self.UnlockItemType = {
        Illustrated = 1, --原料
        Food = 2, --食谱/物品
        Character = 3, --角色
    }
    --endregion

    --region 角色与技能
    -- 技能标签类型（SkyTowerSkillType表的Type）
    self.SkillTabType = {
        Collect = 1, -- 采集
        Make = 2, --制作
        Sale = 3, -- 售卖
        Wish = 4, -- 愿望（技能带ConditionType）
        Aura = 5, -- 光环（技能对非自身工位生效）
        Universal = 6, -- 通用
        AllRound = 7, -- 全能（多面手）
    }
    -- 技能图标类型
    self.SkillIconType = {
        -- 默认
        Normal = 1,
        -- 愿望
        Wish = 2,
        -- 光环
        Aura = 3,
        -- 通用
        Universal = 4,
    }
    -- 技能加成类型（SkyTowerCharacterSkill表SkillAdditionType[i]，与同下标的ProductId/SkillAddition配对，对齐服务端XSkyTowerSkillAdditionType）
    self.SkillAdditionType = {
        None = 0,
        --生产周期缩短，加成值单位是秒
        ReduceTime = 1,
        --产出数量提升，加成值按万分比
        UpProduce = 2,
        --售卖单价提升，加成值是金币增量
        UpProductPrice = 3,
    }
    -- 技能生效范围的坐标偏移特殊值（ShareType填"x_y"相对偏移，x为工位横坐标差、y为楼层差）
    self.ShareOffset = {
        --自身工位对应的偏移
        SelfX = 0,
        SelfY = 0,
    }
    -- 技能触发条件类型（SkyTowerCharacterSkill表ConditionType，对齐服务端XSkyTowerSkillConditionType）
    self.SkillConditionType = {
        --无额外条件，技能解锁即生效
        None = 0,
        --位于指定角色的相对位置时触发
        NearbyCharacter = 1,
        --位于指定楼层或工作区时触发
        WorkPosition = 2,
        --所处楼层越高效果越强
        FloorHeight = 3,
        --每满足一个角色的技能激活效果越强
        OtherActiveCharacter = 4,
    }
    -- SkillConditionType.OtherActiveCharacter的ConditionParams[1]统计范围（对齐服务端XSkyTowerSkillAreaType）
    self.SkillAreaType = {
        --自身所在的楼层区间
        FloorGroup = 1,
        --自身所在的楼层
        Floor = 2,
        --所有楼层
        AllFloor = 3,
    }
    -- 技能生效状态（拖动换位时的实时预览态）
    self.SkillEffectState = {
        --未生效
        NotActive = 1,
        --已生效
        Active = 2,
        --放下后将生效
        WillActive = 3,
        --放下后将失效
        WillDeactivate = 4,
    }
    -- 工位可否放入的判定结果
    self.DropCheckResult = {
        --可放入
        Ok = 1,
        --拖动的工作类型与目标工位的指定工作不符
        WorkTypeMismatch = 2,
        --拖动源是限制工位，换位后对方工作会落到限制工位引起冲突
        SourceLimited = 3,
        --换位后角色会去往它不能工作的楼层分区
        FloorGroupMismatch = 4,
        --换位后产品会落到不属于它的楼层分区，仓库无对应槽位
        ProductGroupMismatch = 5,
    }
    --角色弹窗升级按钮状态
    self.StaffUpgradeState = {
        --可升级（代币不足只影响文本颜色，按钮仍可点）
        Normal = 1,
        --解锁条件未满足，置灰但可点
        Lock = 2,
        --已满级，置灰不可用
        Max = 3,
    }
    --endregion

    --region 通天塔成长
    --通天塔升级效果类型
    self.EffectType = {
        IngredientCount = 1,
        FoodCount = 2,
        SaleCount = 3,
        --SkyTowerLv表已无CharacterLimit/CashierLimit/HotSaleAddition列，
        --对应的4员工上限、5收银台上限、6热销加成三种效果通天塔都没有，SkyTowerLvUpEffectText后三行已废弃
    }
    -- 通天塔升级条件类型（GetSkyTowerUnlockConditionList返回项的Type）
    self.LvUpConditionType = {
        --前置条件
        Precondition = 1,
        --道具消耗
        Consume = 2,
    }
    -- 楼层升级弹窗的行样式
    self.LevelUpRowType = {
        Value = 1, --单个数值
        ValueChange = 2, --升级前后对比
        Toggle = 3, --勾选项
    }
    --endregion

    --region 任务与签到
    --任务类型
    self.TaskType = {
        Daily = 1, --每日任务
        Recipe = 2, --食谱任务
        Activity = 3, --活动任务
    }
    --演出任务类型
    self.PerformTaskType = {
        GainGold = 143001, --获得x个金币
        Production = 143002, --制造x件产品
        SellOut = 143003, --售卖x件产品
        TowerLevel = 143004, --大楼达到x级
        RoleLevel = 143005, --角色达到x级
        PerformTimes = 143006, --完成事件/订单/区间目标事件x次
        Perform = 143007, --完成某个事件/订单/区间目标事件
        GainGoldSpeed = 143008, --某个分区售卖工位少于x时金币获取速度达到y
    }
    --签到状态
    self.SignState = {
        Incomplete = 1, --签到未完成
        Complete = 2, --签到已完成
    }
    --endregion

    --region 界面与交互
    --通天塔日志页签类型
    self.MenuTabType = {
        Perform = 1, --事件
        Indent = 2, --订单
        Food = 3, --食谱
    }
    --对话类型
    self.MessageType = {
        Auto = 1,
        Select = 2,
    }
    --埋点按钮
    self.BuryingButton = {
        BtnShop = 1,
        BtnTask = 2,
        BtnMenu = 3,
        BtnGo = 4,
        BtnStatistics = 6,
    }
    self.StaffSortGroup = {
        FreeWithAddition = 1, -- 有加成的空闲员工
        FreeWithAura = 2, -- 有光环的空闲员工
        Universal = 3, -- 通用员工
        FreeWithoutAddition = 4, -- 无加成的空闲员工
        Working = 5, -- 工作中的员工
    }
    --endregion
end

---初始化通天塔常量
function XSkyTowerAgency:InitConst()
    --region 等级范围（源表自动生成）
    self.MaxLv = self._Model:GetIntClientConfigValue("MaxLv")
    self.MaxFloorId = self._Model:GetIntClientConfigValue("MaxFloorId")
    --endregion

    --region 员工等级
    --SkyTowerCharacterLv表Id = CharacterId * StaffLevelBase + Lv
    self.StaffLevelBase = 100
    --等级下界（SkyTowerCharacterLv的Lv从1起）
    self.StaffLevelMin = 1
    --倒序探测SkyTowerCharacterLv最大等级的Lv上界，实际最大等级以表为准
    self.StaffLevelSearchMax = 99
    --endregion

    --region 道具
    --道具Id
    self.ItemId = {
        --局内金币
        SkyTowerCoin = 38000001,
        --角色升级券
        SkyTowerUpgradeCoin = 38000002,
        --加速道具
        SkyTowerAccelerate = 38000003,
    }
    --endregion

    --region 时间与数值
    --时间单位
    self.TimeUnit = {
        Second = 1,
        Minute = 60,
        Hour = 3600
    }
    --保留小数位数
    self.Digital = {
        One = 1,
        Two = 2,
    }
    --用于消除误差
    self.Inaccurate = 0.0000001
    -- 万分比基数
    self.TenThousandRate = 10000
    --生产周期下限（秒），对齐服务端MinCycleDuration，减到0工位会以极限速度空转
    self.MinCycleDuration = 1
    --单轮产出份数下限，对齐服务端MinOutputCount，避免工位白耗材料却不产出
    self.MinOutputCount = 1
    --endregion

    --region 特殊标识值
    --角色FloorGroup特殊值：-1表示全分区通用
    self.CharacterFloorGroupAll = -1
    -- SkyTowerCharacterSkill的ConditionParams某一项配0或没配时表示该维度不做限制
    self.UnlimitedConditionParam = 0
    --endregion

    --region 角色弹窗
    -- 成员技能筛选标签展示上限
    self.SkillFilterMaxTagCount = 3
    --数字滚动时长（秒）
    self.StaffRollDuration = 0.3
    --文本颜色
    self.StaffColor = {
        --代币充足
        CoinEnough = XUiHelper.Hexcolor2Color("0D70BC"),
        --代币不足
        CoinNotEnough = XUiHelper.Hexcolor2Color("FF0000"),
        --下一级预览态高亮
        Preview = XUiHelper.Hexcolor2Color("0D70BC"),
        --加成为正
        AdditionUp = XUiHelper.Hexcolor2Color("356C38"),
        --加成为负
        AdditionDown = XUiHelper.Hexcolor2Color("CE453B"),
    }
    --endregion

    --region 角色拖动与主界面
    -- 主界面提示条展示时长（秒）
    self.TipShowTime = 2
    -- 分区定位按钮数量上限
    self.NavigationMaxButtonCount = 4
    -- 分区定位提示条展示时长（秒）
    self.NavigationTipShowTime = 3
    -- 仓库面板展开/收起时长（秒）
    self.StorageMoveDuration = 0.5
    -- 拖动时源工位的透明度
    self.DragSourceAlpha = 0.5
    -- 工位倒计时文本颜色
    self.WorkBenchColor = {
        --停工
        Pause = XUiHelper.Hexcolor2Color("FF0000"),
        --工作中
        Working = XUiHelper.Hexcolor2Color("FFFFFF"),
    }
    -- 未解锁工位Lock模型的呼吸光参数（升级弹窗聚焦新工作区域时播放的缩放脉动）
    self.BreathScale = {
        --缩放倍率下界
        Min = 0.92,
        --缩放倍率上界
        Max = 1.08,
        --单程时长（秒）
        Duration = 0.6,
    }
    -- SkyTowerCharacterSkill表ShareType的坐标分隔符
    self.ShareTypeSeparator = "_"
    --endregion

    --region 安排工作界面
    -- 事件/订单进度条最多展示几条
    self.WorkOrderMaxCount = 2
    --endregion

    --region 加载界面
    -- 进度条推进速度（每秒推进的比例）
    self.SceneLoadingBarSpeed = 0.5
    --endregion

    --region 本地化文本
    self.TimeText = {
        Minute = CS.XTextManager.GetText("Minute"),
        Second = CS.XTextManager.GetText("Second"),
    }
    --endregion
end

return XSkyTowerAgency
