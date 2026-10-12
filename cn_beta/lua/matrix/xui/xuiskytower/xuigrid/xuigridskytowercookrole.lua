---@class XUiGridSkyTowerCookRole : XUiNode 角色弹窗-成员列表格子
---@field private _Control XSkyTowerControl
local XUiGridSkyTowerCookRole = XClass(XUiNode, "XUiGridSkyTowerCookRole")

--region 生命周期
function XUiGridSkyTowerCookRole:OnStart(onClick)
    self.GridTag.gameObject:SetActiveEx(false)
    self.OnClick = onClick
    ---@type UiObject[]
    self.GridSkillTagList = {}
    self:RegisterUiEvents()
end
--endregion

--region 界面刷新
---@param characterId number
function XUiGridSkyTowerCookRole:Refresh(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    self.CharacterId = characterId
    self:RefreshInfo()
    self:RefreshTags()
end

function XUiGridSkyTowerCookRole:RefreshInfo()
    self.RImgHead:SetRawImageEx(self._Control:GetCharacterPortrait(self.CharacterId))
    self.PanelUnlock.gameObject:SetActiveEx(true)
    self.PanelLock.gameObject:SetActiveEx(false)
    -- 通用角色等级恒为1，不展示等级与等级底板
    local showLevel = not self._Control:GetCharacterIsUniversal(self.CharacterId)
    self.TxtLevel.gameObject:SetActiveEx(showLevel)
    self.ImgLabel.gameObject:SetActiveEx(showLevel)
    if showLevel then
        local level = self._Control:GetCurCharacterLevel(self.CharacterId)
        self.TxtLevel.text = string.format("%s%s", self._Control:GetSkyTowerInfoText(1), level)
    end
end

-- 刷新能力标签
function XUiGridSkyTowerCookRole:RefreshTags()
    local skillTypes = self._Control:GetCharacterSkillTypes(self.CharacterId)
    for index, skillType in ipairs(skillTypes) do
        local grid = self.GridSkillTagList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridTag, self.PanelTag)
            self.GridSkillTagList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtTag").text = self._Control:GetSkillTypeName(skillType)
        grid:GetObject("ImgBg"):SetSprite(self._Control:GetSkillTypeSmallIcon(skillType))
    end
    for index = #skillTypes + 1, #self.GridSkillTagList do
        self.GridSkillTagList[index].gameObject:SetActiveEx(false)
    end
end

function XUiGridSkyTowerCookRole:SetSelect(isSelect)
    self.ImgNormal.gameObject:SetActiveEx(not isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
    self.ImgDisable.gameObject:SetActiveEx(false)
end
--endregion

--region 按钮
function XUiGridSkyTowerCookRole:RegisterUiEvents()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
end

function XUiGridSkyTowerCookRole:OnBtnClick()
    if not XTool.IsNumberValid(self.CharacterId) then
        return
    end
    if self.OnClick then
        self.OnClick(self)
    end
end
--endregion

return XUiGridSkyTowerCookRole
