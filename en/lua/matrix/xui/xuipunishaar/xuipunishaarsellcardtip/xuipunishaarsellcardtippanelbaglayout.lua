local XUiPunishaarPanelBagLayoutBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarPanelBagLayoutBase")
local XUiPunishaarSellCardTipGridCard = require("XUi/XUiPunishaar/XUiPunishaarSellCardTip/XUiPunishaarSellCardTipGridCard")

--- 弹窗内暂存区 PanelBagLayout：派生基类，覆写 _GetGridClass 返 SellCardTipGridCard（EnableDrag no-op 禁拖，对齐战斗区）#SellCardTip暂存区禁拖
local XUiPunishaarSellCardTipPanelBagLayout = XClass(XUiPunishaarPanelBagLayoutBase, "XUiPunishaarSellCardTipPanelBagLayout")

function XUiPunishaarSellCardTipPanelBagLayout:_GetGridClass()
    return XUiPunishaarSellCardTipGridCard
end

return XUiPunishaarSellCardTipPanelBagLayout
