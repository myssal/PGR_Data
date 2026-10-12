local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")

---@class XUiPanelSkyTowerActivityAsset : XUiPanelActivityAsset
---@field _Control XSkyTowerControl
local XUiPanelSkyTowerActivityAsset = XClass(XUiPanelActivityAsset, "XUiPanelSkyTowerActivityAsset")

function XUiPanelSkyTowerActivityAsset:OnStart()
    self.Super.OnStart(self)
end

function XUiPanelSkyTowerActivityAsset:OnEnable()
    self:RefreshCurrentAssets()
end

function XUiPanelSkyTowerActivityAsset:OnGetLuaEvents()
    return {
        XEventId.EVENT_SKY_TOWER_DATA_CHANGE,
        XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE,
        XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE,
    }
end

function XUiPanelSkyTowerActivityAsset:OnNotify()
    self:RefreshCurrentAssets()
end

function XUiPanelSkyTowerActivityAsset:OnBtnClick(index)
    if not self.ItemIds then
        return
    end

    local itemId = self.ItemIds[index]
    if not itemId then
        return
    end

    if self:CheckCanBuy(itemId) then
        --可购买物品
        XUiManager.OpenBuyAssetPanel(itemId)
    else
        --展示物品详情
        local data
        if self._Control:IsSkyTowerItem(itemId) then
            data = XTool.Clone(XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId))
            data.Count = self._Control:GetItemCount(itemId)
            data.IsTempItemData = true
        else
            local item = XDataCenter.ItemManager.GetItem(itemId)
            data = {
                Id = itemId,
                Count = item ~= nil and tostring(item.Count) or "0"
            }
        end
        if itemId == XDataCenter.ItemManager.ItemId.HongKa then
            local count = XDataCenter.ItemManager.GetCount(itemId)
            XLuaUiManager.Open("UiTip", itemId, false, "UiPurchase", 0, count, true)
        else
            XLuaUiManager.Open("UiTip", data, self.HideSkipBtn, self.RootUiName)
        end
    end
end

function XUiPanelSkyTowerActivityAsset:Refresh(itemIds)
    self.ItemIds = itemIds
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    self.GameObject:SetActiveEx(true)
    for i = 1, 3 do
        if i > #self.ItemIds then
            self["PanelSpecialTool" .. i].gameObject:SetActive(false)
        else
            self["PanelSpecialTool" .. i].gameObject:SetActive(true)
        end
    end

    if self.HideAssetPanel and self.Parent then
        if not (self.PanelSpecialTool3.gameObject.activeSelf or self.PanelSpecialTool2.gameObject.activeSelf or
                self.PanelSpecialTool1.gameObject.activeSelf) then
            self.Parent.AssetPanel:Open()
        else
            self.Parent.AssetPanel:Close()
        end
    end
    
    self.PanelSpecialTool.gameObject:SetActiveEx(self.PanelSpecialTool3.gameObject.activeSelf or self.PanelSpecialTool2.gameObject.activeSelf or
            self.PanelSpecialTool1.gameObject.activeSelf)

    for i, itemId in ipairs(self.ItemIds) do
        local count = self._Control:GetItemCount(itemId)
        local content = CS.XTextManager.GetText("ShopActivityItemCount", count)
        self["PanelSpecialTool" .. i].gameObject:SetActive(true)
        self["TxtSpecialTool" .. i].text = content

        local rImgSpecialTool = self["RImgSpecialTool" .. i]
        if rImgSpecialTool and rImgSpecialTool:Exist() then
            rImgSpecialTool:SetRawImage(self._Control:GetItemIcon(itemId))
        end
    end
end

function XUiPanelSkyTowerActivityAsset:RefreshCurrentAssets()
    if self.ItemIds then
        self:Refresh(self.ItemIds)
    end
end

function XUiPanelSkyTowerActivityAsset:OnRelease()
    self.Super.OnRelease(self)
end

return XUiPanelSkyTowerActivityAsset
lf)
end

return XUiPanelSkyTowerActivityAsset
