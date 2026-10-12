--- PacMan2 手柄输入处理脚本
--- 用于响应手柄输入，控制游戏角色移动

local Direction = require("XUi/XUiPacMan2/XUiPacMan2InputDirection")

-- 输入轴死区；绝对值超过此值才视为有效方向输入。
local GamepadAxisDeadZone = 0.3

-- 最后一次有效手柄输入后，允许解锁鼠标的等待时间，单位为秒。
local CursorUnlockDelaySeconds = 1

-- 鼠标任一坐标轴的移动量超过此值时，恢复鼠标显示，单位为像素。
local MouseMoveThresholdPixels = 10

-- Unity Input.GetMouseButtonDown的按钮编号。
local MouseButton = {
    Left = 0,
    Right = 1,
    Middle = 2,
}

---@class XUiPacMan2GamepadInput
local XUiPacMan2GamepadInput = XClass(nil, "XUiPacMan2GamepadInput")

local Input = CS.UnityEngine.Input
local KeyCode = CS.UnityEngine.KeyCode
local Cursor = CS.UnityEngine.Cursor
local CursorLockMode = CS.UnityEngine.CursorLockMode
local Time = CS.UnityEngine.Time

---@param onDirection fun(direction:number):boolean
---@param pcInputFeedback XUiPacMan2PcInputFeedback
function XUiPacMan2GamepadInput:Ctor(onDirection, pcInputFeedback)
    self._OnDirection = onDirection
    self._PcInputFeedback = pcInputFeedback
    self._InputEnabled = false

    -- 手柄输入相关
    self._LastDirection = Direction.None
    self._LastHasGamepadInput = false

    -- 鼠标控制相关
    self._IsUsingGamepad = false
    self._OriginalCursorLockState = CursorLockMode.None
    self._OriginalCursorVisible = true
    self._LastMousePosition = nil
    self._LockStartTime = nil
    self._UnlockDelay = CursorUnlockDelaySeconds -- 解锁延迟时间（秒），避免鼠标闪烁
end

--- 启用手柄输入
--- 定时器由InputManager统一负责，这里只重置状态
function XUiPacMan2GamepadInput:OnEnable()
    self._OriginalCursorLockState = Cursor.lockState
    self._OriginalCursorVisible = Cursor.visible
    self._LastDirection = Direction.None
    self._LastHasGamepadInput = false
end

--- 禁用手柄输入
--- 定时器由InputManager统一负责，这里只清理状态
function XUiPacMan2GamepadInput:OnDisable()
    self._LastDirection = Direction.None
    self._LastHasGamepadInput = false
    self._LockStartTime = nil

    if self._PcInputFeedback then
        self._PcInputFeedback:Release(self)
    end
    
    if Cursor.lockState == CursorLockMode.Locked then
        Cursor.lockState = CursorLockMode.None
    end

    self:_RestoreCursor()
end

--- 由InputManager每帧统一调用
function XUiPacMan2GamepadInput:UpdateInput()
    if not self._OnDirection then
        return
    end

    -- 检测手柄摇杆输入
    -- 暂时继续使用Horizontal/Vertical，因此WASD也可能进入这里
    local horizontal = Input.GetAxis("Horizontal")
    local vertical = Input.GetAxis("Vertical")
    local hasGamepadInput = math.abs(horizontal) > GamepadAxisDeadZone or math.abs(vertical) > GamepadAxisDeadZone

    if hasGamepadInput ~= (self._LastHasGamepadInput or false) then
        self._LastHasGamepadInput = hasGamepadInput
    end

    -- 手柄输入处理：锁定鼠标并隐藏
    if hasGamepadInput then
        if not self._IsUsingGamepad then
            self._IsUsingGamepad = true
        end

        if Cursor.lockState ~= CursorLockMode.Locked then
            Cursor.lockState = CursorLockMode.Locked
        end

        self._LockStartTime = Time.realtimeSinceStartup

        if Cursor.visible then
            Cursor.visible = false
        end
    else
        -- 无手柄输入时：延迟解锁，检测鼠标/键盘输入以恢复鼠标显示
        if self._IsUsingGamepad and self._LockStartTime then
            local elapsedTime = Time.realtimeSinceStartup - self._LockStartTime

            if elapsedTime >= self._UnlockDelay then
                -- 延迟时间已过，解锁鼠标但保持隐藏，等待输入
                if Cursor.lockState == CursorLockMode.Locked then
                    Cursor.lockState = CursorLockMode.None
                    self._LastMousePosition = Input.mousePosition
                end

                if Cursor.visible then
                    Cursor.visible = false
                end

                self:_CheckMouseOrKeyboardInput()
            end
        end
    end

    -- 根据输入确定方向（优先水平方向）
    local currentDirection = Direction.None

    if math.abs(horizontal) > GamepadAxisDeadZone then
        if horizontal > 0 then
            currentDirection = Direction.Right
        else
            currentDirection = Direction.Left
        end
    elseif math.abs(vertical) > GamepadAxisDeadZone then
        if vertical > 0 then
            currentDirection = Direction.Up
        else
            currentDirection = Direction.Down
        end
    end

    -- 方向变化时触发移动
    if currentDirection ~= self._LastDirection then
        if currentDirection == Direction.Up then
            self:_OnMoveUp()
        elseif currentDirection == Direction.Down then
            self:_OnMoveDown()
        elseif currentDirection == Direction.Left then
            self:_OnMoveLeft()
        elseif currentDirection == Direction.Right then
            self:_OnMoveRight()
        end

        self._LastDirection = currentDirection

        if self._PcInputFeedback then
            if currentDirection == Direction.None or not self._InputEnabled then
                -- 回中或回调期间输入被禁用时，只释放自己的反馈。
                -- 不向移动系统提交停止请求。
                self._PcInputFeedback:Release(self)
            else
                self._PcInputFeedback:Show(self, currentDirection)
            end
        end
    end
