---@type XRelinkBossBase
local Base = require("Character/FightCharBase/XRelinkBossBase")

---白龙
---@class XChar8005 : XRelinkCharBase
local XChar8005 = XDlcScriptManager.RegCharScript(8005, "XChar8005", Base)

--region 函数: 脚本生命周期
function XChar8005:Init()
    Base.Init(self)

    --- 修正角度的技能ID
    self._angleRectifySkills = {
        [1] = 8005003,      -- 右45度
        [2] = 8005004,      -- 左45度
        [3] = 8005005,      -- 右90度
        [4] = 8005006,      -- 左90度
        [5] = 8005007,      -- 右135度
        [6] = 8005008,      -- 左135度
        [7] = 8005009       -- 180度
    }
    --- 角度修正的区间
    self._angleRectifyConds ={
        [1] = {{30, 50}},
        [2] = {{-50, -30}},
        [3] = {{50, 105}},
        [4] = {{-105, -50}},
        [5] = {{105, 150}},
        [6] = {{-150, -105}},
        [7] = {{150, 180}, {-180, -150}}
    }
    --- 修正距离的技能
    self._disRectifySkills = {
        [1] = 8005015,      -- 小后跳
        [2] = 8005056       -- 小后撤
    }
    --- 距离修正技能的修正距离
    self._disRectifyConds = {
        [1] = 8,
        [2] = 4
    }
    --- 最大烦躁值
    self._maxRectifyIrritation = 25
    --- 角度修正的烦躁增长值表
    self._angleRectifyCostTable = {
        [1] = 5,
        [2] = 5,
        [3] = 5,
        [4] = 5,
        [5] = 5,
        [6] = 5,
        [7] = 5
    }
    --- 距离修正的烦躁增长值表
    self._disRectifyCostTable = {
        [1] = 5,
        [2] = 5,
    }
    --- 烦躁后的技能ID表
    self._irritationSkills = {
        8005014,
    }

    --- 存储技能信息，其中 [技能ID] = {CD, 转阶段是否重置CD, 是否允许修正, 距离条件, 角度条件}
    self._skillInfos =
    {
        [8005012] = {     -- 入战吼
            math.huge,   false,   false,   {},   {}
        },
        [8005011] = {     -- OD吼
            math.huge,   true,    false,   {},   {}
        },
        [8005014] = {
            0,          true,    true,    {},   {}
        },
        [8005030] = {     -- 二连小前咬
            0,          true,    true,    {7, 11}, {{-60, 60}}
        },
        [8005031] = {     -- 右扫爪+拍地板
            0,          true,    true,    {6, 12}, {{-60, 60}}
        },
        [8005032] = {     -- 黄圈右扫爪
            0,          true,    true,    {6, 14}, {{-90, 60}}
        },
        [8005035] = {     -- 黄圈左扫爪
            0,           true,    true,    {6, 14}, {{-60, 90}}
        },
        [8005037] = {      -- 黄圈左扫爪 + 起飞砸地（占位）
            0,           true,    true,    {6, 14}, {{-60, 90}}
        },
        [8005033] = {      -- 身后二连甩尾
            0,           true,    false,    {6, 12}, {{-180, -120}, {120, 180}}
        },
        [8005034] = {      -- 后撤开炮
            0,           true,    true,    {6, 12}, {{-60, 60}}
        },
        [8005038] = {      -- 左刺
            0,           true,    true,    {8, 12}, {{-55, 55}}
        },
        [8005039] = {      -- 左右刺
            0,           true,    true,    {10, 17.5}, {{-55, 55}}
        },
        [8005036] = {      -- 龙车
            0,           true,    true,    {6, 35}, {{-55, 55}}
        },
        [8005040] = {      -- 龙车+起飞砸地
            0,           true,    true,    {6, 12}, {{-55, 55}}
        },
        [8005045] = {      -- 龙车+起飞失败
            0,           true,    true,    {6, 12}, {{-55, 55}}
        },
        [8005041] = {      -- 浮游炮射击
            0,           true,    true,    {6, 12}, {{-55, 55}}
        },
        [8005042] = {      -- 小喷火
            0,           true,    true,    {6, 12}, {{-45, 45}}
        },
        [8005043] = {      -- 大喷火
            0,           true,    true,    {12, 25}, {{-55, 55}}
        },
        [8005046] = {      -- 蓄力跳砸
            0,           true,    true,    {7, 35}, {{-55, 55}}
        },
        [8005047] = {      -- 喷气起飞冲地
            0,           true,    true,    {6, 25}, {{-55, 55}}
        },
        [8005051] = {      -- 横扫口爆
            0,           true,    true,    {4, 9}, {{-55, 55}}
        },
        [8005055] = {      -- 飞天轰炸
            math.huge,    true,    false,   {},   {}
        }
    }

    --- 技能冷却时间计时器
    self._skillCdTimers = {
        [8005012] = 0,
        [8005011] = 0,
        [8005014] = 0,
        [8005030] = 0,
        [8005031] = 0,
        [8005032] = 0,
        [8005035] = 0,
        [8005037] = 0,
        [8005033] = 0,
        [8005034] = 0,
        [8005038] = 0,
        [8005039] = 0,
        [8005036] = 0,
        [8005040] = 0,
        [8005045] = 0,
        [8005041] = 0,
        [8005042] = 0,
        [8005043] = 0,
        [8005046] = 0,
        [8005047] = 0,
        [8005051] = 0,
        [8005055] = 0
    }

    --- 技能并行群组
    self._skillGroup = {
        -- 1号轴普通阶段
        [1] = {{8005011, 1, 1}},             -- OD吼
        [2] = {{8005012, 1, 1}},             -- 落地吼
        [3] = {{8005030, 1, 1}},             -- 二连前咬
        [4] = {{8005031, 1, 1}},             -- 右扫爪+拍地板
        [5] = {{8005032, 1, 1}},             -- 黄圈右扫
        [6] = {{8005033, 1, 1}},             -- 身后二连甩尾
        [7] = {{8005034, 1, 1}},             -- 后撤开炮
        [8] = {{8005035, 1, 1}},             -- 黄圈左扫
        [9] = {{8005036, 1, 1}},             -- 龙车
        [10] = {{8005037, 1, 1}},            -- 黄圈扫+砸地
        [11] = {{8005038, 1, 1}},            -- 左刺
        [12] = {{8005039, 1, 1}},            -- 左右刺
        [13] = {{8005040, 1, 1}},            -- 龙车+起飞砸地
        [14] = {{8005041, 1, 1}},            -- 浮游炮射击
        [15] = {{8005042, 1, 1}},            -- 小喷火
        [16] = {{8005043, 1, 1}},            -- 大喷火
        [17] = {{8005046, 1, 1}},            -- 蓄力跳砸
        [18] = {{8005047, 1, 1}},            -- 喷气起飞冲地
        [19] = {{8005051, 1, 1}},            -- 横扫口爆
        [20] = {{8005055, 1, 1}},            -- 飞天轰
        [21] = {{8005030, 1, 2}, {8005046, 1, 1}},  -- 二连咬 or 蓄力跳砸
        [22] = {{8005032, 1, 1}, {8005037, 1, 1}}   -- 右扫爪 or 左扫爪+起飞砸地
    }

    --- 期望技能轴，按照顺序执行循环
    self._intendSkillSeqs = {
        -- 弹刀测试技能轴
        [1] = {
            [XChar8005.EBattleState.NormalState] = { 2, 9, 17, 3, 4, 5, 7, 11 },
            [XChar8005.EBattleState.ODState] = { 1, 20, 9, 17, 16, 19, 12, 4, 14, 8, 18  },
        }
        --[1] = {
        --    [XChar8005.EBattleState.NormalState] = { 2, 3},
        --    [XChar8005.EBattleState.ODState] = { 1, 3 },
        --}
    }

    --- 连招表
    --TODO: 可配置
    self._comboTable = {
        -- 右扫接左扫拍地
        --[[
        [8005032] = {
            [1] = {0,  8005037,  {2.2, 2.3},  0.5,  7,  1,  {2, 14},  {{-35, 120}}}
        },
        ]]
    }

    --- ODBreak技能组
    self._odBreakSkillSeq = {
        8005121,
        8005122,
        8005123
    }

    --- 破韧技能表（适配多方位破韧受击）
    self._tenacityBreakSkillSeq = {
        8005124,
        8005128,
        8005132,
        8005136
    }

    --- 破韧不同角度受击动作的触发角度条件
    self._tenacityBreakAngleConds = {
        {{-45, 45}},
        {{-135, -45}},
        {{45, 135}},
        {{-180, -135}, {135, 180}}
    }

    -- 临时初始化时打开AI
    self._isAiActivated = true

    --- 是否调试核心战斗逻辑
    self._isDebugBattleLogic = false
    --- 是否调试修正逻辑
    self._isDebugRectifyLogic = false
    --- 是否调试追逐逻辑
    self._isDebugChasingLogic = false
    --- 是否调试OD值
    self._isDebugODValue = false
    --- 是否调试韧性值
    self._isDebugTenacity = false

    --- 血量伤害半分比 -> 韧性增长的转换率
    self._hpPctToTenaIncreRatio = 18
    --- 血量伤害半分比 -> OD值增长的转换率
    self._hpPctToODIncreRatio = 5
    --- 血量伤害百分比 -> OD值削减的转换率
    self._hpPctToODDecreRatio = 3

    --self._testDelayTime = 100
    self._rHandReflectParticle = 8005003
    self._lHandReflectParticle = 8005002
    self._lightReflectSlomo = 8005004
    self._heavyReflectSlomo = 8005005

    -- 事件绑定
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcDamageBefore)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

