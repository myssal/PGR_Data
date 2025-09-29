local XMovieActionEffectMove = XClass(XMovieActionBase, "XMovieActionEffectMove")

function XMovieActionEffectMove:Ctor(actionData)
    local params = actionData.Params

    self.EffectKey = params[1]
    self.Time = XMVCA.XMovie:ParamToNumber(params[2])
    self.PosParams = params[3] and XMVCA.XMovie:SplitParam(params[3], "|",true) or nil
    self.Rotation = params[4] and XMVCA.XMovie:ParamToNumber(params[4]) or nil
end

function XMovieActionEffectMove:OnInit()
    XLuaUiManager.SetMask(true)
end

function XMovieActionEffectMove:OnRunning()
    local effectLink = self.UiRoot.EffectGoDic[self.EffectKey]
    if effectLink.transform.childCount == 0 then
        return
    end

    -- 不能使用挂点移动，部分挂点的父节点Pivot非(0.5, 0.5)
    local effectGo = effectLink.transform:GetChild(0)

    -- 移动
    if self.PosParams then
        local pos = XLuaVector3.New(self.PosParams[1], self.PosParams[2], self.PosParams[3])
        if self.Time == 0 then
            effectGo.transform.localPosition = pos
        else
            effectGo.transform:DOLocalMove(pos, self.Time)
        end
    end
    -- 旋转
    if self.Rotation then
        local addRotate = XLuaVector3.New(0, 0, self.Rotation)
        effectGo.transform:DORotate(addRotate, self.Time, CS.DG.Tweening.RotateMode.LocalAxisAdd)
    end
end

function XMovieActionEffectMove:OnExit()
    XLuaUiManager.SetMask(false)
end

return XMovieActionEffectMove