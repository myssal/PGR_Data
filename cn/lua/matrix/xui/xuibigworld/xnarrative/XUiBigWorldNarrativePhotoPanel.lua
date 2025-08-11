---@class XUiBigWorldNarrativePhotoPanel : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtContent UnityEngine.UI.Text
---@field RImgPhoto UnityEngine.UI.RawImage
---@field BtnPhoto XUiComponent.XUiButton
---@field TranPhoto UnityEngine.RectTransform
local XUiBigWorldNarrativePhotoPanel = XClass(XUiNode, "XUiBigWorldNarrativePhotoPanel")

function XUiBigWorldNarrativePhotoPanel:OnStart()
    self._IsFullScreenPhoto = false
    if not self.BtnPhoto then
        return
    end
    self._RImgPhotoBigScale = Vector3(1,1,1)
    self._RImgPhotoBigOffsetMax = Vector2(0, 0)
    self._RImgPhotoBigOffsetMin = Vector2(0, 0)
    self._RImgPhotoOffsetMax = self.TranPhoto.offsetMax
    self._RImgPhotoOffsetMin = self.TranPhoto.offsetMin
    self._RImgPhotoNormalScale = self.TranPhoto.localScale
    self.BtnPhoto.CallBack = Handler(self, self.OpenPhoto)
end

function XUiBigWorldNarrativePhotoPanel:Refresh(narrativeId)
    self.TxtTitle.text = XMVCA.XBigWorldService:GetNarrativeTitle(narrativeId)
    self.TxtContent.text = XMVCA.XBigWorldService:GetNarrativeContent(narrativeId)
    self.RImgPhoto:SetRawImage(XMVCA.XBigWorldService:GetNarrativeRawImage(narrativeId))
end

function XUiBigWorldNarrativePhotoPanel:OpenPhoto()
    if self._IsFullScreenPhoto then
        self.RImgPhoto.transform.localScale = self._RImgPhotoNormalScale
        self.TranPhoto.offsetMax = self._RImgPhotoOffsetMax
        self.TranPhoto.offsetMin = self._RImgPhotoOffsetMin
    else
        self.RImgPhoto.transform.localScale = self._RImgPhotoBigScale
        self.TranPhoto.offsetMax = self._RImgPhotoBigOffsetMax
        self.TranPhoto.offsetMin = self._RImgPhotoBigOffsetMin
    end
    self._IsFullScreenPhoto = not self._IsFullScreenPhoto
end

return XUiBigWorldNarrativePhotoPanel