---@param dt number @ delta time
function XChar8005:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8005:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8005:Terminate()
    -- 事件解绑
    self._proxy:UnregisterEvent(EWorldEvent.NpcCalcDamageBefore)
    self._proxy:UnregisterEvent(EWorldEvent.NpcAddBuff)

    Base.Terminate(self)
end
--endregion

--region 函数重写
function XChar8005:CustomInSkillLogic()
    -- 对白龙的一些修正技能进行提前打断，很多动作有些拖沓，验证过后可以让美术微调

    -- 打断大翻身
    if self._proxy:CheckNpcCurrentSkill(self._uuid, 8005014) and self._skillTimer >= 1.567 then
        self._proxy:AbortSkill(self._uuid, true)
    end

    -- 打断小后跳
    if self._proxy:CheckNpcCurrentSkill(self._uuid, 8005015) and self._skillTimer >= 1.4 then
        self._proxy:AbortSkill(self._uuid, true)
    end

    -- 打断小后撤
    if self._proxy:CheckNpcCurrentSkill(self._uuid, 8005056) and self._skillTimer >= 0.867 then
        self._proxy:AbortSkill(self._uuid, true)
    end

    -- 打断右转45
    if self._proxy:CheckNpcCurrentSkill(self._uuid, 8005003) and self._skillTimer >= 0.833 then
        self._proxy:AbortSkill(self._uuid, true)
    end

    -- 打断左转45
    if self._proxy:CheckNpcCurrentSkill(self._uuid, 8005004) and self._skillTimer >= 0.833 then
        self._proxy:AbortSkill(self._uuid, true)
    end

    -- 打断右转90
    if self._proxy:CheckNpcCurrentSkill(self._uuid, 8005005) and self._skillTimer >= 1.333 then
        self._proxy:AbortSkill(self._uuid, true)
    end

    -- 打断左转90
    if self._proxy:CheckNpcCurrentSkill(self._uuid, 8005006) and self._skillTimer >= 1.333 then
        self._proxy:AbortSkill(self._uuid, true)
    end

    -- 打断右转135
    if self._proxy:CheckNpcCurrentSkill(self._uuid, 8005007) and self._skillTimer >= 1.167 then
        self._proxy:AbortSkill(self._uuid, true)
    end

    -- 打断左转135
    if self._proxy:CheckNpcCurrentSkill(self._uuid, 8005008) and self._skillTimer >= 1.167 then
        self._proxy:AbortSkill(self._uuid, true)
    end

    -- 打断后转180
    if self._proxy:CheckNpcCurrentSkill(self._uuid, 8005009) and self._skillTimer >= 1.267 then
        self._proxy:AbortSkill(self._uuid, true)
    end
