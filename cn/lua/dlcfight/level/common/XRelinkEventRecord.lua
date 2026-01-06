local XRelinkEventRecord = XClass(nil, "XRelinkEventRecord")
--统计工具
---@param proxy XDlcCSharpFuncs
function XRelinkEventRecord:Ctor(proxy)
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end
function XRelinkEventRecord:Init(Porxy, LevelName)
    self._levelName = LevelName
    -- self._data ={
    --     MakeDamageData = {
    --         Npc1 = value,
    --         Npc2 = value,
    --         ...
    --     },
    --     TakeOnDamageData = {
    --         Npc1 = value,
    --         Npc2 = value,
    --         ...
    --     },
    --     CureData = {
    --         Npc1 = value,
    --         Npc2 = value,
    --         ...
    --     },
    --     CounterData = {
    --         Npc1 = value,
    --         Npc2 = value,
    --         ...
    --     },
    --     BreakTimes = 0,
    --     FullChainTimes = 0,
    -- }
    self._resultDataKey = {                 --传值键值 
        CureDataTimes = 133005,             --治疗次数
        LinkTimes = 133006,                 --break次数   Linktime OD结束后的那个break
        FullChain = 133007,                  --FC      
        MultiGuardTimes = 133008,           --多人弹刀
        MakeDamageData = 133009,            --伤害  
        TakeOnDamageData = 133010,          --抗伤
        CureData = 133011,                  --治疗量
        BreakCount = 133012,                --破韧次数
        Deaths = 133013,                    --死亡次数
        DeathTime = 133014,                 --死亡时长               --无
        RescueTime = 133015,                --救人时长               --无
        Qtes = 133016,                      --QTE                    --无
        CounterData = 133017,               --拼刀成功
        ClashFailCount = 133018,            --拼刀失败次数          --无 
        FullChain_2 = 133019,               --触发2人fullchain     --无了 
        FullChain_3 = 133020,               --触发3人fullchain
        WrestleTimes = 133021,              --角力次数
        TeamWorkSkillTimes = 133022,         --极限技释放次数
        DragonDpsCheckTimes= 133023,         --白龙DPS检测通过次数
        OverDriveTimes = 133024,            --进入OD次数
        DragonDpsCheckFailTimes = 133025,   --白龙DPS检测失败次数
    }
    self._data = {
        --个人项目
        MakeDamageData = {},                --造成伤害
        TakeOnDamageData = {},              --承受伤害
        CureData = {},                      --治疗
        CureDataTimes = {},                 --治疗次数
        CounterData = {},                   --拼刀次数
        Deaths = {},                        --死亡次数
        WrestleTimes = {},                  --角力次数
        Qtes = {},                          --破韧追击次数          --无
        FullChain = {},                     --参与FC次数
        TeamWorkSkillTimes = {},              --极限技释放次数
        --团队项目
        BreakCount = 0,                     --Break次数
        LinkTimes = 0,                      --破韧次数
        FullChain_2 = 0,                    --触发2人fullchain     --无
        FullChain_3 = 0,                   --触发3人fullchain
        DragonDpsCheckTimes = 0,             --白龙DPS检测通过次数
        DragonDpsCheckFailTimes = 0,          --白龙DPS检测失败次数
        OverDriveTimes = 0,                 --进入OD次数
        MultiGuardTimes = 0,               --多人参与弹刀
    }
    self._playerIdDictionary = {}

    Porxy:RegisterEvent(EWorldEvent.NpcDamage)                                     --事件注册：NPC伤害
    Porxy:RegisterEvent(EWorldEvent.NpcCure)                                       --事件注册：NPC治疗
    Porxy:RegisterEvent(EWorldEvent.NpcDie)                                        --事件注册：NPC死亡
    Porxy:RegisterEvent(EWorldEvent.CastFullChainFinalSkill)                       --事件注册：Fullchain
    Porxy:RegisterEvent(EWorldEvent.NpcWrestleReversal)                            --事件注册：角力成功
    Porxy:RegisterEvent(EWorldEvent.NpcMultiParrySucceed)                          --事件注册：多人弹刀成功
    Porxy:RegisterEvent(EWorldEvent.NpcWaitReboot)                                 --事件注册：进入复活
    Porxy:RegisterEvent(EWorldEvent.NpcODBreakBefore)                              --事件注册：怪物break
    Porxy:RegisterEvent(EWorldEvent.NpcBrokenBefore)                               --事件注册：怪物破韧
    Porxy:RegisterEvent(EWorldEvent.NpcAddBuff)                                    --事件注册：上buff 用于白龙DPS检测通过
    Porxy:RegisterEvent(EWorldEvent.NpcTeamWorkSkillCast)                          --事件注册：极限技释放次数
    Porxy:RegisterEvent(EWorldEvent.NpcEnterOverDrive)                             --事件注册：进入OD
    Porxy:RegisterEvent(EFightLuaEvent.RelinkCounterSuccess)                       --事件注册：单人弹刀成功
