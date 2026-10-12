
---@class XUiSkyTowerPopup : XLuaUi
local XUiSkyTowerPopup = XLuaUiManager.Register(XLuaUi, "UiSkyTowerPopup")

function XUiSkyTowerPopup:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiSkyTowerPopup:OnStart(title, content, itemData, cancelCb, confirmCb, isHideBtnCancel)
    self.Title = title
    self.Content = XUiHelper.ReplaceTextNewLine(content)
    self.CancelCb = cancelCb
    self.ConfirmCb = confirmCb
    self.ItemData = itemData
    self.BtnCancel.gameObject:SetActiveEx(not isHideBtnCancel)
    
    self:InitView()
end

function XUiSkyTowerPopup:InitUi()
end 

function XUiSkyTowerPopup:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end

    self.BtnCancel.CallBack = function()
        self:OnBtnCancelClick()
    end

    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
end 

function XUiSkyTowerPopup:InitView()
    self.TxtTittle.text = self.Title
    local isItem = self.ItemData ~= nil
    self.PanelMassage.gameObject:SetActiveEx(not isItem)
    self.PanelMassageTwo.gameObject:SetActiveEx(isItem)
    if isItem then
        self.TxtMassage2.text = self.Content
        if self.ItemData.Icon then
            self.RImgIcon:SetRawImage(self.ItemData.Icon)
        end
        if self.ItemData.Count then
            self.TxtCount.text = self.ItemData.Count
        end
    else
        self.TxtMassage1.text = self.Content
    end
    
end

function XUiSkyTowerPopup:OnBtnConfirmClick()
    self:Close()
    if self.ConfirmCb then self.ConfirmCb() end
end

function XUiSkyTowerPopup:OnBtnCancelClick()
    self:Close()
    if self.CancelCb then self.CancelCb() end
end 