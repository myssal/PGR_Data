local XUiGridTheatre5Item = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Item')
--- 物品类
---@class XUiGridTheatre5ShopItem: XUiGridTheatre5Item
---@field private _Control XTheatre5Control
local XUiGridTheatre5ShopItem = XClass(XUiGridTheatre5Item, 'XUiGridTheatre5ShopItem')

local DragMoveLimit = nil
local Vector3Cache = Vector3.zero

function XUiGridTheatre5ShopItem:OnStart()
    XUiGridTheatre5Item.OnStart(self)
    
    self.ContainerObj = self.Parent.GameObject
    self.DefaultLocalPosition = self.Transform.localPosition
    self.DefaultSiblingIndex = self.Transform:GetSiblingIndex()
    
    self._AfterEndDragCallBackHandler = handler(self, self._AfterEndDragCallBack)
end

function XUiGridTheatre5ShopItem:OnDisable()
    self:RemoveDraggingEvent()
end

--region 商店拖拽

function XUiGridTheatre5ShopItem:InitDrag()
    if DragMoveLimit == nil or XMain.IsEditorDebug then
        DragMoveLimit = self._Control.ShopControl:GetTheatre5ItemDragLimitFromClientConfig()
    end
    
    -- 物品需要支持拖拽
    ---@type XGoInputHandler
    self.UiDragCom = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    self.UiDragCom:AddBeginDragListener(handler(self, self.OnBeginDrag))
    self.UiDragCom:AddDragListener(handler(self, self.OnDragging))
    self.UiDragCom:AddEndDragListener(handler(self, self.OnEndDrag))
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopItem:OnBeginDrag(eventData)
    -- 缓存拖拽起点屏幕坐标
    self._BeginScreenPos = eventData.position
    self._IsDragging = false
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopItem:OnDragging(eventData)
    if self:_CheckIsCanDrag(eventData) then
        -- 取消选择，关闭详情界面
        if self.IsSelected then
            self:OnGridBtnClickEvent()
        else
            self._Control:SetItemSelected(nil)
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
        end
        
        -- 同步鼠标位置
        self.Transform.localPosition = self:_GetPosByEventData(eventData)
        
        -- 刷新标签显示
        if self.RawImgSelectNo then
            self.RawImgSelectNo.gameObject:SetActiveEx(not self._Control.ShopControl:CheckDraggingItemIsFitInContainer())
        end
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopItem:OnEndDrag(eventData)
    self._IsDragging = false

    if self.CanvasGroup then
        self.CanvasGroup.blocksRaycasts = true
    end
    
    if not self._Control.ShopControl:OnEndDragging(self._AfterEndDragCallBackHandler) then
        self._AfterEndDragCallBackHandler()
    end

    if self.RawImgSelectNo then
        self.RawImgSelectNo.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre5ShopItem:_AfterEndDragCallBack(opType)
    if opType == XMVCA.XTheatre5.EnumConst.ShopOperationType.SellGem then
        -- 卖掉宝珠，需要显示特效
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_GEM_SELLOUT_EFFECT_SHOW, self.Transform.position)
    end
    
    -- 假拖拽，即结束拖拽后始终返回原位置
    self.Transform:SetParent(self.ContainerObj.transform)
    self.Transform.localPosition = self.DefaultLocalPosition
    self.Transform:SetSiblingIndex(self.DefaultSiblingIndex)

    self._Control.ShopControl:SetDraggingItemData(nil)

    -- 关闭商店遮罩
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FULLSHOPAREA_SHOW_STATE, false)

    -- 隐藏售出图标
    self.PanelSellPrice.gameObject:SetActiveEx(false)

    -- 移除拖拽过程中的进入和退出商店区域的事件监听
    self:RemoveDraggingEvent()
end


function XUiGridTheatre5ShopItem:RemoveDraggingEvent()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ENTER_FULLSHOPAREA, self.OnFullShopEnterEvent, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_EXIT_FULLSHOPAREA, self.OnFullShopExitEvent, self)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopItem:_GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.Transform.parent.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end

    Vector3Cache.x = point.x
    Vector3Cache.y = point.y
    
    return Vector3Cache
end

--- 检查是否满足拖拽
function XUiGridTheatre5ShopItem:_CheckIsCanDrag(eventData)
    if not self._IsDragging then
        if Vector2.Distance(self._BeginScreenPos, eventData.position) > DragMoveLimit then
            self._IsDragging = true

            if self.CanvasGroup then
                self.CanvasGroup.blocksRaycasts = false
            end
            
            -- 执行开始拖拽的初始化
            
            -- 取消选择，关闭详情界面
            if self.IsSelected then
                self:OnGridBtnClickEvent()
            end

            -- 设置到拖拽节点
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SET_ITEM_TO_DRAGGINGROOT, self)
            
            -- 缓存
            self._Control.ShopControl:SetDraggingItemData(self.ItemData, self.OwnerContainerType, self.BelongIndex)

            -- 打开商店遮罩
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FULLSHOPAREA_SHOW_STATE, true)

            -- 添加进入和退出商店区域的事件监听
            self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ENTER_FULLSHOPAREA, self.OnFullShopEnterEvent, self)
            self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_EXIT_FULLSHOPAREA, self.OnFullShopExitEvent, self)
            
            return true
        end
    else
        return true
    end
    
    return false
end

function XUiGridTheatre5ShopItem:OnFullShopEnterEvent()
    if self.OwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods and self.OwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection then
        self.PanelSellPrice.gameObject:SetActiveEx(true)

        -- 技能显示“废弃”
        if self.ItemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
            self.TxtSellNum.text = self._Control.ShopControl:GetClientConfigSellSkillLabel()
        else
            ---@type XTableTheatre5Item
            local cfg = self._Control:GetTheatre5ItemCfgById(self.ItemData.ItemId)

            if cfg and self.TxtSellNum then
                local content = string.gsub(self._Control.ShopControl:GetClientConfigSellItemWithPriceShow(), '\\', '')
                self.TxtSellNum.text = XUiHelper.FormatText(content, cfg.SellPrice)
            end
        end
    end
end

function XUiGridTheatre5ShopItem:OnFullShopExitEvent()
    if self.OwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods and self.OwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection then
        self.PanelSellPrice.gameObject:SetActiveEx(false)
    end
end
--endregion

return XUiGridTheatre5ShopItem