
---@class XSkyTowerHideEffectNode : XLuaBehaviorNode 隐藏小人特效
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerHideEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerHideEffect", CsBehaviorNodeType.Action, true, false)


function XSkyTowerHideEffectNode:OnEnter()
    self.AgentProxy:DoHideEffect()
    self.Node.Status = CsNodeStatus.SUCCESS 
end