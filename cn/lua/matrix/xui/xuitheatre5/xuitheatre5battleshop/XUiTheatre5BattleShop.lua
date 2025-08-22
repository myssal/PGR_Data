---@class XUiTheatre5BattleShop: XLuaUi
---@field private _Control XTheatre5Control
---@field FxCoin XUiPlayParticleSystemGroup
local XUiTheatre5BattleShop = XLuaUiManager.Register(XLuaUi, 'UiTheatre5BattleShop')
local XUiPanelTheatre5TopInfo = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5TopInfo')
local XUiPanelTheatre5Bag = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5Bag')
local XUiPanelTheatre5Store = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5Store')
local XUiPanelTheatre5Skill = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5Skill')
local XUiPanelTheatre5Gem = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5Gem')
local XUiModelTheatre5PVPCharacter3D = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiModelTheatre5PVPCharacter3D')
local XUiPanelTheatre5ShopDetail = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5ShopDetail')
local XUiPanelTheatre5SkillChoice = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5SkillChoice')
local XUiPanelTheatre5ShopNpc = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5ShopNpc')
local XUiPanelTheatre5TempBag = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5TempBag')
local UNITY = CS.UnityEngine

function XUiTheatre5BattleShop:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.OnClickClose))
    self.BtnName:AddEventListener(handler(self, self.OnBtnNameClickEvent))
    self.BtnFight:AddEventListener(handler(self, self.OnBtnFightClickEvent))
    self:BindHelpBtn(self.BtnHelp, 'Theatre5')
    self.BtnShopMaskDetailShow:AddEventListener(handler(self, self.OnBtnMaskDetailShowClickEvent))
    self.BtnBagMaskDetailShow:AddEventListener(self.BtnShopMaskDetailShow.CallBack)

    self.BtnShopMaskDetailShow.gameObject:SetActiveEx(false)
    self.BtnBagMaskDetailShow.gameObject:SetActiveEx(false)
    self.BtnSkillChoiceMaskDetailShow.gameObject:SetActiveEx(false)
    
    -- 卖出道具的特效池
    if self.FxCoin then
        self.FxCoin.gameObject:SetActiveEx(false)
        self._FxCoinPool = XPool.New(function()
            local go = CS.UnityEngine.GameObject.Instantiate(self.FxCoin.gameObject, self.FxCoin.transform.parent)
            go:SetActiveEx(true)
            local particlePlayer = go:GetComponent(typeof(CS.XUiPlayParticleSystemGroup))

            if particlePlayer then
                particlePlayer:FindAllParticleSystems(true)
            end

            return particlePlayer
        end, nil, false)
    end
    
    -- 放置音效
    if self.SFX_EquipBall then
        self.SFX_EquipBall.gameObject:SetActiveEx(false)
    end

    if self.SFX_EquipSkill then
        self.SFX_EquipSkill.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre5BattleShop:OnStart()
    self:InitPanels()
    self:InitCharacter3D()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SET_ITEM_TO_DRAGGINGROOT, self.OnSetItemDraggingEvent, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.OnItemDetailOpenEvent, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL, self.OnItemDetailHideEvent, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SHOP_STATE_CHANGED, self.OnShopStateChangedEvent, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_GEM_SELLOUT_EFFECT_SHOW, self.OnSellOutGemEffectShow, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_BAG_SHOW, self.OnRefreshBagShow, self)

    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ITEM_SKILL_PLACED, self.OnItemSkillPlacedSFX, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ITEM_GEM_PLACED, self.OnItemGemPlacedSFX, self)

    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameModel.PVP then
        self._Control.PVPControl:StartPVPTimer()
    end
    
    self.DraggingItemCheckTimeId = XScheduleManager.ScheduleForever(handler(self, self.EndDragErrorCheckTimer), XScheduleManager.SECOND)
end

function XUiTheatre5BattleShop:OnEnable()
    self:RefreshAll()
end

function XUiTheatre5BattleShop:OnDestroy()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SET_ITEM_TO_DRAGGINGROOT, self.OnSetItemDraggingEvent, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.OnItemDetailOpenEvent, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL, self.OnItemDetailHideEvent, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SHOP_STATE_CHANGED, self.OnShopStateChangedEvent, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_GEM_SELLOUT_EFFECT_SHOW, self.OnSellOutGemEffectShow, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_BAG_SHOW, self.OnRefreshBagShow, self)

    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ITEM_SKILL_PLACED, self.OnItemSkillPlacedSFX, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ITEM_GEM_PLACED, self.OnItemGemPlacedSFX, self)
    
    self._Control.ShopControl:ResetOnShopClose()

    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameModel.PVP then
        self._Control.PVPControl:StopPVPTimer()
    end

    if self.DraggingItemCheckTimeId then
        XScheduleManager.UnSchedule(self.DraggingItemCheckTimeId)
        self.DraggingItemCheckTimeId = nil
    end
