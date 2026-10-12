local Direction = require("XUi/XUiPacMan2/XUiPacMan2InputDirection")

---@class XUiPacMan2KeyboardInput
local XUiPacMan2KeyboardInput = XClass(nil, "XUiPacMan2KeyboardInput")

local Input = CS.UnityEngine.Input
local KeyCode = CS.UnityEngine.KeyCode

---@param onDirection fun(direction:number):boolean
---@param pcInputFeedback XUiPacMan2PcInputFeedback
function XUiPacMan2KeyboardInput:Ctor(onDirection, pcInputFeedback)
    self._OnDirection = onDirection
    self._PcInputFeedback = pcInputFeedback
end

function XUiPacMan2KeyboardInput:UpdateInput()
    if not self._OnDirection then
        return
    end

    -- 保留原有GetKeyDown及if/elseif顺序。
    -- 同一次更新最多选出一个键盘方向，不根据按住状态重新选择方向。
    local direction = Direction.None

    if Input.GetKeyDown(KeyCode.W) or Input.GetKeyDown(KeyCode.UpArrow) then
        direction = Direction.Up
    elseif Input.GetKeyDown(KeyCode.S) or Input.GetKeyDown(KeyCode.DownArrow) then
        direction = Direction.Down
    elseif Input.GetKeyDown(KeyCode.A) or Input.GetKeyDown(KeyCode.LeftArrow) then
        direction = Direction.Left
    elseif Input.GetKeyDown(KeyCode.D) or Input.GetKeyDown(KeyCode.RightArrow) then
        direction = Direction.Right
    end

    if direction ~= Direction.None then
        self._OnDirection(direction)

        -- 回调可能触发暂停，因此显示前检查当前输入状态。
        -- 只禁止移动时仍允许反馈；输入禁止时不再点亮。
        if self._InputEnabled and self._PcInputFeedback then
            self._PcInputFeedback:Show(self, direction)
        end
    end

    if self._PcInputFeedback then
        -- 只检查是否全部松开，不参与方向判定。
        local hasDirectionInput = Input.GetKey(KeyCode.W)
            or Input.GetKey(KeyCode.S)
            or Input.GetKey(KeyCode.A)
            or Input.GetKey(KeyCode.D)
            or Input.GetKey(KeyCode.UpArrow)
            or Input.GetKey(KeyCode.DownArrow)
            or Input.GetKey(KeyCode.LeftArrow)
            or Input.GetKey(KeyCode.RightArrow)

        if not hasDirectionInput then
            self._PcInputFeedback:Release(self)
        end
    end
end

--- InputManager继续使用原有机制通知输入权限变化。
function XUiPacMan2KeyboardInput:OnControlStateChanged(inputEnabled, movementEnabled)
    self._InputEnabled = inputEnabled

    if not inputEnabled and self._PcInputFeedback then
        self._PcInputFeedback:Release(self)
    end
end

function XUiPacMan2KeyboardInput:Dispose()
    if self._PcInputFeedback then
        self._PcInputFeedback:Release(self)
        self._PcInputFeedback = nil
    end

    self._InputEnabled = false
    self._OnDirection = nil
end

return XUiPacMan2KeyboardInput