---@class XUiMainLine2EggsTreasureTips:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2EggsTreasureTips = XLuaUiManager.Register(XLuaUi, "UiMainLine2EggsTreasureTips")

function XUiMainLine2EggsTreasureTips:OnAwake()
    self:RegisterUiEvents()
end

function XUiMainLine2EggsTreasureTips:OnStart(chapterId, eggId)
    self.ChapterId = chapterId
    self.EggId = eggId
end

function XUiMainLine2EggsTreasureTips:OnEnable()
    self:Refresh()
end

function XUiMainLine2EggsTreasureTips:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnTips, self.OnBtnTipsClick)
end

function XUiMainLine2EggsTreasureTips:OnBtnTipsClick()
    local chapterId = self.ChapterId
    local eggId = self.EggId
    self:Close()
    XLuaUiManager.Open("UiMainLine2EggsTreasureMail", chapterId, eggId)
end

function XUiMainLine2EggsTreasureTips:Refresh()
    self.TxtTitle.text = self._Control:GetEggTipsText(self.EggId)
end

return XUiMainLine2EggsTreasureTips