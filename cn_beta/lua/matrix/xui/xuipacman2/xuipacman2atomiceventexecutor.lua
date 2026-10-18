local EventDefine = require("XUi/XUiPacMan2/XUiPacMan2EventDefine")

local AtomicType = EventDefine.AtomicType
local SoundAction = EventDefine.SoundAction
local BgmAction = EventDefine.BgmAction
local BgmTrackState = EventDefine.BgmTrackState
local DialogType = EventDefine.DialogType

---以下为临时测试参数。
local BgmAisacControlName = "MusicTrack_Volume_1"
local BgmNormalValue = 0.3
local BgmDrumValue = 1
local BgmCurveTime = 0.5

---@class XUiPacMan2AtomicEventExecutor
---原子事件执行器。
---
---职责：
---1. 根据原子事件类型选择对应执行函数；
---2. 处理各类型自己的覆盖和并发规则；
---3. 确保每个原子事件最终只通知一次完成；
---4. 管理对话计时器和循环音效实例。
---5. 将Overlay开关和消息追加命令交给VisualController。
local XUiPacMan2AtomicEventExecutor = XClass(nil, "XUiPacMan2AtomicEventExecutor")

---@param visualController XUiPacMan2VisualController
---@param eventTimerManager XUiPacMan2EventTimerManager
function XUiPacMan2AtomicEventExecutor:Ctor(visualController, eventTimerManager)
    self._VisualController = visualController
    self._TimerIds = {}
    self._CurrentDialogue = nil
    self._LoopSounds = {}
    self._EventTimerManager = eventTimerManager
    
    self._Executors = {
        [AtomicType.Dialogue] = self._ExecuteDialogue,
        [AtomicType.Sound] = self._ExecuteSound,
        [AtomicType.Bgm] = self._ExecuteBgm,
        [AtomicType.MagicFilter] = self._ExecuteMagicFilter,
        [AtomicType.EndingMask] = self._ExecuteEndingMask,
        [AtomicType.Overlay] = self._ExecuteOverlay,
        [AtomicType.OverlayDialogue] = self._ExecuteOverlayDialogue,
    }
end

---将Params中的"1"/"0"转换成boolean。
---@param value string
---@return boolean|nil
local function ParseBoolean(value)
    if value == "1" then
        return true
    end

    if value == "0" then
        return false
    end

    return nil
end

---执行一个原子事件。
---@param atomicConfig table
---@param atomicRuntime table
---@param onComplete function
function XUiPacMan2AtomicEventExecutor:Execute(atomicConfig, atomicRuntime, onComplete)
    if not atomicConfig then
        XLog.Error("[PacMan2AtomicExecutor] atomicConfig为空")
        onComplete()
        return
    end

    local executor = self._Executors[atomicConfig.EventType]

    if not executor then
        XLog.Error("[PacMan2AtomicExecutor] 不支持的原子事件类型, atomicEventId=" .. tostring(atomicConfig.Id) .. ", type=" .. tostring(atomicConfig.EventType))
        onComplete()
        return
    end

    -- 防止重复完成；已经取消的原子事件不再通知完成。
    local isCompleted = false
    local completeOnce = function()
        if isCompleted or atomicRuntime.IsCancelled then
            return
        end

        isCompleted = true
        onComplete()
    end

    executor(self, atomicConfig, atomicRuntime, completeOnce)
end

