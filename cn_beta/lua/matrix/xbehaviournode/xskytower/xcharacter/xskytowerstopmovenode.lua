
---@class XSkyTowerStopMoveNode : XLuaBehaviorNode 小人停止移动
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerStopMoveNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerStopMove", CsBehaviorNodeType.Action, true, false)


function XSkyTowerStopMoveNode:OnEnter()
    self.AgentProxy:DoStopMove()
    self.Node.Status = CsNodeStatus.SUCCESS 
end