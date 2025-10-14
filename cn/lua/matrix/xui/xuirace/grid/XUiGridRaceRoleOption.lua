---@class XUiGridRaceRoleOption : XUiNode 角色列表项
---@field Parent XUiPanelRaceChoose
---@field _Control XRaceControl
local XUiGridRaceRoleOption = XClass(XUiNode, "XUiGridRaceRoleOption")

local Sort = XEnumConst.Race.Sort

function XUiGridRaceRoleOption:OnStart()
    self.GridMember:SetButtonState(XUiButtonState.Normal)
end

function XUiGridRaceRoleOption:SetRoleId(roleId, sortRule)
    self._RoleId = roleId
    local roleCfg = self._Control:GetRaceCharacterById(roleId)
    local isObsolete = self.Parent.Parent:IsCharacterObsoleteNow(roleId)

    local rate = self.Parent.Parent:GetVotingRate(roleId)
    if XTool.IsNumberValid(rate) then
        self.TxtNum.text = string.format("%s%%", rate)
    else
        self.TxtNum.text = "-%"
    end
    self.RImgHead:SetRawImage(roleCfg.Icon)
    self.ImgFail.gameObject:SetActiveEx(isObsolete)

    if sortRule == Sort.Id or sortRule == Sort.Support then
        self.ImgAttribute.gameObject:SetActiveEx(false)
    else
        local icon = ""
        if sortRule == Sort.Speed then
            icon = self._Control:GetCharacterGradeIcon(roleCfg.ShowSpeed)
        elseif sortRule == Sort.Luck then
            icon = self._Control:GetCharacterGradeIcon(roleCfg.ShowLuck)
        elseif sortRule == Sort.Drift then
            icon = self._Control:GetCharacterGradeIcon(roleCfg.ShowDrift)
        elseif sortRule == Sort.Acc then
            icon = self._Control:GetCharacterGradeIcon(roleCfg.ShowAcc)
        end
        self.ImgAttribute.gameObject:SetActiveEx(true)
        self.ImgAttribute:SetSprite(icon)
    end
end

return XUiGridRaceRoleOption