---取消一个尚未完成的原子事件。
---不调用完成回调，不回滚已经执行完毕的BGM、滤镜等状态。
---取消不会自动关闭Overlay，页面由明确的关闭事件或外部业务响应关闭。
---@param atomicRuntime table
function XUiPacMan2AtomicEventExecutor:Cancel(atomicRuntime)
    if not atomicRuntime or atomicRuntime.IsCancelled then
        return
    end

    atomicRuntime.IsCancelled = true

    -- 页面异步操作可能已经结束，但完成通知仍在等待事件系统恢复。
    self:_CancelTimer(atomicRuntime.CompletionTimerId)
    atomicRuntime.CompletionTimerId = nil

    local dialogueRuntime = self._CurrentDialogue

    -- 普通Dialogue有独立的显示计时，取消时需要同时停止。
    -- 通过原子事件运行Id判断，避免关闭其他事件组的对话。
    if dialogueRuntime and dialogueRuntime.AtomicRuntimeId == atomicRuntime.RuntimeId then
        self._CurrentDialogue = nil
        self:_CancelTimer(dialogueRuntime.TimerId)

        if self._VisualController then
            self._VisualController:HideDialogue()
        end

        -- 取消不调用dialogueRuntime.OnComplete。
    end
end

---执行对话。
---对话是单通道资源，事件组Id大的覆盖小的，同Id后到覆盖先到。
function XUiPacMan2AtomicEventExecutor:_ExecuteDialogue(atomicConfig, atomicRuntime, onComplete)
    local params = atomicConfig.Params or {}
    local duration = tonumber(params[1]) or 0
    local text = params[2] or ""
    local headIcon = params[3] or ""
    local characterName = params[4] or ""
    local eventGroupId = atomicRuntime.EventGroupId or 0
    
    if duration <= 0 then
        XLog.Error("[PacMan2AtomicExecutor] 对话显示时间必须大于0, atomicEventId=" .. tostring(atomicConfig.Id))
        onComplete()
        return
    end

    local currentDialogue = self._CurrentDialogue

    if currentDialogue then
        if currentDialogue.EventGroupId > eventGroupId then
            onComplete()
            return
        end

        self:_FinishCurrentDialogue(false)
    end

    if not self._VisualController then
        XLog.Error("[PacMan2AtomicExecutor] VisualController为空")
        onComplete()
        return
    end

    local dialogType = DialogType.Text

    if characterName ~= "" or headIcon ~= "" then
        dialogType = DialogType.Character
    end

    self._VisualController:ShowDialogue(dialogType, text, characterName, headIcon)

    local dialogueRuntime = {
        AtomicRuntimeId = atomicRuntime.RuntimeId,
        EventGroupId = eventGroupId,
        TimerId = nil,
        OnComplete = onComplete,
    }

    self._CurrentDialogue = dialogueRuntime
    dialogueRuntime.TimerId = self:_ScheduleOnce(duration, function()
        if not self._CurrentDialogue or self._CurrentDialogue.AtomicRuntimeId ~= atomicRuntime.RuntimeId then
            return
        end

        self:_FinishCurrentDialogue(true)
    end)
end

---结束当前对话。
---@param hideDialogue boolean
function XUiPacMan2AtomicEventExecutor:_FinishCurrentDialogue(hideDialogue)
    local dialogueRuntime = self._CurrentDialogue

    if not dialogueRuntime then
        return
    end

    self._CurrentDialogue = nil
    self:_CancelTimer(dialogueRuntime.TimerId)

    if hideDialogue and self._VisualController then
        self._VisualController:HideDialogue()
    end

    dialogueRuntime.OnComplete()
end

---执行音效事件。
---
---参数：
---Params[1]：1单次播放 / 2开始循环 / 3停止循环；
---Params[2]：CueId。
function XUiPacMan2AtomicEventExecutor:_ExecuteSound(atomicConfig, atomicRuntime, onComplete)
    local params = atomicConfig.Params or {}
    local action = tonumber(params[1])
    local cueId = tonumber(params[2])

    if not XTool.IsNumberValid(cueId) then
        XLog.Error("[PacMan2AtomicExecutor] Sound的CueId非法, atomicEventId=" .. tostring(atomicConfig.Id))
        onComplete()
        return
    end

    if action == SoundAction.PlayOnce then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
        onComplete()
        return
    end

    if action == SoundAction.LoopStart then
        -- 当前协议没有单独的InstanceKey，因此使用CueId作为循环音效实例标识。
        -- 相同CueId已经开始循环时，不重复播放。
        if not self._LoopSounds[cueId] then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
            self._LoopSounds[cueId] = true
        end

        onComplete()
        return
    end

    if action == SoundAction.LoopStop then
        if self._LoopSounds[cueId] then
            XLuaAudioManager.StopAudioByCueId(cueId)
            self._LoopSounds[cueId] = nil
        end

        onComplete()
        return
    end

    XLog.Error("[PacMan2AtomicExecutor] 未知SoundAction=" .. tostring(action) .. ", atomicEventId=" .. tostring(atomicConfig.Id))
    onComplete()
