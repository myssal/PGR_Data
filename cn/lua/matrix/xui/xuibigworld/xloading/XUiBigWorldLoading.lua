---@class XUiBigWorldLoadingPartial : XLuaUi
---@field ImgLoading UnityEngine.UI.RawImage
---@field Desc UnityEngine.UI.Text
---@field TitleText UnityEngine.UI.Text
---@field SpineRoot XUiLoadPrefab
---@field Loading UnityEngine.RectTransform
---@field _Control XBigWorldLoadingControl
local XUiBigWorldLoading = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldLoading")

function XUiBigWorldLoading:OnAwake()
    ---@type XTableBigWorldLoading
    self._Loading = false

    XMVCA.XBigWorldUI:SetMaskActive(true)
end

function XUiBigWorldLoading:OnStart(config)
    self._Loading = config
end

function XUiBigWorldLoading:OnEnable()
    self:_RefreshBackground()
    -- 进入空花前关闭音乐
    XLuaAudioManager.StopCurrentBGM()
end

function XUiBigWorldLoading:OnDestroy()
    XMVCA.XBigWorldUI:SetMaskActive(false)
end

function XUiBigWorldLoading:_RefreshBackground()
    local config = self._Loading

    if config then
        self.Desc.text = XUiHelper.ReplaceTextNewLine(config.Desc)
        self.TitleText.text = XUiHelper.ReplaceTextNewLine(config.Name)
        self.ImgLoading:SetRawImage(config.ImageUrl)
    end
end

return XUiBigWorldLoading
