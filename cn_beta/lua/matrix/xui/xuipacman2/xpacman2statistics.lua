local SignalType = CS.XPacMan2.XPacMan2SignalType
local GhostState = CS.XPacMan2.XPacMan2GhostState

local Time = CS.UnityEngine.Time
local CsGameState = CS.XPacMan2.XPacMan2GameState

local GameClearState = CS.System.Convert.ToInt32(CsGameState.GameClear)

-- 1000050最后遭遇事件的客户端埋点约定。
local LastEvent = {
    Other = 0,
    -- 运营埋点中的“被击杀”：
    -- 玩家碰怪受伤、复位，随后进入恢复倒计时，不代表对局结束。
    Damaged = 1,
    ItemPicked = 2,
    Cleared = 3
}

-- 1000050离开类型的客户端埋点约定。
local LeaveType = {
    Abort = 1,
    Restart = 2,
    RestartAfterClear = 3,
}

---@class XPacMan2Statistics
local XPacMan2Statistics = XClass(nil,"XPacMan2Statistics")
-- Game使用同一份定义，不在各个入口重复填写数字。
XPacMan2Statistics.LeaveType = LeaveType

---@param initialGhostState XPacMan2.XPacMan2GhostState
function XPacMan2Statistics:Ctor(initialGhostState)
    -- 1000050按每次关卡运行独立统计。
    -- 包含开局表现、倒计时、系统暂停及结算页等待，
    -- 只扣除手动ESC菜单停留时间。
    self._RoundStartTime = nil
    self._ManualPauseStartTime = nil
    self._ManualPauseSeconds = 0
    
    self._LastEvent = LastEvent.Other

    -- 对局结束后固定最后遭遇事件，避免后续信号覆盖结束结果。
    self._RoundEnded = false

    -- 表示本次运行已调用离开日志接口，不表示日志平台已确认收到。
    self._HasReportedLeave = false

    -- 本次关卡运行中的有效扣血次数。
    -- 单次扣除多点生命，仍然只统计一次。
    self._SubHpTimes = 0

    -- 本次关卡运行中，各类道具的累计拾取次数。
    -- key为XPacMan2EntityEnum对应的整数值，value为次数。
    ---@type table<number, number>
    self._ItemPickupCounts = {}

    -- 本次关卡运行中，各类怪物的累计击杀数量。
    -- key为XPacMan2EntityEnum对应的整数值，value为数量。
    ---@type table<number, number>
    self._GhostKillCounts = {}

    -- Game传入初始化状态，后续由Game转发完整业务事务。
    -- 复活保护属于已经进入追击阶段后的临时保护状态。
    self._IsTriggerChase = initialGhostState == GhostState.Attack or initialGhostState == GhostState.ReviveProtectionTime
end

---接收Game已完成实例过滤的完整业务事务，不包含StageLoaded流程通知。
---按原始业务Signal统计，不依赖事件条件系统的合并结果。
---@param transaction XPacMan2.XPacMan2GameSignalTransaction
function XPacMan2Statistics:OnGameSignalTransaction(transaction)
    local signals = transaction.Signals
    -- 同一事务如果既有道具拾取又有对局结束，
    -- 最后统一使用结束结果，避免依赖Signal排列顺序。
    local roundEndEvent = nil
    
    for index = 0, signals.Length - 1 do
        local signal = signals[index]
        if signal then
            local signalType = signal.SignalType
            local args = signal.Args

            if signalType == SignalType.HpChanged then
                local oldHp = args[0]
                local newHp = args[1]

                if newHp < oldHp then
                    self._SubHpTimes = self._SubHpTimes + 1
                    if not self._RoundEnded then
                        self._LastEvent = LastEvent.Damaged
                    end
                end
            elseif signalType == SignalType.GhostStateChanged then
                local newState = args[1]
                if newState == GhostState.Attack or newState == GhostState.ReviveProtectionTime then
                    self._IsTriggerChase = true
                end
            elseif signalType == SignalType.ItemChanged then
                self:_OnItemChanged(args)
            elseif signalType == SignalType.KillChanged then
                self:_OnKillChanged(args)
            elseif signalType == SignalType.GameEnded then
                local gameState = args[0]
                if gameState == GameClearState then
                    roundEndEvent = LastEvent.Cleared
                end
            end
        end
    end
    if roundEndEvent ~= nil then
        self._LastEvent = roundEndEvent
        self._RoundEnded = true
    end
end

