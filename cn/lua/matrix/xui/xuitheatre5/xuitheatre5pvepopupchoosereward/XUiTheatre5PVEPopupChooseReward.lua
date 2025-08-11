---道具宝箱三选一
---@class XUiTheatre5PVEPopupChooseReward: XLuaUi
---@field private _Control XTheatre5Control
---@field self._ItemBoxSelectData CSTheatre5ItemBoxSelectData
local XUiTheatre5PVEPopupChooseReward = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEPopupChooseReward')
local XUiTheatre5PVEChooseRewardItem = require("XUi/XUiTheatre5/XUiTheatre5PVEPopupChooseReward/XUiTheatre5PVEChooseRewardItem")
function XUiTheatre5PVEPopupChooseReward:OnAwake()
    self:AddUIListener()
    self:AddEventListener()
    self._ItemGridList = {}
    self._ItemBoxSelectData = nil
    self._ChapterBattlePromoteCb = nil
end

function XUiTheatre5PVEPopupChooseReward:OnStart(chapterBattlePromoteCb)
    self._ChapterBattlePromoteCb = chapterBattlePromoteCb
    self:ChapterBattlePromote() 
end

function XUiTheatre5PVEPopupChooseReward:AddUIListener()
    self:RegisterClickEvent(self.BtnCharacterDetail, self.OnClickCharacterDetail, true)
end

function XUiTheatre5PVEPopupChooseReward:AddEventListener()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_PVE_ITEM_BOX_SELECT, self.OnItemBoxSelect, self)
end

function XUiTheatre5PVEPopupChooseReward:OnItemBoxSelect(theatre5Item)
    XMVCA.XTheatre5.PVEAgency:RequestItemBoxSelect(self._ItemBoxSelectData.BoxInstanceId,theatre5Item.InstanceId,function(success)
            if success then
                local rewardList = {{Id = theatre5Item.ItemId,Type = theatre5Item.ItemType,Count = 1}}
                XLuaUiManager.Open("UiTheatre5PopupGetReward", nil, rewardList, function()
                    self:ChapterBattlePromote()
                end)
            end        
    end)
end

function XUiTheatre5PVEPopupChooseReward:ChapterBattlePromote()
    local itemBoxSelectDatas = self._Control.PVEControl:GetItemBoxSelectData()
    if not XTool.IsTableEmpty(itemBoxSelectDatas) then
        self._ItemBoxSelectData = itemBoxSelectDatas[1]
        self:RefreshPanel(self._ItemBoxSelectData) 
        return
    end
    if self._ChapterBattlePromoteCb then
        local canPveBattle = self._Control.PVEControl:CanPveBattle()
        local nextNodeType = canPveBattle and XMVCA.XTheatre5.EnumConst.PVENodeType.Battle or XMVCA.XTheatre5.EnumConst.PVENodeType.Event
        local chapterBattleData = self._Control.PVEControl:GetCurChapterBattleData()
        local param = canPveBattle and chapterBattleData or self._Control.PVEControl:GetCurEventId()
        self._ChapterBattlePromoteCb(nextNodeType, param)
    end    
end

function XUiTheatre5PVEPopupChooseReward:RefreshPanel(itemBoxSelectData)
    XTool.UpdateDynamicItem(self._ItemGridList, itemBoxSelectData.ItemList, self.GridReward, XUiTheatre5PVEChooseRewardItem, self)  
end

function XUiTheatre5PVEPopupChooseReward:OnClickCharacterDetail()
    XLuaUiManager.Open("UiTheatre5PVECheckCharacter")
end

function XUiTheatre5PVEPopupChooseReward:OnDestroy()
    self._itemGridList = nil
    self._ItemBoxSelectData = nil
    self._ChapterBattlePromoteCb = nil
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_PVE_ITEM_BOX_SELECT, self.OnItemBoxSelect, self)
end

return XUiTheatre5PVEPopupChooseReward