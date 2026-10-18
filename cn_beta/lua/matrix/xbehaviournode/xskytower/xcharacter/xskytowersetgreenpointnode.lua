
---@class XSkyTowerSetGreenPointNode : XLuaBehaviorNode 设置顾客绿色点位
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerSetGreenPointNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerSetGreenPoint", CsBehaviorNodeType.Action, true, false)


function XSkyTowerSetGreenPointNode:OnEnter()
    self.AgentProxy:DoSetGreenPoint()
    self.Node.Status = CsNodeStatus.SUCCESS 
end