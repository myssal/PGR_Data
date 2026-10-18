---@class XSkyTowerDisposeRoleNode : XLuaBehaviorNode 移除小人
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerDisposeRoleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerDisposeRole", CsBehaviorNodeType.Action, true, false)


function XSkyTowerDisposeRoleNode:OnEnter()
    self.AgentProxy:DelayRelease()
    self.Node.Status = CsNodeStatus.SUCCESS 
end