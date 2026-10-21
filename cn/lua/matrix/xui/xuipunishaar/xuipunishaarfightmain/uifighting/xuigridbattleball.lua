---@class XUiGridBattleBall: XUiNode
---@field protected _Control
---@field Parent
---@field IconBall UnityEngine.UI.Image 球图标（按色 SetSprite）
local XUiGridBattleBall = XClass(XUiNode, "XUiGridBattleBall")

function XUiGridBattleBall:Refresh(color)
    self._Color = color  -- 缓存颜色供 GetColor 查（消球动效按色找球位 #消球动效）
    -- 按色取球图标 sprite 名（BallColorToImgs 配置：color→sprite 名），SetSprite 替原 color 设置
    local spriteName = XMVCA.XPunishaar:GetClientStringByKey("BallColorToImgs", color)
    if not string.IsNilOrEmpty(spriteName) and self.IconBall then
        self.IconBall:SetSprite(spriteName)
    end
end

--- 获取球颜色（消球动效按色定位球 UI 位置用）#消球动效
---@return number|nil
function XUiGridBattleBall:GetColor()
    return self._Color
end

return XUiGridBattleBall
