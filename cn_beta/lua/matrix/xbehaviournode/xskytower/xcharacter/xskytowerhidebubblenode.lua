
---@class XSkyTowerHideBubbleNode : XLuaBehaviorNode 隐藏小人气泡
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerHideBubbleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerHideBubble", CsBehaviorNodeType.Action, true, false)


function XSkyTowerHideBubbleNode:OnEnter()
    self.AgentProxy:DoHideBubble()
    self.Node.Status = CsNodeStatus.SUCCESS 
end