end

function XRelinkEventRecord:AddPlayerNpc(playerId, uuid)        --初始化所有个人数据，在logic的初始化玩家处初始化
    self._data.MakeDamageData[uuid] = 0
    self._data.TakeOnDamageData[uuid] = 0
    self._data.CureData[uuid] = 0
    self._data.CureDataTimes[uuid] = 0
    self._data.CounterData[uuid] = 0
    self._data.Deaths[uuid] = 0
    self._data.MultiGuardTimes = 0
    self._data.WrestleTimes[uuid] = 0
    self._data.Qtes[uuid] = 0
    self._data.FullChain[uuid] = 0
    self._playerIdDictionary[uuid] = playerId
    self._data.TeamWorkSkillTimes[uuid] = 0
end


function XRelinkEventRecord:HandleEvent(eventType, eventArgs)                     
    if eventType == EWorldEvent.NpcDamage then     --伤害事件
        if self._data.MakeDamageData[eventArgs.LauncherId] ~= nil then     --防止伤害来源是白龙
            self._data.MakeDamageData[eventArgs.LauncherId] = self._data.MakeDamageData[eventArgs.LauncherId] + eventArgs.PhysicalDamage + eventArgs.ElementDamage + eventArgs.RealDamage
        end
        if self._data.TakeOnDamageData[eventArgs.TargetId] ~= nil then      --防止挨打的是白龙
            self._data.TakeOnDamageData[eventArgs.TargetId] = self._data.TakeOnDamageData[eventArgs.TargetId] + eventArgs.PhysicalDamage + eventArgs.ElementDamage + eventArgs.RealDamage
        end
    elseif  eventType == EWorldEvent.NpcCure then    --治疗事件
        if self._data.CureData[eventArgs.LauncherId] ~= nil then
            self._data.CureDataTimes[eventArgs.LauncherId] = self._data.CureDataTimes[eventArgs.LauncherId] + 1
            self._data.CureData[eventArgs.LauncherId] = self._data.CureData[eventArgs.LauncherId] + eventArgs.Value
        end
    elseif  eventType == EWorldEvent.NpcWaitReboot then    --死亡事件
        if self._data.Deaths[eventArgs.NpcId] ~= nil then
            self._data.Deaths[eventArgs.NpcId] = self._data.Deaths[eventArgs.NpcId] + 1
        end

    elseif  eventType == EWorldEvent.CastFullChainFinalSkill then  --3人FullChain完成
            self._data.FullChain_3 = self._data.FullChain_3 + 1

    elseif  eventType == EWorldEvent.NpcWrestleReversal then  --角力成功
        if self._data.WrestleTimes[eventArgs.LauncherUUID] ~= nil then
            self._data.WrestleTimes[eventArgs.LauncherUUID] = self._data.WrestleTimes[eventArgs.LauncherUUID] + 1
        end
    elseif  eventType == EWorldEvent.NpcODBreakBefore then   --怪物break次数
        self._data.LinkTimes = self._data.LinkTimes + 1 
    elseif  eventType == EWorldEvent.NpcBrokenBefore then   --怪物破韧次数
        self._data.BreakCount = self._data.BreakCount + 1
    elseif  eventType == EWorldEvent.NpcMultiParrySucceed then -- 多人弹刀成功
            self._data.MultiGuardTimes = self._data.MultiGuardTimes + 1
    elseif eventType == EWorldEvent.NpcTeamWorkSkillCast then  -- 极限技成功次数
        if self._data.TeamWorkSkillTimes[eventArgs.sourceUUID] ~= nil then
            self._data.TeamWorkSkillTimes[eventArgs.sourceUUID] = self._data.TeamWorkSkillTimes[eventArgs.sourceUUID] + 1
        end
    elseif eventType == EWorldEvent.NpcAddBuff then  -- 白龙DPS检测
        if eventArgs.BuffTableId == 8005915 then
            --白龙专用:DPS检测成功1次
            self._data.DragonDpsCheckTimes = self._data.DragonDpsCheckTimes + 1
        elseif eventArgs.BuffTableId == 8005916 then
            --白龙专用:DPS检测失败1次
            self._data.DragonDpsCheckFailTimes = self._data.DragonDpsCheckFailTimes + 1
        end
    elseif eventType == EWorldEvent.NpcEnterOverDrive then  -- OD次数
        if self._data.OverDriveTimes[eventArgs.TargetUUID] ~= nil then
            self._data.OverDriveTimes[eventArgs.TargetUUID] = self._data.OverDriveTimes[eventArgs.TargetUUID] + 1
        end
    end
