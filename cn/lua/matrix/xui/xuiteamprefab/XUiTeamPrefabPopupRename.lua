
local XUiTeamPrefabPopupRename = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabPopupRename")

function XUiTeamPrefabPopupRename:OnAwake()
    self:InitButton()
end

function XUiTeamPrefabPopupRename:InitButton()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnNameCancel.CallBack = function() self:Close() end
    self.BtnNameSure.CallBack = function() self:OnBtnNameSureClick() end
    self.BtnNameSure:SetDisable(true)
    self.InputField.onValueChanged:AddListener(function(v)
        self:OnInputValueChanged(v) 
    end)
    self.TxtNum.text = 0
end

function XUiTeamPrefabPopupRename:OnBtnNameSureClick()
    local str = self.InputField.text
    if string.IsNilOrEmpty(str) then
        XUiManager.TipText("TeamPrefabWithoutName")
        return
    end

    if self.ConfirmCb then
        self.ConfirmCb(str)
    end
    self:Close()
end

function XUiTeamPrefabPopupRename:OnInputValueChanged(v)
    local str = self.InputField.text
    local _, count = string.gsub(str, "[^\128-\193]", "")
    self.TxtNum.text = count
    if str ~= "" then
        self.BtnNameSure:SetDisable(false)
    else
        self.BtnNameSure:SetDisable(true)
    end
end

function XUiTeamPrefabPopupRename:OnStart(confirmCb)
    self.ConfirmCb = confirmCb
end


