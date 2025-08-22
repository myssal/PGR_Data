---@class XMovieActionActorAlphaChange
---@field UiRoot XUiMovie
local XMovieActionActorAlphaChange = XClass(XMovieActionBase, "XMovieActionActorAlphaChange")
local FRONT_BG_INDEX = 999
function XMovieActionActorAlphaChange:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.Index = paramToNumber(params[1])
    self.BgPath = params[2]
    self.BeginAlpha = paramToNumber(params[3])
    self.EndAlpha = paramToNumber(params[4])
    self.Duration = paramToNumber(params[5])
end

function XMovieActionActorAlphaChange:OnRunning()
    if self.Index < FRONT_BG_INDEX then
        local actor = self.UiRoot:GetActor(self.Index)
        actor:PlayFadeAnimation(self.BeginAlpha, self.EndAlpha, self.Duration)
    else
        local bgIndex = self.Index == FRONT_BG_INDEX and 3 or self.Index % 1000
        local rImgBg = self.UiRoot.UiMovieBg:GetBg(bgIndex)
        if not string.IsNilOrEmpty(self.BgPath) then
            rImgBg:SetBgPath(self.BgPath)
            rImgBg:Show()
        else
            rImgBg:Hide()
        end
        local oldColor = rImgBg:GetColor()
        local newColor = CS.UnityEngine.Color(oldColor.r, oldColor.g, oldColor.b, self.BeginAlpha)
        rImgBg:SetColor(newColor)
        rImgBg:SetAlpha(self.EndAlpha, self.Duration)
    end
end

return XMovieActionActorAlphaChange