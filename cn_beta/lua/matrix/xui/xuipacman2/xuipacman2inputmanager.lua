local Direction = require("XUi/XUiPacMan2/XUiPacMan2InputDirection")
local KeyboardInput = require("XUi/XUiPacMan2/XUiPacMan2KeyboardInput")
local GamepadInput = require("XUi/XUiPacMan2/XUiPacMan2GamepadInput")
local TouchInput = require("XUi/XUiPacMan2/XUiPacMan2TouchInput")
local JoystickInput = require("XUi/XUiPacMan2/XUiPacMan2JoystickInput")
local PcInputFeedback = require("XUi/XUiPacMan2/XUiPacMan2PcInputFeedback")
---锁分为输入锁和移动锁，输入锁处理是否允许输入，移动锁处理是否允许移动
---输入锁和移动锁都生效时，不再记录任何输入状态，且角色不能移动
---只有输入锁生效时，不再接受新的玩家输入， Movement保留现有移动状态、路径和待转方向并继续运行。
---只有移动锁生效时：输入源仍然更新自身状态，但方向无法提交给角色
---当前暂不统一处理各输入源在移动锁期间记录的输入。
---@class XUiPacMan2InputManager
local XUiPacMan2InputManager = XClass(nil, "XUiPacMan2InputManager")

function XUiPacMan2InputManager:Ctor(gameUi)
    self._GameUi = gameUi
    self._Movement = nil

    -- 输入禁止锁
    self._Locks = {}

    -- 每一个输入锁对应一个token，用于应对多个地方同时禁止输入
    self._NextLockToken = 0

    --分别有三种不同的状态：输入管理器是否开启、玩家输入是否开启、玩家是否可以移动
    self._IsActive = false
    self._LastInputEnabled = nil
    self._LastMovementEnabled = nil
    self._UpdateTimerId = nil

    -- 所有输入源最终都只向InputManager提交方向
    local onDirection = function(direction)
        return self:SubmitDirection(direction)
    end

    local canInput = function()
        return self:CanSubmitDirection()
    end

    -- 键盘和手柄共用一个PC反馈对象。
    -- Manager只负责组装，不保存显示方向，也不判断哪个来源松开。
    self._PcInputFeedback = PcInputFeedback.New(gameUi.Keyboard)
    
    -- 旧PanelControl及四方向按钮已移除，不再创建ButtonInput。
    self._InputSources = {
        KeyboardInput.New(onDirection, self._PcInputFeedback),
        GamepadInput.New(onDirection, self._PcInputFeedback),
        TouchInput.New(gameUi.InputHandler, canInput, onDirection),
        JoystickInput.New(gameUi.PanelJoystick, canInput, onDirection),
    }
end

function XUiPacMan2InputManager:BindMovement(movement)
    self._Movement = movement

    if self._Movement then
        self._Movement:SetMovementSuspended(not self:IsMovementEnabled())
    end
end

function XUiPacMan2InputManager:Enable()
    if self._IsActive then
        return
    end

    self._IsActive = true
    -- 整个输入系统只在这里创建一个更新定时器
    self._UpdateTimerId = XScheduleManager.ScheduleForever(function()
        self:UpdateInput()
    end, 0)

    self:RefreshControlState()
end

function XUiPacMan2InputManager:Disable()
    if not self._IsActive then
        return
    end

    self._IsActive = false

    if self._UpdateTimerId then
        XScheduleManager.UnSchedule(self._UpdateTimerId)
        self._UpdateTimerId = nil
    end
    self:RefreshControlState()
end

function XUiPacMan2InputManager:UpdateInput()
    if not self:IsInputEnabled() then
        return
    end

    for _, inputSource in ipairs(self._InputSources) do
        if inputSource.UpdateInput then
            inputSource:UpdateInput()
        end
    end
end


function XUiPacMan2InputManager:CanSubmitDirection()
    if not self:IsInputEnabled() then
        return false
    end

    if not self:IsMovementEnabled() then
        return false
    end

    if not self._Movement then
        return false
    end

    return self._Movement:CanReceiveMoveInput()
end

