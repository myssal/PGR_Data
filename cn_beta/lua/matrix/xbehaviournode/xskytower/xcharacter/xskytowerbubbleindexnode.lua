
---@class XSkyTowerBubbleIndexNode : XLuaBehaviorNode 根据下标弹出气泡
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
---@field Index number Dialog表中的下标
local XSkyTowerBubbleIndexNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerBubbleIndex", CsBehaviorNodeType.Action, true, false)

function XSkyTowerBubbleIndexNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["Index"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.Index = self.Fields["Index"]
end

function XSkyTowerBubbleIndexNode:OnEnter()
    self.AgentProxy:DoBubbleIndex(self.Index)
    self.Node.Status = CsNodeStatus.SUCCESS 
end