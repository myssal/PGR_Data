
---@class XSkyTowerSetRedPointNode : XLuaBehaviorNode 设置顾客红色点位
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerSetRedPointNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerSetRedPoint", CsBehaviorNodeType.Action, true, false)


function XSkyTowerSetRedPointNode:OnEnter()
    self.AgentProxy:DoSetRedPoint()
    self.Node.Status = CsNodeStatus.SUCCESS 
end