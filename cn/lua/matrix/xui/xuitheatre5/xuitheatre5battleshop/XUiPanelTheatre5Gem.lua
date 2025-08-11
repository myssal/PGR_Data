--- 宝珠栏
---@class XUiPanelTheatre5Gem: XUiNode
---@field private _Control XTheatre5Control
---@field Parent XUiTheatre5BattleShop
local XUiPanelTheatre5Gem = XClass(XUiNode, 'XUiPanelTheatre5Gem')
local XUiGridTheatre5ShopGemSlot = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShopGemSlot')

function XUiPanelTheatre5Gem:OnStart(customContainerCls)
    self:InitGemContainers(customContainerCls)
    self:RefreshGemShow()
end

function XUiPanelTheatre5Gem:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_EQUIP_SHOW, self.RefreshGemShow, self)
end

function XUiPanelTheatre5Gem:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_EQUIP_SHOW, self.RefreshGemShow, self)
end

function XUiPanelTheatre5Gem:InitGemContainers(customContainerCls)
    ---@type XUiGridTheatre5ShopGemSlot[]
    self.GridContainers = {}
    self.GridGem.gameObject:SetActiveEx(false)

    local gemMaxSlot = self._Control.PVPControl:GetGemMaxSlot()

    for i = 1, gemMaxSlot do
        ---@type UiObject
        local root = self['Gem'..i]

        if root then
            local go = CS.UnityEngine.GameObject.Instantiate(self.GridGem, root.transform)
            go.name = self.GridGem.name
            go.transform.localPosition = Vector3.zero
            root:AddGameObject(go)

            ---@type XUiGridTheatre5ShopGemSlot
            local grid = customContainerCls and customContainerCls.New(root, self) or XUiGridTheatre5ShopGemSlot.New(root, self)
            grid:Open()
            grid:SetContainerType(XMVCA.XTheatre5.EnumConst.ItemContainerType.EquipBlock)
            grid:SetContainerIndex(i)
            
            self.GridContainers[i] = grid
        end
    end
end

function XUiPanelTheatre5Gem:RefreshGemShow()
    local unlockCount = self._Control:GetGemUnlockSlotCount()
    
    for i, v in ipairs(self.GridContainers) do
        v:SetItemData(self._Control:GetItemInRuneListByIndex(i))
        v:SetLockShow(i > unlockCount, i == unlockCount + 1)
    end
end

return XUiPanelTheatre5Gem