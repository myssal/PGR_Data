local Direction = require("XUi/XUiPacMan2/XUiPacMan2InputDirection")
local Vector2 = CS.UnityEngine.Vector2

-- PC转盘中心圆点相对初始位置的移动距离。
-- 该值使用UI本地坐标，可根据最终资源尺寸调整。
local HANDLEMOVEDISTANCE = 15
---@class XUiPacMan2PcInputFeedback
local XUiPacMan2PcInputFeedback = XClass(nil, "XUiPacMan2PcInputFeedback")

--- PC共享圆盘反馈。
--- 输入源通过Show提交显示方向，通过Release释放自己的参与状态。
---@param keyboard UnityEngine.RectTransform
function XUiPacMan2PcInputFeedback:Ctor(keyboard)

    -- 保存每个仍在参与反馈的输入来源及其当前方向。
    -- key为输入源对象，value为该来源最后提交的有效方向。
    self._ActiveSources = {}

    -- 最后一次提交有效方向、当前正在控制圆盘显示的输入来源。
    self._CurrentSource = nil
    local ui = XTool.InitUiObjectByUi({}, keyboard)
    -- PC转盘中心圆点只负责表现，不参与输入判定。
    -- 保存美术配置的初始位置，输入释放后恢复到这里。
    self._Handle = ui.Handle
    self._HandleOrigin = self._Handle.anchoredPosition

    -- 每个方向保存亮/暗节点，以及上一次显示状态。
    -- 这些table只在创建时分配，不在每帧更新时创建。
    self._DirectionViews = {
        [Direction.Up] = {
            Normal = ui.UpOn.gameObject,
            Highlighted = ui.UpOff.gameObject,
        },
        [Direction.Down] = {
            Normal = ui.DownOn.gameObject,
            Highlighted = ui.DownOff.gameObject,
        },
        [Direction.Left] = {
            Normal = ui.LeftOn.gameObject,
            Highlighted = ui.LeftOff.gameObject,
        },
        [Direction.Right] = {
            Normal = ui.RightOn.gameObject,
            Highlighted = ui.RightOff.gameObject,
        },
    }

    self:Reset()
end

--- 显示某个输入来源刚刚提交的方向。
--- source直接传输入源对象自身，不代表物理设备类型。
--- 后调用的方向覆盖前面的显示，不在这里重新判断优先级。
---@param source table
---@param direction number
function XUiPacMan2PcInputFeedback:Show(source, direction)
    if direction == Direction.None then
        self:Release(source)
        return
    end

    self._ActiveSources[source] = direction
    self._CurrentSource = source
    self:_RefreshDirection(direction)
end

--- 释放某个来源的反馈参与状态。
--- 如果释放的是当前显示来源，则恢复另一个仍在活动的输入来源。
---@param source table
function XUiPacMan2PcInputFeedback:Release(source)
    if self._ActiveSources[source] == nil then
        return
    end

    self._ActiveSources[source] = nil

    -- 释放的不是当前显示来源，不需要改变当前高亮。
    if self._CurrentSource ~= source then
        return
    end

    self._CurrentSource = nil

    -- 当前只有键盘和手柄两个PC输入来源。
    -- 当前来源释放后，如果另一个来源仍然活动，则恢复它保存的方向。
    for activeSource, direction in pairs(self._ActiveSources) do
        self._CurrentSource = activeSource
        self:_RefreshDirection(direction)
        return
    end

    self:_RefreshDirection(Direction.None)
end

--- 根据唯一方向更新节点，不读取输入、不提交移动。
---@param direction number
function XUiPacMan2PcInputFeedback:_RefreshDirection(direction)
    self:_SetPressed(Direction.Up, direction == Direction.Up)
    self:_SetPressed(Direction.Down, direction == Direction.Down)
    self:_SetPressed(Direction.Left, direction == Direction.Left)
    self:_SetPressed(Direction.Right, direction == Direction.Right)
    self:_RefreshHandlePosition(direction)
end

---根据当前最终方向移动PC转盘中心圆点。
---PC端不需要模拟连续拖动，因此直接瞬移到上下左右四个固定位置。
---@param direction number
function XUiPacMan2PcInputFeedback:_RefreshHandlePosition(direction)
    if not self._Handle then
        return
    end

    local offsetX = 0
    local offsetY = 0

    if direction == Direction.Up then
        offsetY = HANDLEMOVEDISTANCE
    elseif direction == Direction.Down then
        offsetY = -HANDLEMOVEDISTANCE
    elseif direction == Direction.Left then
        offsetX = -HANDLEMOVEDISTANCE
    elseif direction == Direction.Right then
        offsetX = HANDLEMOVEDISTANCE
    end

    self._Handle.anchoredPosition = Vector2(
        self._HandleOrigin.x + offsetX,
        self._HandleOrigin.y + offsetY
    )
end

--- 仅在状态发生变化时修改节点，避免每帧重复设置显隐。
---@param direction number
---@param pressed boolean
function XUiPacMan2PcInputFeedback:_SetPressed(direction, pressed)
    local view = self._DirectionViews[direction]

    if view.IsPressed == pressed then
        return
    end

    view.IsPressed = pressed
    view.Highlighted:SetActiveEx(pressed)
    view.Normal:SetActiveEx(not pressed)
end

--- 整体重置，仅用于初始化或整体清理。
--- 普通输入源释放时必须调用Release(self)，不能清掉其他来源。
function XUiPacMan2PcInputFeedback:Reset()
    for source in pairs(self._ActiveSources) do
        self._ActiveSources[source] = nil
    end

    self._CurrentSource = nil
    self:_RefreshDirection(Direction.None)
end

--- 输入源应先完成释放和销毁，再销毁共享高亮对象。
function XUiPacMan2PcInputFeedback:Dispose()
    self._CurrentSource = nil
    self._ActiveSources = nil
    self._DirectionViews = nil
    self._Handle = nil
    self._HandleOrigin = nil
end

return XUiPacMan2PcInputFeedback