
---@class XUiGridBirthdayRole : XUiNode
---@field _Control XBirthdayPlotControl
---@field BtnClick XUiComponent.XUiButton
---@field GridBirthdayEnable UnityEngine.Transform
local XUiGridBirthdayRole = XClass(XUiNode, "XUiGridBirthdayRole")

local Duration = 100

function XUiGridBirthdayRole:OnStart()
    self.BtnClick = self.Transform:GetComponent("XUiButton")
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
    self.IsPlay = false
    
    self.GridBirthdayEnable = self.Transform:Find("Animation/GridBirthdayEnable")
end

function XUiGridBirthdayRole:Refresh(storyId, index)
    self.StoryId = storyId
    self.BtnClick:SetRawImage(self._Control:GetHalfBodyImage(self.StoryId))
    local level = self._Control:GetFavorAbilityLevel(self.StoryId)
    self.BtnClick:SetSprite(self._Control:GetFavorLevelIcon(level))
    self.BtnClick:SetNameByGroup(0, level)
    self.BtnClick:SetNameByGroup(1, XUiHelper.GetText("SingleStoryInviteText", self._Control:GetGender(self.StoryId)))
    local invited = self._Control:IsInvited(self.StoryId)
    self.BtnClick:SetDisable(invited)

    self:PlayTimelineAnimation(index)
end

function XUiGridBirthdayRole:PlayTimelineAnimation(index)
    if self.IsPlay then
        return
    end
    if XScheduleManagerPro.HasSchedule(XUiGridBirthdayRole._OnPlayTimelineAnimationScheduleCb, self) then
        return
    end
    local canvasGroup = self.GridBirthdayEnable.parent.gameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    canvasGroup.alpha = 0
    local delay = (index - 1) * Duration
    if delay <= 1 then
        XScheduleManagerPro.ScheduleNextFrame(XUiGridBirthdayRole._OnPlayTimelineAnimationScheduleCb, self)
    else
        XScheduleManagerPro.ScheduleOnce(XUiGridBirthdayRole._OnPlayTimelineAnimationScheduleCb, self, delay)
    end
end

function XUiGridBirthdayRole:OnBtnClick()
    self._Control:ShowSingleStory(self.StoryId)
end

function XUiGridBirthdayRole:_OnPlayTimelineAnimationScheduleCb()
    if XTool.UObjIsNil(self.GridBirthdayEnable) then
        return
    end
    self.GridBirthdayEnable:PlayTimelineAnimation(function()
        self.GridBirthdayEnable.parent.gameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup)).alpha = 1
    end)
    self.IsPlay = true
end

return XUiGridBirthdayRole