function XPacMan2Statistics:_OnItemChanged(args)
    local itemType = args[0]
    if itemType == nil then
        XLog.Error("[XPacMan2Statistics] ItemChanged缺少itemType")
        return
    end

    -- C#传来的是枚举，协议需要整数Id。
    local itemId = CS.System.Convert.ToInt32(itemType)
    local counts = self._ItemPickupCounts
    counts[itemId] = (counts[itemId] or 0) + 1

    if not self._RoundEnded then
        self._LastEvent = LastEvent.ItemPicked
    end
end

function XPacMan2Statistics:_OnKillChanged(args)
    if not args or args.Length < 3 then
        XLog.Error("[XPacMan2Statistics] KillChanged缺少怪物类型参数")
        return
    end
    local oldKills = args[0]
    local newKills = args[1]
    local ghostType = args[2]

    if oldKills == nil or newKills == nil or ghostType == nil then
        XLog.Error("[XPacMan2Statistics] KillChanged参数不完整")
        return
    end
    
    local killCount = newKills - oldKills
    if killCount <= 0 then
        return
    end
    local ghostId = CS.System.Convert.ToInt32(ghostType)
    if ghostId <= 0 then
        XLog.Error("[XPacMan2Statistics] 怪物类型未初始化，请检查ImportConfig")
        return
    end
    
    local counts = self._GhostKillCounts
    counts[ghostId] = (counts[ghostId] or 0) + killCount
end

---开始本次关卡运行的离开统计。
---场景和开局请求就绪后调用一次，后续恢复游戏不能重复开始。
function XPacMan2Statistics:BeginRound()
    if self._RoundStartTime ~= nil then
        return
    end
    self._RoundStartTime = Time.realtimeSinceStartupAsDouble
end

---开始扣除手动ESC暂停时间。
---受伤暂停、开局事件和倒计时不能调用此方法。
function XPacMan2Statistics:BeginManualPause()
    if self._RoundStartTime == nil then
        return
    end
    if self._ManualPauseStartTime ~= nil then
        return
    end
    self._ManualPauseStartTime = Time.realtimeSinceStartupAsDouble
end

---退出ESC菜单时结束扣时。
---在开始恢复倒计时之前调用，因此恢复倒计时计入对局时长。
function XPacMan2Statistics:EndManualPause()
    if self._ManualPauseStartTime == nil then
        return
    end
    local now = Time.realtimeSinceStartupAsDouble
    self._ManualPauseSeconds = self._ManualPauseSeconds + (now - self._ManualPauseStartTime)
    self._ManualPauseStartTime = nil
end

function XPacMan2Statistics:_GetRoundDuration()
    local now = Time.realtimeSinceStartupAsDouble
    local pauseSeconds = self._ManualPauseSeconds

    if self._ManualPauseStartTime ~= nil then
        pauseSeconds = pauseSeconds + (now - self._ManualPauseStartTime)
    end
    
    local duration = now - self._RoundStartTime - pauseSeconds
    return math.max(0,math.floor(duration))
end

function XPacMan2Statistics:FillSettleData(data)
    data.SubHpTimes = self._SubHpTimes
    data.IsTriggerChase = self._IsTriggerChase

    local itemData = {}
    local bossData = {}
    for ghostId, count in pairs(self._GhostKillCounts) do
        bossData[#bossData + 1] = {
            Id = ghostId,
            KillCount = count,
        }
    end
    data.BossData = bossData
    
    for itemId,count in pairs(self._ItemPickupCounts) do
        itemData[#itemData + 1] = {
            Id = itemId,
            Count = count,
        }
    end

    data.ItemData = itemData
end

---仅在主动放弃或重开时调用。
---正常退出、下一关和对象释放不触发上报。
---@param leaveType number
---@param operateType number 1滑动，2摇杆，沿用现有结算统计口径
---@param starCount number|nil 仅通关后重开时传入本局星级
---@param orbCount number 本次运行玩家获得的豆子总数，即累计抢救数
---@return boolean 是否调用了日志接口
function XPacMan2Statistics:ReportRoundLeave(leaveType,operateType,starCount, orbCount)
    if self._HasReportedLeave then
        return false
    end
    if self._RoundStartTime == nil then
        return false
    end
    local dict = {
        i_last_event = self._LastEvent,
        i_duration = self:_GetRoundDuration(),
        i_operate_type = operateType,
        i_take_back_point = orbCount,
        i_leave_type = leaveType,
    }

    -- 运营说仅在重开时记录星级
    if leaveType == LeaveType.RestartAfterClear then
        dict.i_star = starCount
    end
    self._HasReportedLeave = true
    if XMain.IsWindowsEditor then
        CS.XRecord.RecordTest(dict, "1000050", "PacMan2RoundLeave")
    else
        CS.XRecord.Record(dict, "1000050", "PacMan2RoundLeave")
    end
    return true
end

return XPacMan2Statistics