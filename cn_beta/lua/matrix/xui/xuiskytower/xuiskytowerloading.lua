---@class XUiSkyTowerLoading : XLuaUi
---@field private _Control XSkyTowerControl
local XUiSkyTowerLoading = XLuaUiManager.Register(XLuaUi, "UiSkyTowerLoading")

local CsTime = CS.UnityEngine.Time

--region 生命周期
function XUiSkyTowerLoading:OnEnable()
    self._Progress = 0
    self._IsProgressFinished = false
    self._IsEnableAnimationFinished = false
    self._IsSuccess = false
    self:RefreshBar()
    XScheduleManagerPro.ScheduleForever(self._OnUpdateScheduleCb, self, 0, 0)
    self:PlayAnimation("Enable", handler(self, self.OnEnableAnimationFinished))
end

function XUiSkyTowerLoading:OnDisable()
    self:ClearTimer()
end

function XUiSkyTowerLoading:_OnUpdateScheduleCb()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self:UpdateLoop()
end

function XUiSkyTowerLoading:ClearTimer()
    XScheduleManagerPro.UnSchedule(self._OnUpdateScheduleCb, self)
end

function XUiSkyTowerLoading:OnEnableAnimationFinished(isFinished)
    if not isFinished then
        return
    end
    self._IsEnableAnimationFinished = true
    self:TryFinishLoading()
end
--endregion

--region 界面刷新
-- 每帧推进进度条：目标值取资源实际加载比例，显示值按固定速度逼近目标，
-- 故资源瞬时就绪时进度条仍要走完这段时间，不会直接跳满
function XUiSkyTowerLoading:UpdateLoop()
    if self._IsProgressFinished then
        return
    end
    local target = XMVCA.XSkyTower:GetSceneLoadProgress()
    local step = XMVCA.XSkyTower.SceneLoadingBarSpeed * CsTime.deltaTime
    self._Progress = math.min(self._Progress + step, target)
    self:RefreshBar()
    if self._Progress < 1 then
        return
    end
    self._IsProgressFinished = true
    self:ClearTimer()
    self:TryFinishLoading()
end

function XUiSkyTowerLoading:RefreshBar()
    if XTool.UObjIsNil(self.ImgBar) then
        return
    end
    self.ImgBar.fillAmount = self._Progress
end

function XUiSkyTowerLoading:TryFinishLoading()
    if not self._IsProgressFinished or not self._IsEnableAnimationFinished then
        return
    end
    if self._IsSuccess then
        return
    end
    self._IsSuccess = true
    XMVCA.XSkyTower:OnLoadSceneSuccess()
end
--endregion

return XUiSkyTowerLoading
nFinished))
end

function XUiSkyTowerLoading:RefreshBar()
    if XTool.UObjIsNil(self.ImgBar) then
        return
    end
    self.ImgBar.fillAmount = self._Progress
end

--endregion

return XUiSkyTowerLoading
