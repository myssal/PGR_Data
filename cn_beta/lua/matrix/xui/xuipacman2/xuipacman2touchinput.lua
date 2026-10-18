local Direction = require("XUi/XUiPacMan2/XUiPacMan2InputDirection")

---@class XUiPacMan2TouchInput
local XUiPacMan2TouchInput = XClass(nil, "XUiPacMan2TouchInput")

---@param inputHandler XGoInputHandler
---@param canInput fun():boolean
---@param onDirection fun(direction:number):boolean
function XUiPacMan2TouchInput:Ctor(inputHandler, canInput, onDirection)
    self._InputHandler = inputHandler
    self._CanInput = canInput
    self._OnDirection = onDirection

    -- 初始化拖拽相关变量
    self._DragOffset = XLuaVector2.New()
    self._OperationPos = XLuaVector2.New()
    self._IsDragging = false

    -- 初始化当前方向（本地记录，不使用movement的方向，使用枚举值）
    self._CurrentDirection = Direction.None

    self:AddListenerInput()
end

function XUiPacMan2TouchInput:AddListenerInput()
    ---@type XGoInputHandler
    local goInputHandler = self._InputHandler

    goInputHandler:AddPointerDownListener(function(...)
        self:OnBeginDrag(...)
    end)

    goInputHandler:AddDragListener(function(...)
        self:OnDrag(...)
    end)

    goInputHandler:AddPointerUpListener(function(...)
        self:OnEndDrag(...)
    end)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2TouchInput:OnBeginDrag(eventData)
    if not self:_CanSubmitInput() then
        self:Reset()
        return
    end

    local x, y = self:GetPosByEventData(eventData)

    self._DragOffset.x = x
    self._DragOffset.y = y
    self._IsDragging = true
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2TouchInput:OnDrag(eventData)
    if not self._IsDragging then
        return
    end

    if not self:_CanSubmitInput() then
        self:Reset()
        return
    end

    local x, y = self:GetPosByEventData(eventData)
    local offsetX = x - self._DragOffset.x
    local offsetY = y - self._DragOffset.y

    local isTriggerMove = false
    local length = offsetX ^ 2 + offsetY ^ 2

    if length > 5 then
        -- 在长度足够的情况下，以长度为方向移动
        local xAbs = math.abs(offsetX)
        local yAbs = math.abs(offsetY)

        if xAbs > yAbs then
            if offsetX > 0 then
                -- 如果当前方向已经是Right，则不调用Move
                if self._CurrentDirection ~= Direction.Right then
                    isTriggerMove = self:_SubmitDirection(Direction.Right)
                end
            else
                -- 如果当前方向已经是Left，则不调用Move
                if self._CurrentDirection ~= Direction.Left then
                    isTriggerMove = self:_SubmitDirection(Direction.Left)
                end
            end
        else
            if offsetY > 0 then
                -- 如果当前方向已经是Up，则不调用Move
                if self._CurrentDirection ~= Direction.Up then
                    isTriggerMove = self:_SubmitDirection(Direction.Up)
                end
            else
                -- 如果当前方向已经是Down，则不调用Move
                if self._CurrentDirection ~= Direction.Down then
                    isTriggerMove = self:_SubmitDirection(Direction.Down)
                end
            end
        end

        -- 其实人的手并没有那么精准，经常会拖出介于两者之间的角度，
        -- 所以当处于边界角度时，需要进行“聪明”的判断，
        -- 否则会被认为“操作手感不好”
        -- 但是这相当于要预判下一个拐弯处的方向，
        -- 目前已经没有时间做这种事情了~~
        -- 所以由角度改为距离判断
    end

    -- 重置操控点
    if isTriggerMove then
        self._DragOffset.x = x
        self._DragOffset.y = y
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2TouchInput:OnEndDrag(eventData)
    self:Reset()
end

function XUiPacMan2TouchInput:_CanSubmitInput()
    return self._CanInput and self._CanInput()
end

function XUiPacMan2TouchInput:_SubmitDirection(direction)
    if not self._OnDirection then
        return false
    end

    local success = self._OnDirection(direction)

    if success then
        self._CurrentDirection = direction
    end

    return success
end

function XUiPacMan2TouchInput:Reset()
    self._IsDragging = false
    self._DragOffset.x = 0
    self._DragOffset.y = 0
    self._CurrentDirection = Direction.None
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2TouchInput:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self._InputHandler.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
        transform,
        eventData.position,
        CS.XUiManager.Instance.UiCamera
    )

    if not hasValue then
        return -99999, -99999
    end

    return point.x, point.y
end

function XUiPacMan2TouchInput:OnControlStateChanged(inputEnabled, movementEnabled)
    if not inputEnabled or not movementEnabled then
        self:Reset()
    end
end

function XUiPacMan2TouchInput:Dispose()
    self:Reset()

    if self._InputHandler then
        self._InputHandler:RemoveAllListeners()
    end

    self._InputHandler = nil
    self._CanInput = nil
    self._OnDirection = nil
end

return XUiPacMan2TouchInput