local XUiGridTheatre5Item = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Item')

---@class XUiGridTheatre5SettleGem: XUiGridTheatre5Item
local XUiGridTheatre5SettleGem = XClass(XUiGridTheatre5Item, 'XUiGridTheatre5SettleGem')


---@overload
function XUiGridTheatre5SettleGem:OnGridBtnClickEvent()
    self.IsSelected = not self.IsSelected

    self:RefreshSelectState()

    if self.IsSelected then
        self._Control:SetItemSelected(self)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.ItemId, self.OwnerContainerType, self.Parent.DetailPos)
    else
        self._Control:SetItemSelected(nil)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
    end
end

return XUiGridTheatre5SettleGem