end

function XChar8005:OnODBreak()
    Base.OnODBreak(self)

    -- 移除绑定特效buff
    self._proxy:RemoveBuff(self._uuid, 8005012)
    self._proxy:RemoveBuff(self._uuid, 8005013)
    self._proxy:RemoveBuff(self._uuid, 8005014)
    self._proxy:RemoveBuff(self._uuid, 8005015)
    self._proxy:RemoveBuff(self._uuid, 8005016)
    self._proxy:RemoveBuff(self._uuid, 8005017)
    self._proxy:RemoveBuff(self._uuid, 8005018)
    self._proxy:RemoveBuff(self._uuid, 8005019)
    self._proxy:RemoveBuff(self._uuid, 8005020)

    -- 给所有玩家播Break屏幕特效
    --TODO: 目前只给仇恨目标播了
    self._proxy:ApplyMagic(self._uuid, self._uuid, 8005302, 100)
    local players = self._proxy:GetPlayerNpcList()
    for k, playerID in ipairs(players) do
        self._proxy:ApplyMagic(self._uuid, playerID, 8005302, 100)
        self._proxy:ApplyMagic(self._uuid, playerID, 8005201, 100)
        self._proxy:ApplyMagic(self._uuid, playerID, 8005401, 100)
    end
end

function XChar8005:OnStateChanged(previousState, newState)
    if previousState == Base.EBattleState.Inactive and newState == Base.EBattleState.NormalState then
        -- 给全场玩家加仇恨值
        local players = self._proxy:GetPlayerNpcList()
        for key, playerId in ipairs(players) do
            self._proxy:ApplyMagic(self._uuid, playerId, 8005351, 1)
        end
        XLog.Debug("加点仇恨")
    end
end
--endregion

