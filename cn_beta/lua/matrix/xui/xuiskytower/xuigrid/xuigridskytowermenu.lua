---@class XUiGridSkyTowerMenu : XUiNode
---@field _Control XSkyTowerControl
local XUiGridSkyTowerMenu = XClass(XUiNode, "XUiGridSkyTowerMenu")

function XUiGridSkyTowerMenu:OnStart()
    self.TipAnimation = self.Transform:Find("Animation/TipsEnable")
    if self.TipAnimation then
        self.TipAnimation.gameObject:SetActiveEx(false)
    end
end

function XUiGridSkyTowerMenu:RefreshFood(foodId)
    self.Id = foodId
    local workType = XMVCA.XSkyTower.WorkType.Food
    local unlock = self._Control:IsProductUnlock(workType, foodId)
    self.Unlock = unlock
    self.Normal.gameObject:SetActiveEx(unlock)
    self.Disable.gameObject:SetActiveEx(not unlock)
    if not unlock then
        return
    end
    self.RImgIcon:SetRawImage(self._Control:GetProductIcon(workType, foodId))
    self.TxtName.text = self._Control:GetProductName(workType, foodId)
    self.ImgQualityBg:SetSprite(self._Control:GetProductQualityIcon(workType, foodId, false))
end

function XUiGridSkyTowerMenu:RefreshIndent(indentId)
    self.Id = indentId
    local isFinish, isOnGoing, isLock = self._Control:IsFinish(indentId), false, false
    if not isFinish then
        isOnGoing = self._Control:IsPerformShow(indentId)
        isLock = self._Control:IsNotStart(indentId) or not isOnGoing
    end
    self.Unlock = not isLock
    self.PanelOngoing.gameObject:SetActiveEx(isOnGoing)
    self.PanelComplete.gameObject:SetActiveEx(isFinish)
    self.PanelLock.gameObject:SetActiveEx(isLock)

    self.BtnClick:SetNameByGroup(0, self._Control:GetPerformTitleWithStory(indentId))
    self.BtnClick:SetRawImage(self._Control:GetPerformIcon(indentId))
    self:SetRedPointState(self._Control:CheckPerformRedPoint(indentId))
end

function XUiGridSkyTowerMenu:RefreshPerform(performId)
    self:RefreshIndent(performId)
end

function XUiGridSkyTowerMenu:IsUnLock()
    return self.Unlock
end

function XUiGridSkyTowerMenu:SetRedPointState(state)
    if self.BtnClick then
        self.BtnClick:ShowReddot(state)
    end
end

function XUiGridSkyTowerMenu:GetId()
    return self.Id
end

function XUiGridSkyTowerMenu:PlayTip()
    if not self.TipAnimation then
        return
    end
    if not self:IsNodeShow() then
        return
    end
    self.TipAnimation.gameObject:SetActiveEx(false)
    self.TipAnimation.gameObject:SetActiveEx(true)
end

return XUiGridSkyTowerMenu
