
---@class XSkyTowerCharAgent : XLuaBehaviorAgent 通天塔员工行为代理
---@field Role XSkyTowerChar
local XSkyTowerCharAgent = XLuaBehaviorManager.RegisterAgent(XLuaBehaviorAgent, "SkyTowerChar")

function XSkyTowerCharAgent:OnAwake()
end

function XSkyTowerCharAgent:SetRole(role)
    self.Role = role
end

function XSkyTowerCharAgent:DoAction(actionId, needFadeCross, crossDuration)
    self.Role:DoAction(actionId, needFadeCross, crossDuration)
end

function XSkyTowerCharAgent:DoActionIndex(index, needFadeCross, crossDuration)
    self.Role:DoActionIndex(index, needFadeCross, crossDuration)
end

function XSkyTowerCharAgent:DoRandomBubble()
    self.Role:DoRandomBubble()
end

function XSkyTowerCharAgent:DoBubbleIndex(index)
    self.Role:DoBubble(index)
end

function XSkyTowerCharAgent:DoHideBubble()
    self.Role:DoHideBubble()
end

function XSkyTowerCharAgent:DoLoadEffect(effectId, x, y, z)
    self.Role:DoLoadEffect(effectId, x, y, z)
end

function XSkyTowerCharAgent:DoHideEffect()
    self.Role:DoHideEffect()
end

function XSkyTowerCharAgent:DoDestroyEffect()
    self.Role:DoDestroyEffect()
end

function XSkyTowerCharAgent:GetActionId(index)
    return self.Role:GetActionId(index)
end

function XSkyTowerCharAgent:GetActionDuration(index)
    return self.Role:GetActionDuration(index)
end

function XSkyTowerCharAgent:DelayRelease()
    self.Role:Dispose()
end

function XSkyTowerCharAgent:DoIsWorking()
    return self.Role:DoIsWorking()
end

function XSkyTowerCharAgent:CheckPlayRepeat(index, isRequireRepeat)
    return self.Role:CheckPlayRepeat(index, isRequireRepeat)
end

function XSkyTowerCharAgent:DoCheckInt(intValue)
    return self.Role:DoCheckInt(intValue)
end

function XSkyTowerCharAgent:DoIsExist()
    return self.Role:Exist() and self.Role._GameObject.activeInHierarchy
end

function XSkyTowerCharAgent:DoRandomPath()
    self.Role:DoFindRandomPoint()
end

function XSkyTowerCharAgent:IsShowDelayBubble()
    return self.Role:IsShowDelayBubble()
end

function XSkyTowerCharAgent:DoRandomBubbleDelay(delay)
    self.Role:DoRandomBubbleDelay(delay)
end

function XSkyTowerCharAgent:DoLoadComplete()
    self.Role:DoLoadComplete()
end

function XSkyTowerCharAgent:DoSetRedPoint()
    self.Role:DoSetRedPoint()
end

function XSkyTowerCharAgent:DoSetGreenPoint()
    self.Role:DoSetGreenPoint()
end

function XSkyTowerCharAgent:DoSetStartPoint()
    self.Role:DoSetStartPoint()
end

function XSkyTowerCharAgent:DoStopMove()
    self.Role:DoStopMove()
end

function XSkyTowerCharAgent:DoIsWorkWithBuff()
    return self.Role:IsWorkWithBuff()
end