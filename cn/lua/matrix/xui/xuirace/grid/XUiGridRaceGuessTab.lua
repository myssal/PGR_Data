---@class XUiGridRaceGuessTab : XUiNode 预测选项
---@field Parent XUiRacePredict
---@field _Control XRaceControl
local XUiGridRaceGuessTab = XClass(XUiNode, "XUiGridRaceGuessTab")

function XUiGridRaceGuessTab:OnStart()
    local activityConfig = self._Control:GetCurrentConfig()
    self.RImgMoney:SetRawImage(XDataCenter.ItemManager.GetItemIcon(activityConfig.ItemId))
end

function XUiGridRaceGuessTab:SetGuessId(guessId)
    self.Transform.name = guessId
    self._GuessId = guessId
    self._GuessCfg = self._Control:GetRaceGuessById(self._GuessId)
    self:Update()
end

function XUiGridRaceGuessTab:Update()
    local isRole = self:IsRole()
    self.TxtName.text = self._GuessCfg.Name
    self.PanelGuessRole.gameObject:SetActiveEx(isRole)
    self.PanleGuessItem.gameObject:SetActiveEx(not isRole)

    local mineOption = self.Parent:GetGuessProjectOption(self._GuessId)
    local isPredicted = self.Parent:IsPredict(self._GuessId)
    self.ImgRoleEmpty.gameObject:SetActiveEx(not isPredicted)
    self.ImgItemEmpty.gameObject:SetActiveEx(not isPredicted)
    self.GridProject:ShowReddot(false)
    self.ImgRoleMask.gameObject:SetActiveEx(isPredicted)
    self.TxtOption.gameObject:SetActiveEx(isPredicted)
    self.ImgFail.gameObject:SetActiveEx(false)

    if isPredicted then
        if isRole then
            local roleCfg = self._Control:GetRaceCharacterById(mineOption)
            local isObsolete = self.Parent:IsCharacterObsoleteNow(mineOption)
            self.GridProject:SetRawImage(roleCfg.Icon)
            self.ImgFail.gameObject:SetActiveEx(isObsolete)
        else
            self.TxtOption.text = self._Control:GetGuessParamDesc(mineOption)
        end
    end

    local isSpecial = self._GuessCfg.SpecialType == 1
    self.ImgTag.gameObject:SetActiveEx(isSpecial)
    self.TxtNum.text = self._Control:GetRaceGuessById(self._GuessId).RewardNum
end

---是否预测角色
function XUiGridRaceGuessTab:IsRole()
    return self._Control:IsGuessNeedCharacter(self._GuessId)
end

function XUiGridRaceGuessTab:GetGuessId()
    return self._GuessId
end

return XUiGridRaceGuessTab
