---@class XMovieActionTextAnim
---@field UiRoot XUiMovie
local XMovieActionTextAnim = XClass(XMovieActionBase, "XMovieActionTextAnim")

function XMovieActionTextAnim:Ctor(actionData)
    local params = actionData.Params

    self.TextId = params[1]
    self.Time = XMVCA.XMovie:ParamToNumber(params[2])
    self.Pos = params[3] and XMVCA.XMovie:SplitParam(params[3], "|",true) or nil
    self.Rotation = params[4] and XMVCA.XMovie:ParamToNumber(params[4]) or nil
    self.Scale = params[5] and XMVCA.XMovie:ParamToNumber(params[5]) or nil
end

function XMovieActionTextAnim:OnRunning()
    self.UiRoot:TextPlayAnim(self.TextId, self.Time, self.Pos, self.Rotation, self.Scale)
end

return XMovieActionTextAnim