end

function XUiTheatre5BattleShop:Close()
    if XLuaUiManager.IsUiShow('UiTheatre5BubbleItemDetail') then
        XLuaUiManager.Remove('UiTheatre5BubbleItemDetail')
    end
    
    self.Super.Close(self)
end

function XUiTheatre5BattleShop:InitPanels()
    self.PanelGemShop.gameObject:SetActiveEx(false)
    self.PanelSkillShop.gameObject:SetActiveEx(false)
    
    ---@type XUiPanelTheatre5TopInfo
    self.PanelTopInfo = XUiPanelTheatre5TopInfo.New(self.PanelTop, self)
    ---@type XUiPanelTheatre5Bag
    self.PanelBag = XUiPanelTheatre5Bag.New(self.ListBag, self)
    ---@type XUiPanelTheatre5Store
    self.PanelStore = XUiPanelTheatre5Store.New(self.PanelGemShop, self)
    ---@type XUiPanelTheatre5Skill
    self.PanelSkill = XUiPanelTheatre5Skill.New(self.ListSkillBag, self)
    ---@type XUiPanelTheatre5Gem
    self.PanelGem = XUiPanelTheatre5Gem.New(self.PanelGem, self)
    ---@type XUiPanelTheatre5SkillChoice
    self.PanelSkillChoice = XUiPanelTheatre5SkillChoice.New(self.PanelSkillShop, self)
    ---@type XUiModelTheatre5PVPCharacter3D
    self.Model3D = XUiModelTheatre5PVPCharacter3D.New(self.UiModelGo, self)
    ---@type XUiPanelTheatre5ShopNpc
    self.ShopNpc = XUiPanelTheatre5ShopNpc.New(self.PanelNpc, self)
    self.ShopNpc:Open()

    if self.PanelTemporaryBag then --todo 资源未打包无引用会报错，确认svn打包后可去除
        ---@type XUiPanelTheatre5TempBag
        self.TempBag = XUiPanelTheatre5TempBag.New(self.PanelTemporaryBag, self)
        self.TempBag:Open()
    end
    
    ---@type XUiPanelTheatre5ShopDetail
    self.PanelShopDetail = XUiPanelTheatre5ShopDetail.New(self.BubbleShopDetail, self)
    self.PanelShopDetail:Close()
    
    --- 判断是商店还是技能三选一
    if self._Control.ShopControl:GetShopState() == XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping then
        self.PanelStore:Open()
    else
        self.PanelSkillChoice:Open()
    end
end

function XUiTheatre5BattleShop:InitCharacter3D()
    ---@type XTableTheatre5Character
    local characterCfg = self._Control:GetCurCharacterCfg()
    
    if characterCfg then
        local animatorController = self._Control.CharacterControl:GetAnimatorControllerByCharacterIdCurMode(characterCfg.Id)
        local detailIdleAnima = self._Control.CharacterControl:GetDetailIdleAnimaByCharacterIdCurMode(characterCfg.Id)
        local fashionId = self._Control.CharacterControl:GetMainlineFashionIdByCharacterIdCurMode(characterCfg.Id)
        
        self.Model3D:UpdateRoleModelByHand(characterCfg.CharacterId, fashionId, animatorController)
        -- 播放战备界面的待机动画
        if not string.IsNilOrEmpty(detailIdleAnima) then
            self.Model3D.UiPanelRoleModel:PlayAnimaCross(detailIdleAnima)
        end
        self.BtnName:SetNameByGroup(0, characterCfg.Name)
    end
end

function XUiTheatre5BattleShop:RefreshAll()
    self.PanelTopInfo:RefreshAll()
    self.PanelBag:RefreshBagShow()
    
    local isNormalShop = self._Control.ShopControl:GetShopState() == XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping
    
    if isNormalShop then
        self.PanelStore:RefreshStoreShow()
        -- 检查引导
        XDataCenter.GuideManager.CheckGuideOpen()
    else
        self.PanelSkillChoice:RefreshSkillChoiceShow()
    end
    self:OnRefreshBagShow()
    self.PanelSkill:RefreshSkillShow()
end

