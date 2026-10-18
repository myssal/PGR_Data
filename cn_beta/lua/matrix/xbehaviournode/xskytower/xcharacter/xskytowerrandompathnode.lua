
---@class XSkyTowerRandomPathNode : XLuaBehaviorNode 小人随机寻路
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerRandomPathNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerRandomPath", CsBehaviorNodeType.Action, true, false)


function XSkyTowerRandomPathNode:OnEnter()
    self.AgentProxy:DoRandomPath()
    self.Node.Status = CsNodeStatus.SUCCESS 
end