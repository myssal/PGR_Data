---@class XSkyTowerDestroyEffectNode : XLuaBehaviorNode 销毁角色身上挂载的特效
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerDestroyEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerDestroyEffect", CsBehaviorNodeType.Action, true, false)


function XSkyTowerDestroyEffectNode:OnEnter()
    self.AgentProxy:DoDestroyEffect()
    self.Node.Status = CsNodeStatus.SUCCESS 
end