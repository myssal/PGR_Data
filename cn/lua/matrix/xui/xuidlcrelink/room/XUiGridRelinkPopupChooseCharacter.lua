---@class XUiGridRelinkPopupChooseCharacter : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridRelinkPopupChooseCharacter = XClass(XUiNode, "XUiGridRelinkPopupChooseCharacter")

function XUiGridRelinkPopupChooseCharacter:GetCharacterId()
    return self.CharacterId
end

function XUiGridRelinkPopupChooseCharacter:Refresh(characterId)
    self.CharacterId = characterId
    self.RImgHeadIcon:SetRawImage(self._Control:GetCharacterSquareHeadImage(characterId))
    self.TxtName.text = self._Control:GetCharacterName(characterId)
    self.TxtTradeName.text = self._Control:GetCharacterTradeName(characterId)
end

function XUiGridRelinkPopupChooseCharacter:OnSelected(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

return XUiGridRelinkPopupChooseCharacter
