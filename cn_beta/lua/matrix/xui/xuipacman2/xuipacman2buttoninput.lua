local Direction = require("XUi/XUiPacMan2/XUiPacMan2InputDirection")

---@class XUiPacMan2ButtonInput
local XUiPacMan2ButtonInput = XClass(nil, "XUiPacMan2ButtonInput")

---@param onDirection fun(direction:number):boolean
function XUiPacMan2ButtonInput:Ctor(btnUp, btnDown, btnLeft, btnRight, onDirection)
    self.BtnUp = btnUp
    self.BtnDown = btnDown
    self.BtnLeft = btnLeft
    self.BtnRight = btnRight
    self._OnDirection = onDirection

    -- 注册按钮事件
    self.BtnUp.CallBack = function()
        self:_OnClickUp()
    end

    self.BtnDown.CallBack = function()
        self:_OnClickDown()
    end

    self.BtnLeft.CallBack = function()
        self:_OnClickLeft()
    end

    self.BtnRight.CallBack = function()
        self:_OnClickRight()
    end
end

function XUiPacMan2ButtonInput:_OnClickUp()
    self:_SubmitDirection(Direction.Up)
end

function XUiPacMan2ButtonInput:_OnClickDown()
    self:_SubmitDirection(Direction.Down)
end

function XUiPacMan2ButtonInput:_OnClickLeft()
    self:_SubmitDirection(Direction.Left)
end

function XUiPacMan2ButtonInput:_OnClickRight()
    self:_SubmitDirection(Direction.Right)
end

function XUiPacMan2ButtonInput:_SubmitDirection(direction)
    if not self._OnDirection then
        return false
    end

    return self._OnDirection(direction)
end

function XUiPacMan2ButtonInput:Dispose()
    -- 清除按钮回调，避免界面销毁后继续访问输入对象
    if self.BtnUp then
        self.BtnUp.CallBack = nil
    end

    if self.BtnDown then
        self.BtnDown.CallBack = nil
    end

    if self.BtnLeft then
        self.BtnLeft.CallBack = nil
    end

    if self.BtnRight then
        self.BtnRight.CallBack = nil
    end

    self.BtnUp = nil
    self.BtnDown = nil
    self.BtnLeft = nil
    self.BtnRight = nil
    self._OnDirection = nil
end

return XUiPacMan2ButtonInput