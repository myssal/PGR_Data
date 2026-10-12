---@class XUiGridSkyTowerWorkRole : XUiNode 分配工作界面-可选角色格子
---@field private _Control XSkyTowerControl
---@field Parent XUiPanelSkyTowerWorkChooseRole
local XUiGridSkyTowerWorkRole = XClass(XUiNode, "XUiGridSkyTowerWorkRole")

--region 生命周期
function XUiGridSkyTowerWorkRole:OnStart(onClick)
    self._OnClick = onClick
    ---@type UiObject[] 技能加成文本复用池
    self._GridSkillList = {}
    self:RegisterUiEvents()
end
--endregion

--region 界面刷新
-- 角色格子的展示同时受选中的产品影响，产品变了要整列重刷
---@param characterId number
---@param skillDescList XSkyTowerStaffSkillDesc[] 该角色坐上当前工位后的技能明细，由Parent整列一次性算好
function XUiGridSkyTowerWorkRole:Refresh(characterId, skillDescList)
    self.CharacterId = characterId
    self._SkillDescList = skillDescList
    self:RefreshInfo()
    self:RefreshTag()
    self:RefreshAddition()
end

function XUiGridSkyTowerWorkRole:RefreshInfo()
    self.RImgIcon:SetRawImageEx(self._Control:GetCharacterPortrait(self.CharacterId))
    self.PanelDisable.gameObject:SetActiveEx(false)
    self.TxtName.text = self._Control:GetWorkRoleNameLevelText(self._Control:GetCharacterName(self.CharacterId), self._Control:GetCurCharacterLevel(self.CharacterId))
end

function XUiGridSkyTowerWorkRole:RefreshTag()
    -- 通用角色不占工位，不存在"工作中"的概念
    local isUniversal = self._Control:GetCharacterIsUniversal(self.CharacterId)
    local isWorking = not isUniversal and not self._Control:IsStaffFree(self.CharacterId)
    self.TagCommon.gameObject:SetActiveEx(isUniversal)
    self.TagWorking.gameObject:SetActiveEx(isWorking)
    self.TxtWorking.gameObject:SetActiveEx(isWorking)
end

-- 技能描述按能否加成当前工位着色，图标按技能是默认/愿望/光环/通用取
function XUiGridSkyTowerWorkRole:RefreshAddition()
    local list = self._SkillDescList or table.empty
    local hasEffective = false
    XUiHelper.RefreshUiObjectList(self._GridSkillList, self.PanelSkill, self.GridSkill, #list, function(index, grid)
        local item = list[index]
        hasEffective = hasEffective or item.IsEffective
        grid.TxtPercent.gameObject:SetActiveEx(false)
        grid.TxtSkill.requestImage = XMVCA.XSkyTower.RichTextImageCallBack
        grid.TxtSkill.text = self._Control:GetCharacterSkillDesc(item.SkillId)
        grid.TxtSkill.color = XUiHelper.Hexcolor2Color(self._Control:GetClientConfigValue("SkillEffectiveColor", item.IsEffective and 1 or 2))
        grid.ImgIcon:SetSprite(self._Control:GetClientConfigValue("SkillTypeIcon", item.IconType))
    end)
    self.ImgUpgrade.gameObject:SetActiveEx(hasEffective)
end

function XUiGridSkyTowerWorkRole:SetSelect(isSelect)
    self.ImgNormal.gameObject:SetActiveEx(not isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end
--endregion

--region 按钮
function XUiGridSkyTowerWorkRole:RegisterUiEvents()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClickClick))
end

function XUiGridSkyTowerWorkRole:OnBtnClickClick()
    if not XTool.IsNumberValid(self.CharacterId) then
        return
    end
    if self._OnClick then
        self._OnClick(self)
    end
end
--endregion

return XUiGridSkyTowerWorkRole