end

---执行BGM事件。
---
---参数：
---Params[1]：1播放指定BGM / 2变轨；
---Params[2]：播放BGM时为CueId，变轨时为1普通轨/2鼓点轨。
function XUiPacMan2AtomicEventExecutor:_ExecuteBgm(atomicConfig, atomicRuntime, onComplete)
    local params = atomicConfig.Params or {}
    local action = tonumber(params[1])
    local value = tonumber(params[2])

    if action == BgmAction.Play then
        if not XTool.IsNumberValid(value) then
            XLog.Error("[PacMan2AtomicExecutor] BGM CueId非法, atomicEventId=" .. tostring(atomicConfig.Id))
            onComplete()
            return
        end

        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, value)
        onComplete()
        return
    end

    if action == BgmAction.ChangeTrack then
        local targetValue

        if value == BgmTrackState.Normal then
            targetValue = BgmNormalValue
        elseif value == BgmTrackState.Drum then
            targetValue = BgmDrumValue
        else
            XLog.Error("[PacMan2AtomicExecutor] 未知BGM轨道状态=" .. tostring(value) .. ", atomicEventId=" .. tostring(atomicConfig.Id))
            onComplete()
            return
        end

        CS.XAudioManager.ChangeMusicSourceAisac(BgmAisacControlName, targetValue, BgmCurveTime)
        onComplete()
        return
    end

    XLog.Error("[PacMan2AtomicExecutor] 未知BgmAction=" .. tostring(action) .. ", atomicEventId=" .. tostring(atomicConfig.Id))
    onComplete()
end

---切换指定魔幻滤镜。
---
---参数：
---Params[1]：1开启 / 0关闭；
---Params[2]：FilterKey。
---
---滤镜属于持续状态，设置完成后原子事件立即完成。
function XUiPacMan2AtomicEventExecutor:_ExecuteMagicFilter(atomicConfig, atomicRuntime, onComplete)
    local params = atomicConfig.Params or {}
    local enabled = ParseBoolean(params[1])
    local filterKey = params[2]

    if enabled == nil then
        XLog.Error("[PacMan2AtomicExecutor] MagicFilter开关参数非法, atomicEventId=" .. tostring(atomicConfig.Id))
        onComplete()
        return
    end

    if not filterKey or filterKey == "" then
        XLog.Error("[PacMan2AtomicExecutor] MagicFilter缺少FilterKey, atomicEventId=" .. tostring(atomicConfig.Id))
        onComplete()
        return
    end

    if not self._VisualController then
        XLog.Error("[PacMan2AtomicExecutor] VisualController为空")
        onComplete()
        return
    end

    self._VisualController:SetMagicFilterEnabled(filterKey, enabled)
    onComplete()
end

---切换指定结局遮罩。
---
---参数：
---Params[1]：1开启 / 0关闭；
---Params[2]：MaskKey。
---
---遮罩属于持续状态，设置完成后原子事件立即完成。
function XUiPacMan2AtomicEventExecutor:_ExecuteEndingMask(atomicConfig, atomicRuntime, onComplete)
    local params = atomicConfig.Params or {}
    local enabled = ParseBoolean(params[1])
    local maskKey = params[2]

    if enabled == nil then
        XLog.Error("[PacMan2AtomicExecutor] EndingMask开关参数非法, atomicEventId=" .. tostring(atomicConfig.Id))
        onComplete()
        return
    end

    if not maskKey or maskKey == "" then
        XLog.Error("[PacMan2AtomicExecutor] EndingMask缺少MaskKey, atomicEventId=" .. tostring(atomicConfig.Id))
        onComplete()
        return
    end

    if not self._VisualController then
        XLog.Error("[PacMan2AtomicExecutor] VisualController为空")
        onComplete()
        return
    end

    self._VisualController:SetEndingMaskEnabled(maskKey, enabled)
    onComplete()
