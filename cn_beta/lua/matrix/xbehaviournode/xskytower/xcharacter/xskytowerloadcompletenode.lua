
---@class XSkyTowerLoadCompleteNode : XLuaBehaviorNode 小人加载完成节点（设置标记）
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerLoadCompleteNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerLoadComplete", CsBehaviorNodeType.Action, true, false)


function XSkyTowerLoadCompleteNode:OnEnter()
    self.AgentProxy:DoLoadComplete()
    self.Node.Status = CsNodeStatus.SUCCESS 
end