end

function XRelinkEventRecord:HandleLuaEvent(eventType, eventArgs) --lua自定义事件响应逻辑
    if eventType == EFightLuaEvent.RelinkCounterSuccess then --弹刀成功？
    XLog.Debug("弹刀成功")
        if self._data.CounterData[eventArgs.counterNpcUUID] ~= nil then
            self._data.CounterData[eventArgs.counterNpcUUID] = self._data.CounterData[eventArgs.counterNpcUUID] + 1
            XLog.Debug("拼刀次数+1")
        end
    end
end


function XRelinkEventRecord:SetResultData(Proxy)
    for uuid, _ in pairs(self._data.MakeDamageData) do
        local playerId = self._playerIdDictionary[uuid]
        local damage =    self._data.MakeDamageData[uuid]
        local takeOnDamage =    self._data.TakeOnDamageData[uuid]
        local cure =    self._data.CureData[uuid]
        local curetimes =  self._data.CureDataTimes[uuid] 
        local counter = self._data.CounterData[uuid] 
        local deaths = self._data.Deaths[uuid]
        local wrestle = self._data.WrestleTimes[uuid]  
        local qte = self._data.Qtes[uuid] 
        local fullchain = self._data.FullChain[uuid]
        local teamWorkSkillTimes = self._data.TeamWorkSkillTimes[uuid]

        --个人项目
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.MakeDamageData, damage)  --133009 伤害
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.TakeOnDamageData, takeOnDamage)  --133010 抗伤
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.CureData, cure)  --治疗 133011
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.CureDataTimes, curetimes)  --治疗次数 133005
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.CounterData, counter)  --133017 拼刀
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.Deaths, deaths)  --133013 死亡次数
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.WrestleTimes, wrestle)    --133021 角力
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.Qtes, qte)                             --无了
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.FullChain, fullchain) --133007 Fc参与
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.TeamWorkSkillTimes, teamWorkSkillTimes) --133022 极限技释放次数
        --团队项目
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.BreakCount, self._data.BreakCount) --133012 破韧
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.LinkTimes, self._data.LinkTimes) --133006 Break
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.FullChain_2, self._data.FullChain_2) --无了
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.FullChain_3, self._data.FullChain_3) --133020 3人Fc
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.TeamWorkSkillTimes, self._data.TeamWorkSkillTimes) --133022 极限技
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.DragonDpsCheckTimes, self._data.DragonDpsCheckTimes) --133023 白龙DPS检测通过
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.OverDriveTimes, self._data.OverDriveTimes) --133024 OD次数
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.MultiGuardTimes, self._data.MultiGuardTimes)  --133008 多人弹刀
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.DragonDpsCheckFailTimes, self._data.DragonDpsCheckFailTimes) --133025 白龙DPS检测失败

        XLog.Debug("玩家"..playerId.."   造成伤害:"..damage)
        XLog.Debug("玩家"..playerId.."   抗伤:"..takeOnDamage)
        XLog.Debug("玩家"..playerId.."   治疗:"..cure)
        XLog.Debug("玩家"..playerId.."   治疗次数:"..curetimes)
        XLog.Debug("玩家"..playerId.."   拼刀次数:"..counter)
        XLog.Debug("玩家"..playerId.."   死亡次数:"..deaths)
        XLog.Debug("玩家"..playerId.."   角力次数:"..wrestle)
        XLog.Debug("玩家"..playerId.."   参与FC次数:"..fullchain)
        XLog.Debug("玩家"..playerId.."   Break次数:"..self._data.BreakCount)
        XLog.Debug("玩家"..playerId.."   破韧次数:"..self._data.LinkTimes)
        XLog.Debug("玩家"..playerId.."   极限技次数:"..self._data.MultiGuardTimes)
    end 
end

function XRelinkEventRecord:Destory()
    self._levelName = nil
    self._data = nil
    self = nil
end


return XRelinkEventRecord