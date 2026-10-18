
---@class XSkyTowerSetStartPointNode : XLuaBehaviorNode 设置顾客起始点
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerSetStartPointNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerSetStartPoint", CsBehaviorNodeType.Action, true, false)


function XSkyTowerSetStartPointNode:OnEnter()
    self.AgentProxy:DoSetStartPoint()
    self.Node.Status = CsNodeStatus.SUCCESS 
end