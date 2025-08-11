---@class XUiSkyGardenShoppingStreetGameTips : XLuaUi
local XUiSkyGardenShoppingStreetGameTips = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetGameTips")

--region 生命周期
function XUiSkyGardenShoppingStreetGameTips:OnStart(text, pos)
    self.BtnClose.CallBack = function() self:Close() end
    self.TxtDetail.text = text
    self.GridBuffDetail.transform.position = pos
end
--endregion

return XUiSkyGardenShoppingStreetGameTips
