
---@class XSkyTowerPerformShowBubbleNode : XLuaBehaviorNode 通过演出展示演员的气泡
---@field AgentProxy XSkyTowerPerformAgent 通天塔演出行为代理
---@field NpcId number 演员Id
---@field DialogId number 对话表Id
---@field Index number 对话内容下标
local XSkyTowerPerformShowBubbleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerPerformShowBubble", CsBehaviorNodeType.Action, true, false)

function XSkyTowerPerformShowBubbleNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["NpcId"] == 0 or self.Fields["DialogId"] == 0 then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.NpcId = self.Fields["NpcId"]
    self.DialogId = self.Fields["DialogId"]
    self.Index = self.Fields["Index"]
end

function XSkyTowerPerformShowBubbleNode:OnEnter()
    self.AgentProxy:DoBubble(self.NpcId, self.DialogId, self.Index)
    self.Node.Status = CsNodeStatus.SUCCESS
end