local XUiGridSkyTower3DBase = require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DBase")

---@class XUiGridSkyTower3DDialog : XUiGridSkyTower3DBase
---@field CanvasGroup UnityEngine.CanvasGroup
local XUiGridSkyTower3DDialog = XClass(XUiGridSkyTower3DBase, "XUiGridSkyTower3DDialog")

-- 缓动动画时间
local TweenDuration = 0.2

function XUiGridSkyTower3DDialog:InitUi()
    self._BubbleDuration = self._Control:GetBubbleProperty() * XScheduleManager.SECOND
    self._OnHideCb = function()
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_HIDE_3D_DIALOG, self.Id)
    end
    
    self._OnShowCb = function()
        self:StopHideTimer()
        self.HideTimer = XScheduleManager.ScheduleOnce(function()
            self:TryTweenHide()
        end, self._BubbleDuration)
    end
end

function XUiGridSkyTower3DDialog:OnRefresh(id, content, emoji)
    self.Id = id
    self:TweenShow()
    self.PanelText.gameObject:SetActiveEx(false)
    self.PanelEmoji.gameObject:SetActiveEx(false)
    if content then
        self.TxtDesc.text = content
        self.PanelText.gameObject:SetActiveEx(true)
    end

    if emoji then
        self.RImgEmoji:SetRawIamge(emoji)
        self.PanelEmoji.gameObject:SetActiveEx(true)
    end
end

function XUiGridSkyTower3DDialog:Hide()
    self:StopHideTimer()
    XUiGridSkyTower3DBase.Hide(self)
    self.CanvasGroup.alpha = 0
    self.Target = nil
end
function XUiGridSkyTower3DDialog:TweenShow()
    self.CanvasGroup:DOFade(1, TweenDuration):OnComplete(self._OnShowCb)
end

function XUiGridSkyTower3DDialog:TryTweenHide()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    if XTool.UObjIsNil(self.CanvasGroup) then
        return
    end

    self.CanvasGroup:DOFade(0, TweenDuration):OnComplete(self._OnHideCb)
end

function XUiGridSkyTower3DDialog:StopHideTimer()
    if not self.HideTimer then
        return
    end
    XScheduleManager.UnSchedule(self.HideTimer)
    self.HideTimer = nil
end

return XUiGridSkyTower3DDialog