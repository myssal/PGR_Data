local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationUpdateMap : XLineArithmetic2Animation
local XLineArithmetic2AnimationUpdateMap = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationUpdateMap")

function XLineArithmetic2AnimationUpdateMap:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.UPDATE_MAP
    self._Duration = 0
    self._Passed = 0
    self._GridUid = 0
    self._EatIndex = 0
    self._EatGridType = XLineArithmetic2Enum.GRID.NONE
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationUpdateMap:Update(game, ui, deltaTime)
    self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
    ui:UpdateMap()
end

return XLineArithmetic2AnimationUpdateMap