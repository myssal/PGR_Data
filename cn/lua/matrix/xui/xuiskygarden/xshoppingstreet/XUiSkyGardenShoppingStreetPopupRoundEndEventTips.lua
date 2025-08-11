---@class XUiSkyGardenShoppingStreetPopupRoundEndEventTips : XLuaUi
local XUiSkyGardenShoppingStreetPopupRoundEndEventTips = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetPopupRoundEndEventTips")

--region 生命周期
function XUiSkyGardenShoppingStreetPopupRoundEndEventTips:OnStart(text, pos)
    self.BtnClose.CallBack = function() self:Close() end
    self.TxtDetail.text = text
    self.Pointer.transform.position = pos
end
--endregion

return XUiSkyGardenShoppingStreetPopupRoundEndEventTips
