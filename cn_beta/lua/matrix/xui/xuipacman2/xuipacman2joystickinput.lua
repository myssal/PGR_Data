local Direction = require("XUi/XUiPacMan2/XUiPacMan2InputDirection")

local RectTransformUtility = CS.UnityEngine.RectTransformUtility
local Vector2 = CS.UnityEngine.Vector2

---@class XUiPacMan2JoystickInput
local XUiPacMan2JoystickInput = XClass(nil, "XUiPacMan2JoystickInput")

-- 中心死区半径，防止中心附近误触
local DEAD_ZONE = 10
local DEAD_ZONE_SQR = DEAD_ZONE * DEAD_ZONE

-- 摇杆中心最大移动范围
local JOYSTICK_TOUCH_RANGE = 15
local JOYSTICK_TOUCH_RANGE_SQR = JOYSTICK_TOUCH_RANGE * JOYSTICK_TOUCH_RANGE

---@param panelJoystick XUiComponent.XUiObject
---@param canInput fun():boolean
---@param onDirection fun(direction:number):boolean
function XUiPacMan2JoystickInput:Ctor(panelJoystick, canInput, onDirection)

    self._PanelJoystick = panelJoystick
    self._CanInput = canInput
    self._OnDirection = onDirection

    local ui = XTool.InitUiObjectByUi({}, panelJoystick)

    self._JoystickScope = ui.JoystickScope
    self._BackdragTouch = ui.BackdragTouch
    self._TouchButton = ui.TouchButton

    self._PanelSelect = ui.PanelSelect
    self._RImgUp = ui.RImgUp
    self._RImgDown = ui.RImgDown
    self._RImgLeft = ui.RImgLeft
    self._RImgRight = ui.RImgRight

    self._IsDragging = false
    self._CurrentDirection = Direction.None

    -- 中心点固定不移动
    self._TouchButtonOrigin = self._TouchButton.anchoredPosition

    self:_RegisterUiEvents()
    self:Reset()
end

function XUiPacMan2JoystickInput:_RegisterUiEvents()
    self._UiWidget = self._JoystickScope.gameObject:AddComponent(typeof(CS.XUiWidget))

    self._UiWidget:AddPointerDownListener(
        function(eventData)
            self:_OnPointerDown(eventData)
        end
    )

    self._UiWidget:AddDragListener(
        function(eventData)
            self:_OnDrag(eventData)
        end
    )

    self._UiWidget:AddPointerUpListener(
        function(eventData)
            self:_OnPointerUp(eventData)
        end
    )
end

function XUiPacMan2JoystickInput:_OnPointerDown(eventData)
    if not self:_CanSubmitInput() then
        self:Reset()
        return
    end

    self._IsDragging = true
    self:_UpdateDirection(eventData)
end

function XUiPacMan2JoystickInput:_OnDrag(eventData)
    if not self._IsDragging then
        return
    end

    if not self:_CanSubmitInput() then
        self:Reset()
        return
    end

    self:_UpdateDirection(eventData)
end

function XUiPacMan2JoystickInput:_OnPointerUp(eventData)
    -- 只复位摇杆UI，不停止角色
    self:Reset()
end

function XUiPacMan2JoystickInput:_UpdateDirection(eventData)
    --用BackdragTouch建立坐标系
    local hasValue, point = RectTransformUtility.ScreenPointToLocalPointInRectangle(
        self._BackdragTouch,
        eventData.position,
        CS.XUiManager.Instance.UiCamera
    )

    if not hasValue then
        return
    end

    --实际上拖动计算的是手指相对于摇杆中心的位置
    local x = point.x - self._TouchButtonOrigin.x
    local y = point.y - self._TouchButtonOrigin.y
    local distanceSqr = x * x + y * y

    -- 限制摇杆头最多移动120
    if distanceSqr > JOYSTICK_TOUCH_RANGE_SQR then
        local distance = math.sqrt(distanceSqr)
        local scale = JOYSTICK_TOUCH_RANGE / distance

        self._TouchButton.anchoredPosition = Vector2(
            self._TouchButtonOrigin.x + x * scale,
            self._TouchButtonOrigin.y + y * scale
        )
    else
        self._TouchButton.anchoredPosition = Vector2(
            self._TouchButtonOrigin.x + x,
            self._TouchButtonOrigin.y + y
        )
    end

    -- 进入中心死区时只取消高亮，不停止角色
    if distanceSqr <= DEAD_ZONE_SQR then
        self._CurrentDirection = Direction.None
        self:_RefreshDirection(Direction.None)
        return
    end

    local direction

    -- 横纵距离比较，只选择一个方向
    if math.abs(x) > math.abs(y) then
        if x > 0 then
            direction = Direction.Right
        else
            direction = Direction.Left
        end
    else
        if y > 0 then
            direction = Direction.Up
        else
            direction = Direction.Down
        end
    end

    -- 同方向不重复提交
    if direction == self._CurrentDirection then
        return
    end

    if not self._OnDirection then
        return
    end

    local success = self._OnDirection(direction)

    if success then
        self._CurrentDirection = direction
        self:_RefreshDirection(direction)
    end
end

function XUiPacMan2JoystickInput:_RefreshDirection(direction)
    local hasDirection = direction ~= Direction.None

    self._PanelSelect.gameObject:SetActiveEx(hasDirection)

    self._RImgUp.gameObject:SetActiveEx(
        direction == Direction.Up
    )

    self._RImgDown.gameObject:SetActiveEx(
        direction == Direction.Down
    )

    self._RImgLeft.gameObject:SetActiveEx(
        direction == Direction.Left
    )

    self._RImgRight.gameObject:SetActiveEx(
        direction == Direction.Right
    )
end

function XUiPacMan2JoystickInput:_CanSubmitInput()
    return self._CanInput and self._CanInput()
end

function XUiPacMan2JoystickInput:Reset()
    self._IsDragging = false
    self._CurrentDirection = Direction.None

    -- 中心点始终保持默认位置
    if self._TouchButton then
        self._TouchButton.anchoredPosition = self._TouchButtonOrigin
    end

    -- 只关闭高亮，不改变角色方向
    self:_RefreshDirection(Direction.None)
end

function XUiPacMan2JoystickInput:OnControlStateChanged(inputEnabled, movementEnabled)
    if not inputEnabled or not movementEnabled then
        self:Reset()
    end
end

function XUiPacMan2JoystickInput:Dispose()
    self:Reset()

    if self._UiWidget then
        self._UiWidget:RemoveAllListeners()
        self._UiWidget = nil
    end

    self._PanelJoystick = nil
    self._JoystickScope = nil
    self._BackdragTouch = nil
    self._TouchButton = nil

    self._PanelSelect = nil
    self._RImgUp = nil
    self._RImgDown = nil
    self._RImgLeft = nil
    self._RImgRight = nil

    self._CanInput = nil
    self._OnDirection = nil
end

return XUiPacMan2JoystickInput