--region 基类事件
function XChar8005:BeforeDamageCalc(eventArgs)
    Base.BeforeDamageCalc(self, eventArgs)
    if self._uuid ~= eventArgs.Launcher or self._uuid == eventArgs.Target then return end
    --XLog.Debug(self._proxy:GetBuffStacks(eventArgs.Target, 105233))
    --XLog.Debug(self._proxy:GetBuffStacks(eventArgs.Target, 105234))
    -- 临时用七实防御buff作弹反条件
    if self._proxy:CheckBuffByKind(eventArgs.Target, 105233) or self._proxy:CheckBuffByKind(eventArgs.Target, 105234) then
        -- 右扫爪弹刀
        if eventArgs.Id == 8005025 then
            self._proxy:AbortSkill(self._uuid, true)
            self._proxy:CastSkillToTarget(self._uuid, 8005503, eventArgs.Target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._rHandReflectParticle, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, eventArgs.Target, self._heavyReflectSlomo, 1)
        end

        -- 左扫爪弹刀
        if eventArgs.Id == 8005026 then
            self._proxy:AbortSkill(self._uuid, true)
            self._proxy:CastSkillToTarget(self._uuid, 8005502, eventArgs.Target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._lHandReflectParticle, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, eventArgs.Target, self._heavyReflectSlomo, 1)
        end

        -- 左刺弹刀
        if eventArgs.Id == 8005030 then
            self._proxy:AbortSkill(self._uuid, true)
            self._proxy:CastSkillToTarget(self._uuid, 8005500, eventArgs.Target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, eventArgs.Target, self._heavyReflectSlomo, 1)
        end

        -- 左右刺弹刀
        if eventArgs.Id == 8005031 then
            -- 左刺
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._lHandReflectParticle, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._lightReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, eventArgs.Target, self._lightReflectSlomo, 1)
        end
        if eventArgs.Id == 8005032 then
            -- 右刺
            self._proxy:AbortSkill(self._uuid, true)
            self._proxy:CastSkillToTarget(self._uuid, 8005501, eventArgs.Target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, eventArgs.Target, self._heavyReflectSlomo, 1)
        end
        -- 蓄力跳砸弹刀
        if eventArgs.Id == 8005035 then
            self._proxy:AbortSkill(self._uuid, true)
            self._proxy:CastSkillToTarget(self._uuid, 8005504, eventArgs.Target)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._heavyReflectSlomo, 1)
            self._proxy:ApplyMagic(self._uuid, eventArgs.Target, self._heavyReflectSlomo, 1)
        end

        -- 清空伤害（貌似还是会有1点伤害？？？）
        --eventArgs.PhysicalPermyraid = 0
        --eventArgs.ElementPermyraid = 0

        -- 临时给玩家添加一个弹刀通知buff
        self._proxy:ApplyMagic(self._uuid, eventArgs.Target, 8005501, 1)
    end

    -- 扫爪+拍地，扫爪卡肉
    if(eventArgs.Id == 8005023) then self._proxy:ApplyMagic(self._uuid, self._uuid, 8005301, 1) end
end

function XChar8005:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    Base.OnNpcDamageEvent(self, launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if targetId ~= self._uuid then return end

    -- 破韧期间受击
    if magicId == 10519201 and self._proxy:CheckBuffByKind(self._uuid, 8005901) then
        self:PlayTenaBreakSkillBySrcPos(launcherId)
    end
end

function XChar8005:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then return end

    self:Skill041LaunchMissile(buffId)
end
--endregion

function XChar8005:Skill041LaunchMissile(buffId)
    --XLog.Debug(buffId)
    if buffId == 8005006 then
        XLog.Debug("浮游炮1")
        XLog.Debug(self._curAggroTarUUID)
        self._proxy:LaunchMissile(self._uuid, self._curAggroTarUUID, 800500001, 1)
        return
    end
    if buffId == 8005007 then
        XLog.Debug("浮游炮2")
        self._proxy:LaunchMissile(self._uuid, self._curAggroTarUUID, 800500002, 1)
        return
    end
    if buffId == 8005008 then
        XLog.Debug("浮游炮3")
        self._proxy:LaunchMissile(self._uuid, self._curAggroTarUUID, 800500003, 1)
        return
    end
    if buffId == 8005009 then
        XLog.Debug("浮游炮4")
        self._proxy:LaunchMissile(self._uuid, self._curAggroTarUUID, 800500004, 1)
        return
    end
    if buffId == 8005010 then
        XLog.Debug("浮游炮5")
        self._proxy:LaunchMissile(self._uuid, self._curAggroTarUUID, 800500005, 1)
        return
    end
    if buffId == 8005011 then
        XLog.Debug("浮游炮6")
        self._proxy:LaunchMissile(self._uuid, self._curAggroTarUUID, 800500006, 1)
        return
    end
end

return XChar8005