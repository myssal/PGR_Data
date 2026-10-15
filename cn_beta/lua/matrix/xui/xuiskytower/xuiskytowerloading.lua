---@class XUiSkyTowerLoading : XLuaUi
---@field private _Control XSkyTowerControl
local XUiSkyTowerLoading = XLuaUiManager.Register(XLuaUi, "UiSkyTowerLoading")

local CsTime = CS.UnityEngine.Time

--region 生命周期
function XUiSkyTowerLoading:OnEnable()
    self._IsLoadingActive = true
    self._SceneLoadId = nil
    self._Progress = 0
    self._HasStartedLoading = false
    self._HasFinishedLoading = false
    self._HasNotifiedLoadSuccess = false
    self:RefreshBar()
    self:PlayAnimation("Enable", handler(self, self.OnEnableAnimationFinished))
end

function XUiSkyTowerLoading:OnDisable()
    self._IsLoadingActive = false
    self:ClearTimer()
end

function XUiSkyTowerLoading:OnRelease()
    self._IsLoadingActive = false
    self:ClearTimer()
end

function XUiSkyTowerLoading:_OnUpdateScheduleCb()
    if not self._IsLoadingActive or XTool.UObjIsNil(self.GameObject) then
        return
    end
    self:UpdateLoop()
end

function XUiSkyTowerLoading:ClearTimer()
    XScheduleManagerPro.UnSchedule(self._OnUpdateScheduleCb, self)
end

function XUiSkyTowerLoading:OnEnableAnimationFinished(isFinished)
    if not self._IsLoadingActive or not isFinished or self._HasStartedLoading then
        return
    end
    self._HasStartedLoading = true
    self:PlayAnimation("Loop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    XScheduleManagerPro.ScheduleForever(self._OnUpdateScheduleCb, self, 0, 0)
    self._SceneLoadId = XMVCA.XSkyTower:LoadSceneResources()
end

function XUiSkyTowerLoading:OnDisableAnimationFinished(isFinished)
    if not self._IsLoadingActive or not isFinished or self._HasNotifiedLoadSuccess then
        return
    end
    self._HasNotifiedLoadSuccess = true
    XMVCA.XSkyTower:OnLoadSceneSuccess()
end
--endregion

--region 界面刷新
-- 按固定速度逼近实际进度，进度条走满后再切入退场动画
function XUiSkyTowerLoading:UpdateLoop()
    if not self._HasStartedLoading or self._HasFinishedLoading then
        return
    end
    local targetProgress = XMVCA.XSkyTower:GetSceneLoadProgress()
    local step = XMVCA.XSkyTower.SceneLoadingBarSpeed * CsTime.deltaTime
    local progress = math.min(self._Progress + step, targetProgress)
    if self._Progress ~= progress then
        self._Progress = progress
        self:RefreshBar()
    end
    if self._Progress < 1 then
        return
    end
    self._HasFinishedLoading = true
    self:ClearTimer()
    self:StopAnimation("Loop", false, false)
    self:PlayAnimation("Disable", handler(self, self.OnDisableAnimationFinished))
end

function XUiSkyTowerLoading:RefreshBar()
    if XTool.UObjIsNil(self.ImgBar) then
        return
    end
    self.ImgBar.fillAmount = self._Progress
end

--endregion

return XUiSkyTowerLoading
