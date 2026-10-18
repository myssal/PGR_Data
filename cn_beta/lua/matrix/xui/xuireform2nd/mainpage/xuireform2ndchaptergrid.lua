local XUiButton = require("XUi/XUiCommon/XUiButton")

---@class XUiReform2ndChapterGrid : XUiNode
---@field _Control XReformControl
---@field Parent XUiReform2New
---@field BtnReform XUiComponent.XUiButton
local XUiReform2ndChapterGrid = XClass(XUiNode, "XUiReform2ndChapterGrid")

local GROUP_NAME = 0
local GROUP_NUMBER = 1
local GROUP_GUAN = 2

function XUiReform2ndChapterGrid:OnStart()
    self._Index = 0
    self._Data = nil
    self.BtnReform:AddEventListener(handler(self, self.OnBtnReformClick))
    self._BtnWrapper = XUiButton.New(self.BtnReform)
end

---@param data XUiReform2ndChapterData
function XUiReform2ndChapterGrid:Update(data, index)
    self._Data = data
    self._Index = index

    local button = self.BtnReform
    button:SetNameByGroup(GROUP_NAME, data.Name)
    button:SetNameByGroup(GROUP_GUAN, data.GuanText)
    self:RefreshStatus()
end

function XUiReform2ndChapterGrid:RefreshStatus()
    local data = self._Data
    if not data then
        return
    end

    local button = self.BtnReform
    button:SetNameByGroup(GROUP_NUMBER, data.QualityDesc)
    -- 未解锁的关卡不展示质量进度
    self._BtnWrapper:SetActive("TxtNumber", data.IsUnlocked)
    self._BtnWrapper:SetActive("ImgIcon", data.IsUnlocked)
    button:SetRawImageVisible(data.IsFinished)
    button:ShowReddot(data.IsShowRed)
    button:SetDisable(not data.IsUnlocked)
end

function XUiReform2ndChapterGrid:OnBtnReformClick()
    self.Parent:OnChapterClick(self._Index)
end

return XUiReform2ndChapterGrid
