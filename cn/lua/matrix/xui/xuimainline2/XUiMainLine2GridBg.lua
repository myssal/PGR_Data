---@class XUiMainLine2GridBg : XUiNode
---@field private _Control XMainLine2Control
local XUiMainLine2GridBg = XClass(XUiNode, "XUiMainLine2GridBg")

function XUiMainLine2GridBg:Refresh(bgPath, isUnlock, isStart, isEnd)
    self.RImgBg:SetRawImage(bgPath)
    self.Normal.gameObject:SetActiveEx(isUnlock)
    self.BgStart.gameObject:SetActive(isStart)
    self.BgEnd.gameObject:SetActive(isEnd)
end

function XUiMainLine2GridBg:OnDestroy()
    self:ClearUnlockTimer()
end

-- 播放解锁动画
function XUiMainLine2GridBg:PlayUnlockAnim()
    self:ClearUnlockTimer()
    local effectGo = self.Effect.transform:GetChild(0)
    local anim = XUiHelper.TryGetComponent(effectGo, "Animation/Enable", typeof(CS.UnityEngine.Playables.PlayableDirector))
    if anim then
        local waitTime = 200
        self.Normal.gameObject:SetActiveEx(false)
        self.UnlockTimer = XScheduleManager.ScheduleForever(function()
            self.Normal.gameObject:SetActiveEx(true)
            anim:Play()
        end, waitTime)
    end
end

function XUiMainLine2GridBg:ClearUnlockTimer()
    if self.UnlockTimer then
        XScheduleManager.UnSchedule(self.UnlockTimer)
        self.UnlockTimer = nil
    end
end

return XUiMainLine2GridBg