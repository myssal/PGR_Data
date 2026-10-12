--local CSXFightIntStringMapManagerTryGetString = CS.XFightIntStringMapManager.TryGetString

local XUiFightAchievementTip = XLuaUiManager.Register(XLuaUi, "UiFightAchievementTip")

function XUiFightAchievementTip:OnAwake()
    self.Id = 0
    self.StageId = CS.XFight.Instance.FightData.StageId
    self.Agency = XMVCA:GetAgency(ModuleId.XMainLine2)
end

function XUiFightAchievementTip:OnEnable()
    self:StartTimer()
end

function XUiFightAchievementTip:OnDisable()
    self:StopTimer()
end

function XUiFightAchievementTip:StartTimer()
    self:StopTimer()
    XScheduleManagerPro.ScheduleOnce(XUiFightAchievementTip._OnCloseScheduleCb, self, 3000)
end

function XUiFightAchievementTip:StopTimer()
    XScheduleManagerPro.UnSchedule(XUiFightAchievementTip._OnCloseScheduleCb, self)
end

--V2.11 以后要增加样式时，转为加载不同Perfab。然后通过不同Lua接口，增加LuaFuncID让策划在行为树填写。
function XUiFightAchievementTip:Show(achievementId)
    self.Id = achievementId
    self.RImgIcon:SetRawImage(self.Agency:GetStageChapterAchievementIcon(self.StageId))
    self.TxtName.text = self.Agency:GetStageAchievementName(self.StageId , self.Id)
    self:PlayAnimation("Enable")
    self:StartTimer()
end

function XUiFightAchievementTip:_OnCloseScheduleCb()
    self:Close()
end