end

---执行Overlay开关事件。
---Params[1]：1打开 / 0关闭。
---页面打开或关闭完成后，原子事件完成。
function XUiPacMan2AtomicEventExecutor:_ExecuteOverlay(atomicConfig, atomicRuntime, onComplete)
    local params = atomicConfig.Params or {}
    local enabled = ParseBoolean(params[1])

    if enabled == nil then
        XLog.Error("[PacMan2AtomicExecutor] Overlay开关参数非法, atomicEventId=" .. tostring(atomicConfig.Id))
        onComplete()
        return
    end

    if not self._VisualController then
        XLog.Error("[PacMan2AtomicExecutor] VisualController为空")
        onComplete()
        return
    end

    self._VisualController:SetOverlayEnabled(enabled, function()
        -- 页面开关结束前，所属事件组可能已经被取消。
        if atomicRuntime.IsCancelled then
            return
        end

        -- 页面回调可能在事件系统暂停期间返回。
        -- 保存完成通知的计时器，取消原子事件时可以一起清理。
        atomicRuntime.CompletionTimerId = self:_ScheduleOnce(0, function()
            atomicRuntime.CompletionTimerId = nil
            onComplete()
        end)
    end)
end

---执行Overlay消息事件。
---Params[1]：Left / Right / System；
---Params[2]：文本；
---Params[3]：头像路径，可空。
---
---出现时间由事件组AtomicEventTimes控制。
---消息写入OverlayDialogueData后立即完成。
function XUiPacMan2AtomicEventExecutor:_ExecuteOverlayDialogue(atomicConfig, atomicRuntime, onComplete)
    local params = atomicConfig.Params or {}

    if not self._VisualController then
        XLog.Error("[PacMan2AtomicExecutor] VisualController为空")
        onComplete()
        return
    end

    self._VisualController:AppendOverlayDialogue(params[1] or "", params[2] or "", params[3] or "")
    onComplete()
end


---@param seconds number
---@param callback function
---@return number|nil
function XUiPacMan2AtomicEventExecutor:_ScheduleOnce(seconds, callback)
    local timerId

    timerId = self._EventTimerManager:Schedule(seconds, function()
        -- 零秒任务可能同步执行，此时没有需要移除的任务Id。
        if timerId then
            self._TimerIds[timerId] = nil
        end

        callback()
    end)

    -- Schedule只为等待中的任务返回Id。
    if timerId then
        self._TimerIds[timerId] = true
    end

    return timerId
end

function XUiPacMan2AtomicEventExecutor:_CancelTimer(timerId)
    if not timerId or not self._TimerIds[timerId] then
        return
    end

    self._TimerIds[timerId] = nil

    if self._EventTimerManager then
        self._EventTimerManager:Cancel(timerId)
    end
end

---开始新关卡时清理上一关的原子事件运行状态。
function XUiPacMan2AtomicEventExecutor:Reset()
    for timerId in pairs(self._TimerIds) do
        if self._EventTimerManager then
            self._EventTimerManager:Cancel(timerId)
        end
    end

    self._TimerIds = {}
    self._CurrentDialogue = nil
    
    for cueId in pairs(self._LoopSounds) do
        XLuaAudioManager.StopAudioByCueId(cueId)
    end

    self._LoopSounds = {}

    if self._VisualController then
        self._VisualController:Reset()
    end
end

function XUiPacMan2AtomicEventExecutor:Dispose()
    self:Reset()
    self._Executors = nil
    self._VisualController = nil
    self._EventTimerManager = nil
end

return XUiPacMan2AtomicEventExecutor