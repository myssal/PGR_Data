---@class XUiBigWorldMapSelect : XUiNode
---@field PanelImgSelect UnityEngine.RectTransform
---@field Options XUiButtonGroup
---@field BtnOption XUiComponent.XUiButton
---@field Parent XUiBigWorldMap
---@field _Control XBigWorldMapControl
local XUiBigWorldMapSelect = XClass(XUiNode, "XUiBigWorldMapSelect")

function XUiBigWorldMapSelect:OnStart()
    self._LevelId = 0
    ---@type XBWMapPinData[]
    self._PinDatas = {}

    self._OptionCache = {}

    self:_InitUi()
end

function XUiBigWorldMapSelect:OnOptionClick(index)
    local pinData = self._PinDatas[index]

    if pinData then
        self.Parent:OpenSelectPinDetail(self._LevelId, pinData)
    end
end

---@param pinDatas XBWMapPinData[]
function XUiBigWorldMapSelect:Refresh(levelId, pinDatas, position)
    self._PinDatas = pinDatas
    self._LevelId = levelId
    self:_RefreshOptions(pinDatas)
    self:_RefreshPosition(position)
end

---@param pinDatas XBWMapPinData[]
function XUiBigWorldMapSelect:_RefreshOptions(pinDatas)
    local optionList = {}

    if not XTool.IsTableEmpty(pinDatas) then
        for i, pinData in pairs(pinDatas) do
            local option = self._OptionCache[i]

            if not option then
                option = XUiHelper.Instantiate(self.BtnOption, self.Options.transform)
                self._OptionCache[i] = option
            end

            option.gameObject:SetActiveEx(true)
            option:SetNameByGroup(0, pinData.Name)
            table.insert(optionList, option)
        end
    end
    for i = table.nums(optionList) + 1, table.nums(self._OptionCache) do
        local option = self._OptionCache[i]

        option.gameObject:SetActiveEx(false)
    end

    self.Options:Init(optionList, Handler(self, self.OnOptionClick))
    self.Options:CancelSelect()

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Options.transform)
end

function XUiBigWorldMapSelect:_RefreshPosition(position)
    self.PanelImgSelect.position = position
    self:_RefreshRing(position)
end

function XUiBigWorldMapSelect:_RefreshRing(position)
    local axisConversion = self.Parent:GetAxisConversion()
    local distance = self._Control:GetNearDistance()
    local width = axisConversion:ScreenToUIDistance(self.Transform, distance, 1920)

    if self.Ring then
        self.Ring.sizeDelta = Vector2(width, width)
    end
end

function XUiBigWorldMapSelect:_InitUi()
    self.Ring = self.Transform:FindTransform("Ring")
    self.BtnOption.gameObject:SetActiveEx(false)
end

return XUiBigWorldMapSelect
