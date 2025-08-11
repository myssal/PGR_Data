---@class XUiBigWorldShowLoading : XBigWorldUi
---@field SpineRoot XUiLoadPrefab
---@field Loading UnityEngine.RectTransform
---@field _Control XBigWorldLoadingControl
local XUiBigWorldShowLoading = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldShowLoading")

function XUiBigWorldShowLoading:OnStart()
    XMVCA.XBigWorldUI:SetMaskActive(true)
end

function XUiBigWorldShowLoading:OnDestroy()
    XMVCA.XBigWorldUI:SetMaskActive(false)
end

return XUiBigWorldShowLoading