--战斗按钮受商店状态和临时背包清空控制
function XUiTheatre5BattleShop:OnRefreshBagShow()
    local isNormalShop = self._Control.ShopControl:GetShopState() == XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping
    local hasTempBag = self._Control.ShopControl:HasTempBagGrid()  --没有临时背包才能战斗
    self.BtnFight.gameObject:SetActiveEx(isNormalShop and not hasTempBag)
end

function XUiTheatre5BattleShop:OnSetItemDraggingEvent(grid)
    grid.Transform:SetParent(self.PanelDraggingRoot)
end

function XUiTheatre5BattleShop:OnBtnNameClickEvent()
    if not XLuaUiManager.IsUiShow('UiTheatre5BubbleCharacterDetail') then
        XLuaUiManager.Open('UiTheatre5BubbleCharacterDetail')
    end
end

function XUiTheatre5BattleShop:OnClickClose()
    self._Control:ReturnTheatre5Main()
end

function XUiTheatre5BattleShop:OnBtnFightClickEvent()
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameModel.PVP then
        if not XMVCA.XTheatre5:CheckInPVPActivityTime() then
            -- 不提示，提示由踢出定时器弹出
            return
        end
        
        XMVCA.XTheatre5.BattleCom:RequestTheatre5Match(function(success, enemeyData)
            if success then
                XMVCA.XTheatre5.BattleCom:OpenMatchLoadingUi(enemeyData)
            end
        end)
    else
        XMVCA.XTheatre5.BattleCom:OpenMatchLoadingUi()
    end 
    
    self:Close()
end

function XUiTheatre5BattleShop:OnBtnMaskDetailShowClickEvent()
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
end

function XUiTheatre5BattleShop:OnItemDetailOpenEvent(itemData, containerType, uiPos)
    if not XLuaUiManager.IsUiShow('UiTheatre5BubbleItemDetail') then
        XLuaUiManager.Open('UiTheatre5BubbleItemDetail', itemData, containerType, uiPos)
    else
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_ITEM_DETAIL, itemData, containerType, uiPos)
    end
    
    self.BtnShopMaskDetailShow.gameObject:SetActiveEx(true)
    self.BtnBagMaskDetailShow.gameObject:SetActiveEx(true)
    self.BtnSkillChoiceMaskDetailShow.gameObject:SetActiveEx(true)
end

function XUiTheatre5BattleShop:OnItemDetailHideEvent()
    self.BtnShopMaskDetailShow.gameObject:SetActiveEx(false)
    self.BtnBagMaskDetailShow.gameObject:SetActiveEx(false)
    self.BtnSkillChoiceMaskDetailShow.gameObject:SetActiveEx(false)
end

function XUiTheatre5BattleShop:OpenShopDetailPanel()
    self.PanelShopDetail:Open()
end

function XUiTheatre5BattleShop:OnShopStateChangedEvent(afterSkillSelection)
    if not afterSkillSelection then
        self.PanelStore:Close()
        self.PanelSkillChoice:Close()
    end
    
    if self._Control.ShopControl:GetShopState() == XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping then
        self.PanelStore:Open()
        if afterSkillSelection then
            self:PlayAnimationWithMask('QieHuan', function()
                self.PanelSkillChoice:Close()
            end)
        end
    else
        self.PanelSkillChoice:Open()
    end
    
    self:RefreshAll()
end

function XUiTheatre5BattleShop:OnSellOutGemEffectShow(position)
    local fxCoin = self._FxCoinPool:GetItemFromPool()
    
    if fxCoin then
        fxCoin.transform.position = position
        fxCoin:PlayWithEnable(function()
            self._FxCoinPool:ReturnItemToPool(fxCoin)
        end)
    end
end

function XUiTheatre5BattleShop:OnItemSkillPlacedSFX()
    if self.SFX_EquipSkill then
        self.SFX_EquipSkill.gameObject:SetActiveEx(false)
        self.SFX_EquipSkill.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre5BattleShop:OnItemGemPlacedSFX()
    if self.SFX_EquipBall then
        self.SFX_EquipBall.gameObject:SetActiveEx(false)
        self.SFX_EquipBall.gameObject:SetActiveEx(true)
    end
end

--- 间隔时间检查场上有问题的物品
function XUiTheatre5BattleShop:EndDragErrorCheckTimer()
    if UNITY.Input.GetMouseButtonUp(0) or (UNITY.Input.touchCount > 0 and UNITY.Input.GetTouch(0).phase == UNITY.TouchPhase.Ended) then
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CHECK_AND_FIX_DRAGGING_STATE)
    end
end

return XUiTheatre5BattleShop