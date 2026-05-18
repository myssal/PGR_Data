---@class XUiGridTheatre6Relic : XUiNode 遗物格子
---@field _Control XTheatre6Control
---@field ListTag UnityEngine.RectTransform
---@field Tag UiObject
local XUiGridTheatre6Relic = XClass(XUiNode, "XUiGridTheatre6Relic")

function XUiGridTheatre6Relic:OnStart()
    if self.GridRelic then
        self.GridRelic:AddEventListener(handler(self, self.OnGridRelicClick))
    end
end

function XUiGridTheatre6Relic:SetRelic(id, count)
    if self._Id ~= id then
        self._LastHighLightTagIds = nil
    end
    self._Id = id
    self._Config = self._Control:GetAttrPackCfgById(id)
    self.RImgIcon:SetRawImage(self._Config.Icon)
    self.ImgBg:SetRawImage(self._Control:GetRelicQualityIcon(self._Config.Quality))
    self.UiTxtNum.text = count
    if self.UiTxtNumBg then
        self.UiTxtNumBg.gameObject:SetActiveEx(count > 1)
    end
    self.ImgMask.gameObject:SetActiveEx(false)
    self:ShowBuildTag()
end

---置灰 显示 +count
function XUiGridTheatre6Relic:ShowMore(count)
    self.ImgMask.gameObject:SetActiveEx(true)
    self.UiTxtAddNum.text = string.format("+%s", count)
end

function XUiGridTheatre6Relic:ShowBuildTag()
    ---@type XTableTheatre6BuildTag[]
    local showTags = self._Control:GetShowBuildTagWithSort(self._Config.BuildTags)
    self.TagUis = {}
    if #showTags > 0 then
        self.ListTag.gameObject:SetActiveEx(true)
        XUiHelper.RefreshCustomizedList(self.Tag.parent, self.Tag, #showTags, function(i, go)
            local uiObject = {}
            XUiHelper.InitUiClass(uiObject, go)
            uiObject.RImgIcon:SetRawImage(showTags[i].Icon)
            if uiObject.HighLight then
                uiObject.HighLight.gameObject:SetActiveEx(false)
            end
            self.TagUis[showTags[i].Id] = uiObject
        end)
    else
        self.ListTag.gameObject:SetActiveEx(false)
    end
    if self._LastHighLightTagIds then
        self:ShowTagHightLight(self._LastHighLightTagIds)
    end
end

function XUiGridTheatre6Relic:ShowTagHightLight(ids)
    self._LastHighLightTagIds = ids
    if not self.TagUis then return end
    for _, ui in pairs(self.TagUis) do
        if ui.HighLight then
            ui.HighLight.gameObject:SetActiveEx(false)
        end
    end
    for _, id in pairs(ids) do
        if self.TagUis[id] and self.TagUis[id].HighLight then
            self.TagUis[id].HighLight.gameObject:SetActiveEx(true)
        end
    end
end

---按当前装备技能 dominant tag 刷新本格 tag 高亮
---@param skillIdsBySlot table<number, table>|nil 存档模式下传入,避免查实时玩法数据
function XUiGridTheatre6Relic:RefreshTagHightLight(skillIdsBySlot)
    if not self._Config then return end
    self:ShowTagHightLight(self._Control:GetEquippedDominantTagInList(self._Config.BuildTags, skillIdsBySlot))
end

function XUiGridTheatre6Relic:SetClickCb(cb)
    self._Click = cb
end

function XUiGridTheatre6Relic:OnGridRelicClick()
    if self._Click then
        self._Click()
    end
end


----------------------------------------------------------------------------------------------

function XUiGridTheatre6Relic:Update(relicId)
    if self._RelicId ~= relicId then
        self._LastHighLightTagIds = nil
    end
    self._RelicId = relicId
    self._Config = self._Control:GetAttrPackCfgById(self._RelicId)
    self.ImgBg:SetRawImage(self._Control:GetRelicQualityIcon(self._Config.Quality))
    self.RImgIcon:SetRawImage(self._Config.Icon)
    self:ShowBuildTag()
end

function XUiGridTheatre6Relic:GetDesc()
    local shortDesc = self._Control:GetAttrPackDesc(self._RelicId, true)
    if not shortDesc or shortDesc == "" then
          return self._Control:GetAttrPackDesc(self._RelicId, false)
    end
  return shortDesc
end

--@return string Icon 用于快速获取技能价格
function XUiGridTheatre6Relic:GetBuyPrice()
    local config = self._Control:GetAttrPackCfgById(self._RelicId)
    return config.BuyPrice or 0
end

return XUiGridTheatre6Relic
