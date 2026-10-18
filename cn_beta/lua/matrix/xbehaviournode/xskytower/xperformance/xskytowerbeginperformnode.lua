
---@class XSkyTowerBeginPerformNode : XLuaBehaviorNode 演出开始节点
---@field AgentProxy XSkyTowerPerformAgent 通天塔演出行为代理
local XSkyTowerBeginPerformNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerBeginPerform", CsBehaviorNodeType.Action, true, false)


function XSkyTowerBeginPerformNode:OnEnter()
    self.AgentProxy:BeginPerform()
    self.Node.Status = CsNodeStatus.SUCCESS
end