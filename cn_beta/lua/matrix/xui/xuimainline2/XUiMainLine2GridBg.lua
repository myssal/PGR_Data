---@class XUiMainLine2GridBg : XUiNode
---@field private _Control XMainLine2Control
---@field private _CueId number|nil 解锁音效Id（入参一次性值，随 UI 生死）
local XUiMainLine2GridBg = XClass(XUiNode, "XUiMainLine2GridBg")

function XUiMainLine2GridBg:Refresh(bgPath, isUnlock, isStart, isEnd)
    self.RImgBg:SetRawImage(bgPath)
    self.Normal.gameObject:SetActiveEx(isUnlock)
    self.BgStart.gameObject:SetActive(isStart)
    self.BgEnd.gameObject:SetActive(isEnd)
end

function XUiMainLine2GridBg:OnDestroy()
    self:ClearTimer()
end

-- 播放解锁动画
function XUiMainLine2GridBg:PlayUnlockAnim(cueId, cueDelay)
    self:ClearTimer()
    local effectGo = self.Effect.transform:GetChild(0)
    local anim = XUiHelper.TryGetComponent(effectGo, "Animation/Enable", typeof(CS.UnityEngine.Playables.PlayableDirector))
    if anim then
        local waitTime = 200
        self.Normal.gameObject:SetActiveEx(false)
        XScheduleManagerPro.ScheduleOnce(XUiMainLine2GridBg._OnUnlockAnimScheduleCb, self, waitTime)
        if cueId then
            XScheduleManagerPro.UnSchedule(XUiMainLine2GridBg._OnPlayCueScheduleCb, self)
            self._CueId = tonumber(cueId)
            XScheduleManagerPro.ScheduleOnce(XUiMainLine2GridBg._OnPlayCueScheduleCb, self, waitTime + tonumber(cueDelay))
        end
    end
end

-- 解锁动画定时器回调：动画组件由 self.Effect 实时推导
function XUiMainLine2GridBg:_OnUnlockAnimScheduleCb()
    self.Normal.gameObject:SetActiveEx(true)
    local effectGo = self.Effect.transform:GetChild(0)
    local anim = XUiHelper.TryGetComponent(effectGo, "Animation/Enable", typeof(CS.UnityEngine.Playables.PlayableDirector))
    if anim then
        anim:Play()
    end
end

-- 解锁音效定时器回调
function XUiMainLine2GridBg:_OnPlayCueScheduleCb()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, self._CueId)
end

function XUiMainLine2GridBg:ClearTimer()
    XScheduleManagerPro.UnSchedule(XUiMainLine2GridBg._OnUnlockAnimScheduleCb, self)
    XScheduleManagerPro.UnSchedule(XUiMainLine2GridBg._OnPlayCueScheduleCb, self)
end

return XUiMainLine2GridBg
