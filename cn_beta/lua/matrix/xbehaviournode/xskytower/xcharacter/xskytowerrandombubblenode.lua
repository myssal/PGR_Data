
---@class XSkyTowerRandomBubbleNode : XLuaBehaviorNode 随机弹出气泡
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerRandomBubbleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerRandomBubble", CsBehaviorNodeType.Action, true, false)


function XSkyTowerRandomBubbleNode:OnEnter()
    self.AgentProxy:DoRandomBubble()
    self.Node.Status = CsNodeStatus.SUCCESS 
end