function XUiPacMan2InputManager:SubmitDirection(direction)
    if not self:CanSubmitDirection() then
        return false
    end

    if direction == Direction.Up then
        self._Movement:MoveUp()
    elseif direction == Direction.Down then
        self._Movement:MoveDown()
    elseif direction == Direction.Left then
        self._Movement:MoveLeft()
    elseif direction == Direction.Right then
        self._Movement:MoveRight()
    else
        return false
    end

    return true
end

function XUiPacMan2InputManager:_AcquireLock(reason, blockInput, blockMovement)
    self._NextLockToken = self._NextLockToken + 1

    local token = self._NextLockToken
    self._Locks[token] = {
        Reason = reason or "Unknown",
        BlockInput = blockInput == true,
        BlockMovement = blockMovement == true,
    }

    self:RefreshControlState()
    return token
end

---只禁止读取操作，角色保持原方向移动
function XUiPacMan2InputManager:AcquireInputLock(reason)
    return self:_AcquireLock(reason, true, false)
end

---只禁止角色移动，输入检测仍然运行
function XUiPacMan2InputManager:AcquireMovementLock(reason)
    return self:_AcquireLock(reason, false, true)
end

---同时禁止输入和移动，普通事件默认使用这个
function XUiPacMan2InputManager:AcquireControlLock(reason)
    return self:_AcquireLock(reason, true, true)
end


function XUiPacMan2InputManager:ReleaseLock(token)
    if not token or not self._Locks[token] then
        XLog.Warning("[XUiPacMan2InputManager] Invalid lock token: " .. tostring(token))
        return false
    end

    self._Locks[token] = nil
    self:RefreshControlState()
    return true
end

function XUiPacMan2InputManager:ClearLocks()
    self._Locks = {}
    self:RefreshControlState()
end

function XUiPacMan2InputManager:_HasLock(fieldName)
    for _, lockInfo in pairs(self._Locks) do
        if lockInfo[fieldName] then
            return true
        end
    end

    return false
end

function XUiPacMan2InputManager:IsInputEnabled()
    return self._IsActive and not self:_HasLock("BlockInput")
end

function XUiPacMan2InputManager:IsMovementEnabled()
    return self._IsActive
        and not self:_HasLock("BlockMovement")
end

function XUiPacMan2InputManager:RefreshControlState()
    --输入禁止时，不再读取手柄状态，清空现有手柄状态
    --移动禁止时，仍然读取设备输入
    local inputEnabled = self:IsInputEnabled()
    local movementEnabled = self:IsMovementEnabled()

    local inputChanged = self._LastInputEnabled ~= inputEnabled
    local movementChanged = self._LastMovementEnabled ~= movementEnabled

    self._LastInputEnabled = inputEnabled
    self._LastMovementEnabled = movementEnabled

    -- 移动权限控制C# Movement
    if movementChanged and self._Movement then
        self._Movement:SetMovementSuspended(not movementEnabled)
    end


    -- 统一通知所有输入源
    if inputChanged or movementChanged then
        for _, inputSource in ipairs(self._InputSources) do
            if inputSource.OnControlStateChanged then
                inputSource:OnControlStateChanged(inputEnabled, movementEnabled)
            end
        end
    end

    if (inputChanged or movementChanged) and self._GameUi and self._GameUi.OnControlStateChanged then
        self._GameUi:OnControlStateChanged(inputEnabled, movementEnabled)
    end
end

function XUiPacMan2InputManager:RestoreCursor()
    for _, inputSource in ipairs(self._InputSources) do
        if inputSource.RestoreCursor then
            inputSource:RestoreCursor()
        end
    end
end

function XUiPacMan2InputManager:Dispose()
    self:Disable()

    if self._InputSources then
        for _, inputSource in ipairs(self._InputSources) do
            if inputSource.Dispose then
                inputSource:Dispose()
            end
        end

        self._InputSources = nil
    end

    -- 必须先销毁输入源，让它们完成Release，再销毁共享反馈对象。
    if self._PcInputFeedback then
        self._PcInputFeedback:Dispose()
        self._PcInputFeedback = nil
    end

    self._Locks = {}
    self._Movement = nil
    self._GameUi = nil
end

return XUiPacMan2InputManager