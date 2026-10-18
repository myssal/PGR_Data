
---@class XSkyTowerPerformHideBubbleNode : XLuaBehaviorNode 通过演出隐藏演员的气泡
---@field AgentProxy XSkyTowerPerformAgent 通天塔演出行为代理
---@field NpcId number 演员Id
local XSkyTowerPerformHideBubbleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerPerformHideBubble", CsBehaviorNodeType.Action, true, false)

function XSkyTowerPerformHideBubbleNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["NpcId"] == 0 then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.NpcId = self.Fields["NpcId"]
end

function XSkyTowerPerformHideBubbleNode:OnEnter()
    self.AgentProxy:DoHideBubble(self.NpcId)
    self.Node.Status = CsNodeStatus.SUCCESS
end