end

function XUiPacMan2GamepadInput:_OnMoveUp()
    if self._OnDirection then
        self._OnDirection(Direction.Up)
    end
end

function XUiPacMan2GamepadInput:_OnMoveDown()
    if self._OnDirection then
        self._OnDirection(Direction.Down)
    end
end

function XUiPacMan2GamepadInput:_OnMoveLeft()
    if self._OnDirection then
        self._OnDirection(Direction.Left)
    end
end

function XUiPacMan2GamepadInput:_OnMoveRight()
    if self._OnDirection then
        self._OnDirection(Direction.Right)
    end
end

--- 检测鼠标移动或键盘输入，用于恢复鼠标显示
function XUiPacMan2GamepadInput:_CheckMouseOrKeyboardInput()
    -- 检测鼠标移动
    local currentMousePosition = Input.mousePosition

    if self._LastMousePosition then
        local deltaX = math.abs(currentMousePosition.x - self._LastMousePosition.x)
        local deltaY = math.abs(currentMousePosition.y - self._LastMousePosition.y)

        if deltaX > MouseMoveThresholdPixels or deltaY > MouseMoveThresholdPixels then
            self:_RestoreCursor()
            return
        end
    end

    self._LastMousePosition = currentMousePosition

    -- 检测键盘输入（方向键或WASD）
    local hasKeyInput = Input.GetKeyDown(KeyCode.UpArrow)
        or Input.GetKeyDown(KeyCode.DownArrow)
        or Input.GetKeyDown(KeyCode.LeftArrow)
        or Input.GetKeyDown(KeyCode.RightArrow)
        or Input.GetKeyDown(KeyCode.W)
        or Input.GetKeyDown(KeyCode.S)
        or Input.GetKeyDown(KeyCode.A)
        or Input.GetKeyDown(KeyCode.D)

    if hasKeyInput then
        self:_RestoreCursor()
        return
    end

    -- 检测鼠标点击
    local hasMouseClick = Input.GetMouseButtonDown(MouseButton.Left)
        or Input.GetMouseButtonDown(MouseButton.Right)
        or Input.GetMouseButtonDown(MouseButton.Middle)

    if hasMouseClick then
        self:_RestoreCursor()
    end
end

--- 恢复鼠标状态（公共方法，供外部调用）
function XUiPacMan2GamepadInput:RestoreCursor()
    self:_RestoreCursor()
end

--- 恢复鼠标状态（私有方法）
function XUiPacMan2GamepadInput:_RestoreCursor()
    if not self._IsUsingGamepad then
        return
    end

    self._IsUsingGamepad = false
    self._LockStartTime = nil
    Cursor.lockState = self._OriginalCursorLockState
    Cursor.visible = self._OriginalCursorVisible
    self._LastMousePosition = nil
end

function XUiPacMan2GamepadInput:OnControlStateChanged(inputEnabled, movementEnabled)
    if self._InputEnabled == inputEnabled then
        return
    end

    self._InputEnabled = inputEnabled

    if inputEnabled then
        self:OnEnable()
    else
        self:OnDisable()
    end
end

--- 销毁
function XUiPacMan2GamepadInput:Dispose()
    -- 如果仍处于启用状态，保留原来的清理流程。
    if self._InputEnabled then
        self._InputEnabled = false
        self:OnDisable()
    end

    -- Release允许重复调用，确保销毁后不再被共享反馈对象引用。
    if self._PcInputFeedback then
        self._PcInputFeedback:Release(self)
        self._PcInputFeedback = nil
    end

    self._OnDirection = nil
end

return XUiPacMan2GamepadInput