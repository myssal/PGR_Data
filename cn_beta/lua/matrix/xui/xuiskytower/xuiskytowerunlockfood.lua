---@class XUiSkyTowerUnlockFood : XLuaUi
---@field _Control XSkyTowerControl
local XUiSkyTowerUnlockFood = XLuaUiManager.Register(XLuaUi, "UiSkyTowerUnlockFood")

local UnlockItemType = XMVCA.XSkyTower.UnlockItemType

function XUiSkyTowerUnlockFood:OnAwake()
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

function XUiSkyTowerUnlockFood:OnStart(title, itemDict, onCloseCb)
    self._OnCloseCb = onCloseCb
    self._Handers = {
        [UnlockItemType.Illustrated] = handler(self, self.GetIllustratedInfo),
        [UnlockItemType.Food] = handler(self, self.GetFoodInfo),
        [UnlockItemType.Character] = handler(self, self.GetCharacterInfo),
    }

    --自定义标题
    if not string.IsNilOrEmpty(title) then
        self.TxtTitle.text = title
    end

    --按id从小到大排序
    for _, itemIds in pairs(itemDict) do
        table.sort(itemIds)
    end

    --原料＞食谱/物品＞角色
    for itemType = UnlockItemType.Illustrated, UnlockItemType.Character do
        local datas = itemDict[itemType]
        local count = datas and #datas or 0
        if count > 0 then
            for i = 1, count do
                local go = XUiHelper.Instantiate(self.GridNewContent, self.GridNewContent.parent)
                local grid = {}
                local itemId = datas[i]
                local name, icon, desc, tags = self._Handers[itemType](itemId)
                XUiHelper.InitUiClass(grid, go)
                grid.TxtName.text = name
                grid.RImgIcon:SetRawImage(icon)
                grid.TxtMeterialInfo.requestImage = XMVCA.XSkyTower.RichTextImageCallBack
                grid.TxtMeterialInfo.text = desc
                if type(tags) == "string" then
                    local uiObj = {}
                    XUiHelper.InitUiClass(uiObj, grid.TagType)
                    uiObj.TxtMeterial.text = tags
                else
                    for j = 1, #tags do
                        local tag = j == 1 and grid.TagType or XUiHelper.Instantiate(grid.TagType, grid.TagType.parent)
                        local uiObj = {}
                        XUiHelper.InitUiClass(uiObj, tag)
                        uiObj.TxtMeterial.text = tags[j]
                    end
                end
            end
        end
    end
    self.GridNewContent.gameObject:SetActiveEx(false)

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Content)
    local isSlide = self.Content.rect.width > self.Viewport.rect.width
    if isSlide then
        self.Content:SetPivotX(0)
        self.Content:SetAnchorMin(0, 1)
        self.Content:SetAnchorMax(0, 1)
    else
        self.Content:SetPivotX(0.5)
        self.Content:SetAnchorMin(0.5, 1)
        self.Content:SetAnchorMax(0.5, 1)
    end
    self.Content:SetAnchoredPositionX(0)
end

function XUiSkyTowerUnlockFood:Close()
    if self._OnCloseCb then
        self._OnCloseCb()
    end
    self.Super.Close(self)
end

---原料
function XUiSkyTowerUnlockFood:GetIllustratedInfo(productId)
    local cfg = self._Control:GetIngredientConfig(productId)
    return cfg.Name, cfg.Icon, cfg.Desc, self._Control:GetClientConfigText("ItemTagName", 1)
end

---食谱/物品
function XUiSkyTowerUnlockFood:GetFoodInfo(productId)
    local cfg = self._Control:GetFoodConfig(productId)
    return cfg.Name, cfg.Icon, cfg.Desc, self._Control:GetClientConfigText("ItemTagName", 2)
end

---角色
function XUiSkyTowerUnlockFood:GetCharacterInfo(characterId)
    local cfg = self._Control:GetCharacterConfig(characterId)
    local tags = {}
    for _, skillType in ipairs(cfg.SkillTypes) do
        table.insert(tags, self._Control:GetSkillTypeName(skillType))
    end
    return cfg.Name, cfg.Portrait, cfg.Desc, tags
end

return XUiSkyTowerUnlockFood
